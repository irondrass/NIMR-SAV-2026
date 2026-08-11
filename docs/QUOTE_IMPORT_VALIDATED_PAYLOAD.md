# Payload validé d’une ligne d’import

> Projection proposée, non implémentée. Les champs ci-dessous sont dérivés des types et normalisations existants ; leur persistance stricte reste à approuver.

## Table un-à-un proposée

Future `quote_import_row_validated_payloads`, une ligne par version validée :

| Champ | Type proposé | Nullable | Source frontend actuelle | Validation serveur / absence | Sensible | Usage futur | Index / contrainte |
|---|---|---:|---|---|---|---|---|
| `id` | `uuid` | Non | serveur | UUID serveur | Non | identité preuve | PK |
| `quote_import_row_id` | `uuid` | Non | ligne persistée | FK et unique pour preuve courante | Non | lien dossier | unique/index |
| `validation_version` | `integer` | Non | serveur | commence à 1, incrémente | Non | concurrence | `> 0` |
| `payload_hash` | `text` | Non | hash serveur | hash canonique payload | Non | revalidation 0010 | format hash, immuable après APPROVED |
| `customer_display_name` | `text` | Oui | `NormalizedQuote.customerDisplayName` | trim, longueur bornée | Oui | `source_snapshot` | aucun par défaut |
| `customer_external_reference` | `text` | Oui | référence métier si réellement mappée | trim, jamais identifiant sensible | Oui | `source_snapshot` | aucun |
| `vin` | `text` | Oui | `registration/vin` normalisés | format et longueur validés | Oui | snapshot véhicule | aucun par défaut |
| `registration_number` | `text` | Oui | `registrationNumber` | normalisation immatriculation | Oui | snapshot véhicule | aucun |
| `make` | `text` | Oui | `brand` | trim, longueur bornée | Oui | snapshot véhicule | aucun |
| `model` | `text` | Oui | `model` | trim, longueur bornée | Oui | snapshot véhicule | aucun |
| `variant` | `text` | Oui | non disponible actuellement | NULL si absent | Oui | snapshot véhicule | aucun |
| `mileage_km` | `numeric` | Oui | `mileage` | entier >= 0 si fourni | Non | snapshot véhicule | check |
| `powertrain` | `text` | Oui | non disponible actuellement | NULL sauf champ source approuvé | Non | snapshot véhicule | aucun |
| `normalized_label` | `text` | Non | `NormalizedQuoteLine.normalizedLabel` | non vide | Non | ordre réparation | index rare |
| `operation_category` | `text` | Non | `operationCategory` | enum métier fermé | Non | ordre réparation | check |
| `quantity` | `numeric` | Non | `quantity` | > 0 | Non | ordre réparation | check |
| `unit_price` | `numeric(14,2)` | Oui | `unitPrice` | >= 0 si fourni | Non | ordre réparation | aucun |
| `total_price` | `numeric(14,2)` | Oui | `totalPrice` | >= 0 si fourni | Non | ordre réparation | aucun |
| `labor_hours` | `numeric(8,2)` | Oui | `laborHours` | >= 0 si fourni | Non | ordre réparation | aucun |
| `source_row_number` | `integer` | Non | ligne source | FK/valeur positive | Non | traçabilité | index |
| `source_reference` | `text` | Oui | `externalReference`/`operationCode` | longueur bornée | Non | ordre réparation | aucun |
| `validated_at` | `timestamptz` | Non | serveur | UTC serveur | Non | audit/version | index |

Le payload de ligne de réparation doit être une table enfant structurée si plusieurs lignes métier peuvent correspondre à une ligne d’import. Il ne faut pas traiter un JSONB libre comme l’unique preuve. Les champs `variant`, `powertrain`, `customer_external_reference` et certaines références ne sont pas réellement produits par le flux actuel : ils restent NULL jusqu’à une source et une règle approuvées.

## Snapshot futur

`source_snapshot` est construit uniquement depuis les colonnes validées. Client autorisé : `customer_display_name`, `customer_external_reference`. Véhicule autorisé : `vin`, `registration_number`, `make`, `model`, `variant`, `mileage_km`, et `powertrain` seulement lorsqu’il est fourni et validé.

`repair_order_snapshot` est une projection déterministe des lignes validées, avec au minimum `normalized_label`, `operation_category`, `quantity`, prix ou montant disponible, durée disponible, `source_row_number` et `source_reference`. Chaque champ absent reste NULL ou empêche l’éligibilité selon le catalogue de validation ; aucune valeur frontend n’est substituée silencieusement.

## Version, hash et approbation

Le serveur canonise les champs dans un ordre déterministe, calcule `payload_hash`, écrit le payload et les issues dans une transaction, puis expose la version. L’opération ne peut devenir `APPROVED` que si toutes les lignes requises ont une preuve conforme. La fonction dossier 0010 vérifie l’association ligne/opération, `APPROVED`, version et hash.
