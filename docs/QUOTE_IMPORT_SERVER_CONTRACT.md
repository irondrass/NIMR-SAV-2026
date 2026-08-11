# Contrat serveur des imports de devis

> Conception proposée, non implémentée. Les migrations 0001–0008 et la base locale/distante restent inchangées.

## Objectif

Fournir à PostgreSQL une preuve structurée qu’une ligne d’import peut être utilisée ultérieurement par la migration dossier 0010. La preuve ne doit pas dépendre d’un `VALID`, d’un `WARNING`, d’un snapshot ou d’un site fourni par le frontend.

## État de l’existant audité

`quote_import_operations` contient `status`, `approved_by`, `approved_at`, le site, l’organisation, les snapshots de mapping/résumé et `validation_issues`. Les contraintes existantes prouvent qu’une opération `APPROVED` a un acteur et une date d’approbation. `quote_import_rows` contient `source_values`, `normalized_values`, `validation_status` et `issues`; sa FK prouve son appartenance à une opération.

En revanche, les trois JSONB sont libres au-delà de leur type JSON. Les migrations ne contraignent ni les clés, ni les types métier, ni les codes ou la sévérité des issues. `validation_status` ne constitue donc pas à lui seul une preuve de l’absence d’erreur bloquante.

Le frontend possède des structures plus riches : mapping de devis, `NormalizedQuote`, `NormalizedQuoteLine`, `DossierDraft`, warnings de normalisation et validation locale. Ces types ne sont pas persistés ni vérifiés par PostgreSQL. L’approbation locale retourne `SERVER_CONFIRMATION_REQUIRED`; elle ne vaut pas approbation serveur.

## Options étudiées

| Option | Intégrité / typage | RLS / audit | Évolutivité / coût | Conclusion |
|---|---|---|---|---|
| A. Colonnes structurées sur `quote_import_rows` | Simple, mais table large et mélange source/preuve | RLS simple, audit couplé à la ligne | Migration et évolution de colonnes coûteuses | Acceptable seulement pour un petit contrat stable |
| B. Table un-à-un `quote_import_row_validated_payloads` | Excellent typage, version/hash et immutabilité naturels | RLS dédiée, audit clair | Ajout limité et compatible avec les lignes existantes | Bonne base pour la preuve |
| C. Table `quote_import_row_issues` | Excellent catalogue relationnel, contraintes et comptage | RLS dédiée, audit précis | Très évolutive, migration ciblée | Nécessaire pour les issues |
| D. B + C | Preuve complète, séparation payload/issues, concurrence maîtrisable | Deux RLS cohérentes, audit sans PII | Deux tables mais coût raisonnable | Architecture recommandée |

## Architecture recommandée

Choisir D : une table relationnelle un-à-un pour le payload validé et une table relationnelle enfant pour les issues structurées. Les JSONB historiques restent des traces d’entrée et ne deviennent jamais automatiquement une preuve.

Le payload validé porte une `validation_version`, un hash déterministe et un instant de validation. La ligne ne devient éligible que si le payload existe, est cohérent avec la ligne et si les issues satisfont les invariants du document `QUOTE_IMPORT_ISSUES_CONTRACT.md`.

La future fonction de validation reçoit l’identifiant de ligne et les valeurs autorisées nécessaires à la projection ; elle dérive opération, organisation et site depuis les tables persistées. Elle remplace issues et payload dans une transaction, calcule le statut, fige la version/hash et audite le résultat.

Stratégie retenue : validation serveur avant approbation, approbation seulement si toutes les lignes requises sont prouvées, puis vérification version/hash lors de la création dossier 0010. La création dossier réinterroge la ligne et le payload, mais ne revalide pas silencieusement une preuve figée.

## Immutabilité et anciennes lignes

Les payloads, issues, hash, `validation_status`, site et organisation deviennent immuables dès que l’opération est `APPROVED`. Aucune ligne ne peut être ajoutée ou supprimée d’une opération approuvée et aucune réapprobation silencieuse n’est possible.

Les lignes historiques ne sont pas backfillées automatiquement. Elles sont marquées conceptuellement `NEEDS_REVALIDATION` dans le contrat de transition (sans modifier aujourd’hui l’enum textuel existant) et ne sont pas éligibles à 0010 tant qu’une validation serveur n’a pas créé un payload et des issues conformes. Une correction exige le retour explicite vers un statut éditable ou, de préférence, une nouvelle opération d’import ; le choix final reste humain.

## Sécurité

Les futures mutations passent par des fonctions `SECURITY DEFINER` avec `search_path = ''`, objets qualifiés, acteur dérivé de `auth.uid()` et profil actif. `ADMIN_TECHNIQUE` est global inter-organisations ; `IMPORT_DEVIS` et `DIRECTEUR_SAV` restent limités à leur organisation/site. Aucun INSERT/UPDATE/DELETE direct authenticated sur la preuve validée, aucun accès anon, aucune élévation de privilèges et aucune suppression applicative.

## Impact dossier 0010

La migration dossier est renumérotée conceptuellement de 0009 à 0010. Elle utilisera comme preuves : la FK de la ligne vers l’opération, `APPROVED`, le payload validé immuable, son hash/version et les issues sans blocage. La fonction `create_dossier_from_validated_quote` conservera uniquement `p_quote_import_row_id` et `p_accept_warnings` comme paramètres métier.
