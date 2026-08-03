# Brouillon de modèle de données

Entités futures autorisées, sans migration en phase 1 : `organizations`, `sites`, `profiles`, `roles`, `profile_roles`, `imported_quotes`, `import_batches`, `import_rows`, `import_mapping_templates`, `dossiers`, `repair_orders`, `repair_order_lines`, `workshop_tasks`, `task_dependencies`, `task_skill_requirements`, `technicians`, `technician_skills`, `teams`, `shifts`, `absences`, `workshop_zones`, `workshop_bays`, `material_resources`, `resource_availability`, `bookings`, `booking_resources`, `quality_controls`, `deliveries`, `warranties`, `complaints`, `satisfaction_surveys`, `attachments`, `audit_events`.

Le dossier porte un snapshot issu du devis : `dossier_number`, `imported_quote_id`, `quote_reference`, `quote_date`, `customer_display_name`, `customer_phone`, `customer_email`, `registration_number`, `vin`, `brand`, `model`, `mileage`, `insurer_name`, `expert_name`, `claim_reference`, `coverage_type`, `status`, `priority`, montants estimés, dates, créateur et timestamps. Ces snapshots ne créent aucun référentiel séparé.

Entités interdites : référentiels clients ou véhicules, rendez-vous de réception, pièces, commandes/réservations de pièces et événements de blocage PDR.
# Modèle de données phase 3A

Créées : organizations, sites, profiles, roles, profile_roles,
profile_site_access, quote_import_operations, quote_import_rows,
quote_mapping_templates, attachments et audit_events. Les snapshots client et
véhicule appartiendront uniquement aux futurs dossiers SAV.

Reportées : dossiers, repair_orders, repair_order_lines, workshop_tasks,
bookings, quality_controls, deliveries, clients, véhicules, réception, pièces
et PDR.

Les identifiants, organisation, site, créateur et hash des imports sont
immuables. Les lignes gardent leur import parent et leur numéro de ligne. Les
statuts suivent un graphe forward-only jusqu’à `APPROVED` ou `REJECTED`.
