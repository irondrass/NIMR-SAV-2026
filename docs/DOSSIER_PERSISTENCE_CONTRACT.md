# Contrat de persistance des dossiers

> Conception validée après seconde revue. Aucun SQL n’est implémenté par ce document.

## Principes validés

- Une opération d’import peut produire plusieurs dossiers ; chaque ligne éligible produit au maximum un dossier.
- `quote_import_row_id` est la clé principale d’idempotence. `quote_import_operation_id` est conservé pour l’intégrité référentielle et l’audit.
- La création est effectuée uniquement par une future fonction serveur, pour `IMPORT_DEVIS`, `DIRECTEUR_SAV` ou `ADMIN_TECHNIQUE`. Aucun `INSERT` direct n’est accordé à `authenticated`.
- Une ligne `WARNING` est admise seulement si aucune erreur bloquante ne subsiste, si l’opération est `APPROVED`, et si les avertissements ont été explicitement acceptés côté serveur. Les avertissements sont conservés dans le snapshot et l’audit.
- `ADMIN_TECHNIQUE` est l’exception technique globale inter-organisations ; toute action sensible est auditée.
- Aucun accès dossier spécifique au technicien n’est créé en 0009. L’affectation atelier et les accès associés sont futurs.

## Modèle minimal proposé

Le type PostgreSQL `dossier_status` contient `CREATED`, `PLANNED`, `IN_PROGRESS`, `ON_HOLD`, `QUALITY_PENDING`, `QUALITY_REJECTED`, `QUALITY_APPROVED`, `CLOSED`, `CANCELLED`. Le type et la table sont proposés pour une future migration de fondation 0009 ; ils ne sont pas encore présents.

| Nom | Type PostgreSQL recommandé | Nullable | Source | Valeur initiale | Mutable / rôles | Sensible | Index | Contraintes | Justification |
|---|---|---|---|---|---|---|---|---|---|
| `id` | `uuid` | Non | serveur | `gen_random_uuid()` | Immuable / aucun rôle | Non | PK | unique | Identité technique |
| `organization_id` | `uuid` | Non | import/site | site source | Immuable / aucun rôle | Non | `(organization_id, dossier_number)` | FK composite | Isolation organisationnelle |
| `site_id` | `uuid` | Non | import source | site source | Immuable / aucun rôle | Non | `(site_id, status)` | FK `(site_id, organization_id)` | Isolation par site |
| `quote_import_operation_id` | `uuid` | Non | `quote_import_operations.id` | opération source | Immuable / aucun rôle | Non | index | FK et même périmètre | Intégrité et audit |
| `quote_import_row_id` | `uuid` | Non | `quote_import_rows.id` | ligne source | Immuable / aucun rôle | Non | unique | une seule fois | Idempotence principale |
| `dossier_number` | `text` | Non | serveur PostgreSQL | `DOS-YYYY-000001` | Immuable / aucun rôle | Non | unique par organisation | séquence annuelle org | Identifiant lisible indépendant du devis |
| `status` | `dossier_status` | Non | serveur | `CREATED` | Transition contrôlée / rôles de la matrice | Non | `(site_id,status)` | machine d’états | Cycle de vie |
| `held_from_status` | `dossier_status` | Oui | serveur | `NULL` | Indirectement mutable par transition | Non | aucun | seulement `CREATED`, `PLANNED`, `IN_PROGRESS` | Reprise déterministe depuis `ON_HOLD` |
| `source_snapshot` | `jsonb` objet | Non | devis normalisé validé | snapshot serveur | Immuable / aucun rôle | Oui, données personnelles minimales | Aucun par défaut | objet JSONB, clés explicitement autorisées, aucun secret, aucun email/téléphone/adresse/identité | Preuve de la source sans dépendance au frontend |
| `repair_order_snapshot` | `jsonb` objet | Non | brouillon validé | snapshot serveur | Immuable en 0009 | Données métier | aucun par défaut | objet | Préserver les lignes importées sans modèle atelier prématuré |
| `priority` | `text` | Non | règles/import | `NORMAL` | Selon transitions futures | Non | `(site_id,priority)` si besoin | `LOW/NORMAL/HIGH/URGENT` | Pilotage |
| `currency` | `text` | Non | devis | valeur du devis | Immuable avec snapshot | Non | aucun | code devise valide | Montants interprétables |
| `estimated_amount` | `numeric(14,2)` | Oui | devis | montant normalisé | Immuable en 0009 | Non | aucun | non négatif | Référence économique |
| `created_by` | `uuid` | Non | `auth.uid()` → profil | acteur serveur | Immuable / aucun rôle | Non | index | FK profil actif | Traçabilité |
| `created_at` | `timestamptz` | Non | serveur | `now()` | Immuable | Non | index | serveur uniquement | Horodatage fiable |
| `updated_by` | `uuid` | Non | acteur serveur | `created_by` | Serveur / rôles autorisés | Non | index | FK profil | Dernier acteur |
| `updated_at` | `timestamptz` | Non | serveur | `now()` | Serveur uniquement | Non | aucun | monotone | Dernière mutation |
| `version` | `integer` | Non | serveur | `1` | Incrément atomique | Non | aucun | `> 0` | Concurrence optimiste |
| `closed_at` | `timestamptz` | Oui | serveur | `NULL` | Seulement `QUALITY_APPROVED → CLOSED` | Non | index partiel | présent uniquement en `CLOSED` | Clôture fiable |
| `cancel_reason` | `text` | Oui | acteur, code contrôlé | `NULL` | Seulement à l’annulation | Non | aucun | obligatoire en `CANCELLED` | Explication conservée |

