# Rapport de tests Quote Import

La couverture comprend le parsing CSV, séparateurs, BOM, guillemets, retours internes, formules dangereuses, nombres et dates françaises, normalisation, mapping, doublons, génération de brouillons et machine d’état.

Les fixtures sont synthétiques et anonymisées sous `tests/fixtures/quote-import/`. Elles ne sont jamais chargées automatiquement au runtime.

## Sécurité et limites

Le provider E2E exige simultanément `import.meta.env.DEV`, `VITE_ENABLE_E2E_AUTH=true` et `?e2eAuth=1`. Il ne contient ni mot de passe, ni clé, ni persistance. Le build production servi par `vite preview` refuse cette session et affiche la configuration Supabase manquante.

Les CSV acceptés peuvent déclarer `text/csv`, `application/csv`, `application/vnd.ms-excel`, `text/plain` ou un MIME vide ; l’extension, le contenu, l’encodage et le parsing restent obligatoires. XLSX et PDF ne sont pas implémentés.

Aucune donnée métier n’est persistée et aucune confirmation serveur n’est simulée. Les vulnérabilités npm connues concernent React Router en production et Vitest/Vite/esbuild en développement. `npm audit fix --force` n’est pas appliqué car il imposerait des changements majeurs interdits dans cette branche.
