# Guide de base de données

## Objet
Définir les attentes de conception, d’accès, de migration et d’intégrité des données sans imposer un schema technique.

## Périmètre
Le guide couvre les données après-vente : OR, contexte Réception atelier, opérations Technicien, planification Chef d’atelier, Garantie, Campagne technique, justificatifs de Réclamation Garantie, Contrôle qualité, audit, métadonnées du PDF de devis, configuration et accès. ERP, stock, achats, comptabilité, facturation, paiements et finance sont exclus.

## Principes
La responsabilité des données suit les frontières de modules ; l’intégrité est protégée aux bonnes couches ; les données sensibles sont minimisées ; l’historique est conservé ; les migrations sont revues et réversibles lorsque possible.

## Définitions
Un **enregistrement opérationnel** contient les données nécessaires à la coordination d’un OR. Les métadonnées documentaires identifient une révision de PDF de devis. L’autorisation au niveau des lignes vérifie utilisateur, rôle et périmètre de concession. Les justificatifs de Réclamation Garantie référencent des faits OR approuvés, sans constituer un ledger financier.

## Règles
- Utiliser des identifiants stables et des timestamps explicites avec politique de timezone.
- Garantir unicité et transitions d’état valides à la persistence boundary.
- Conserver les audit events en append-only avec actor et correlation information.
- Séparer le stockage binaire du PDF de devis de ses métadonnées transactionnelles.
- Ne jamais stocker secrets, credentials de paiement ou données personnelles inutiles.
- Toute migration exige review, plan de backup/restore et preuve de test.
- Les requêtes sont paramétrées et contrôlées par accès ; les logs ne révèlent pas de données sensibles.
- La capacité et les ressources décrivent disponibilité et affectation ; elles ne deviennent ni stock ni données de paie.

## Exemples
Un OR peut référencer le véhicule, le motif, une Garantie, un identifiant de campagne, les justificatifs de Réclamation Garantie et le résultat du Contrôle qualité. Un enregistrement de devis référence une révision, un checksum, une direction et un statut, jamais un numéro de facture ou un statut de paiement.

## Évolution future
Partitioning, archival, search indexes ou event projections pourront être ajoutés après besoin mesuré, avec un design et un migration plan revus.
