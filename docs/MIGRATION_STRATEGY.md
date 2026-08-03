# Stratégie de migrations

Les migrations sont petites, ordonnées et forward-only. Elles peuvent être
rejouées lorsque cela est raisonnable grâce à `if not exists`/`on conflict`.
Les corrections de cette revue modifient directement `0001` à `0008` ; aucune
migration contradictoire `0009` n’est ajoutée.
La génération de types locale est une étape explicite après validation du
schéma. La phase suivante seulement pourra ajouter les tables dossiers,
réparation, planning et qualité.

Pour un futur projet DEV-V2 : créer un projet neuf, configurer ses secrets dans
l’environnement local, vérifier le diff des migrations puis appliquer avec la
procédure Supabase approuvée. Ne jamais réutiliser l’ancien projet Supabase,
ne jamais mettre de secret dans Git et faire tourner les clés après incident ou
changement d’équipe. Cette phase n’a utilisé ni `link`, ni `db push`, ni
déploiement.
