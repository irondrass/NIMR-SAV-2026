# Architecture

Frontend React 18 + TypeScript strict + Vite + Tailwind CSS. `main.tsx` compose uniquement les providers, le routeur et l’Error Boundary. La logique d’interface est répartie dans `layouts`, `components` et `features`, dont `quote-import` est le seul point de création future d’un dossier.

La source de vérité métier sera Supabase/PostgreSQL. `src/lib/supabase.ts` expose un client nul lorsque les variables ne sont pas présentes; aucun fallback local ou backend fictif n’existe. L’authentification est représentée par un provider abstrait destiné à être relié à Supabase Auth.

Les opérations atomiques et les contrôles métier futurs seront réalisés par RPC PostgreSQL. Les données sensibles ne doivent pas être persistées dans localStorage. La RLS sera obligatoire pour chaque table métier.
