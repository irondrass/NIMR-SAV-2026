# ADR-0003 : Facturation et finance hors périmètre

## Statut
Accepted

## Objet
Documenter pourquoi la facturation et la finance sont exclues de NIMR-SAV-PRO.

## Périmètre
Cette décision couvre factures, paiements, comptabilité, règlement financier, reporting financier et intégrations.

## Principes
Séparer l’orchestration opérationnelle des responsabilités financières réglementées et éviter toute extension implicite.

## Contexte
La facturation, la comptabilité, le paiement et la finance ne sont pas nécessaires à la coordination de la Réception atelier, des OR, des opérations Technicien, de la Garantie, des Campagnes techniques, des Réclamations Garantie ou du Contrôle qualité.

## Décision
NIMR-SAV-PRO ne gère ni facturation, ni factures, ni paiements, ni comptabilité, ni finance, ni règlement financier.

## Conséquences
La décision sur le PDF de devis est opérationnelle. La clôture d’un OR ne signifie pas qu’un paiement a eu lieu. Aucune intégration financière n’est conçue.

## Définitions
Un devis est une proposition de périmètre et un document échangé ; une facture est une créance ; un paiement est son règlement.

## Règles
Ne pas ajouter d’état financier, de registre, d’action de paiement ou d’indicateur financier sous une autre appellation.

## Exemples
« Le client a approuvé la révision 3 du PDF de devis de l’OR 10482 » est dans le périmètre. « Facture payée » ne l’est pas. Le statut de justificatifs d’une Réclamation Garantie est opérationnel ; un registre de remboursement ne l’est pas.

## Évolution future
Un produit distinct pourra couvrir la finance. La frontière de NIMR-SAV-PRO reste inchangée sans nouvelle décision formelle.
