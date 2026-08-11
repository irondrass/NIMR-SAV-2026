# Frontières des modules

## Objet
Définir les modules logiques et empêcher les chevauchements de responsabilité.

## Périmètre
Les modules couvrent uniquement l’après-vente automobile et les fondations de la plateforme. Les noms techniques des modules restent en anglais.

## Principes
Chaque module a une responsabilité, une API, des invariants et des dépendances minimales. Les shared primitives restent petites et stables.

## Définitions
Un responsable de module est responsable du comportement et des données d’une capability. Un contract publié est l’interface supportée par les autres modules.

## Règles
| Module | Owns | Must not own |
|---|---|---|
| Dossier | Identité, cycle et responsable de l’Ordre de Réparation (OR) | Stock ou finance |
| Customer & vehicle context | Faits client et véhicule utiles à la Réception | Identité de paiement ou comptable |
| Intake | Capture de Réception atelier et rendez-vous | Conclusions de diagnostic |
| Diagnosis | Constatations, tests, justificatifs et recommandations Technicien | Commandes fournisseurs |
| Quotation | Préparation, révisions et échange du PDF de devis | Facturation ou paiement |
| Execution coordination | Affectations, files, capacité, ressources, avancement et blocages | Déstockage |
| Quality control | Contrôles de fin, justificatifs Garantie/Campagne et disponibilité | Règlement financier |
| Communication | Messages approuvés à l’atelier et au client | Promesses non approuvées |
| AI assistant | Suggestions, résumés et provenance | Approbations autonomes |
| Identity & access | Authentication et policy decisions | Décisions métier |
| Audit & observability | Operational trail et telemetry | Mutable business truth |

## Référentiel de terminologie concessionnaire
| Terme concession | Responsabilité architecturale |
|---|---|
| Ordre de Réparation (OR) | Identité et cycle du dossier |
| Réception atelier | Intake et contexte client/véhicule |
| Chef d’atelier | Coordination d’exécution, capacité et ressources |
| Technicien | Contributeurs de Diagnosis et Execution |
| Garantie / Campagne technique | Attributs de couverture et justificatifs dans les processus |
| Réclamation Garantie | Paquet de justificatifs issu de faits OR approuvés |
| Contrôle qualité | Gate de contrôle et de mise à disposition |

Cette table est une correspondance de langage, pas une modification de responsabilité ou de modules.

## Exemples
Un blocage d’exécution appartient à Execution coordination ; le constat d’un Technicien reste dans Diagnosis même s’il apparaît dans la file du Chef d’atelier.

## Évolution future
Tout nouveau module exige une responsabilité, une carte de dépendances, un responsable des données, un comportement d’erreur, une revue de sécurité et un ADR si les frontières évoluent.
