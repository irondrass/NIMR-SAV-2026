# ADR-0001 : NIMR-SAV-PRO est une orchestration atelier, pas un ERP

## Statut
Accepted

## Objet
Documenter la frontière qui distingue l’orchestration de l’après-vente automobile d’un ERP.

## Périmètre
Cette décision s’applique aux capacités, données, interfaces, navigation, indicateurs et feuille de route de NIMR-SAV-PRO.

## Principes
Atelier d’abord, autonomie de la plateforme, responsabilité explicite et valeur opérationnelle mesurable.

## Contexte
Le produit coordonne Réception atelier, Ordres de Réparation (OR), Techniciens, Chef d’atelier, Garantie, Campagnes techniques, Réclamations Garantie et Contrôle qualité. Un périmètre ERP introduirait d’autres responsabilités, contrôles et obligations financières.

## Décision
NIMR-SAV-PRO reste une plateforme autonome d’orchestration de l’après-vente et ne devient pas un ERP ni un produit intégré à un ERP.

## Conséquences
Le langage, l’architecture, les écrans, les métriques et le backlog restent centrés sur l’activité atelier. Toute demande ERP exige une validation du Responsable produit et un ADR de remplacement.

## Définitions
`ERP` signifie Enterprise Resource Planning. `Workshop orchestration` signifie coordonner OR, personnes, preuves, décisions et progression opérationnelle.

## Règles
Le produit ne gère ni inventory, ni procurement, ni accounting, ni billing, ni payments, ni finance.

## Exemples
La gestion d’une file d’OR et de la Capacité atelier est dans le périmètre ; un ledger comptable ne l’est pas.

## Évolution future
Une capability voisine n’est envisageable que si elle conserve la frontière autonome et une valeur mesurable pour la concession.
