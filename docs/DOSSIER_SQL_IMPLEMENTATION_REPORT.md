# Rapport d’implémentation — fondation SQL des dossiers

## Verdict

Le bloqueur SQL historique est résolu par les migrations 0009 et 0010.
Le schéma 0001–0008 ne permettait pas de prouver côté PostgreSQL toutes les
préconditions opérationnelles. La preuve serveur quote-import, la projection
opérationnelle et la fondation dossier/OR sont maintenant implémentées. La
base distante n’a pas été modifiée.

## Mesures implémentées

- `quote_import_row_validated_payloads` structure et versionne la preuve opérationnelle.
- `quote_import_row_issues` dérive le blocage depuis un catalogue de sévérité fermé.
- `validate_quote_import_row` calcule le hash serveur, contrôle l’identité de ligne et audite la validation.
- `create_dossier_from_validated_quote` dérive l’acteur de `auth.uid()`, vérifie l’approbation, les avertissements, le périmètre et crée dossier/OR/ligne atomiquement.
- Les colonnes commerciales (`currency`, `estimated_amount`, prix et montants) ne sont pas implémentées conformément à la décision Product Owner.

## Preuves disponibles

- `public.quote_import_operations.status` est limité à des valeurs textuelles,
  dont `APPROVED`.
- Les contraintes de `quote_import_operations` lient `APPROVED` à
  `approved_by` et `approved_at`.
- `public.quote_import_rows.import_operation_id` référence l’opération source.
- Les colonnes `source_values`, `normalized_values` et `issues` sont des
  `jsonb`, mais seules leur nature objet/tableau est contrainte.
- `validation_status` est limité à `VALID`, `INVALID`, `WARNING` et
  `UNREVIEWED`.

## Manques historiques résolus

### 1. Erreurs bloquantes

La colonne `issues` accepte un tableau ou un objet JSONB sans schéma de clés,
de codes, de sévérité ou de règle bloquante. PostgreSQL ne peut donc pas
prouver qu’une ligne `VALID` ou `WARNING` ne contient aucune erreur bloquante.
La valeur textuelle de `validation_status` ne suffit pas à établir cette
preuve, car aucune contrainte ou fonction existante ne relie ce statut au
contenu de `issues`.

### 2. WARNING réellement présents

Le schéma ne définit ni structure d’avertissement, ni code obligatoire, ni
sévérité, ni règle de sensibilité. La future fonction ne pourrait pas
réinterroger de manière sûre `warning_count` et `warning_codes` sans inventer
une convention JSONB non garantie par les migrations existantes.

### 3. Snapshot validé

`normalized_values` est seulement un objet JSONB nullable sans clés autorisées
ni types validés. `source_values` est également un objet JSONB libre. Le dépôt
frontend décrit des champs comme `customer_display_name`, `vin`, `make` ou
`mileage`, mais ces descriptions TypeScript ne constituent pas une preuve
persistée côté PostgreSQL. La migration ne peut donc pas construire avec
certitude les snapshots autorisés sans faire confiance à une structure non
contrainte.

### 4. Projection de l’ordre de réparation

Les lignes persistées ne garantissent pas la présence, le type ou la validation
des champs nécessaires à `repair_order_snapshot` (`normalized_label`, quantité,
prix, catégorie, étape, etc.). Une projection déterministe et sûre ne peut pas
être prouvée avec le schéma actuel.

## Action requise avant reprise

Faire valider et implémenter au préalable un contrat serveur des lignes
d’import, par exemple une migration dédiée avant 0009 ou une modification
approuvée du modèle existant, définissant explicitement :

- la structure des `issues` et des warnings ;
- les codes non sensibles et leur sévérité ;
- la règle PostgreSQL d’absence d’erreur bloquante ;
- les clés et types de `normalized_values` utilisables pour les snapshots ;
- la projection validée des lignes de réparation.

Cette action n’a pas été réalisée, conformément à la consigne de ne jamais
remplacer une preuve serveur manquante par un paramètre frontend.

```text
MIGRATION_0009=IMPLEMENTED_QUOTE_IMPORT_SERVER_CONTRACT
MIGRATION_0010=IMPLEMENTED_DOSSIER_PERSISTENCE
DATABASE_LOCAL=NOT_MODIFIED
DATABASE_REMOTE=NOT_MODIFIED
GO_SQL_IMPLEMENTATION=YES
```
