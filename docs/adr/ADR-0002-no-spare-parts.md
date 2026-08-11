# ADR-0002 : Le stock de pièces est hors périmètre

## Statut
Accepted

## Objet
Documenter pourquoi le stock de pièces de rechange est exclu de NIMR-SAV-PRO.

## Périmètre
Cette décision couvre les enregistrements de stock, processus magasin, réapprovisionnement, fournisseurs et interfaces associées.

## Principes
Responsabilité unique, responsabilité claire des données et coordination atelier sans périmètre ERP.

## Contexte
Les Techniciens et la Réception atelier peuvent mentionner une pièce nécessaire sur un OR. La propriété, la disponibilité, la valorisation et le réapprovisionnement relèvent toutefois d’une autre responsabilité. Les Ressources atelier — baies, outils et équipements — restent des moyens opérationnels et non des articles de stock.

## Décision
NIMR-SAV-PRO peut conserver des notes ou besoins opérationnels pour coordonner un travail, mais ne gère pas le stock de pièces.

## Conséquences
Il n’y a ni registre de stock, ni valorisation article, ni processus magasin, ni logique de réapprovisionnement, ni commande fournisseur, ni intégration stock.

## Définitions
Une note de pièce est une information opérationnelle ; un stock est une ressource comptée, valorisée et réapprovisionnable.

## Règles
L’UI, les APIs, les données, les indicateurs et les tests ne doivent pas suggérer une propriété du stock.

## Exemples
« Le Technicien recommande le remplacement des plaquettes de frein » est valide. « 12 plaquettes disponibles dans le magasin A » est hors périmètre.

## Évolution future
Si les notes opérationnelles sont insuffisantes, améliorer la coordination sans créer de sous-système de stock. Tout changement de frontière nécessite un nouvel ADR.
