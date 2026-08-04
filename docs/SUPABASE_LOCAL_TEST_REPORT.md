# Rapport des tests Supabase locaux et liés

Date : 2026-08-04
Branche : `feature/supabase-dev-connection`
Supabase CLI : `2.111.0`

## Migrations et pgTAP

- Migrations locales : `0001` à `0008`.
- Migrations distantes : `0001` à `0008`.
- Migration `0009` : absente localement et absente de l’historique distant.
- pgTAP est activé automatiquement par le CLI pendant `supabase test db`.
- `extensions.plan(integer)` fonctionne dans une transaction distante directe.

Les débuts des deux suites sont distincts volontairement :

- `foundation.sql` utilise `extensions, public, storage, pg_catalog`, sans
  `auth`, afin que `pg_get_expr` conserve la qualification textuelle
  `auth.uid()` dans l’assertion 41.
- `rls_behavior.sql` utilise `extensions, public, auth, storage, pg_catalog`
  pour simuler les claims et appeler `auth.uid()` réellement.

Chaque fichier contient exactement un `set local search_path` et un plan de
67 tests. Aucun search_path redondant ne subsiste après `plan()`.

## Résultats SQL

- `npx supabase test db` : PASS — 134/134.
  - `foundation.sql` : 67/67.
  - `rls_behavior.sql` : 67/67.
- `npx supabase test db --linked` : connu comme bloqué avant les assertions
  par le contexte du runner CLI `2.111.0`, avec `plan(integer) does not exist`.
  Les fichiers actuels sont bien exécutés, comme le confirme l’erreur à la
  ligne 5.

## Lint et validation

- Lint public local : PASS.
- Lint public distant : PASS.
- `npx supabase migration list` : local et distant alignés sur `0001`–`0008`.
- `npx supabase db push --dry-run` : PASS — remote database up to date.
- `npm run check:supabase-foundation` : PASS — 24 contrôles.
- `npm run lint` : PASS — `supabase/.temp/**` et
  `supabase/.branches/**` sont exclus par `eslint.config.js`.
- `npm test` : PASS — 29 tests.
- `npm run build` : PASS.
- `npm run check:no-secrets` : PASS.
- `git diff --check` : PASS.

Les répertoires `supabase/.temp/` et `supabase/.branches/` sont conservés
physiquement et apparaissent exactement une fois chacun dans `.gitignore`.

Aucune clé ni aucun secret n’est présent dans ce rapport. Aucun commit, push
Git, `db push`, nouvelle migration, `db reset --linked` ou déploiement n’a été
effectué.

## Verdict

```text
LOCAL_MIGRATIONS=0001-0008
REMOTE_MIGRATIONS=0001-0008
LOCAL_SQL_TESTS=134/134_PASS
LINKED_SQL_TESTS=BLOCKED_BY_CLI_2_111_0_RUNNER
LOCAL_PUBLIC_LINT=PASS
REMOTE_PUBLIC_LINT=PASS
REMOTE_DATABASE=UP_TO_DATE
ESLINT=PASS
GO_DEV_CONNECTION_COMMIT=YES_WITH_KNOWN_CLI_LIMITATION
```
