# NIMR SAV PRO V2

Fondation React/TypeScript/Vite pour le pilotage atelier SAV NIMR Tunisie. Le seul point d’entrée d’un dossier est l’import validé d’un devis.

## Démarrage

```powershell
npm install
npm run dev
```

La phase 1 ne contient aucun compte, aucune donnée de démonstration et aucun workflow métier actif. Sans `VITE_SUPABASE_URL` et `VITE_SUPABASE_ANON_KEY`, les routes protégées affichent la configuration manquante et n’instancient pas de session fictive.

## Commandes

`npm run lint` · `npm test` · `npm run build` · `npm run check:no-secrets` · `npm run test:e2e`

## Structure

Le code est organisé par fonctionnalités sous `src/features`, avec les contrats transverses dans `src/types`, l’authentification abstraite dans `src/auth`, le client Supabase dans `src/lib` et les routes dans `src/routes`.

Voir [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md), [docs/QUOTE_IMPORT_SPECIFICATION.md](docs/QUOTE_IMPORT_SPECIFICATION.md) et [docs/DEVELOPMENT_PLAN.md](docs/DEVELOPMENT_PLAN.md).
