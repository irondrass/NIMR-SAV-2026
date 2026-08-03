# NIMR SAV PRO V2

Fondation React/TypeScript/Vite pour le pilotage atelier SAV NIMR Tunisie. Le seul point d’entrée d’un dossier est l’import validé d’un devis.

## Démarrage

```powershell
npm install
npm run dev
```

La phase 3A ne contient aucun compte ni donnée de démonstration. Sans `VITE_SUPABASE_URL` et `VITE_SUPABASE_ANON_KEY`, les routes protégées affichent la configuration manquante et n’instancient pas de session fictive.

## Commandes

`npm run lint` · `npm test` · `npm run build` · `npm run check:no-secrets` · `npm run check:supabase-foundation` · `npm run test:e2e` · `npm run test:production-auth`

## Fondation Supabase locale

Les migrations `0001` à `0008` sont forward-only et n’ont jamais été
appliquées à distance. Le contrôle `check:supabase-foundation` est statique ;
il ne remplace pas PostgreSQL/pgTAP. `SQL_TESTS=NOT_EXECUTED` tant que la CLI
Supabase n’est pas disponible.

`ADMIN_TECHNIQUE` est l’unique exception d’accès technique global. `DIRECTEUR_SAV`
est toujours limité aux sites explicitement attribués. Les imports sont créés
par `IMPORT_DEVIS`, `DIRECTEUR_SAV` ou `ADMIN_TECHNIQUE` avec un scope
`OPERATE`/`MANAGE`.

## Structure

Le code est organisé par fonctionnalités sous `src/features`, avec les contrats transverses dans `src/types`, l’authentification abstraite dans `src/auth`, le client Supabase dans `src/lib` et les routes dans `src/routes`.

Voir [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md), [docs/QUOTE_IMPORT_SPECIFICATION.md](docs/QUOTE_IMPORT_SPECIFICATION.md) et [docs/DEVELOPMENT_PLAN.md](docs/DEVELOPMENT_PLAN.md).
# NIMR SAV PRO V2

La fondation Supabase locale de la phase 3A est décrite dans
[`docs/SUPABASE_FOUNDATION.md`](docs/SUPABASE_FOUNDATION.md). Aucun projet
distant n’est connecté. Les migrations locales et le contrat pgTAP se trouvent
dans `supabase/`; les tests SQL sont déclarés **NOT_EXECUTED** si Supabase CLI
ou Docker ne sont pas disponibles.
