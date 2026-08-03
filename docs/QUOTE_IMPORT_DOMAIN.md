# Domaine Quote Import V2

Le domaine est composé de fonctions TypeScript pures : parseur CSV UTF-8, normalisation, suggestions de mapping, validation, hash SHA-256, fingerprint métier, détection de doublons, génération de devis normalisé, `DossierDraft` et `RepairOrderDraft`.

Formats supportés réellement : CSV UTF-8, virgule ou point-virgule, BOM, guillemets, guillemets échappés et retours à la ligne dans une cellule. XLSX, PDF structuré et export ERP sont documentés seulement.

L’approbation locale ne persiste rien. Elle retourne un brouillon avec `SERVER_CONFIRMATION_REQUIRED`. Le rafraîchissement de la page peut perdre le brouillon pendant cette phase.
