create type public.dossier_status as enum ('CREATED','PLANNED','IN_PROGRESS','ON_HOLD','QUALITY_PENDING','QUALITY_REJECTED','QUALITY_APPROVED','CLOSED','CANCELLED');
alter table public.quote_import_operations add constraint quote_import_operations_scope_key unique (id, organization_id, site_id);
alter table public.quote_import_rows add constraint quote_import_rows_operation_key unique (id, import_operation_id);

create table public.dossiers (
  id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id) on delete restrict,
  site_id uuid not null, quote_import_operation_id uuid not null references public.quote_import_operations(id) on delete restrict,
  quote_import_row_id uuid not null unique references public.quote_import_rows(id) on delete restrict,
  dossier_number text not null, status public.dossier_status not null default 'CREATED', priority text not null default 'NORMAL' check (priority in ('LOW','NORMAL','HIGH','URGENT')),
  source_snapshot jsonb not null check (jsonb_typeof(source_snapshot) = 'object'), repair_order_snapshot jsonb not null check (jsonb_typeof(repair_order_snapshot) = 'object'),
  created_by uuid not null references public.profiles(id) on delete restrict, updated_by uuid not null references public.profiles(id) on delete restrict,
  created_at timestamptz not null default timezone('utc', now()), updated_at timestamptz not null default timezone('utc', now()), version integer not null default 1 check (version > 0),
  foreign key (site_id, organization_id) references public.sites(id, organization_id) on delete restrict,
  foreign key (quote_import_operation_id, organization_id, site_id) references public.quote_import_operations(id, organization_id, site_id) on delete restrict,
  foreign key (quote_import_row_id, quote_import_operation_id) references public.quote_import_rows(id, import_operation_id) on delete restrict,
  unique (organization_id, dossier_number)
);
create table public.repair_orders (
  id uuid primary key default gen_random_uuid(), dossier_id uuid not null unique references public.dossiers(id) on delete restrict,
  organization_id uuid not null references public.organizations(id) on delete restrict, site_id uuid not null,
  source_import_operation_id uuid not null references public.quote_import_operations(id) on delete restrict, source_import_row_id uuid not null unique references public.quote_import_rows(id) on delete restrict,
  provenance_snapshot jsonb not null check (jsonb_typeof(provenance_snapshot) = 'object'), created_at timestamptz not null default timezone('utc', now()), updated_at timestamptz not null default timezone('utc', now()), version integer not null default 1 check (version > 0),
  foreign key (site_id, organization_id) references public.sites(id, organization_id) on delete restrict,
  foreign key (source_import_operation_id, organization_id, site_id) references public.quote_import_operations(id, organization_id, site_id) on delete restrict,
  foreign key (source_import_row_id, source_import_operation_id) references public.quote_import_rows(id, import_operation_id) on delete restrict,
  unique (id, source_import_row_id)
);
create table public.repair_order_lines (
  id uuid primary key default gen_random_uuid(), repair_order_id uuid not null references public.repair_orders(id) on delete restrict, source_import_row_id uuid not null references public.quote_import_rows(id) on delete restrict,
  line_order integer not null check (line_order > 0), source_row_number integer not null check (source_row_number > 0), description text not null check (length(btrim(description)) between 1 and 240), operation_category text not null check (operation_category in ('LABOR','BODYWORK','PAINT','MECHANICAL','ELECTRICAL','DIAGNOSTIC','OTHER')),
  quantity numeric(10,3) not null check (quantity > 0), unit text not null check (unit in ('unit','hour','day','job')), planned_duration_minutes integer not null check (planned_duration_minutes > 0), source_reference text,
  provenance jsonb not null check (jsonb_typeof(provenance) = 'object'), created_at timestamptz not null default timezone('utc', now()),
  foreign key (repair_order_id, source_import_row_id) references public.repair_orders(id, source_import_row_id) on delete restrict,
  unique (repair_order_id, source_import_row_id), unique (repair_order_id, line_order)
);
create table public.dossier_number_counters (organization_id uuid not null references public.organizations(id) on delete restrict, calendar_year integer not null check (calendar_year between 2000 and 9999), last_value bigint not null default 0 check (last_value >= 0), updated_at timestamptz not null default timezone('utc', now()), primary key (organization_id, calendar_year));
create index dossiers_scope_idx on public.dossiers (organization_id, site_id, status);
create index repair_order_lines_order_idx on public.repair_order_lines (repair_order_id, line_order);

