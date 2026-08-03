# Sécurité Storage

`quote-source-files` est privé. Les policies Storage vérifient le bucket, le
site présent dans le second segment du chemin et l’organisation du site. Les
chemins attendus sont `organization_id/site_id/import_operation_id/filename`.
Les helpers refusent les chemins malformés, les UUID invalides, les segments
vides, les doubles séparateurs, `..` et les caractères de contrôle sans lever
d’exception. L’INSERT vérifie l’organisation, le site, l’import existant, le
nom de fichier et le rôle autorisé. Il n’existe ni policy UPDATE ni policy
DELETE : les fichiers sources sont conservés pour la traçabilité.
