# Matrice d’accès dossier

> Conception validée ; aucune politique RLS n’est ajoutée ici.

`ADMIN_TECHNIQUE` est l’exception technique globale inter-organisations. Ses actions sensibles sont toujours auditées. Les autres rôles restent limités à leur organisation et à leurs sites autorisés. Aucun contrôle frontend ne remplace PostgreSQL.

| Rôle | SELECT | CREATE via fonction serveur | UPDATE / transitions en 0009 |
|---|---|---|---|
| `ADMIN_TECHNIQUE` | Tous les dossiers inter-organisations | Oui | Oui selon machine, actions sensibles auditées |
| `DIRECTEUR_SAV` | Ses sites autorisés | Oui | Annulation, clôture et transitions autorisées |
| `CHEF_ATELIER` | Ses sites autorisés | Non | Planification, `IN_PROGRESS`, mise en attente, reprise, `IN_PROGRESS → QUALITY_PENDING`, clôture |
| `IMPORT_DEVIS` | Imports et dossiers de ses sites autorisés | Oui | Création seulement ; aucune transition dossier |
| `TECHNICIEN` | Interdit en 0009 | Interdit | Interdit ; aucun DELETE, aucune fonction de création ou de transition accessible |
| `CONTROLE_QUALITE` | Dossiers de ses sites autorisés | Non | `QUALITY_PENDING → QUALITY_REJECTED` ou `QUALITY_APPROVED` |
| `RESPONSABLE_GARANTIE` | Dossiers de ses sites autorisés | Non | Aucun UPDATE ni transition |
| `LECTURE_SEULE` | Dossiers de ses sites autorisés | Non | Aucun |

La fonction serveur de création accepte uniquement `IMPORT_DEVIS`, `DIRECTEUR_SAV` et `ADMIN_TECHNIQUE`. Aucun `INSERT` direct sur `dossiers` n’est accordé à `authenticated`.

Pour les futures RPC, `EXECUTE` est révoqué de `PUBLIC` et `anon`. Si le frontend appelle directement une RPC, `authenticated` reçoit seulement le `GRANT EXECUTE`; le rôle métier n’est pas distingué par le grant PostgreSQL mais contrôlé dans la fonction à partir du profil et de `profile_roles`. `TECHNICIEN` est rejeté par toutes les fonctions dossier en 0009. Un appel rejeté ne modifie rien et ne produit aucun audit métier de succès.

`authenticated` ne reçoit aucun `INSERT`, `UPDATE` ou `DELETE` direct sur `dossiers`. Toutes les mutations passent exclusivement par `create_dossier_from_validated_quote(...)` et `transition_dossier(...)`. `TECHNICIEN` ne reçoit aucun accès dossier ni aucune fonction dossier en 0009 ; ses droits sont reportés à la phase d’affectation atelier.

Règles RLS futures : organisation/site cohérents, profil actif, accès de site, source import approuvée, aucune suppression physique, aucune auto-élévation, et audit append-only. `anon` et les profils sans accès ne lisent ni n’écrivent.

Les accès technicien et l’affectation ne font pas partie de 0009. Le rôle `RESPONSABLE_GARANTIE` conserve uniquement la lecture dans cette phase.