create or replace function public.guard_dossier_mutation() returns trigger language plpgsql set search_path = '' as $$ begin raise exception 'dossiers and repair orders are mutable only through approved server functions'; end; $$;
create trigger dossiers_no_direct_mutation before update or delete on public.dossiers for each row execute function public.guard_dossier_mutation();
create trigger repair_orders_no_direct_mutation before update or delete on public.repair_orders for each row execute function public.guard_dossier_mutation();
create trigger repair_order_lines_no_direct_mutation before update or delete on public.repair_order_lines for each row execute function public.guard_dossier_mutation();
create trigger dossiers_set_updated_at before update on public.dossiers for each row execute function public.set_updated_at();
create trigger repair_orders_set_updated_at before update on public.repair_orders for each row execute function public.set_updated_at();

create or replace function public.create_dossier_from_validated_quote(p_quote_import_row_id uuid, p_accept_warnings boolean default false)
returns uuid language plpgsql security definer set search_path = '' as $$
declare row_record record; payload record; dossier_id uuid; repair_order_id uuid; next_number bigint; year_value integer := extract(year from timezone('utc', now()))::integer; dossier_number_value text; warning_count integer;
begin
  if auth.uid() is null or not (public.has_role('IMPORT_DEVIS') or public.has_role('DIRECTEUR_SAV') or public.has_role('ADMIN_TECHNIQUE')) then raise exception 'role is not authorized to create a dossier'; end if;
  select r.*, i.organization_id, i.site_id, i.status as operation_status into row_record from public.quote_import_rows r join public.quote_import_operations i on i.id = r.import_operation_id where r.id = p_quote_import_row_id for update;
  if not found or not public.has_site_access(row_record.site_id, 'OPERATE') or not (public.is_admin_technique() or public.has_role('DIRECTEUR_SAV') or public.has_role('IMPORT_DEVIS')) then raise exception 'source import scope is not authorized'; end if;
  if row_record.operation_status <> 'APPROVED' then raise exception 'source import operation is not approved'; end if;
  select p.* into payload from public.quote_import_row_validated_payloads p where p.quote_import_row_id = p_quote_import_row_id order by p.validation_version desc limit 1;
  if not found then raise exception 'validated payload is missing'; end if;
  select count(*) into warning_count from public.quote_import_row_issues x where x.quote_import_row_id = p_quote_import_row_id and x.validation_version = payload.validation_version and x.severity = 'WARNING';
  if exists (select 1 from public.quote_import_row_issues x where x.quote_import_row_id = p_quote_import_row_id and x.validation_version = payload.validation_version and x.is_blocking) then raise exception 'blocking validation issue prevents dossier creation'; end if;
  if warning_count > 0 and (not p_accept_warnings or not (public.has_role('IMPORT_DEVIS') or public.has_role('DIRECTEUR_SAV') or public.has_role('ADMIN_TECHNIQUE'))) then raise exception 'warnings must be explicitly accepted'; end if;
  select d.id into dossier_id from public.dossiers d where d.quote_import_row_id = p_quote_import_row_id;
  if dossier_id is not null then return dossier_id; end if;
  insert into public.dossier_number_counters (organization_id, calendar_year, last_value) values (row_record.organization_id, year_value, 1) on conflict (organization_id, calendar_year) do update set last_value = dossier_number_counters.last_value + 1, updated_at = timezone('utc', now()) returning last_value into next_number;
  dossier_number_value := format('DOS-%s-%s', year_value, lpad(next_number::text, 6, '0'));
  insert into public.dossiers (organization_id, site_id, quote_import_operation_id, quote_import_row_id, dossier_number, source_snapshot, repair_order_snapshot, created_by, updated_by) values (row_record.organization_id, row_record.site_id, row_record.import_operation_id, p_quote_import_row_id, dossier_number_value, jsonb_build_object('source_row_number', payload.source_row_number, 'customer_display_name', payload.customer_display_name, 'customer_external_reference', payload.customer_external_reference, 'vin', payload.vin, 'registration_number', payload.registration_number, 'make', payload.make, 'model', payload.model, 'variant', payload.variant, 'mileage_km', payload.mileage_km, 'powertrain', payload.powertrain, 'payload_hash', payload.payload_hash, 'validation_version', payload.validation_version), jsonb_build_object('source_import_row_id', p_quote_import_row_id, 'normalized_label', payload.normalized_label, 'operation_category', payload.operation_category, 'quantity', payload.quantity, 'unit', payload.unit, 'planned_duration_minutes', payload.planned_duration_minutes, 'source_row_number', payload.source_row_number, 'source_reference', payload.source_reference), auth.uid(), auth.uid()) returning id into dossier_id;
  insert into public.repair_orders (dossier_id, organization_id, site_id, source_import_operation_id, source_import_row_id, provenance_snapshot) values (dossier_id, row_record.organization_id, row_record.site_id, row_record.import_operation_id, p_quote_import_row_id, jsonb_build_object('payload_hash', payload.payload_hash, 'validation_version', payload.validation_version, 'source_import_row_id', p_quote_import_row_id)) returning id into repair_order_id;
  insert into public.repair_order_lines (repair_order_id, source_import_row_id, line_order, source_row_number, description, operation_category, quantity, unit, planned_duration_minutes, source_reference, provenance) values (repair_order_id, p_quote_import_row_id, payload.source_row_number, payload.source_row_number, payload.normalized_label, payload.operation_category, payload.quantity, payload.unit, payload.planned_duration_minutes, payload.source_reference, jsonb_build_object('payload_hash', payload.payload_hash, 'validation_version', payload.validation_version));
  perform public.append_audit_event(row_record.organization_id, row_record.site_id, 'DOSSIER.CREATED_FROM_VALIDATED_QUOTE', 'DOSSIER', dossier_id, jsonb_build_object('quote_import_row_id', p_quote_import_row_id, 'quote_import_operation_id', row_record.import_operation_id, 'validation_version', payload.validation_version, 'payload_hash', payload.payload_hash, 'warnings_accepted', p_accept_warnings, 'warning_count', warning_count));
  return dossier_id;
exception when unique_violation then
  select d.id into dossier_id from public.dossiers d where d.quote_import_row_id = p_quote_import_row_id;
  if dossier_id is not null then return dossier_id; end if; raise;
end;
$$;

revoke all on table public.dossiers, public.repair_orders, public.repair_order_lines, public.dossier_number_counters from anon, authenticated, public;
revoke all on function public.create_dossier_from_validated_quote(uuid,boolean) from public, anon;
grant execute on function public.create_dossier_from_validated_quote(uuid,boolean) to authenticated;
alter table public.dossiers enable row level security; alter table public.repair_orders enable row level security; alter table public.repair_order_lines enable row level security; alter table public.dossier_number_counters enable row level security;
create policy dossiers_read on public.dossiers for select to authenticated using (public.has_site_access(site_id));
create policy repair_orders_read on public.repair_orders for select to authenticated using (public.has_site_access(site_id));
create policy repair_order_lines_read on public.repair_order_lines for select to authenticated using (exists (select 1 from public.repair_orders r where r.id = repair_order_id and public.has_site_access(r.site_id)));
