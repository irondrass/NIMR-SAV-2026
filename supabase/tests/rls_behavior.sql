-- Behavioral RLS contract for local Supabase. Run only with `supabase test db`.
-- Every fixture and every mutation is contained in this transaction.
begin;
select plan(67);

-- Synthetic identities, organisations and sites. These values are local-only.
insert into auth.users (id, aud, role, email, encrypted_password, raw_user_meta_data)
values
  ('10000000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', 'user-no-role@local.test', 'x', '{}'::jsonb),
  ('10000000-0000-4000-8000-000000000002', 'authenticated', 'authenticated', 'user-inactive@local.test', 'x', '{}'::jsonb),
  ('10000000-0000-4000-8000-000000000003', 'authenticated', 'authenticated', 'technicien-site-a@local.test', 'x', '{}'::jsonb),
  ('10000000-0000-4000-8000-000000000004', 'authenticated', 'authenticated', 'lecture-site-a@local.test', 'x', '{}'::jsonb),
  ('10000000-0000-4000-8000-000000000005', 'authenticated', 'authenticated', 'import-devis-a@local.test', 'x', '{}'::jsonb),
  ('10000000-0000-4000-8000-000000000006', 'authenticated', 'authenticated', 'import-devis-b@local.test', 'x', '{}'::jsonb),
  ('10000000-0000-4000-8000-000000000007', 'authenticated', 'authenticated', 'directeur-site-a@local.test', 'x', '{}'::jsonb),
  ('10000000-0000-4000-8000-000000000008', 'authenticated', 'authenticated', 'admin-technique@local.test', 'x', '{}'::jsonb);

update public.profiles
set active = false
where id = '10000000-0000-4000-8000-000000000002';

insert into public.organizations (id, code, name)
values
  ('00000000-0000-4000-8000-000000000001', 'ORG_A_TEST', 'Synthetic Organisation A'),
  ('00000000-0000-4000-8000-000000000002', 'ORG_B_TEST', 'Synthetic Organisation B');

insert into public.sites (id, organization_id, code, name, city)
values
  ('00000000-0000-4000-8000-000000000101', '00000000-0000-4000-8000-000000000001', 'SITE_A1', 'Synthetic Site A1', 'Tunis'),
  ('00000000-0000-4000-8000-000000000102', '00000000-0000-4000-8000-000000000001', 'SITE_A2', 'Synthetic Site A2', 'Sousse'),
  ('00000000-0000-4000-8000-000000000201', '00000000-0000-4000-8000-000000000002', 'SITE_B1', 'Synthetic Site B1', 'Bizerte');

insert into public.profile_roles (profile_id, role_id, assigned_by)
select v.profile_id, r.id, '10000000-0000-4000-8000-000000000008'
from (values
  ('10000000-0000-4000-8000-000000000003'::uuid, 'TECHNICIEN'),
  ('10000000-0000-4000-8000-000000000004'::uuid, 'LECTURE_SEULE'),
  ('10000000-0000-4000-8000-000000000005'::uuid, 'IMPORT_DEVIS'),
  ('10000000-0000-4000-8000-000000000006'::uuid, 'IMPORT_DEVIS'),
  ('10000000-0000-4000-8000-000000000007'::uuid, 'DIRECTEUR_SAV'),
  ('10000000-0000-4000-8000-000000000008'::uuid, 'ADMIN_TECHNIQUE')
) as v(profile_id, role_code)
join public.roles r on r.code = v.role_code;

