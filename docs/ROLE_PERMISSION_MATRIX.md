# Matrice rôles / permissions

La matrice exécutable se trouve dans `src/types/auth.ts`. Les permissions sont unionnées entre les rôles de la session et doivent être réappliquées côté PostgreSQL/RLS.

| Rôle | Accès principal |
|---|---|
| ADMIN_TECHNIQUE | configuration technique, utilisateurs/rôles, audit en lecture et gestion technique |
| DIRECTEUR_SAV | accès fonctionnel complet, pilotage, rapports et paramétrage métier |
| CHEF_ATELIER | dossiers, tâches, techniciens, équipes, ressources, planning et conflits |
| IMPORT_DEVIS | dépôt, prévisualisation, mapping, erreurs, validation et historique des imports |
| TECHNICIEN | ses tâches uniquement : démarrer, pause, reprise, terminer, observations autorisées |
| CONTROLE_QUALITE | travaux à contrôler, validation, refus et reprise |
| RESPONSABLE_GARANTIE | dossiers concernés, workflow garantie, décisions et documents autorisés |
| LECTURE_SEULE | consultation uniquement |

L’audit n’est pas supprimable par l’interface métier.
