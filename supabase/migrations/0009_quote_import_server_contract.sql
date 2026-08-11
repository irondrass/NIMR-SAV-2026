-- Server-side proof for a quote row that can become operational workshop work.
-- Commercial fields are deliberately absent: this application plans work only.
create extension if not exists pgcrypto with schema extensions;

create type public.quote_import_issue_severity as enum ('ERROR', 'WARNING', 'INFO');

create table public.quote_import_issue_catalog (
  issue_code text primary key check (issue_code ~ '^[A-Z][A-Z0-9_]{1,63}$'),
  severity public.quote_import_issue_severity not null,
  active boolean not null default true
);

insert into public.quote_import_issue_catalog (issue_code, severity) values
  ('FILE_MISSING', 'ERROR'), ('FILE_EMPTY', 'ERROR'), ('FILE_TOO_LARGE', 'ERROR'),
  ('EXTENSION_INVALID', 'ERROR'), ('MIME_INVALID', 'WARNING'), ('ENCODING_INVALID', 'ERROR'),
  ('ROW_LIMIT_EXCEEDED', 'ERROR'), ('HEADER_MISSING', 'ERROR'), ('DUPLICATE_HEADER', 'ERROR'),
  ('INCONSISTENT_CONTENT', 'ERROR'), ('DANGEROUS_FORMULA', 'WARNING'),
  ('REQUIRED_FIELD_MISSING', 'ERROR'), ('AMBIGUOUS_MAPPING', 'ERROR'),
  ('DUPLICATE_MAPPING', 'ERROR'), ('INVALID_NUMBER', 'ERROR'), ('INVALID_DATE', 'ERROR'),
  ('EMPTY_LINE_LABEL', 'ERROR'), ('DUPLICATE_IMPORT', 'WARNING')
on conflict (issue_code) do nothing;

create table public.quote_import_row_validated_payloads (
  id uuid primary key default gen_random_uuid(),
  quote_import_row_id uuid not null references public.quote_import_rows(id) on delete restrict,
  validation_version integer not null default 1 check (validation_version > 0),
  payload_hash text not null check (payload_hash ~ '^[0-9a-f]{64}$'),
  customer_display_name text check (customer_display_name is null or length(btrim(customer_display_name)) between 1 and 160),
  customer_external_reference text check (customer_external_reference is null or length(btrim(customer_external_reference)) between 1 and 160),
  vin text check (vin is null or length(btrim(vin)) between 1 and 32),
  registration_number text check (registration_number is null or length(btrim(registration_number)) between 1 and 32),
  make text check (make is null or length(btrim(make)) between 1 and 80),
  model text check (model is null or length(btrim(model)) between 1 and 120),
  variant text check (variant is null or length(btrim(variant)) between 1 and 120),
  mileage_km numeric(10,1) check (mileage_km is null or mileage_km >= 0),
  powertrain text check (powertrain is null or powertrain in ('ICE','HYBRID','ELECTRIC','OTHER')),
  normalized_label text not null check (length(btrim(normalized_label)) between 1 and 240),
  operation_category text not null check (operation_category in ('LABOR','BODYWORK','PAINT','MECHANICAL','ELECTRICAL','DIAGNOSTIC','OTHER')),
  quantity numeric(10,3) not null check (quantity > 0),
  unit text not null check (unit in ('unit','hour','day','job')),
  planned_duration_minutes integer not null check (planned_duration_minutes > 0 and planned_duration_minutes <= 10080),
  source_row_number integer not null check (source_row_number > 0),
  source_reference text check (source_reference is null or length(btrim(source_reference)) between 1 and 160),
  validated_at timestamptz not null default timezone('utc', now()),
  unique (quote_import_row_id, validation_version)
);