insert into public.profile_site_access (profile_id, site_id, access_scope, assigned_by)
values
  ('10000000-0000-4000-8000-000000000003', '00000000-0000-4000-8000-000000000101', 'OPERATE', '10000000-0000-4000-8000-000000000008'),
  ('10000000-0000-4000-8000-000000000004', '00000000-0000-4000-8000-000000000101', 'READ', '10000000-0000-4000-8000-000000000008'),
  ('10000000-0000-4000-8000-000000000005', '00000000-0000-4000-8000-000000000101', 'OPERATE', '10000000-0000-4000-8000-000000000008'),
  ('10000000-0000-4000-8000-000000000006', '00000000-0000-4000-8000-000000000201', 'OPERATE', '10000000-0000-4000-8000-000000000008'),
  ('10000000-0000-4000-8000-000000000007', '00000000-0000-4000-8000-000000000101', 'MANAGE', '10000000-0000-4000-8000-000000000008'),
  ('10000000-0000-4000-8000-000000000007', '00000000-0000-4000-8000-000000000102', 'MANAGE', '10000000-0000-4000-8000-000000000008');

insert into public.quote_import_operations
  (id, organization_id, site_id, operation_key, status, source_file_name, source_file_size, source_mime_type, source_file_hash, detected_format, created_by, approved_by, approved_at, rejected_at)
values
  ('20000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000101', 'op-a', 'UPLOADED', 'devis-a.csv', 10, 'text/csv', repeat('a', 64), 'CSV', '10000000-0000-4000-8000-000000000005', null, null, null),
  ('20000000-0000-4000-8000-000000000002', '00000000-0000-4000-8000-000000000002', '00000000-0000-4000-8000-000000000201', 'op-b', 'UPLOADED', 'devis-b.csv', 10, 'text/csv', repeat('b', 64), 'CSV', '10000000-0000-4000-8000-000000000006', null, null, null),
  ('20000000-0000-4000-8000-000000000003', '00000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000102', 'op-a2', 'UPLOADED', 'devis-a2.csv', 10, 'text/csv', repeat('c', 64), 'CSV', '10000000-0000-4000-8000-000000000007', null, null, null),
  ('20000000-0000-4000-8000-000000000004', '00000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000101', 'op-approved', 'APPROVED', 'approved.csv', 10, 'text/csv', repeat('d', 64), 'CSV', '10000000-0000-4000-8000-000000000005', '10000000-0000-4000-8000-000000000007', timezone('utc', now()), null),
  ('20000000-0000-4000-8000-000000000005', '00000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000101', 'op-rejected', 'REJECTED', 'rejected.csv', 10, 'text/csv', repeat('e', 64), 'CSV', '10000000-0000-4000-8000-000000000005', null, null, timezone('utc', now()));

insert into public.quote_import_rows (id, import_operation_id, source_row_number, source_values, validation_status)
values
  ('30000000-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000001', 1, '{"sku":"A"}', 'VALID'),
  ('30000000-0000-4000-8000-000000000002', '20000000-0000-4000-8000-000000000002', 1, '{"sku":"B"}', 'VALID');

select set_config('request.jwt.claim.sub', '10000000-0000-4000-8000-000000000005', true);
insert into public.attachments
  (id, organization_id, site_id, entity_type, entity_id, storage_bucket, storage_path, original_file_name, mime_type, file_size, uploaded_by)
values
  ('40000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000101', 'QUOTE_IMPORT', '20000000-0000-4000-8000-000000000001', 'quote-source-files', '00000000-0000-4000-8000-000000000001/00000000-0000-4000-8000-000000000101/20000000-0000-4000-8000-000000000001/devis-a.csv', 'devis-a.csv', 'text/csv', 10, '10000000-0000-4000-8000-000000000005');

insert into public.audit_events (organization_id, site_id, actor_profile_id, event_type, entity_type, entity_id, event_data)
values
  ('00000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000101', '10000000-0000-4000-8000-000000000005', 'IMPORT.CREATED', 'QUOTE_IMPORT', '20000000-0000-4000-8000-000000000001', '{"fixture":true}');

insert into storage.objects (bucket_id, name, metadata)
values
  ('quote-source-files', '00000000-0000-4000-8000-000000000002/00000000-0000-4000-8000-000000000201/20000000-0000-4000-8000-000000000002/devis-b.csv', '{"fixture":true}');

