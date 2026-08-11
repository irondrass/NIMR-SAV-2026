# Guide des agents d’ingénierie NIMR-SAV-PRO

## Objet
Ce fichier constitue le contrat de travail des humains et coding agents intervenant sur NIMR-SAV-PRO. Il protège la frontière produit et rend chaque changement traçable.

## Périmètre
Il s’applique au code source, aux tests, aux artefacts de base de données, à la documentation, à l’automatisation et à la livraison. Le manuel de référence est sous [`docs/`](docs/vision/PROJECT_VISION.md). Les documents fonctionnels destinés aux concessions sont en français ; les identifiants techniques et concepts d’architecture restent en anglais.

## Principes
- Atelier d’abord : optimiser la Réception atelier, l’OR, le diagnostic Technicien, la coordination du Chef d’atelier, la Garantie, la Campagne technique, la Réclamation Garantie et le Contrôle qualité.
- Configuration avant code ; l’assistant IA assiste les humains ; documenter avant d’implémenter.
- Préférer une architecture modulaire, la responsabilité unique, les solutions simples et une valeur atelier mesurable.
- Utiliser le vocabulaire Ordre de Réparation (OR), Réception atelier, Chef d’atelier, Technicien, Garantie, Contrôle qualité, Campagne technique, Réclamation Garantie, Capacité atelier et Ressources atelier.

## Définitions
`Ordre de Réparation (OR)` désigne l’enregistrement opérationnel de la visite ; `dossier` est un synonyme interne historique. Le `PDF de devis` est l’unique document externe échangé. L’assistant IA est un recommandateur non responsable soumis à approbation humaine et audit.

## Règles
1. NIMR-SAV-PRO n’est pas un ERP et ne gère ni stock de pièces de rechange, ni achats, ni comptabilité, ni facturation, ni paiements, ni finance.
2. Il n’existe aucune ERP integration.
3. Pour une tâche documentation-only, ne pas modifier source code ou schema.
4. Garder les frontières de domaine explicites et valider les entrées aux frontières.
5. Ne jamais committer secrets ou credentials.
6. Préserver l’audit des transitions, approbations, suggestions IA et échanges documentaires.

## Exemples
Bonne évolution : ajouter un contrôle qualité configurable pour les justificatifs de Campagne technique et mesurer le taux d’OR corrects du premier coup. Mauvaise évolution : ajouter stocks, commandes fournisseurs ou états de factures.

## Évolution future
Ce guide pourra intégrer des commandes de dépôt, cartes de responsabilités, objectifs de niveau de service et contrôles de mise en production. Toute extension de périmètre exige un ADR et la validation du Responsable produit.