create table public.quote_import_row_issues (
  id uuid primary key default gen_random_uuid(),
  quote_import_row_id uuid not null references public.quote_import_rows(id) on delete restrict,
  validation_version integer not null check (validation_version > 0),
  issue_code text not null references public.quote_import_issue_catalog(issue_code),
  severity public.quote_import_issue_severity not null,
  is_blocking boolean generated always as (severity = 'ERROR') stored,
  field_key text check (field_key is null or field_key in ('normalized_label','operation_category','quantity','unit','planned_duration_minutes','source_row_number')),
  safe_context jsonb check (safe_context is null or (jsonb_typeof(safe_context) = 'object' and pg_column_size(safe_context) <= 2048)),
  created_at timestamptz not null default timezone('utc', now()),
  unique (quote_import_row_id, validation_version, issue_code, field_key, severity)
);

create index quote_import_row_issues_row_idx on public.quote_import_row_issues (quote_import_row_id, validation_version);
create index quote_import_validated_payloads_hash_idx on public.quote_import_row_validated_payloads (payload_hash);

create or replace function public.guard_quote_import_row_update()
returns trigger language plpgsql set search_path = '' as $$
declare operation_status text;
begin
  if new.id is distinct from old.id or new.import_operation_id is distinct from old.import_operation_id or new.source_row_number is distinct from old.source_row_number or new.created_at is distinct from old.created_at then
    raise exception 'immutable quote import row field';
  end if;
  select status into operation_status from public.quote_import_operations where id = old.import_operation_id;
  if operation_status in ('APPROVED','REJECTED') then raise exception 'finalized quote import rows are immutable'; end if;
  return new;
end;
$$;

create or replace function public.validate_quote_import_payload_shape(p_payload jsonb)
returns boolean language plpgsql immutable set search_path = '' as $$
begin
  if p_payload is null or pg_catalog.jsonb_typeof(p_payload) <> 'object' then return false; end if;
  if exists (select 1 from pg_catalog.jsonb_object_keys(p_payload) as key where key not in ('customer_display_name','customer_external_reference','vin','registration_number','make','model','variant','mileage_km','powertrain','normalized_label','operation_category','quantity','unit','planned_duration_minutes','source_row_number','source_reference')) then return false; end if;
  if not (p_payload ? 'normalized_label' and p_payload ? 'operation_category' and p_payload ? 'quantity'
    and p_payload ? 'unit' and p_payload ? 'planned_duration_minutes' and p_payload ? 'source_row_number') then return false; end if;
  return jsonb_typeof(p_payload->'normalized_label') = 'string'
    and jsonb_typeof(p_payload->'operation_category') = 'string'
    and jsonb_typeof(p_payload->'quantity') = 'number'
    and jsonb_typeof(p_payload->'unit') = 'string'
    and jsonb_typeof(p_payload->'planned_duration_minutes') = 'number'
    and jsonb_typeof(p_payload->'source_row_number') = 'number';
end;
$$;

create or replace function public.guard_validated_payload_mutation()
returns trigger language plpgsql set search_path = '' as $$
declare approved boolean;
begin
  if tg_op = 'DELETE' then
    select i.status = 'APPROVED' into approved from public.quote_import_rows r join public.quote_import_operations i on i.id = r.import_operation_id where r.id = old.quote_import_row_id;
  else
    select i.status = 'APPROVED' into approved from public.quote_import_rows r join public.quote_import_operations i on i.id = r.import_operation_id where r.id = new.quote_import_row_id;
  end if;
  if approved then raise exception 'validated import evidence is immutable after approval'; end if;
  if tg_op = 'UPDATE' then raise exception 'validated payloads are versioned and cannot be updated'; end if;
  if tg_op = 'DELETE' then raise exception 'validated payloads cannot be deleted'; end if;
  return new;
end;
$$;
create trigger quote_import_validated_payloads_immutable before insert or update or delete on public.quote_import_row_validated_payloads for each row execute function public.guard_validated_payload_mutation();
create trigger quote_import_row_issues_immutable before insert or update or delete on public.quote_import_row_issues for each row execute function public.guard_validated_payload_mutation();

