# Règles legacy d’import de devis

## Règles métier confirmées

- Les libellés d’opérations sont normalisés avant classification.
- Les lignes administratives, totaux, reports et mentions légales ne deviennent pas des travaux.
- Les lignes de main-d’œuvre peuvent porter une durée ; les lignes de fournitures ne doivent pas être interprétées automatiquement comme de la main-d’œuvre.
- Les catégories historiques couvrent notamment diagnostic, mécanique, tôlerie, préparation et peinture.
- La peinture peut être regroupée par zone dans l’ancien moteur et la préparation/peinture/finition sont distinguées.
- Le contrôle qualité reste une étape distincte du travail importé.

## Comportements techniques abandonnés

- Extraction PDF heuristique sans parseur vérifié.
- Tolérance permissive des lignes invalides et conversion silencieuse des nombres.
- Types non stricts et dépendances à l’état global/local.
- Import direct vers des objets métier persistés et références historiques réelles.

## Règles ambiguës à valider

- Pondération exacte des phases de peinture selon la zone et les faces.
- Interprétation des lignes sans quantité ou sans prix.
- Définition métier d’une ligne « diagnostic » versus contrôle qualité.
- Algorithme de mutualisation peinture à confirmer avec l’atelier.

## Règles retenues pour V2

- CSV UTF-8 uniquement en phase 2.
- Chaque ligne conserve sa source, son numéro et ses avertissements.
- Toute proposition d’étape comporte un score, une règle, les mots-clés et une correction manuelle possible.
- Les fournitures sont `MATERIAL`, jamais `PART`.
- L’approbation produit uniquement un `DossierDraft` en mémoire et retourne `SERVER_CONFIRMATION_REQUIRED`.

## Règles abandonnées

- PDF et XLSX sans adaptateur fiable.
- Création automatique d’un dossier sans validation explicite.
- Toute persistance locale ou confirmation serveur simulée.

## Écarts legacy / V2

Le legacy mélangeait extraction PDF, classification, allocation d’heures et intégration métier. V2 sépare parsing CSV, mapping, normalisation, validation, génération de brouillons et future RPC Supabase atomique. Aucune donnée réelle ni fixture de production n’a été reprise.
