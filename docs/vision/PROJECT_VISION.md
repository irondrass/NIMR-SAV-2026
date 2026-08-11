# Vision du projet

## Objet
Définir l’intention durable de NIMR-SAV-PRO et fournir un filtre de décision pour le produit, le design et l’ingénierie.

## Périmètre
Cette vision couvre l’après-vente automobile en concession : Réception atelier, ouverture de l’Ordre de Réparation (OR), diagnostic, coordination des travaux, Garantie, Campagne technique, échange du PDF de devis, exécution, Contrôle qualité et amélioration opérationnelle. Les fonctions ERP sont exclues.

## Principes
NIMR-SAV-PRO est centré sur l’atelier, autonome, modulaire, configurable, mesurable et piloté par des personnes responsables. La simplicité réduit les frictions de coordination sans reproduire la complexité du back-office.

## Définitions
- **Ordre de Réparation (OR) :** dossier opérationnel de référence pour une visite véhicule et les travaux associés.
- **Réception atelier :** prise en charge du client, du véhicule, du motif client et de l’engagement de restitution.
- **Vérité opérationnelle :** état courant et auditable fondé sur des faits saisis ou approuvés.
- **Réclamation Garantie :** ensemble d’éléments justificatifs liés à une Garantie ou à une Campagne technique ; ce n’est pas une facture.

## Règles
1. La plateforme coordonne l’activité après-vente de l’atelier.
2. Elle ne gère ni stock de pièces, ni achats, ni comptabilité, ni facturation, ni paiements, ni finance.
3. Il n’existe aucune intégration ERP. Le seul document externe échangé est le PDF de devis.
4. Les recommandations IA ne modifient jamais silencieusement la vérité opérationnelle.
5. Toute fonctionnalité doit démontrer une valeur mesurable pour la concession.

## Exemples
La plateforme peut signaler qu’un diagnostic est incomplet, proposer un message client ou détecter un OR en retard. Elle ne crée pas de commande fournisseur, de facture ou de règlement.

```mermaid
flowchart LR
  R[Réception atelier] --> OR[Ordre de Réparation (OR)]
  OR --> D[Diagnostic et opérations Technicien]
  D --> Q[PDF de devis / décision client]
  Q --> W[Exécution atelier]
  W --> QC[Contrôle qualité]
  QC --> C[Prêt à restituer]
  OR -. Garantie / Campagne technique .-> CL[Preuves de Réclamation Garantie]
```

## Évolution future
Toute extension vers d’autres activités de l’après-vente — par exemple la planification des campagnes ou la gestion de la promesse client — devra conserver les frontières produit et être validée par le Responsable produit dans un ADR.
