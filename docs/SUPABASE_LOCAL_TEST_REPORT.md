# Rapport des tests Supabase locaux

Date : 2026-08-03
Branche : `test/supabase-local-execution`
Supabase CLI : `2.111.0`

## Résultats

- `npx supabase db reset` : PASS
- `npx supabase db lint --level warning` : PASS — No schema errors found
- `npx supabase test db` : PASS — 67 tests exécutés, 67 réussis
- `npm run check:supabase-foundation` : PASS — 10 contrôles statiques
- `npm run lint` : PASS
- `npm test` : PASS — 7 fichiers, 29 tests
- `npm run build` : PASS
- `npm run check:no-secrets` : PASS — aucun secret détecté
- `git diff --check` : PASS

## Corrections pgTAP

Le fichier `supabase/tests/foundation.sql` utilise désormais les signatures
pgTAP non ambiguës avec conversions explicites en `name` et descriptions :

- `has_table` est appelé directement pour les 11 tables de la fondation,
  notamment `organizations`, `sites`, `profiles`, `roles`, `profile_roles`,
  `profile_site_access`, `quote_import_operations`, `quote_import_rows`,
  `quote_mapping_templates`, `attachments` et `audit_events`.
- `col_is_unique` vérifie `operation_key` avec sa signature complète.
- `col_is_unique` vérifie l’unicité composée de
  `import_operation_id` et `source_row_number` à l’intérieur d’un import.
- `has_index` utilise sa signature complète pour
  `quote_import_source_hash_idx`.
- Aucun appel pgTAP retournant du TAP n’est imbriqué dans `ok()`.
- L’assertion de contrainte d’approbation utilise une sous-requête booléenne
  valide.
- Le plan unique est `select plan(67)`, correspondant aux 67 assertions
  exécutées.

Aucun accès distant, aucune migration distante et aucun déploiement n’ont été
effectués. Aucun secret ni clé n’est présent dans ce rapport.

## Verdict

```text
DATABASE_RESET=PASS
DATABASE_LINT=PASS
PGTAP_SIGNATURES=PASS
PGTAP_PLAN=PASS
SQL_TESTS=PASS
REMOTE_PROJECT=NOT_CONNECTED
REMOTE_MIGRATIONS=NOT_APPLIED
GO_SUPABASE_FOUNDATION_COMMIT=YES
```
