# Spécification de l’import de devis

## Phase 2 actuelle

Le CSV UTF-8 est réellement supporté : virgule ou point-virgule, BOM, guillemets échappés, retours à la ligne internes, nombres français et dates françaises/ISO. XLSX, PDF structuré et export ERP restent documentés uniquement.

## Contrat cible

Formats futurs : Excel, CSV et PDF. Le fichier source sera conservé dans Supabase Storage. Une empreinte SHA-256, le nom, la taille et un identifiant d’opération `operation_id` permettront de détecter les doublons et de rendre l’import idempotent.

Statuts : `FILE_SELECTED`, `HASHING`, `PARSING`, `MAPPING_REQUIRED`, `READY_FOR_REVIEW`, `VALIDATION_ERROR`, `APPROVED_LOCALLY`, `SERVER_CONFIRMATION_REQUIRED`, `REJECTED`.

Le flux est : fichier → contrôle → hash → lecture CSV → détection du format → mapping → normalisation → validation → prévisualisation → approbation locale → brouillon de dossier → confirmation serveur requise. Avant l’approbation, l’opération peut être rejetée ou annulée sans créer de dossier. Aucune RPC, migration ou persistance n’est implémentée dans cette phase.