Le numéro est généré exclusivement par PostgreSQL sous la forme `DOS-YYYY-000001`, avec séquence annuelle par organisation, unicité organisationnelle et immutabilité. Il ne réutilise pas le numéro de devis.

### `dossier_number_counters`

Table technique proposée :

| Nom | Type PostgreSQL recommandé | Nullable | Contraintes |
|---|---|---|---|
| `organization_id` | `uuid` | Non | PK composée avec `calendar_year`, FK vers `organizations(id)` |
| `calendar_year` | `integer` | Non | PK composée, année UTC du serveur PostgreSQL, `CHECK (calendar_year BETWEEN 2000 AND 9999)` |
| `last_value` | `bigint` | Non | `CHECK (last_value >= 0)` |
| `updated_at` | `timestamptz` | Non | valeur serveur |

Le compteur est réservé transactionnellement par la fonction de création avec `INSERT ... ON CONFLICT ... DO UPDATE`. Aucun accès direct `authenticated`, aucune policy d’écriture frontend et aucune manipulation hors de la future fonction `SECURITY DEFINER` contrôlée.

Les snapshots client minimaux sont limités à `customer_display_name` et `customer_external_reference`. Aucune adresse, email, téléphone ou identité n’est conservée. Le snapshot véhicule peut contenir `vin`, `registration_number`, `make`, `model`, `variant`, `mileage_km` et `powertrain` uniquement si fourni par le devis.

La paire source doit appartenir au même site et à la même organisation ; la source doit être `APPROVED`. La future fonction conceptuelle est `create_dossier_from_validated_quote(p_quote_import_row_id uuid, p_accept_warnings boolean default false)`. Elle réinterroge la validation serveur. Si la ligne contient des `WARNING`, `p_accept_warnings` doit être `true` et l’acteur doit être `IMPORT_DEVIS`, `DIRECTEUR_SAV` ou `ADMIN_TECHNIQUE`. La transaction vérifie les warnings acceptés, applique la contrainte unique sur `quote_import_row_id`, écrit le dossier et l’audit ensemble. Une course concurrente retourne le dossier existant sans doublon.

L’audit de création conserve uniquement `warnings_accepted`, `warning_count` et des `warning_codes` non sensibles. Il ne contient ni snapshot complet ni donnée personnelle. Un warning non accepté, une validation serveur invalide ou un rôle non autorisé provoque un rejet sans mutation et sans audit métier de succès.

`authenticated` ne reçoit aucun `INSERT`, `UPDATE` ou `DELETE` direct sur `dossiers`. Les futures RPC font `REVOKE EXECUTE FROM PUBLIC` et `anon`. Si elles sont appelées directement par le frontend, seul `authenticated` reçoit `GRANT EXECUTE`; la fonction contrôle ensuite le rôle métier en PostgreSQL. Ce grant ne distingue pas les rôles stockés dans `profile_roles` : `IMPORT_DEVIS`, `DIRECTEUR_SAV` et `ADMIN_TECHNIQUE` sont vérifiés dans le corps de la fonction, et `TECHNICIEN` est systématiquement rejeté en 0009.

## Concurrence et immutabilité

Chaque mutation reçoit `expected_version`. La mise à jour atomique exige l’état et la version attendus, puis incrémente `version`. Le conflit est refusé, jamais fusionné silencieusement. `held_from_status` est renseigné par le serveur à l’entrée dans `ON_HOLD`, limité aux trois états autorisés, puis remis à `NULL` lors de la reprise ; le frontend ne peut pas le modifier directement. Une reprise `ON_HOLD` est autorisée uniquement vers la valeur exacte de `held_from_status` : `CREATED`, `PLANNED` ou `IN_PROGRESS`.

Les futures fonctions `SECURITY DEFINER` utiliseront `search_path = ''`, qualifieront tous les objets avec leur schéma, dériveront l’acteur depuis `auth.uid()`, réinterrogeront les tables d’import et vérifieront profil actif, rôle et accès. Elles ne feront jamais confiance à `organization_id`, `site_id`, `created_by`, `dossier_number` ou au snapshot fourni par le frontend ; ces valeurs seront dérivées ou validées côté serveur. L’audit sera écrit dans la même transaction.

## Hors périmètre 0009

Pas d’affectation technicien, pas de SELECT spécifique à une affectation, pas de CREATE/UPDATE pour `TECHNICIEN`, pas de réouverture, pas de clients/véhicules référentiels, tâches atelier détaillées, pièces, rendez-vous, facturation ou déploiement.
