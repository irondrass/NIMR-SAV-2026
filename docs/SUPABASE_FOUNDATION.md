# Fondation Supabase locale

Phase 3A prépare exclusivement la persistance locale PostgreSQL/Supabase. Les
migrations `0001` à `0008` créent organisations, sites, profils Auth, rôles,
accès multi-site, imports de devis, pièces jointes, audit et RLS. Elles ne
créent aucun dossier SAV ni donnée de démonstration.

`ADMIN_TECHNIQUE` possède une exception d’accès global contrôlée par un rôle de
référence. `DIRECTEUR_SAV` n’obtient aucun accès global : ses profils, rôles,
sites, imports, templates et audits sont filtrés par les sites explicitement
présents dans `profile_site_access`. Les imports sont réservés à
`IMPORT_DEVIS`, `DIRECTEUR_SAV` et `ADMIN_TECHNIQUE`.

Les champs d’identité des imports et lignes sont immuables après insertion.
Les transitions de statut sont contrôlées par trigger ; un import finalisé ne
peut plus être modifié. Les fichiers sources sont conservés pour la
traçabilité et ne disposent d’aucune suppression applicative.

Le bucket privé `quote-source-files` utilise le chemin
`organization_id/site_id/import_operation_id/original_filename`. Aucun projet
distant n’est lié et aucune migration distante n’est appliquée.

Les types futurs doivent être générés par
`supabase gen types typescript --local > src/lib/database.types.ts` après
démarrage local de Supabase. Le frontend n’embarque jamais de clé serveur à privilèges.

Le contrôle `npm run check:supabase-foundation` vérifie l’ordre des migrations,
les protections statiques, les policies Storage, l’absence de tables hors
périmètre et l’absence de secrets. Il ne prouve pas l’exécution PostgreSQL.
