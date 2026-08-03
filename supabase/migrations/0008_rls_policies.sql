-- SECURITY DEFINER helpers use an empty search_path and fully-qualified objects.
-- They only answer questions about auth.uid() and never accept an actor identity.
create or replace function public.current_profile_id()
returns uuid language sql stable security definer set search_path = '' as $$
  select p.id from public.profiles p where p.id = auth.uid() and p.active = true;
$$;

create or replace function public.has_role(required_role text)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.profile_roles pr join public.roles r on r.id = pr.role_id where pr.profile_id = public.current_profile_id() and r.code = required_role);
$$;

create or replace function public.has_site_access(target_site uuid, minimum_scope text default 'READ')
returns boolean language sql stable security definer set search_path = '' as $$
  select public.has_role('ADMIN_TECHNIQUE') or exists (
    select 1 from public.profile_site_access a
    where a.profile_id = public.current_profile_id() and a.site_id = target_site
      and case minimum_scope when 'READ' then a.access_scope in ('READ','OPERATE','MANAGE') when 'OPERATE' then a.access_scope in ('OPERATE','MANAGE') when 'MANAGE' then a.access_scope = 'MANAGE' else false end
  );
$$;

create or replace function public.has_organization_access(target_organization uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select public.has_role('ADMIN_TECHNIQUE') or exists (select 1 from public.sites s where s.organization_id = target_organization and public.has_site_access(s.id));
$$;

create or replace function public.has_organization_scope(target_organization uuid, minimum_scope text default 'READ')
returns boolean language sql stable security definer set search_path = '' as $$
  select public.has_role('ADMIN_TECHNIQUE') or exists (select 1 from public.sites s where s.organization_id = target_organization and public.has_site_access(s.id, minimum_scope));
$$;

create or replace function public.shares_accessible_site_with_profile(target_profile uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select public.has_role('ADMIN_TECHNIQUE') or exists (
    select 1 from public.profile_site_access mine join public.profile_site_access theirs on theirs.site_id = mine.site_id
    where mine.profile_id = public.current_profile_id() and theirs.profile_id = target_profile
  );
$$;

create or replace function public.can_read_profile(target_profile uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select target_profile = public.current_profile_id() or public.has_role('ADMIN_TECHNIQUE') or (public.has_role('DIRECTEUR_SAV') and public.shares_accessible_site_with_profile(target_profile));
$$;

create or replace function public.is_admin_technique()
returns boolean language sql stable security definer set search_path = '' as $$ select public.has_role('ADMIN_TECHNIQUE'); $$;

create or replace function public.is_directeur_sav()
returns boolean language sql stable security definer set search_path = '' as $$ select public.has_role('DIRECTEUR_SAV'); $$;

create or replace function public.can_create_quote_import(target_site uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select (public.has_role('ADMIN_TECHNIQUE') or public.has_role('IMPORT_DEVIS') or public.has_role('DIRECTEUR_SAV')) and public.has_site_access(target_site, 'OPERATE');
$$;

create or replace function public.can_manage_quote_import(target_import uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.quote_import_operations i
    where i.id = target_import and public.can_create_quote_import(i.site_id)
      and (public.has_role('ADMIN_TECHNIQUE') or public.has_role('DIRECTEUR_SAV') or (public.has_role('IMPORT_DEVIS') and i.created_by = auth.uid()))
  );
$$;

revoke all on function public.current_profile_id() from public;
revoke all on function public.has_role(text) from public;
revoke all on function public.has_site_access(uuid,text) from public;
revoke all on function public.has_organization_access(uuid) from public;
revoke all on function public.has_organization_scope(uuid,text) from public;
revoke all on function public.shares_accessible_site_with_profile(uuid) from public;
revoke all on function public.can_read_profile(uuid) from public;
revoke all on function public.is_admin_technique() from public;
revoke all on function public.is_directeur_sav() from public;
revoke all on function public.can_create_quote_import(uuid) from public;
revoke all on function public.can_manage_quote_import(uuid) from public;
grant execute on function public.current_profile_id(), public.has_role(text), public.has_site_access(uuid,text), public.has_organization_access(uuid), public.has_organization_scope(uuid,text), public.shares_accessible_site_with_profile(uuid), public.can_read_profile(uuid), public.is_admin_technique(), public.is_directeur_sav(), public.can_create_quote_import(uuid), public.can_manage_quote_import(uuid), public.storage_path_has_expected_shape(text), public.storage_path_organization_id(text), public.storage_path_site_id(text), public.storage_path_import_operation_id(text) to authenticated;
grant execute on function public.append_audit_event(uuid,uuid,text,text,uuid,jsonb,text) to authenticated;

do $$ declare t text; begin
  foreach t in array array['organizations','sites','profiles','roles','profile_roles','profile_site_access','quote_import_operations','quote_import_rows','quote_mapping_templates','attachments','audit_events'] loop
    execute format('alter table public.%I enable row level security', t);
  end loop;
end $$;

drop policy if exists organizations_read on public.organizations;
drop policy if exists organizations_manage on public.organizations;
drop policy if exists sites_read on public.sites;
drop policy if exists sites_manage on public.sites;
drop policy if exists profiles_self_or_admin on public.profiles;
drop policy if exists profiles_admin_manage on public.profiles;
drop policy if exists roles_read on public.roles;
drop policy if exists profile_roles_read on public.profile_roles;
drop policy if exists profile_roles_admin_manage on public.profile_roles;
drop policy if exists site_access_read on public.profile_site_access;
drop policy if exists site_access_admin_manage on public.profile_site_access;
drop policy if exists imports_read on public.quote_import_operations;
drop policy if exists imports_create on public.quote_import_operations;
drop policy if exists imports_update on public.quote_import_operations;
drop policy if exists imports_admin_manage on public.quote_import_operations;
drop policy if exists import_rows_read on public.quote_import_rows;
drop policy if exists import_rows_manage on public.quote_import_rows;
drop policy if exists templates_read on public.quote_mapping_templates;
drop policy if exists templates_manage on public.quote_mapping_templates;
drop policy if exists attachments_read on public.attachments;
drop policy if exists attachments_create on public.attachments;
drop policy if exists audit_read on public.audit_events;
drop policy if exists audit_insert on public.audit_events;

create policy organizations_read on public.organizations for select to authenticated using (public.has_organization_access(id));
create policy organizations_manage on public.organizations for all to authenticated using (public.is_admin_technique()) with check (public.is_admin_technique());
create policy sites_read on public.sites for select to authenticated using (public.has_site_access(id));
create policy sites_manage on public.sites for all to authenticated using (public.is_admin_technique()) with check (public.is_admin_technique());
create policy profiles_self_or_shared on public.profiles for select to authenticated using (public.can_read_profile(id));
create policy profiles_admin_manage on public.profiles for all to authenticated using (public.is_admin_technique()) with check (public.is_admin_technique());
create policy roles_read on public.roles for select to authenticated using (true);
create policy profile_roles_read on public.profile_roles for select to authenticated using (public.can_read_profile(profile_id));
create policy profile_roles_admin_manage on public.profile_roles for all to authenticated using (public.is_admin_technique()) with check (public.is_admin_technique());
create policy site_access_read on public.profile_site_access for select to authenticated using (public.can_read_profile(profile_id));
create policy site_access_admin_manage on public.profile_site_access for all to authenticated using (public.is_admin_technique()) with check (public.is_admin_technique());

create policy imports_read on public.quote_import_operations for select to authenticated using (public.has_site_access(site_id));
create policy imports_create on public.quote_import_operations for insert to authenticated with check (public.can_create_quote_import(site_id) and created_by = auth.uid() and organization_id = (select s.organization_id from public.sites s where s.id = site_id));
create policy imports_update on public.quote_import_operations for update to authenticated using (public.can_manage_quote_import(id) and status not in ('APPROVED','REJECTED')) with check (public.can_manage_quote_import(id) and organization_id = (select s.organization_id from public.sites s where s.id = site_id));
create policy import_rows_read on public.quote_import_rows for select to authenticated using (exists (select 1 from public.quote_import_operations i where i.id = import_operation_id and public.has_site_access(i.site_id)));
create policy import_rows_insert on public.quote_import_rows for insert to authenticated with check (exists (select 1 from public.quote_import_operations i where i.id = import_operation_id and public.can_manage_quote_import(i.id)));

create policy templates_read on public.quote_mapping_templates for select to authenticated using ((site_id is null and public.has_organization_access(organization_id)) or (site_id is not null and public.has_site_access(site_id)));
create policy templates_manage on public.quote_mapping_templates for insert to authenticated with check (
  organization_id = (select s.organization_id from public.sites s where s.id = site_id)
  and ((public.is_admin_technique()) or (public.is_directeur_sav() and public.has_organization_scope(organization_id, 'MANAGE')) or (public.has_role('IMPORT_DEVIS') and site_id is not null and public.has_site_access(site_id, 'MANAGE')))
  and created_by = auth.uid()
);
create policy templates_update on public.quote_mapping_templates for update to authenticated using (
  (public.is_admin_technique()) or (public.is_directeur_sav() and public.has_organization_scope(organization_id, 'MANAGE')) or (public.has_role('IMPORT_DEVIS') and site_id is not null and public.has_site_access(site_id, 'MANAGE') and created_by = auth.uid())
) with check (organization_id = (select s.organization_id from public.sites s where s.id = site_id));

create policy attachments_read on public.attachments for select to authenticated using (public.has_site_access(site_id));
create policy attachments_create on public.attachments for insert to authenticated with check (
  uploaded_by = auth.uid() and public.can_create_quote_import(site_id) and organization_id = (select s.organization_id from public.sites s where s.id = site_id)
  and exists (select 1 from public.quote_import_operations i where i.id = entity_id and i.organization_id = organization_id and i.site_id = site_id and (public.is_admin_technique() or public.is_directeur_sav() or i.created_by = auth.uid()))
);

create policy audit_read on public.audit_events for select to authenticated using ((public.is_admin_technique()) or (public.is_directeur_sav() and ((site_id is not null and public.has_site_access(site_id)) or (site_id is null and public.has_organization_access(organization_id)))));

revoke all on all tables in schema public from anon;
revoke all on all tables in schema public from public;
grant select on public.roles to authenticated;
grant select on public.organizations, public.sites, public.profiles, public.profile_roles, public.profile_site_access, public.quote_import_operations, public.quote_import_rows, public.quote_mapping_templates, public.attachments, public.audit_events to authenticated;
grant insert, update on public.organizations, public.sites, public.profiles, public.profile_roles, public.profile_site_access to authenticated;
grant insert, update on public.quote_import_operations to authenticated;
grant insert on public.quote_import_rows, public.quote_mapping_templates, public.attachments to authenticated;
revoke insert, update, delete on public.audit_events from authenticated;
revoke delete on public.quote_import_operations, public.quote_import_rows, public.quote_mapping_templates, public.attachments from authenticated;

drop policy if exists quote_source_files_read on storage.objects;
drop policy if exists quote_source_files_insert on storage.objects;
drop policy if exists quote_source_files_delete on storage.objects;
create policy quote_source_files_read on storage.objects for select to authenticated using (
  bucket_id = 'quote-source-files' and public.storage_path_has_expected_shape(name)
  and public.has_site_access(public.storage_path_site_id(name))
  and exists (select 1 from public.quote_import_operations i where i.id = public.storage_path_import_operation_id(name) and i.organization_id = public.storage_path_organization_id(name) and i.site_id = public.storage_path_site_id(name))
);
create policy quote_source_files_insert on storage.objects for insert to authenticated with check (
  bucket_id = 'quote-source-files' and public.storage_path_has_expected_shape(name)
  and public.storage_path_organization_id(name) = (select s.organization_id from public.sites s where s.id = public.storage_path_site_id(name))
  and public.can_create_quote_import(public.storage_path_site_id(name))
  and exists (select 1 from public.quote_import_operations i where i.id = public.storage_path_import_operation_id(name) and i.organization_id = public.storage_path_organization_id(name) and i.site_id = public.storage_path_site_id(name) and i.source_file_name = pg_catalog.split_part(name, '/', 4) and (public.is_admin_technique() or public.is_directeur_sav() or i.created_by = auth.uid()))
);