-- AUTHENTICATION
set local role anon;
select set_config('request.jwt.claim.sub', '', true);
select throws_ok($$select id from public.organizations$$, '42501', null, 'anon cannot read organizations');
select throws_ok($$select id from public.sites$$, '42501', null, 'anon cannot read sites');
select throws_ok($$select id from public.profiles$$, '42501', null, 'anon cannot read profiles');

reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub', '10000000-0000-4000-8000-000000000002', true);
select is_empty($$select id from public.organizations$$, 'inactive profile reads no business data');

select set_config('request.jwt.claim.sub', '10000000-0000-4000-8000-000000000001', true);
select throws_ok($$insert into public.quote_import_operations (organization_id, site_id, operation_key, status, source_file_name, source_file_size, source_mime_type, source_file_hash, detected_format, created_by) values ('00000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000101', 'op-no-role', 'UPLOADED', 'x.csv', 1, 'text/csv', repeat('f', 64), 'CSV', auth.uid())$$, '42501', null, 'user without role cannot create import');

-- IMPORT ROLES
select set_config('request.jwt.claim.sub', '10000000-0000-4000-8000-000000000003', true);
select throws_ok($$insert into public.quote_import_operations (organization_id, site_id, operation_key, status, source_file_name, source_file_size, source_mime_type, source_file_hash, detected_format, created_by) values ('00000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000101', 'op-tech', 'UPLOADED', 'x.csv', 1, 'text/csv', repeat('1', 64), 'CSV', auth.uid())$$, '42501', null, 'technician cannot create import');

select set_config('request.jwt.claim.sub', '10000000-0000-4000-8000-000000000004', true);
select throws_ok($$insert into public.quote_import_operations (organization_id, site_id, operation_key, status, source_file_name, source_file_size, source_mime_type, source_file_hash, detected_format, created_by) values ('00000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000101', 'op-read', 'UPLOADED', 'x.csv', 1, 'text/csv', repeat('2', 64), 'CSV', auth.uid())$$, '42501', null, 'read-only user cannot create import');

select set_config('request.jwt.claim.sub', '10000000-0000-4000-8000-000000000005', true);
select isnt_empty($$insert into public.quote_import_operations (organization_id, site_id, operation_key, status, source_file_name, source_file_size, source_mime_type, source_file_hash, detected_format, created_by) values ('00000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000101', 'op-import-a', 'UPLOADED', 'x.csv', 1, 'text/csv', repeat('3', 64), 'CSV', auth.uid()) returning id$$, 'import role creates on assigned site');
select throws_ok($$insert into public.quote_import_operations (organization_id, site_id, operation_key, status, source_file_name, source_file_size, source_mime_type, source_file_hash, detected_format, created_by) values ('00000000-0000-4000-8000-000000000002', '00000000-0000-4000-8000-000000000201', 'op-import-a-b', 'UPLOADED', 'x.csv', 1, 'text/csv', repeat('4', 64), 'CSV', auth.uid())$$, '42501', null, 'import role cannot create on unassigned site');
select throws_ok($$insert into public.quote_import_operations (organization_id, site_id, operation_key, status, source_file_name, source_file_size, source_mime_type, source_file_hash, detected_format, created_by) values ('00000000-0000-4000-8000-000000000002', '00000000-0000-4000-8000-000000000101', 'op-import-incoherent', 'UPLOADED', 'x.csv', 1, 'text/csv', repeat('5', 64), 'CSV', auth.uid())$$, '42501', null, 'import organization must match site');
select is_empty($$update public.quote_import_operations set source_file_name = 'hijacked.csv' where id = '20000000-0000-4000-8000-000000000002' returning id$$, 'import role cannot update another users import');

select set_config('request.jwt.claim.sub', '10000000-0000-4000-8000-000000000007', true);
select isnt_empty($$update public.quote_import_operations set status = 'PARSED' where id = '20000000-0000-4000-8000-000000000003' returning id$$, 'director manages assigned site import');
select is_empty($$update public.quote_import_operations set status = 'PARSED' where id = '20000000-0000-4000-8000-000000000002' returning id$$, 'director cannot manage another site import');

