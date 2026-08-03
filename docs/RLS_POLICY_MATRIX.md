# Matrice RLS

| Domaine | ADMIN_TECHNIQUE | DIRECTEUR_SAV | IMPORT_DEVIS | CHEF_ATELIER | LECTURE_SEULE | Autres |
|---|---|---|---|---|---|---|
| Référentiels | gérer | lire | lire | lire | lire | lire |
| Imports | gérer | gérer sur sites attribués | créer/modifier ses imports sur sites OPERATE | lire | lire | lire |
| Lignes/templates | gérer | gérer selon périmètre | gérer son import/template | lire | lire | refus écriture |
| Rôles/accès | gérer | lire | refus | refus | refus | refus |
| Audit | lire | lire selon sites | insérer son événement | refus | refus | refus |

Les accès sont explicites dans `profile_site_access`. Le rôle ne donne pas
automatiquement tous les sites ; l’exception contrôlée est
`ADMIN_TECHNIQUE`. `DIRECTEUR_SAV` doit partager un site explicitement autorisé
pour lire le profil, les rôles ou les accès d’un autre utilisateur.

Les policies d’import sont séparées en SELECT, INSERT et UPDATE : aucun rôle
applicatif ne supprime un import ou une ligne. `IMPORT_DEVIS` modifie
uniquement ses imports non finalisés ; `DIRECTEUR_SAV` peut gérer ceux de ses
sites ; l’administrateur technique conserve l’exception globale.
