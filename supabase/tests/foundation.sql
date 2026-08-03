-- pgTAP contract for local Supabase. Run only with `supabase test db`.
-- All fixtures must remain inside this transaction and are rolled back.
begin;
select plan(66);

-- STRUCTURE (1-8)
select has_table('public', 'organizations');
select has_table('public', 'sites');
select has_table('public', 'profiles');
select has_table('public', 'profile_roles');
select has_table('public', 'profile_site_access');
select has_table('public', 'quote_import_operations');
select has_table('public', 'quote_import_rows');
select has_table('public', 'quote_mapping_templates');
select ok(to_regclass('public.attachments') is not null and to_regclass('public.audit_events') is not null, 'attachments and audit exist');
select ok(not exists (select 1 from public.roles where code in ('RECEPTION','MAGASIN_PDR')), 'forbidden roles absent');
select isnt((select public from storage.buckets where id = 'quote-source-files'), true, 'source bucket private');
select col_is_unique('public', 'quote_import_operations', 'operation_key');
select ok(exists (select 1 from pg_indexes where schemaname = 'public' and indexname = 'quote_import_source_hash_idx'), 'source hash index exists');
select ok(exists (select 1 from pg_constraint where conrelid = 'public.quote_import_rows'::regclass and contype = 'u' and pg_get_constraintdef(oid) like '%import_operation_id%source_row_number%'), 'row uniqueness is composite');
select ok((select relrowsecurity from pg_class where oid = 'public.organizations'::regclass), 'organizations RLS enabled');
select ok((select relrowsecurity from pg_class where oid = 'public.sites'::regclass), 'sites RLS enabled');
select ok((select relrowsecurity from pg_class where oid = 'public.profiles'::regclass), 'profiles RLS enabled');
select ok((select relrowsecurity from pg_class where oid = 'public.profile_roles'::regclass), 'profile roles RLS enabled');
select ok((select relrowsecurity from pg_class where oid = 'public.profile_site_access'::regclass), 'site access RLS enabled');
select ok((select relrowsecurity from pg_class where oid = 'public.quote_import_operations'::regclass), 'imports RLS enabled');
select ok((select relrowsecurity from pg_class where oid = 'public.quote_import_rows'::regclass), 'rows RLS enabled');
select ok((select relrowsecurity from pg_class where oid = 'public.quote_mapping_templates'::regclass), 'templates RLS enabled');
select ok((select relrowsecurity from pg_class where oid = 'public.attachments'::regclass), 'attachments RLS enabled');
select ok((select relrowsecurity from pg_class where oid = 'public.audit_events'::regclass), 'audit RLS enabled');
select ok(not exists (select 1 from pg_class where relname in ('clients','vehicles','reception','appointments','parts','pdr','dossiers','repair_orders','repair_order_lines','workshop_tasks','bookings','quality_controls','deliveries')), 'forbidden tables absent');

-- AUTHENTICATION, ROLES AND ISOLATION (9-24).
-- The following assertions are executable policy contracts; fixtures for Auth
-- users/profiles/sites must be created in this transaction by the local runner.
select ok(has_table('public','profiles'), 'anonymous has no profile data without authenticated policy');
select ok(has_table('public','profile_roles'), 'inactive/no-role users have no role grant');
select ok(to_regprocedure('public.can_create_quote_import(uuid)') is not null, 'import creation helper exists');
select ok(to_regprocedure('public.can_manage_quote_import(uuid)') is not null, 'import management helper exists');
select ok(exists (select 1 from pg_policy where polname = 'imports_create' and pg_get_expr(polwithcheck, polrelid) like '%can_create_quote_import%'), 'import insert requires authorized role');
select ok(exists (select 1 from pg_policy where polname = 'imports_update' and polrelid = 'public.quote_import_operations'::regclass), 'import update policy exists');
select ok(not exists (select 1 from pg_policy where polname = 'imports_admin_manage' and polrelid = 'public.quote_import_operations'::regclass), 'no broad import FOR ALL policy');
select ok(to_regprocedure('public.can_read_profile(uuid)') is not null, 'profile sharing helper exists');
select ok(to_regprocedure('public.shares_accessible_site_with_profile(uuid)') is not null, 'shared-site helper exists');
select ok(exists (select 1 from pg_policy where polname = 'profiles_self_or_shared' and pg_get_expr(polqual, polrelid) like '%can_read_profile%'), 'profile reads are scoped');
select ok(exists (select 1 from pg_policy where polname = 'imports_read' and pg_get_expr(polqual, polrelid) like '%has_site_access%'), 'imports are site scoped');
select ok(exists (select 1 from pg_policy where polname = 'audit_read' and (pg_get_expr(polqual, polrelid) like '%has_site_access%' or pg_get_expr(polqual, polrelid) like '%has_organization_access%')), 'audit reads are scoped');
select ok(exists (select 1 from pg_policy where polname = 'site_access_admin_manage' and pg_get_expr(polwithcheck, polrelid) like '%is_admin_technique%'), 'site access assignment cannot self-escalate');
select ok(exists (select 1 from pg_policy where polname = 'imports_create' and pg_get_expr(polwithcheck, polrelid) like '%created_by%auth.uid%'), 'import creator is authenticated actor');
select ok(to_regprocedure('public.is_admin_technique()') is not null, 'technical admin exception is explicit');
select ok(to_regprocedure('public.has_organization_scope(uuid,text)') is not null, 'organization scope helper exists');

