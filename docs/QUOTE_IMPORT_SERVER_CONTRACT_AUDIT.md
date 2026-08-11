# Audit du contrat serveur quote-import

## Résultat

La preuve serveur est implémentée dans `0009_quote_import_server_contract.sql` et la persistance dossier/OR dans `0010_dossier_persistence.sql`. Ce document conserve les décisions d’audit et leur statut d’implémentation.

## Faits vérifiés

| Élément | Existe | Contraint par PostgreSQL | Limite |
|---|---:|---:|---|
| Opération `APPROVED` | Oui | Oui, avec `approved_by`/`approved_at` | ne décrit pas les lignes |
| Appartenance ligne/opération | Oui | FK | ne prouve pas la validation |
| `validation_status` | Oui | enum textuel | ne prouve pas `issues` |
| `source_values` | Oui | objet JSONB | contenu libre |
| `normalized_values` | Oui | objet JSONB nullable | clés/types libres |
| `issues` | Oui | tableau/objet JSONB | sévérité et blocage libres |
| mapping/drafts/normalisation | Frontend | Non | pas une preuve persistée |
| empreinte métier | `business_fingerprint` | format nullable | déduplication, pas validation |

## Architecture implémentée

L’option D est implémentée : table versionnée de payload validé plus table relationnelle d’issues. Elle donne un typage PostgreSQL, une immutabilité simple, des RLS séparées, un hash/version auditable et une compatibilité avec les lignes historiques sans les déclarer valides par défaut.

Les lignes existantes ne sont pas backfillées automatiquement. Elles restent à revalider et ne peuvent pas alimenter 0010 tant que leur payload/issue n’est pas établi par le serveur.

## Événements d’audit proposés

| Événement | Payload non sensible |
|---|---|
| `quote_import.row_validation_started` | row_id, operation_id, organization_id, site_id, validation_version |
| `quote_import.row_validation_completed` | row_id, validation_version, validation_status, payload_hash, issue_count |
| `quote_import.row_validation_failed` | row_id, validation_version, failure_code non sensible |
| `quote_import.row_warnings_accepted` | row_id, validation_version, warnings_accepted, warning_count, warning_codes |
| `quote_import.operation_approved_with_server_contract` | operation_id, organization_id, site_id, validated_row_count |
| `quote_import.operation_revalidation_required` | operation_id, row_id, reason_code non sensible |

Les événements n’incluent jamais nom client, VIN, immatriculation, `source_values`, `normalized_values` complets, messages libres ou snapshots. L’audit reste append-only via `append_audit_event`.

## Sécurité et RLS implémentées

Les fonctions de validation utilisent `SECURITY DEFINER`, `search_path = ''`, objets qualifiés, `auth.uid()` et profil actif. `ADMIN_TECHNIQUE` est global ; `IMPORT_DEVIS` et `DIRECTEUR_SAV` sont limités au périmètre organisation/site. Les autres rôles peuvent lire selon besoin métier, mais aucune écriture directe authenticated n’est accordée sur payloads/issues. `anon` est refusé, DELETE applicatif interdit et aucune élévation n’est possible.

## Impact précis sur la conception dossier

La 0010 implémente :

- utiliser `quote_import_row_id` comme clé d’idempotence ;
- vérifier opération `APPROVED`, payload immuable, version et `payload_hash` ;
- prendre `warning_count` et `warning_codes` de la table d’issues structurée ;
- construire `source_snapshot` uniquement depuis le payload validé ;
- construire `repair_order_snapshot` uniquement depuis la projection structurée ;
- conserver la signature `create_dossier_from_validated_quote(p_quote_import_row_id, p_accept_warnings)`.

Les quatre documents dossier ne sont pas modifiés dans cette phase. Après approbation humaine du contrat source, une section d’impact pourra y confirmer le renumérotage 0010 et les FK définitives.

## Décisions humaines encore ouvertes

- table relationnelle complète ou payload typé hybride pour les champs de ligne ;
- catalogue initial définitif des `issue_code` ;
- politique des anciennes lignes et statut de revalidation ;
- correction d’un import `APPROVED` par nouvelle version ou nouvelle opération ;
- liste finale des champs d’ordre de réparation ;
- rétention de `source_values` après validation ;
- conservation ou non des données historiques libres ;
- niveau d’accès de `RESPONSABLE_GARANTIE` aux imports.

```text
BRANCH=feature/quote-import-server-contract-design
DESIGN_DOCUMENTS=CREATED
MIGRATIONS=UNCHANGED_0001_0008
DATABASE_LOCAL=NOT_MODIFIED
DATABASE_REMOTE=NOT_MODIFIED
SOURCE_CONTRACT=IMPLEMENTED_0009
ISSUES_CONTRACT=IMPLEMENTED_0009
VALIDATED_PAYLOAD=IMPLEMENTED_0009
DOSSIER_MIGRATION_RENUMBERED_TO_0010
GO_SOURCE_CONTRACT_SQL=NO
GO_DESIGN_REVIEW=YES
```
