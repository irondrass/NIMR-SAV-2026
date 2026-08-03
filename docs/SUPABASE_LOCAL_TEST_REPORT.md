# Rapport des tests Supabase locaux

Date : 2026-08-03
Branche : `test/supabase-rls-behavior`
Commit de départ : `0a3b11d`
Supabase CLI : `2.111.0`

## Suites SQL

- `supabase/tests/foundation.sql` : 67 assertions structurelles, PASS 67/67.
- `supabase/tests/rls_behavior.sql` : 67 assertions comportementales, PASS
  67/67.
- Total SQL : 134 assertions, PASS 134/134.

La suite comportementale utilise huit identités synthétiques locales :
`USER_NO_ROLE`, `USER_INACTIVE`, `TECHNICIEN_SITE_A`,
`LECTURE_SEULE_SITE_A`, `IMPORT_DEVIS_SITE_A`, `IMPORT_DEVIS_SITE_B`,
`DIRECTEUR_SITE_A` et `ADMIN_TECHNIQUE`. Elle crée deux organisations, trois
sites, les rôles et accès `READ`/`OPERATE`/`MANAGE`, des imports, lignes,
attachments, événements d’audit et objets Storage, le tout dans une
transaction rollbackée.

L’authentification est simulée avec `set local role anon` ou
`set local role authenticated`, puis `set_config('request.jwt.claim.sub',
...)`; les policies évaluent donc réellement `auth.uid()` et les claims
locaux.

Les tests couvrent l’authentification, les rôles, l’isolation intersites et
interorganisations, les tentatives d’élévation, l’immutabilité des imports et
lignes, les transitions de statut, l’audit append-only, les attachments et
les policies Storage.

## Défaut démontré et correction

Le test Storage positif a démontré un défaut réel dans la migration
`0008_rls_policies.sql` : la sous-requête de `quote_source_files_insert`
résolvait `storage_path_site_id(s.name)` sur la colonne `sites.name` au lieu du
chemin de l’objet. La référence a été corrigée en
`storage_path_site_id(objects.name)`.

Après correction :

- `db reset` : PASS ;
- `db lint --level warning` : PASS — No schema errors found ;
- `foundation.sql` : PASS 67/67 ;
- `rls_behavior.sql` : PASS 67/67.

## Validation complète

- `npm run check:supabase-foundation` : PASS — 20 contrôles statiques ;
- `npm run lint` : PASS ;
- `npm test` : PASS — 7 fichiers, 29 tests ;
- `npm run build` : PASS ;
- `npm run check:no-secrets` : PASS ;
- `npm run test:e2e` : PASS — 12 tests ;
- `npm run test:production-auth` : PASS ;
- `git diff --check` : PASS.

Les artefacts locaux `dist`, `test-results`, `supabase/.temp`,
`supabase/.branches` et le fichier `tsconfig.app.tsbuildinfo` ont été supprimés
après validation. Supabase a ensuite été arrêté.

Aucun accès distant, `supabase link`, `db push`, déploiement, commit, push,
merge ou tag n’a été effectué. Aucun secret ni aucune clé locale n’est présent
dans ce rapport.

## Verdict

```text
DATABASE_RESET=PASS
DATABASE_LINT=PASS
STRUCTURAL_SQL_TESTS=PASS
RLS_BEHAVIOR_TESTS=PASS
CROSS_SITE_ISOLATION=PASS
CROSS_ORGANIZATION_ISOLATION=PASS
ROLE_ESCALATION_PROTECTION=PASS
IMPORT_IMMUTABILITY=PASS
STATUS_TRANSITIONS=PASS
AUDIT_BEHAVIOR=PASS
ATTACHMENT_BEHAVIOR=PASS
STORAGE_BEHAVIOR=PASS
REMOTE_PROJECT=NOT_CONNECTED
REMOTE_MIGRATIONS=NOT_APPLIED
GO_MAIN_MERGE_REVIEW=YES
```
