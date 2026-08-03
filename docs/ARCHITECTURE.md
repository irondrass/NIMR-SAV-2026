# Architecture

Frontend React 18 + TypeScript strict + Vite + Tailwind CSS. `main.tsx` compose uniquement les providers, le routeur et l’Error Boundary. La logique d’interface est répartie dans `layouts`, `components` et `features`. `QuoteImportPage` orchestre le workflow ; le parsing, mapping, normalisation, validation et brouillons vivent dans des fonctions pures testables.

La source de vérité métier sera Supabase/PostgreSQL. `src/lib/supabase.ts` expose un client nul lorsque les variables ne sont pas présentes; aucun fallback local ou backend fictif n’existe. L’authentification est représentée par un provider abstrait destiné à être relié à Supabase Auth.

Les opérations atomiques et les contrôles métier futurs seront réalisés par RPC PostgreSQL. Les données sensibles ne doivent pas être persistées dans localStorage. La RLS sera obligatoire pour chaque table métier.
# Architecture et frontières de phase

Supabase/PostgreSQL est la future source de vérité métier. Le frontend utilise
Supabase Auth et ses tables applicatives via RLS ; il ne persiste aucune donnée
métier dans localStorage ou IndexedDB. La phase 3A ne couvre que la fondation
des imports de devis, le stockage privé et l’audit.
