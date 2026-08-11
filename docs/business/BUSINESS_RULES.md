# Règles métier

## Objet
Fournir un catalogue testable des invariants métier de l’après-vente automobile en concession.

## Périmètre
Les règles couvrent l’Ordre de Réparation (OR), la Réception atelier, les opérations Technicien, le Chef d’atelier, la Garantie, les Campagnes techniques, les Réclamations Garantie, le PDF de devis, les communications, l’IA et les indicateurs. Stock, achats, comptabilité, facturation, paiements, finance et ERP sont exclus.

## Principes
Les règles sont explicites, auditables et déterministes autant que possible. La configuration est autorisée seulement lorsque la politique locale varie réellement.

## Définitions
Un **invariant** est une condition qui doit toujours être vraie. Une **approbation** est une décision humaine assumée. Un échange externe est un échange entrant ou sortant de PDF de devis. L’identité OR relie la visite, le véhicule, le client et l’autorisation de travaux.

## Règles
- Chaque OR identifie le véhicule et le motif client de manière suffisante pour la Réception.
- Un OR ne peut avancer sans les données requises pour son état cible.
- Chaque opération Technicien possède un responsable, un statut, un résultat et les justificatifs nécessaires.
- Le Chef d’atelier ne promet pas un travail au-delà de la Capacité atelier sans exception explicitement enregistrée.
- Les opérations Garantie et Campagne technique conservent leurs éléments d’éligibilité, d’autorisation et de preuve avant revue de la Réclamation Garantie.
- Une révision de PDF de devis échangée est immuable ; une correction crée une nouvelle révision.
- Toute recommandation rejetée ou retirée reste historisée avec son motif.
- L’IA est identifiée comme suggestion et ne constitue jamais seule la base d’une transition importante.
- L’achèvement opérationnel est distinct de l’achèvement financier.

## Exemples
Si une preuve de diagnostic est requise pour « Prêt pour devis », l’écran indique la preuve manquante et bloque la transition jusqu’à sa saisie ou à une exception autorisée. Une Campagne technique qui exige un résultat d’inspection reste bloquée au Contrôle qualité tant que ce résultat n’est pas approuvé.

## Évolution future
Toute nouvelle règle doit avoir un responsable, une justification, un impact sur le processus, une stratégie de migration et des tests d’acceptation. Un conflit de règles est tranché par le Responsable produit et un ADR.
