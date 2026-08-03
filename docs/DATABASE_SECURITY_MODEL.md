# Modèle de sécurité des données

L’accès est refusé par défaut : RLS est activé sur toutes les tables
applicatives et les privilèges `public`/`anon` sont révoqués. `authenticated`
ne reçoit que les privilèges nécessaires, puis les policies limitent chaque
ligne à l’organisation et au site autorisés.

Les fonctions `SECURITY DEFINER` utilisent `set search_path = ''`, des objets
entièrement qualifiés et aucun argument d’identité. Leur exécution est
révoquée de `public` puis accordée uniquement à `authenticated` lorsque
nécessaire. Elles servent à lire le profil courant, vérifier rôle/périmètre,
contrôler les imports, valider les chemins Storage et append l’audit.

`public` n’est pas créable par `public`. Un utilisateur ne peut ni s’attribuer
rôle/site, ni changer organisation, créateur ou import parent. GRANT et RLS
sont deux couches complémentaires : les privilèges SQL ne sont jamais
considérés comme un remplacement des policies.