select set_config('request.jwt.claim.sub', '10000000-0000-4000-8000-000000000008', true);
select isnt_empty($$select id from public.organizations$$, 'technical admin uses documented global exception');

-- ISOLATION AND PRIVILEGE ESCALATION
select set_config('request.jwt.claim.sub', '10000000-0000-4000-8000-000000000005', true);
select is_empty($$select id from public.quote_import_operations where site_id = '00000000-0000-4000-8000-000000000201'$$, 'site A user cannot read site B imports');
select is_empty($$select id from public.organizations where id = '00000000-0000-4000-8000-000000000002'$$, 'organization A user cannot read organization B');

select set_config('request.jwt.claim.sub', '10000000-0000-4000-8000-000000000007', true);
select is_empty($$select id from public.profiles where id = '10000000-0000-4000-8000-000000000006'$$, 'director cannot read profile without shared site');
select isnt_empty($$select id from public.profiles where id = '10000000-0000-4000-8000-000000000005'$$, 'director reads profile on shared site');

select throws_ok($$insert into public.profile_roles (profile_id, role_id) select auth.uid(), id from public.roles where code = 'ADMIN_TECHNIQUE'$$, '42501', null, 'user cannot assign own role');
select throws_ok($$insert into public.profile_site_access (profile_id, site_id, access_scope) values (auth.uid(), '00000000-0000-4000-8000-000000000201', 'MANAGE')$$, '42501', null, 'user cannot assign own site access');

-- IMPORT IMMUTABILITY
select set_config('request.jwt.claim.sub', '10000000-0000-4000-8000-000000000005', true);
select throws_ok($$update public.quote_import_operations set organization_id = '00000000-0000-4000-8000-000000000002' where id = '20000000-0000-4000-8000-000000000001'$$, null, null, 'import organization is immutable');
select throws_ok($$update public.quote_import_operations set site_id = '00000000-0000-4000-8000-000000000102' where id = '20000000-0000-4000-8000-000000000001'$$, null, null, 'import site is immutable');
select throws_ok($$update public.quote_import_operations set operation_key = 'changed' where id = '20000000-0000-4000-8000-000000000001'$$, null, null, 'operation key is immutable');
select throws_ok($$update public.quote_import_operations set created_by = '10000000-0000-4000-8000-000000000007' where id = '20000000-0000-4000-8000-000000000001'$$, null, null, 'import creator is immutable');
select throws_ok($$update public.quote_import_operations set source_file_hash = repeat('9', 64) where id = '20000000-0000-4000-8000-000000000001'$$, null, null, 'source hash is immutable');
select throws_ok($$update public.quote_import_rows set import_operation_id = '20000000-0000-4000-8000-000000000002' where id = '30000000-0000-4000-8000-000000000001'$$, null, null, 'row import parent is immutable');
select throws_ok($$update public.quote_import_rows set source_row_number = 2 where id = '30000000-0000-4000-8000-000000000001'$$, null, null, 'row number is immutable');
reset role;
select isnt_empty($$insert into public.quote_import_rows (import_operation_id, source_row_number, source_values, validation_status) values ('20000000-0000-4000-8000-000000000003', 1, '{"sku":"same-number"}', 'VALID') returning id$$, 'same row number is allowed in another import');
select throws_ok($$insert into public.quote_import_rows (import_operation_id, source_row_number, source_values, validation_status) values ('20000000-0000-4000-8000-000000000001', 1, '{"sku":"duplicate"}', 'VALID')$$, '23505', null, 'same row number is rejected inside one import');
set local role authenticated;
select set_config('request.jwt.claim.sub', '10000000-0000-4000-8000-000000000005', true);

