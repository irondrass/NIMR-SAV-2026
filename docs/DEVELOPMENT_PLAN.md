# Plan de développement

## Phase 1 — fondation

Terminée dans ce workspace : outillage, structure recentrée, layout responsive, navigation filtrée par rôle, import de devis placeholder, contrats d’authentification, client Supabase désactivé sans variables, configuration manquante, error boundary et tests de base.

## Phase 2 — plateforme Supabase

Définir les migrations forward-only, les enums, contraintes, indexes, RLS, rôles Postgres, Storage et RPC atomiques de l’import. Brancher Supabase Auth et le provider de session sans compte codé en dur.

## Phase 3 — workflows métier

Implémenter l’import de devis, dossiers, ordres de réparation, tâches, planning, ressources et contrôle qualité avec tests unitaires et intégration.

## Phase 4 — qualité et pilotage

Ajouter qualité, livraison, garantie, réclamations, satisfaction, KPI, audit, exports et tests E2E sur les scénarios opérationnels.
# Phase 3A — fondation locale

La branche `feature/supabase-foundation` prépare les migrations, RLS, Storage,
audit et l’authentification réelle. La création des dossiers SAV et toute
connexion distante sont explicitement reportées à une revue ultérieure.
