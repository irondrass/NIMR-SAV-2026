# Guide de sécurité

## Objet
Protéger les données de la concession, la confidentialité client, l’intégrité des OR et la fiabilité des décisions assistées par IA.

## Périmètre
Le guide s’applique à l’identité, l’autorisation, aux données OR et véhicule, à la Garantie et aux justificatifs de Réclamation Garantie, aux Campagnes techniques, PDF, APIs, UI, logs, fournisseurs IA, dépendances, déploiement, réponse aux incidents et reprise. Les contrôles financiers sont exclus du produit.

## Principes
Least privilege, secure by default, defense in depth, data minimization, validation des boundaries, auditabilité et containment.

## Définitions
Les **données sensibles** incluent identifiants client/véhicule, coordonnées, diagnostics, justificatifs Garantie/Réclamation, données de Campagne technique et documents. Une **frontière** est une interface utilisateur, fichier, API, base de données ou modèle. Un **événement de sécurité** est une activité suspecte ou soumise à revue.

## Règles
- Utiliser une authentification forte, une autorisation limitée au périmètre, des contrôles de session et une révocation testée.
- Appliquer le périmètre site/utilisateur sur chaque read et write ; deny by default.
- Valider type, taille, contenu, nom et storage path des PDF ; scanner et empêcher le path traversal.
- Chiffrer en transit et au repos ; conserver les secrets dans un secret storage géré.
- Masquer les données sensibles dans les logs et la télémétrie et limiter conservation et accès.
- Utiliser des requêtes paramétrées et valider les entrées/sorties sérialisées.
- Minimiser les données personnelles transmises aux fournisseurs IA.
- Journaliser approbation, dérogation, export, changement d’accès et actions administratives.
- Protéger les justificatifs de Réclamation Garantie et de Garantie selon rôle et concession ; les dérogations du Chef d’atelier/Contrôle qualité exigent un motif.

## Exemples
Un PDF de devis n’est accepté qu’après validation de frontière et stockage sûr. Une Réclamation Garantie expose uniquement les faits OR nécessaires à sa revue. Un numéro de téléphone est masqué dans un prompt IA lorsqu’il est inutile.

## Évolution future
Le programme devra ajouter threat models, dependency scanning, penetration testing, privacy assessments, incident runbooks, recovery objectives et access reviews périodiques.