-- STATUS TRANSITIONS
select isnt_empty($$update public.quote_import_operations set status = 'PARSED' where id = '20000000-0000-4000-8000-000000000001' returning id$$, 'initial import transition is allowed');
select is_empty($$update public.quote_import_operations set status = 'PARSED' where id = '20000000-0000-4000-8000-000000000004' returning id$$, 'approved import cannot return to prior state');
select is_empty($$update public.quote_import_operations set status = 'APPROVED', approved_by = auth.uid(), approved_at = timezone('utc', now()) where id = '20000000-0000-4000-8000-000000000005' returning id$$, 'rejected import cannot become approved');
select throws_ok($$insert into public.quote_import_operations (organization_id, site_id, operation_key, status, source_file_name, source_file_size, source_mime_type, source_file_hash, detected_format, created_by) values ('00000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000101', 'op-no-approved-fields', 'APPROVED', 'x.csv', 1, 'text/csv', repeat('6', 64), 'CSV', auth.uid())$$, '23514', null, 'approved status requires approval fields');
select throws_ok($$update public.quote_import_operations set status = 'APPROVED', approved_by = '10000000-0000-4000-8000-000000000006', approved_at = timezone('utc', now()) where id = '20000000-0000-4000-8000-000000000001'$$, null, null, 'approved actor cannot be impersonated');
select is_empty($$update public.quote_import_operations set source_file_name = 'changed.csv' where id = '20000000-0000-4000-8000-000000000004' returning id$$, 'finalized import cannot be modified');

-- AUDIT
select throws_ok($$insert into public.audit_events (organization_id, site_id, actor_profile_id, event_type, entity_type, event_data) values ('00000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000101', auth.uid(), 'DIRECT', 'TEST', '{}')$$, '42501', null, 'direct audit insert is refused');
select throws_ok($$update public.audit_events set event_type = 'CHANGED' where id = (select id from public.audit_events limit 1)$$, '42501', null, 'audit update is refused');
select throws_ok($$delete from public.audit_events where id = (select id from public.audit_events limit 1)$$, '42501', null, 'audit delete is refused');
select isnt_empty($$select public.append_audit_event('00000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000101', 'IMPORT.CREATED', 'QUOTE_IMPORT', '20000000-0000-4000-8000-000000000001', '{"source":"behavior"}', 'request-behavior')$$, 'authorized append creates audit event');
reset role;
select is((select actor_profile_id from public.audit_events where request_id = 'request-behavior'), '10000000-0000-4000-8000-000000000005'::uuid, 'audit actor is derived from auth uid');
set local role authenticated;
select set_config('request.jwt.claim.sub', '10000000-0000-4000-8000-000000000005', true);
select throws_ok($$select public.append_audit_event('00000000-0000-4000-8000-000000000002', '00000000-0000-4000-8000-000000000201', 'IMPORT.CREATED', 'QUOTE_IMPORT', '20000000-0000-4000-8000-000000000002', '{}', null)$$, null, null, 'audit on unassigned site is refused');
select set_config('request.jwt.claim.sub', '10000000-0000-4000-8000-000000000007', true);
select is_empty($$select id from public.audit_events where site_id = '00000000-0000-4000-8000-000000000201'$$, 'director cannot read another site audit');
select set_config('request.jwt.claim.sub', '10000000-0000-4000-8000-000000000008', true);
select isnt_empty($$select id from public.audit_events$$, 'technical admin reads audit globally');
select set_config('request.jwt.claim.sub', '10000000-0000-4000-8000-000000000005', true);
select throws_ok($$select public.append_audit_event('00000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000101', 'IMPORT.CREATED', 'QUOTE_IMPORT', null, '{"token":"forbidden"}', null)$$, null, null, 'sensitive audit data is refused');

