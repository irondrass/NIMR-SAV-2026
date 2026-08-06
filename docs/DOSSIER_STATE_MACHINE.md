# Machine d’états dossier

> Matrice de conception validée. Les lignes marquées FUTUR ne sont pas implémentées en 0009.

## États

`CREATED`, `PLANNED`, `IN_PROGRESS`, `ON_HOLD`, `QUALITY_PENDING`, `QUALITY_REJECTED`, `QUALITY_APPROVED`, `CLOSED`, `CANCELLED`.

| from_status | to_status | rôle autorisé | condition | champs obligatoires | événement d’audit | statut |
|---|---|---|---|---|---|---|
| — | `CREATED` | `IMPORT_DEVIS`, `DIRECTEUR_SAV`, `ADMIN_TECHNIQUE` via fonction | import `APPROVED`, ligne éligible, warning accepté si présent, idempotence | source, snapshots, `created_by` | `dossier.created_from_validated_quote` | Implémenté en 0009 |
| `CREATED` | `PLANNED` | `CHEF_ATELIER`, `DIRECTEUR_SAV`, `ADMIN_TECHNIQUE` | données planifiables | `updated_by`, version | `dossier.status_changed` | Implémenté en 0009 |
| `PLANNED` | `IN_PROGRESS` | `CHEF_ATELIER`, `DIRECTEUR_SAV`, `ADMIN_TECHNIQUE` | prise en charge atelier | `updated_by`, version | `dossier.status_changed` | Implémenté en 0009 |
| `CREATED` / `PLANNED` / `IN_PROGRESS` | `ON_HOLD` | `CHEF_ATELIER`, `DIRECTEUR_SAV`, `ADMIN_TECHNIQUE` | motif requis | `held_from_status`, motif | `dossier.put_on_hold` | Implémenté en 0009 |
| `ON_HOLD` | `CREATED` | `CHEF_ATELIER`, `DIRECTEUR_SAV`, `ADMIN_TECHNIQUE` | uniquement si `held_from_status = CREATED` | `held_from_status = NULL`, motif | `dossier.resumed` | Implémenté en 0009 |
| `ON_HOLD` | `PLANNED` | `CHEF_ATELIER`, `DIRECTEUR_SAV`, `ADMIN_TECHNIQUE` | uniquement si `held_from_status = PLANNED` | `held_from_status = NULL`, motif | `dossier.resumed` | Implémenté en 0009 |
| `ON_HOLD` | `IN_PROGRESS` | `CHEF_ATELIER`, `DIRECTEUR_SAV`, `ADMIN_TECHNIQUE` | uniquement si `held_from_status = IN_PROGRESS` | `held_from_status = NULL`, motif | `dossier.resumed` | Implémenté en 0009 |
| `IN_PROGRESS` | `QUALITY_PENDING` | `CHEF_ATELIER` | travaux terminés | version | `dossier.quality_submitted` | Implémenté en 0009 |
| `QUALITY_PENDING` | `QUALITY_REJECTED` | `CONTROLE_QUALITE` | non-conformité | code motif | `dossier.quality_rejected` | Implémenté en 0009 |
| `QUALITY_PENDING` | `QUALITY_APPROVED` | `CONTROLE_QUALITE` | contrôle conforme | version | `dossier.quality_approved` | Implémenté en 0009 |
| `QUALITY_REJECTED` | `IN_PROGRESS` | `CHEF_ATELIER`, `DIRECTEUR_SAV`, `ADMIN_TECHNIQUE` | reprise atelier | motif | `dossier.status_changed` | Implémenté en 0009 |
| `CREATED` / `PLANNED` / `IN_PROGRESS` / `ON_HOLD` | `CANCELLED` | `DIRECTEUR_SAV`, `ADMIN_TECHNIQUE` | motif obligatoire | `cancel_reason` | `dossier.cancelled` | Implémenté en 0009 |
| `QUALITY_APPROVED` | `CLOSED` | `CHEF_ATELIER`, `DIRECTEUR_SAV`, `ADMIN_TECHNIQUE` | contrôle approuvé | `closed_at` serveur | `dossier.closed` | Implémenté en 0009 |
| `CLOSED` | état actif | aucun en 0009 | réouverture métier à décider | — | — | FUTUR, interdit en 0009 |

`CLOSED` et `CANCELLED` sont terminaux. L’annulation est interdite depuis `QUALITY_APPROVED`, `CLOSED` et `CANCELLED`. `closed_at` est généré par le serveur. `CONTROLE_QUALITE` ne soumet pas le dossier : il ne fait que décider depuis `QUALITY_PENDING`. `IN_PROGRESS → QUALITY_PENDING` est réservé au `CHEF_ATELIER` en 0009.

La machine conserve l’état courant et `version`, refuse les sauts non listés, et vérifie `expected_version` atomiquement. Une reprise doit cibler exactement `held_from_status`, qui ne peut être que `CREATED`, `PLANNED` ou `IN_PROGRESS`, puis est remis à `NULL` dans la même transaction. Les actions sensibles de `ADMIN_TECHNIQUE`, y compris inter-organisations, sont auditées.

`dossier.status_changed` est produit une seule fois et exclusivement pour `CREATED → PLANNED`, `PLANNED → IN_PROGRESS` et `QUALITY_REJECTED → IN_PROGRESS`. Les transitions `ON_HOLD`, reprise, annulation, soumission qualité, refus qualité, validation qualité et clôture utilisent uniquement leur événement spécialisé respectif ; aucun événement générique supplémentaire n’est produit pour ces transitions.

`TECHNICIEN` n’a aucun SELECT, CREATE, UPDATE, DELETE ni aucune fonction de création ou transition dossier accessible en 0009. L’affectation atelier et les droits associés sont futurs.
