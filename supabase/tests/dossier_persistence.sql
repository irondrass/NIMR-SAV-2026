-- Static and executable contract assertions for the dossier foundation.
-- Full fixture execution requires Supabase CLI/Docker.
begin;
set local search_path = extensions, public, auth, storage, pg_catalog;
select plan(22);
select has_table('public'::name, 'quote_import_row_validated_payloads'::name, 'validated payload table exists');
select has_table('public'::name, 'quote_import_row_issues'::name, 'structured issue table exists');
select has_table('public'::name, 'dossiers'::name, 'dossiers table exists');
select has_table('public'::name, 'repair_orders'::name, 'repair orders table exists');
select has_table('public'::name, 'repair_order_lines'::name, 'repair order lines table exists');
select has_index('public'::name, 'dossiers'::name, 'dossiers_scope_idx'::name, 'dossier scope index exists');
select ok(to_regprocedure('public.validate_quote_import_row(uuid,jsonb,jsonb)') is not null, 'server validation RPC exists');
select ok(to_regprocedure('public.create_dossier_from_validated_quote(uuid,boolean)') is not null, 'dossier creation RPC exists');
select ok(exists (select 1 from pg_type where typname = 'quote_import_issue_severity'), 'issue severity type exists');
select ok(exists (select 1 from pg_constraint where conname = 'quote_import_rows_operation_key'), 'row operation linkage is constrained');
select ok(exists (select 1 from pg_constraint where conname = 'quote_import_operations_scope_key'), 'operation scope linkage is constrained');
select ok(exists (select 1 from pg_policy where polname = 'quote_import_validated_payload_read'), 'validated payload RLS exists');
select ok(exists (select 1 from pg_policy where polname = 'quote_import_issue_read'), 'issue RLS exists');
select ok(exists (select 1 from pg_policy where polname = 'dossiers_read'), 'dossier RLS exists');
select ok(exists (select 1 from pg_policy where polname = 'repair_orders_read'), 'repair order RLS exists');
select ok(not exists (select 1 from information_schema.role_table_grants where table_schema = 'public' and table_name in ('dossiers','repair_orders','repair_order_lines') and grantee = 'authenticated' and privilege_type in ('INSERT','UPDATE','DELETE')), 'direct dossier mutations are not granted');
select ok(not exists (select 1 from information_schema.role_table_grants where table_schema = 'public' and table_name in ('quote_import_row_validated_payloads','quote_import_row_issues') and grantee = 'authenticated' and privilege_type in ('INSERT','UPDATE','DELETE')), 'direct validation mutations are not granted');
select ok(exists (select 1 from pg_trigger where tgname = 'quote_import_validated_payloads_immutable'), 'validated payload immutability exists');
select ok(exists (select 1 from pg_trigger where tgname = 'quote_import_row_issues_immutable'), 'issue immutability exists');
select ok(exists (select 1 from pg_trigger where tgname = 'dossiers_no_direct_mutation'), 'dossier mutation guard exists');
select ok(not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name in ('dossiers','repair_orders','repair_order_lines','quote_import_row_validated_payloads') and column_name in ('currency','estimated_amount','amount','price','unit_price','total_price')), 'commercial fields are absent');
select ok(exists (select 1 from pg_proc where proname = 'append_audit_event'), 'creation can use append-only audit');
select * from finish();
rollback;