-- ATTACHMENTS
select set_config('request.jwt.claim.sub', '10000000-0000-4000-8000-000000000003', true);
select throws_ok($$insert into public.attachments (organization_id, site_id, entity_type, entity_id, storage_bucket, storage_path, original_file_name, mime_type, file_size, uploaded_by) values ('00000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000101', 'QUOTE_IMPORT', '20000000-0000-4000-8000-000000000001', 'quote-source-files', '00000000-0000-4000-8000-000000000001/00000000-0000-4000-8000-000000000101/20000000-0000-4000-8000-000000000001/tech.csv', 'tech.csv', 'text/csv', 1, auth.uid())$$, '42501', null, 'technician cannot create quote attachment');
select set_config('request.jwt.claim.sub', '10000000-0000-4000-8000-000000000005', true);
select isnt_empty($$insert into public.attachments (organization_id, site_id, entity_type, entity_id, storage_bucket, storage_path, original_file_name, mime_type, file_size, uploaded_by) values ('00000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000101', 'QUOTE_IMPORT', '20000000-0000-4000-8000-000000000001', 'quote-source-files', '00000000-0000-4000-8000-000000000001/00000000-0000-4000-8000-000000000101/20000000-0000-4000-8000-000000000001/imported.csv', 'imported.csv', 'text/csv', 1, auth.uid()) returning id$$, 'import role creates attachment for own import');
select throws_ok($$insert into public.attachments (organization_id, site_id, entity_type, entity_id, storage_bucket, storage_path, original_file_name, mime_type, file_size, uploaded_by) values ('00000000-0000-4000-8000-000000000002', '00000000-0000-4000-8000-000000000201', 'QUOTE_IMPORT', '20000000-0000-4000-8000-000000000002', 'quote-source-files', '00000000-0000-4000-8000-000000000002/00000000-0000-4000-8000-000000000201/20000000-0000-4000-8000-000000000002/other.csv', 'other.csv', 'text/csv', 1, auth.uid())$$, null, null, 'import role cannot attach on another site');
select throws_ok($$insert into public.attachments (organization_id, site_id, entity_type, entity_id, storage_bucket, storage_path, original_file_name, mime_type, file_size, uploaded_by) values ('00000000-0000-4000-8000-000000000002', '00000000-0000-4000-8000-000000000101', 'QUOTE_IMPORT', '20000000-0000-4000-8000-000000000001', 'quote-source-files', '00000000-0000-4000-8000-000000000002/00000000-0000-4000-8000-000000000101/20000000-0000-4000-8000-000000000001/incoherent.csv', 'incoherent.csv', 'text/csv', 1, auth.uid())$$, null, null, 'attachment organization must match site');
select throws_ok($$insert into public.attachments (organization_id, site_id, entity_type, entity_id, storage_bucket, storage_path, original_file_name, mime_type, file_size, uploaded_by) values ('00000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000102', 'QUOTE_IMPORT', '20000000-0000-4000-8000-000000000001', 'quote-source-files', '00000000-0000-4000-8000-000000000001/00000000-0000-4000-8000-000000000102/20000000-0000-4000-8000-000000000001/wrong-site.csv', 'wrong-site.csv', 'text/csv', 1, auth.uid())$$, null, null, 'attachment site must match import');
select throws_ok($$insert into public.attachments (organization_id, site_id, entity_type, entity_id, storage_bucket, storage_path, original_file_name, mime_type, file_size, uploaded_by) values ('00000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000101', 'QUOTE_IMPORT', '20000000-0000-4000-8000-000000000001', 'quote-source-files', '00000000-0000-4000-8000-000000000001/00000000-0000-4000-8000-000000000101/20000000-0000-4000-8000-000000000001/forged.csv', 'forged.csv', 'text/csv', 1, '10000000-0000-4000-8000-000000000006')$$, null, null, 'attachment uploader cannot be forged');
select throws_ok($$update public.attachments set entity_id = '20000000-0000-4000-8000-000000000002' where id = '40000000-0000-4000-8000-000000000001'$$, null, null, 'attachment entity cannot change');
select throws_ok($$update public.attachments set storage_path = replace(storage_path, 'devis-a.csv', 'changed.csv') where id = '40000000-0000-4000-8000-000000000001'$$, null, null, 'attachment storage path cannot change');
select throws_ok($$delete from public.attachments where id = '40000000-0000-4000-8000-000000000001'$$, '42501', null, 'application attachment deletion is refused');

