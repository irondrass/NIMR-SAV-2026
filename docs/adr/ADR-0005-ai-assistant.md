# ADR-0005 : L’assistant IA ne prend pas de décision autonome

## Statut
Accepted

## Objet
Documenter la limite de responsabilité de l’IA dans l’après-vente.

## Périmètre
Cette décision couvre suggestions, résumés, classifications, prompts, sorties, approbations, audit et contrôles de confidentialité.

## Principes
L’IA assiste les humains ; les décisions importantes restent autorisées, explicables, révisables et auditables.

## Contexte
L’IA peut réduire l’administratif de la Réception atelier, des Techniciens, du Chef d’atelier, de la Garantie et du Contrôle qualité. Les décisions de diagnostic, de sécurité, de campagne, de Réclamation Garantie, de client et de processus exigent cependant un jugement humain responsable.

## Décision
L’IA peut résumer, classer, proposer une action, détecter une information manquante ou signaler une anomalie. Un humain accepte, modifie, refuse ou ignore chaque suggestion ; toute action importante exige un utilisateur autorisé.

## Conséquences
Les sorties IA exigent provenance, incertitude, contrôles de politique, événements d’audit, minimisation des données, gestion des erreurs et parcours de revue humaine.

## Définitions
Une suggestion est une sortie non autoritaire. Une approbation humaine est une action imputable. La provenance conserve suffisamment de contexte pour permettre la revue.

## Règles
L’IA ne modifie pas silencieusement l’OR, n’approuve pas un devis, ne clôture pas le Contrôle qualité, n’invente pas de justificatif et ne prend aucune décision financière. Les résultats de faible confiance ou indisponibles dégradent le service de manière sûre.

## Exemples
L’assistant peut proposer un message client à partir de faits OR approuvés, signaler un justificatif de Réclamation Garantie manquant ou résumer les constats Technicien. Il ne peut pas envoyer une consigne de sécurité non revue ni approuver une opération de Campagne technique.

## Évolution future
Les modèles, méthodes d’évaluation, règles de conservation et fournisseurs pourront évoluer par expérimentations contrôlées, revue de sécurité et ADR mis à jour.
