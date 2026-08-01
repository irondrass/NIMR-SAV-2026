# Spécification de l’import de devis

## Phase 1

La fondation prépare une zone de dépôt, les étapes de prévisualisation, mapping et validation, les états de chargement/erreur et l’historique. Aucun parseur Excel, CSV ou PDF et aucune création locale ne sont implémentés.

## Contrat cible

Formats futurs : Excel, CSV et PDF. Le fichier source sera conservé dans Supabase Storage. Une empreinte SHA-256, le nom, la taille et un identifiant d’opération `operation_id` permettront de détecter les doublons et de rendre l’import idempotent.

Statuts : `UPLOADED`, `PARSING`, `READY_FOR_REVIEW`, `VALIDATION_ERROR`, `APPROVED`, `IMPORTED`, `REJECTED`.

Le flux cible est : dépôt → parsing → prévisualisation → mapping → contrôles de données → liste d’erreurs → approbation explicite. Avant l’approbation, l’opération peut être rejetée ou annulée sans créer de dossier. Après validation, une RPC PostgreSQL crée atomiquement le dossier et ses lignes de réparation, avec rollback en cas d’échec, puis prépare les tâches et écrit l’audit. L’opération, l’empreinte, le fichier source, le mapping, les erreurs et l’utilisateur sont traçables.