-- STORAGE
select is(public.storage_path_has_expected_shape('org/site/import.csv'), false, 'short storage path is refused without exception');
select is(public.storage_path_has_expected_shape('org/site/import/file.csv/extra'), false, 'long storage path is refused');
select is(public.storage_path_has_expected_shape('../site/import/file.csv'), false, 'traversal storage path is refused');
select is(public.storage_path_organization_id('not-a-uuid/not-a-uuid/not-a-uuid/file.csv'), null::uuid, 'malformed storage UUID returns null');
select throws_ok($$insert into storage.objects (bucket_id, name, metadata) values ('quote-source-files', '00000000-0000-4000-8000-000000000002/00000000-0000-4000-8000-000000000101/20000000-0000-4000-8000-000000000001/devis-a.csv', '{}')$$, '42501', null, 'storage organization mismatch is refused');
select throws_ok($$insert into storage.objects (bucket_id, name, metadata) values ('quote-source-files', '00000000-0000-4000-8000-000000000001/00000000-0000-4000-8000-000000000201/20000000-0000-4000-8000-000000000001/devis-a.csv', '{}')$$, '42501', null, 'storage site mismatch is refused');
select throws_ok($$insert into storage.objects (bucket_id, name, metadata) values ('quote-source-files', '00000000-0000-4000-8000-000000000001/00000000-0000-4000-8000-000000000101/90000000-0000-4000-8000-000000000001/devis-a.csv', '{}')$$, '42501', null, 'storage missing import is refused');
select set_config('request.jwt.claim.sub', '10000000-0000-4000-8000-000000000003', true);
select throws_ok($$insert into storage.objects (bucket_id, name, metadata) values ('quote-source-files', '00000000-0000-4000-8000-000000000001/00000000-0000-4000-8000-000000000101/20000000-0000-4000-8000-000000000001/devis-a.csv', '{}')$$, '42501', null, 'technician cannot upload source file');
select set_config('request.jwt.claim.sub', '10000000-0000-4000-8000-000000000005', true);
select lives_ok($$insert into storage.objects (bucket_id, name, owner_id, metadata) values ('quote-source-files', '00000000-0000-4000-8000-000000000001/00000000-0000-4000-8000-000000000101/20000000-0000-4000-8000-000000000001/devis-a.csv', auth.uid(), '{}')$$, 'import role uploads on assigned site and import');
select throws_ok($$insert into storage.objects (bucket_id, name, metadata) values ('quote-source-files', '00000000-0000-4000-8000-000000000002/00000000-0000-4000-8000-000000000201/20000000-0000-4000-8000-000000000002/devis-b.csv', '{}')$$, '42501', null, 'import role cannot upload another users import');
select set_config('request.jwt.claim.sub', '10000000-0000-4000-8000-000000000007', true);
select throws_ok($$insert into storage.objects (bucket_id, name, metadata) values ('quote-source-files', '00000000-0000-4000-8000-000000000002/00000000-0000-4000-8000-000000000201/20000000-0000-4000-8000-000000000002/devis-b.csv', '{}')$$, '42501', null, 'director uploads only on assigned sites');
select isnt_empty($$select id from storage.objects where name = '00000000-0000-4000-8000-000000000001/00000000-0000-4000-8000-000000000101/20000000-0000-4000-8000-000000000001/devis-a.csv'$$, 'storage select respects accessible site');
select is_empty($$update storage.objects set metadata = '{"changed":true}' where name like '%/devis-a.csv' returning id$$, 'storage source update is refused');
select throws_ok($$delete from storage.objects where name like '%/devis-a.csv'$$, null, null, 'storage source delete is refused');

select * from finish();
rollback;
