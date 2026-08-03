# Rapport des tests Supabase locaux

Le contrat pgTAP est dans `supabase/tests/foundation.sql` et déclare 66 tests
structurels et comportementaux : rôles, isolation multi-site, imports,
immutabilité, audit append-only, Storage et tables hors périmètre. Il doit être
lancé avec `supabase test db` dans un environnement local Supabase/Docker.

`npm run check:supabase-foundation` déclare 10 contrôles statiques. Il vérifie
les fichiers et motifs de sécurité mais ne remplace ni PostgreSQL ni pgTAP.

Cette branche ne connecte aucun projet distant. La CLI Supabase étant
indisponible, les tests SQL restent **NOT_EXECUTED** : aucun résultat n’est
simulé et `SQL_TESTS=NOT_EXECUTED`.
