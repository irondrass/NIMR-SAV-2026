# ADR-0004 : NIMR-SAV-PRO est une plateforme autonome

## Statut
Accepted

## Objet
Documenter l’autonomie de la plateforme et sa frontière d’échange externe.

## Périmètre
Cette décision s’applique au processus, aux données OR, à la configuration, aux permissions, à l’audit et au PDF de devis.

## Principes
Autonomie, modularity, contracts simples et absence de dépendance ERP implicite.

## Contexte
La plateforme doit couvrir la Réception atelier, les OR, les Techniciens, le Chef d’atelier, la Garantie, les Campagnes techniques, les Réclamations Garantie et le Contrôle qualité sans dépendre d’un ERP ou d’un autre système opérationnel. Elle échange un seul document défini : le PDF de devis.

## Décision
NIMR-SAV-PRO possède son processus atelier, sa configuration, ses données opérationnelles, ses permissions, son audit et son échange de PDF de devis. Aucune intégration ERP n’est requise ou supposée.

## Conséquences
Les interfaces sont autonomes, la responsabilité des données est explicite et les flux import/export sont limités au PDF de devis approuvé.

## Définitions
`Autonomous` signifie utilisable indépendamment pour sa responsabilité opérationnelle définie, sans signifier « déconnecté de toute infrastructure ».

## Règles
Toute dépendance externe exige une justification explicite et ne doit pas élargir silencieusement le produit.

## Exemples
Un PDF de devis peut être reçu, versionné, revu et rattaché à un OR. Un connecteur ERP n’est ni un prérequis ni une hypothèse de roadmap.

## Évolution future
L’infrastructure pourra évoluer pour la fiabilité ; l’autonomie métier et la frontière documentaire resteront protégées.
