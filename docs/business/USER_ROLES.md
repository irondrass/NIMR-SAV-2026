# Rôles utilisateurs

## Objet
Définir les personas responsables de l’après-vente en concession et leurs limites d’accès.

## Périmètre
Les rôles couvrent l’activité quotidienne et la supervision opérationnelle. Ils ne constituent ni des classifications de paie ni des rôles financiers.

## Principes
Least privilege, séparation des responsabilités, délégation explicite et traçabilité de l’imputabilité.

## Définitions
- **Réception atelier :** ouvre l’OR, recueille le motif client, le véhicule, l’engagement de restitution et les besoins de mobilité.
- **Conseiller service :** coordonne la décision client, le PDF de devis et les communications approuvées.
- **Technicien :** réalise les contrôles, diagnostics et opérations, puis saisit résultats et justificatifs.
- **Chef d’atelier :** pilote la Capacité atelier, les Ressources atelier, affectations, priorités et exceptions.
- **Contrôle qualité :** vérifie la conformité technique, la sécurité, les justificatifs Garantie/Réclamation et la préparation client.
- **Coordinateur Garantie :** vérifie la couverture et la complétude de la Réclamation Garantie lorsqu’un rôle distinct existe.
- **Administrateur système :** administre la configuration et les accès ; il n’approuve pas par défaut les travaux métier.
- **Assistant IA :** capability et non rôle humain ; il propose et explique sans porter la responsabilité.

## Règles
Les accès sont accordés par rôle et périmètre de concession. Les données client, véhicule, Garantie et Réclamation sont accessibles selon le besoin opérationnel. Les approbations et l’exécution doivent être séparables lorsque le risque l’exige. Les accès administratifs sont journalisés et revus.

## Exemples
Un Technicien peut ajouter une preuve de diagnostic mais ne peut approuver un PDF de devis sans permission séparée. Le Chef d’atelier ne planifie une opération que si la compétence et les Ressources atelier sont disponibles. Le Contrôle qualité peut refuser un OR incomplet.

## Évolution future
Les concessions validées pourront ajouter des rôles d’équipe, une délégation temporaire et un périmètre multi-site. Toute permission nouvelle exige une mise à jour de la matrice d’accès et une revue sécurité.
