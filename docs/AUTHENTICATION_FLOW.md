# Flux d’authentification

Le client est créé uniquement si `VITE_SUPABASE_URL` et
`VITE_SUPABASE_ANON_KEY` existent. `AuthProvider` écoute `onAuthStateChange`,
charge le profil, les rôles et les sites autorisés, puis expose
`loading`, `authenticated`, `unauthenticated` ou `configuration_error`.

Il n’y a pas de session locale ni d’utilisateur codé en dur en production. Le
mode E2E est possible uniquement en développement, avec
`VITE_ENABLE_E2E_AUTH=true` et `?e2eAuth=1`. Aucune clé secrète ou token n’est
logué.

