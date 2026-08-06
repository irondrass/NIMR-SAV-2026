# Audit de conception dossier — seconde revue

## Décisions validées

- `ADMIN_TECHNIQUE` est l’exception technique globale inter-organisations ; toutes ses actions sensibles sont auditées.
- Une opération d’import produit plusieurs dossiers au maximum, un par ligne éligible ; `quote_import_row_id` garantit l’idempotence et `quote_import_operation_id` garantit l’intégrité et la traçabilité.
- Les `WARNING` sont conservés intégralement uniquement dans le snapshot métier autorisé. L’audit conserve exclusivement `warnings_accepted`, `warning_count` et les `warning_codes` non sensibles, sans texte libre ni donnée personnelle.
- La création serveur est réservée à `IMPORT_DEVIS`, `DIRECTEUR_SAV` et `ADMIN_TECHNIQUE`, sans INSERT direct `authenticated`.
- Le numéro PostgreSQL est `DOS-YYYY-000001`, séquentiel par année et organisation, unique par organisation et immuable.
- `TECHNICIEN` n’a aucun CREATE, UPDATE ou SELECT spécifique d’affectation en 0009 ; ce workflow est futur.
- `CONTROLE_QUALITE` décide depuis `QUALITY_PENDING`, tandis que le `CHEF_ATELIER` soumet depuis `IN_PROGRESS`.
- `RESPONSABLE_GARANTIE` dispose seulement du SELECT sur ses sites en 0009.
- `held_from_status` est un `dossier_status` nullable, géré par le serveur à l’entrée et à la sortie de `ON_HOLD`.
- L’annulation est réservée à `DIRECTEUR_SAV` et `ADMIN_TECHNIQUE` depuis `CREATED`, `PLANNED`, `IN_PROGRESS` ou `ON_HOLD` ; motif requis.
- La clôture est uniquement `QUALITY_APPROVED → CLOSED`, par `CHEF_ATELIER`, `DIRECTEUR_SAV` ou `ADMIN_TECHNIQUE`, avec `closed_at` serveur.
- `CLOSED` et `CANCELLED` sont terminaux ; aucune réouverture en 0009.
- Les snapshots excluent adresse, email, téléphone et identité ; ils conservent seulement les champs client/véhicule validés dans le contrat.
- `source_snapshot` est sensible : il contient des données personnelles minimales, est un objet JSONB à clés explicitement autorisées, n’a aucun index GIN par défaut, n’inclut aucun secret/email/téléphone/adresse/identité, n’est jamais copié intégralement dans `audit_events` ni écrit dans les logs, et reste accessible uniquement selon les RLS du dossier.
- `dossier_number_counters` est une table technique réservée à la fonction `SECURITY DEFINER`, avec réservation transactionnelle et année UTC PostgreSQL.

## Audit de l’existant

Les migrations 0001–0008 fournissent les organisations, sites, profils, rôles, accès, imports, lignes, pièces jointes, audit append-only et helpers RLS nécessaires. Le domaine `src/features/quote-import/**` reste local jusqu’à la confirmation serveur : parsing, normalisation, mapping, validation, hash et brouillon ne créent pas encore de dossier persistant.

La conception proposée respecte les garde-fous existants : périmètre organisation/site, profil actif, immutabilité de la source, absence de suppression physique, version optimiste et audit sans secrets. Aucun SQL, TypeScript, test applicatif, migration ou base n’a été modifié dans cette revue.

Les futures fonctions `SECURITY DEFINER` devront définir `search_path = ''`, qualifier chaque objet par son schéma, dériver l’acteur par `auth.uid()`, ne jamais faire confiance aux paramètres frontend `organization_id`, `site_id`, `created_by`, `dossier_number` ou snapshot, réinterroger les tables d’import, vérifier profil actif/rôle/accès et produire l’audit dans la même transaction.

Les RPC appliqueront `REVOKE EXECUTE FROM PUBLIC` et `anon`. Un éventuel `GRANT EXECUTE` à `authenticated` ne sera qu’un droit d’appel : les rôles métier sont vérifiés dans la fonction PostgreSQL depuis `profile_roles`. Les fonctions `create_dossier_from_validated_quote(...)` et `transition_dossier(...)` rejettent toujours `TECHNICIEN` en 0009. Un appel rejeté est sans mutation et sans audit métier de succès.

## Catalogue d’audit

Tous les événements utilisent un timestamp serveur et un payload objet minimal. Les événements ne contiennent jamais le snapshot client/véhicule complet.

| Événement | Déclencheur | Payload minimal additionnel |
|---|---|---|
| `dossier.created_from_validated_quote` | création idempotente réussie | source operation/row, `resulting_version` |
| `dossier.status_changed` | uniquement `CREATED → PLANNED`, `PLANNED → IN_PROGRESS` ou `QUALITY_REJECTED → IN_PROGRESS` | `from_status`, `to_status`, versions |
| `dossier.put_on_hold` | entrée `ON_HOLD` | `from_status`, `to_status`, code motif, versions |
| `dossier.resumed` | reprise | `from_status`, `to_status`, code motif, versions |
| `dossier.cancelled` | annulation | `from_status`, `to_status`, code motif, versions |
| `dossier.quality_submitted` | `CHEF_ATELIER` vers pending | `from_status`, `to_status`, versions |
| `dossier.quality_rejected` | refus qualité | `from_status`, `to_status`, code motif, versions |
| `dossier.quality_approved` | validation qualité | `from_status`, `to_status`, versions |
| `dossier.closed` | clôture | `from_status`, `to_status`, versions |

Chaque payload comprend : `dossier_id`, `organization_id`, `site_id`, `actor_profile_id`, `expected_version`, `resulting_version`, `timestamp` serveur, et `from_status`/`to_status` lorsque applicable. Le code motif est obligatoire pour attente, reprise, refus qualité et annulation.

## Verdict

```text
GO_SQL_IMPLEMENTATION=YES_AFTER_DOCUMENT_COMMIT
GO_DESIGN_REVIEW=APPROVED
```