create or replace function public.guard_quote_import_approval_contract()
returns trigger language plpgsql set search_path = '' as $$
begin
  if new.status = 'APPROVED' and (exists (
    select 1 from public.quote_import_rows r
    where r.import_operation_id = new.id
      and (not exists (select 1 from public.quote_import_row_validated_payloads p where p.quote_import_row_id = r.id)
        or exists (select 1 from public.quote_import_row_issues x join public.quote_import_row_validated_payloads p on p.quote_import_row_id = x.quote_import_row_id and p.validation_version = x.validation_version where x.quote_import_row_id = r.id and x.is_blocking))
  ) or not exists (select 1 from public.quote_import_rows r where r.import_operation_id = new.id)) then raise exception 'approved import requires a complete non-blocking server validation'; end if;
  return new;
end;
$$;
create trigger quote_import_operations_approval_contract before update on public.quote_import_operations for each row execute function public.guard_quote_import_approval_contract();

create or replace function public.validate_quote_import_row(
  p_quote_import_row_id uuid,
  p_payload jsonb,
  p_issues jsonb default '[]'::jsonb
)
returns table (quote_import_row_id uuid, validation_version integer, validation_status text, payload_hash text, warning_count integer, warning_codes text[])
language plpgsql security definer set search_path = '' as $$
declare row_record record; next_version integer; issue_record jsonb; canonical jsonb; result_hash text; blocking_count integer;
begin
  select r.*, i.organization_id, i.site_id, i.status as operation_status into row_record
  from public.quote_import_rows r join public.quote_import_operations i on i.id = r.import_operation_id
  where r.id = p_quote_import_row_id for update;
  if not found or not public.can_manage_quote_import(row_record.import_operation_id) or row_record.operation_status in ('APPROVED','REJECTED') then raise exception 'quote import row is not eligible for server validation'; end if;
  if not public.validate_quote_import_payload_shape(p_payload) then raise exception 'invalid validated payload shape'; end if;
  if p_issues is null or jsonb_typeof(p_issues) <> 'array' then raise exception 'validation issues must be an array'; end if;
  if (p_payload->>'source_row_number')::integer <> row_record.source_row_number then raise exception 'validated payload source row does not match import row'; end if;
  select coalesce(max(p.validation_version), 0) + 1 into next_version from public.quote_import_row_validated_payloads p where p.quote_import_row_id = p_quote_import_row_id;
  canonical := jsonb_build_object('row_id', p_quote_import_row_id, 'payload', p_payload, 'validation_version', next_version);
  result_hash := encode(extensions.digest(canonical::text, 'sha256'), 'hex');
  insert into public.quote_import_row_validated_payloads (quote_import_row_id, validation_version, payload_hash, customer_display_name, customer_external_reference, vin, registration_number, make, model, variant, mileage_km, powertrain, normalized_label, operation_category, quantity, unit, planned_duration_minutes, source_row_number, source_reference)
  values (p_quote_import_row_id, next_version, result_hash, nullif(btrim(p_payload->>'customer_display_name'), ''), nullif(btrim(p_payload->>'customer_external_reference'), ''), nullif(btrim(p_payload->>'vin'), ''), nullif(btrim(p_payload->>'registration_number'), ''), nullif(btrim(p_payload->>'make'), ''), nullif(btrim(p_payload->>'model'), ''), nullif(btrim(p_payload->>'variant'), ''), (p_payload->>'mileage_km')::numeric, nullif(p_payload->>'powertrain', ''), btrim(p_payload->>'normalized_label'), p_payload->>'operation_category', (p_payload->>'quantity')::numeric, p_payload->>'unit', (p_payload->>'planned_duration_minutes')::integer, (p_payload->>'source_row_number')::integer, nullif(btrim(p_payload->>'source_reference'), ''));
  for issue_record in select value from jsonb_array_elements(p_issues) loop
    if jsonb_typeof(issue_record) <> 'object' or not (issue_record ? 'issue_code') or not exists (select 1 from public.quote_import_issue_catalog c where c.issue_code = issue_record->>'issue_code' and c.active) then raise exception 'invalid validation issue'; end if;
    if issue_record ? 'safe_context' and (jsonb_typeof(issue_record->'safe_context') <> 'object' or issue_record::text ~* '(email|phone|vin|registration|secret|token)') then raise exception 'unsafe validation issue context'; end if;
    insert into public.quote_import_row_issues (quote_import_row_id, validation_version, issue_code, severity, field_key, safe_context)
    select p_quote_import_row_id, next_version, c.issue_code, c.severity, nullif(issue_record->>'field_key',''), issue_record->'safe_context' from public.quote_import_issue_catalog c where c.issue_code = issue_record->>'issue_code';
  end loop;
  select count(*) filter (where x.is_blocking) into blocking_count from public.quote_import_row_issues x where x.quote_import_row_id = p_quote_import_row_id and x.validation_version = next_version;
  update public.quote_import_rows set normalized_values = p_payload, validation_status = case when blocking_count > 0 then 'INVALID' when exists (select 1 from public.quote_import_row_issues x where x.quote_import_row_id = p_quote_import_row_id and x.validation_version = next_version and x.severity = 'WARNING') then 'WARNING' else 'VALID' end, issues = p_issues where id = p_quote_import_row_id;
  perform public.append_audit_event(row_record.organization_id, row_record.site_id, 'QUOTE_IMPORT.ROW_VALIDATION_COMPLETED', 'QUOTE_IMPORT_ROW', p_quote_import_row_id, jsonb_build_object('validation_version', next_version, 'payload_hash', result_hash, 'issue_count', jsonb_array_length(p_issues), 'warning_count', (select count(*) from public.quote_import_row_issues x where x.quote_import_row_id = p_quote_import_row_id and x.validation_version = next_version and x.severity = 'WARNING')));
  return query select p_quote_import_row_id, next_version, qr.validation_status, result_hash, coalesce((select count(*)::integer from public.quote_import_row_issues x where x.quote_import_row_id = p_quote_import_row_id and x.validation_version = next_version and x.severity = 'WARNING'), 0), coalesce((select array_agg(x.issue_code order by x.issue_code) from public.quote_import_row_issues x where x.quote_import_row_id = p_quote_import_row_id and x.validation_version = next_version and x.severity = 'WARNING'), '{}'::text[]) from public.quote_import_rows qr where qr.id = p_quote_import_row_id;
end;
$$;

revoke all on table public.quote_import_issue_catalog, public.quote_import_row_validated_payloads, public.quote_import_row_issues from anon, authenticated, public;
revoke all on function public.validate_quote_import_payload_shape(jsonb), public.validate_quote_import_row(uuid,jsonb,jsonb) from public, anon;
grant execute on function public.validate_quote_import_row(uuid,jsonb,jsonb) to authenticated;

alter table public.quote_import_issue_catalog enable row level security;
alter table public.quote_import_row_validated_payloads enable row level security;
alter table public.quote_import_row_issues enable row level security;
create policy quote_import_issue_catalog_read on public.quote_import_issue_catalog for select to authenticated using (true);
create policy quote_import_validated_payload_read on public.quote_import_row_validated_payloads for select to authenticated using (exists (select 1 from public.quote_import_rows r join public.quote_import_operations i on i.id = r.import_operation_id where r.id = quote_import_row_id and public.has_site_access(i.site_id)));
create policy quote_import_issue_read on public.quote_import_row_issues for select to authenticated using (exists (select 1 from public.quote_import_rows r join public.quote_import_operations i on i.id = r.import_operation_id where r.id = quote_import_row_id and public.has_site_access(i.site_id)));
