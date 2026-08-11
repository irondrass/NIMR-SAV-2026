# Contrat structuré des issues d’import

> Modèle proposé, non implémenté.

## Modèle relationnel proposé

Table future `quote_import_row_issues` :

| Champ | Type proposé | Règle |
|---|---|---|
| `id` | `uuid` | PK serveur |
| `quote_import_row_id` | `uuid` | NOT NULL, FK vers `quote_import_rows`, index |
| `issue_code` | `text` | NOT NULL, catalogue fermé de codes non sensibles |
| `severity` | enum `quote_import_issue_severity` | exactement `ERROR`, `WARNING`, `INFO` |
| `is_blocking` | `boolean` | dérivé de `severity`, jamais librement choisi |
| `field_key` | `text` | nullable, clé autorisée ou NULL |
| `safe_context` | `jsonb` objet | nullable, clés/valeurs bornées et non sensibles |
| `created_at` | `timestamptz` | NOT NULL, valeur serveur UTC |

Le couple `(quote_import_row_id, issue_code, field_key, severity)` est déterministe pour une version de validation. Une version ou un identifiant de validation doit être ajouté pour conserver un historique sans modifier une preuve approuvée.

## Invariants

`is_blocking` est dérivé : `ERROR = true`, `WARNING = false`, `INFO = false`. Il ne doit pas être une décision frontend ni une valeur contradictoire. Une fonction ou une contrainte garantit cette relation.

- `VALID` : zéro issue `ERROR`, zéro issue bloquante et payload validé présent ;
- `WARNING` : au moins une issue `WARNING`, zéro issue `ERROR` ou bloquante et payload validé présent ;
- `INVALID` : au moins une issue `ERROR`/bloquante ou absence de payload requis ;
- `UNREVIEWED` : aucune conclusion serveur ; création dossier interdite.

`warning_count` est `count(*)` des issues `WARNING`. `warning_codes` est la liste triée et dédupliquée des `issue_code` WARNING du serveur. Les deux sont calculés, jamais acceptés comme preuve depuis le frontend.

## Catalogue et confidentialité

Les codes sont courts, stables et non sensibles, par exemple `MISSING_LABEL`, `INVALID_QUANTITY`, `UNKNOWN_CATEGORY`, `LOW_CONFIDENCE`, `MISSING_VEHICLE_FIELD`. Le catalogue définit leur sévérité et leur caractère bloquant ; la liste définitive reste une décision humaine.

`safe_context` ne contient que des valeurs techniques bornées : nom de clé de champ autorisé, numéro de ligne source, unité ou valeur enum. Sont interdits : nom client, email, téléphone, adresse, identité, VIN, immatriculation, texte libre, token, clé, secret et copie de `source_values`/`normalized_values`. Les messages libres ne sont pas stockés. L’interface peut traduire un code hors base.

## Validation et immutabilité

Une fonction serveur remplace atomiquement les issues avant approbation, puis calcule `validation_status`. Après `APPROVED`, issues, statut, version et hash sont immuables. Une correction utilise une nouvelle version ou une nouvelle opération, jamais une réécriture silencieuse.

Les anciennes lignes dont `issues` est un JSONB libre ne sont pas converties automatiquement. Elles restent non éligibles jusqu’à revalidation serveur.