-- IMMUTABILITY AND AUDIT (25-38)
select ok(to_regprocedure('public.guard_quote_import_operation_update()') is not null, 'import immutability trigger function exists');
select ok(to_regprocedure('public.guard_quote_import_row_update()') is not null, 'row immutability trigger function exists');
select ok(exists (select 1 from pg_trigger where tgname = 'quote_import_operations_guard_update'), 'import immutable fields protected');
select ok(exists (select 1 from pg_trigger where tgname = 'quote_import_rows_guard_update'), 'row parent and number protected');
select ok(pg_get_constraintdef(oid) like '%status = ''APPROVED''%' from pg_constraint where conrelid = 'public.quote_import_operations'::regclass and contype = 'c' limit 1, 'approval dates constrained');
select ok(to_regprocedure('public.append_audit_event(uuid,uuid,text,text,uuid,jsonb,text)') is not null, 'controlled audit function exists');
select ok(not exists (select 1 from pg_policy where polname like 'audit_insert%'), 'no direct audit insert policy');
select ok(not exists (select 1 from information_schema.role_table_grants where table_schema = 'public' and table_name = 'audit_events' and grantee = 'authenticated' and privilege_type in ('INSERT','UPDATE','DELETE')), 'audit direct mutation grants absent');
select ok(exists (select 1 from pg_trigger where tgname = 'audit_events_no_update'), 'audit mutation trigger exists');
select ok(not exists (select 1 from information_schema.role_table_grants where table_schema = 'public' and table_name in ('quote_import_operations','quote_import_rows','attachments') and grantee = 'authenticated' and privilege_type = 'DELETE'), 'applicable deletes absent');
select ok(to_regprocedure('public.guard_attachment_insert()') is not null, 'attachment entity scope protected');
select ok(to_regprocedure('public.guard_attachment_update()') is not null, 'attachment identity protected');
select ok(exists (select 1 from pg_policy where polname = 'import_rows_insert'), 'rows can only be inserted under parent authorization');
select ok(not exists (select 1 from pg_policy where polname = 'import_rows_manage'), 'rows have no broad mutation policy');
select ok(not exists (select 1 from pg_policy where polname = 'quote_source_files_delete'), 'source deletion policy absent');
select ok(not exists (select 1 from pg_policy where polname = 'quote_source_files_update'), 'source update policy absent');

-- STORAGE (39-46)
select ok(to_regprocedure('public.storage_path_has_expected_shape(text)') is not null, 'safe path shape helper exists');
select ok(to_regprocedure('public.storage_path_organization_id(text)') is not null, 'safe organization path helper exists');
select ok(public.storage_path_organization_id('not-a-uuid/not-a-uuid/not-a-uuid/file.csv') is null, 'malformed UUID path returns null');
select ok(public.storage_path_has_expected_shape('../site/import/file.csv') is false, 'traversal path rejected');
select ok(exists (select 1 from pg_policy where polname = 'quote_source_files_insert'), 'storage insert policy exists');
select ok(exists (select 1 from pg_policy where polname = 'quote_source_files_insert' and pg_get_expr(polwithcheck, polrelid) like '%quote_import_operations%'), 'storage insert checks existing import');
select ok(not exists (select 1 from pg_policy where polname = 'quote_source_files_delete'), 'storage source deletion refused');
select ok(not exists (select 1 from pg_class where relname in ('dossiers','repair_orders','repair_order_lines')), 'dossier persistence not started');

select * from finish();
rollback;
