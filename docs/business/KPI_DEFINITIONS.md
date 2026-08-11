# Définitions des indicateurs

## Objet
Établir des mesures cohérentes et utiles de la performance de l’après-vente en concession.

## Périmètre
Les indicateurs mesurent le flux des OR, la qualité, la réactivité, l’utilisation de la Capacité atelier, la coordination des Ressources atelier et l’adoption. Ils ne mesurent ni chiffre d’affaires, ni marge, ni stock, ni achats, ni paiements, ni comptabilité.

## Principes
Chaque indicateur possède une question métier, un numérateur, un dénominateur, une période, des exclusions, un responsable et une réserve de qualité de données.

## Définitions
| Indicateur | Définition | Usage principal |
|---|---|---|
| Délai Réception–diagnostic | Médiane entre ouverture OR et premier diagnostic complet | Identifier les blocages de réception et de diagnostic |
| Délai diagnostic–devis | Médiane entre diagnostic complet et création du PDF de devis | Améliorer le débit du conseiller service |
| Cycle de décision du devis | Médiane entre échange PDF et décision client | Améliorer la réactivité |
| OR correct du premier coup | OR validés par le Contrôle qualité sans reprise évitable / OR présentés | Mesurer la qualité de préparation |
| Taux d’OR en retard | OR ouverts sans événement significatif depuis le seuil configuré | Déclencher l’escalade |
| Délai de passage de relais | Médiane entre affectation et première action | Améliorer les relais |
| Allocation productive Technicien | Temps d’opérations planifié / capacité Technicien configurée | Équilibrer la charge |
| Respect de l’engagement de restitution | OR terminés à l’heure promise / OR avec engagement valide | Protéger l’engagement client |
| Complétude des justificatifs Garantie | OR Garantie avec justificatifs requis / OR Garantie revus | Améliorer les Réclamations Garantie |
| Préparation Campagne technique | Opérations Campagne satisfaisant les contrôles / opérations présentées | Sécuriser les campagnes |
| Taux d’acceptation IA | Suggestions IA acceptées / suggestions examinées | Mesurer l’utilité, pas l’autonomie |

## Règles
Les définitions utilisent des événements horodatés, une politique de fuseau et des exclusions approuvées. Les dates contradictoires sont signalées comme problèmes de qualité et non corrigées silencieusement.

## Exemples
Si 80 suggestions sur 100 sont acceptées, le taux d’acceptation IA est de 80 %. Cela ne signifie pas que 80 % du travail est automatisé. Un respect de l’engagement de restitution de 92 % doit être analysé avec les reprises et échecs du Contrôle qualité.

## Évolution future
Les valeurs de référence, cibles, seuils et propriétaires de tableaux de bord doivent être validés par le Responsable produit et versionnés lors de toute modification de définition.
