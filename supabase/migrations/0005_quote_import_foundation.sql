create table if not exists public.quote_import_operations (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete restrict,
  site_id uuid not null,
  operation_key text not null unique check (length(btrim(operation_key)) between 1 and 160),
  status text not null check (status in ('UPLOADED','PARSED','MAPPING_REQUIRED','READY_FOR_REVIEW','VALIDATION_ERROR','APPROVED','REJECTED')),
  source_file_name text not null check (length(btrim(source_file_name)) between 1 and 255 and source_file_name !~ '[/\\]' and source_file_name !~ '[[:cntrl:]]'),
  source_file_size bigint not null check (source_file_size > 0),
  source_mime_type text not null check (length(btrim(source_mime_type)) <= 160),
  source_file_hash text not null check (source_file_hash ~ '^[0-9a-f]{64}$'),
  business_fingerprint text check (business_fingerprint is null or length(btrim(business_fingerprint)) between 1 and 255),
  detected_format text not null check (length(btrim(detected_format)) between 1 and 40),
  detected_delimiter text check (detected_delimiter is null or length(detected_delimiter) = 1),
  mapping_snapshot jsonb,
  summary_snapshot jsonb,
  validation_issues jsonb not null default '[]'::jsonb check (jsonb_typeof(validation_issues) in ('array','object')),
  created_by uuid not null references public.profiles(id) on delete restrict,
  approved_by uuid references public.profiles(id) on delete restrict,
  approved_at timestamptz,
  server_confirmed_at timestamptz,
  rejected_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  foreign key (site_id, organization_id) references public.sites(id, organization_id) on delete restrict,
  check ((status = 'APPROVED') = (approved_at is not null and approved_by is not null)),
  check ((status = 'REJECTED') = (rejected_at is not null)),
  check (approved_at is null or approved_at >= created_at),
  check (rejected_at is null or rejected_at >= created_at)
);
create index if not exists quote_import_source_hash_idx on public.quote_import_operations (organization_id, site_id, source_file_hash);
create index if not exists quote_import_business_fingerprint_idx on public.quote_import_operations (organization_id, site_id, business_fingerprint) where business_fingerprint is not null;

create table if not exists public.quote_import_rows (
  id uuid primary key default gen_random_uuid(),
  import_operation_id uuid not null references public.quote_import_operations(id) on delete restrict,
  source_row_number integer not null check (source_row_number > 0),
  source_values jsonb not null check (jsonb_typeof(source_values) = 'object'),
  normalized_values jsonb check (normalized_values is null or jsonb_typeof(normalized_values) = 'object'),
  validation_status text not null check (validation_status in ('VALID','INVALID','WARNING','UNREVIEWED')),
  issues jsonb not null default '[]'::jsonb check (jsonb_typeof(issues) in ('array','object')),
  created_at timestamptz not null default timezone('utc', now()),
  unique (import_operation_id, source_row_number)
);

create table if not exists public.quote_mapping_templates (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete restrict,
  site_id uuid,
  name text not null check (length(btrim(name)) between 1 and 160),
  normalized_headers text[] not null check (cardinality(normalized_headers) > 0),
  mapping_definition jsonb not null check (jsonb_typeof(mapping_definition) = 'object'),
  active boolean not null default true,
  created_by uuid not null references public.profiles(id) on delete restrict,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  foreign key (site_id, organization_id) references public.sites(id, organization_id) on delete restrict
);
create index if not exists quote_mapping_templates_scope_idx on public.quote_mapping_templates (organization_id, site_id, active);
drop trigger if exists quote_import_operations_set_updated_at on public.quote_import_operations;
create trigger quote_import_operations_set_updated_at before update on public.quote_import_operations for each row execute function public.set_updated_at();
drop trigger if exists quote_mapping_templates_set_updated_at on public.quote_mapping_templates;
create trigger quote_mapping_templates_set_updated_at before update on public.quote_mapping_templates for each row execute function public.set_updated_at();

create or replace function public.guard_quote_import_operation_update()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.id is distinct from old.id
    or new.organization_id is distinct from old.organization_id
    or new.site_id is distinct from old.site_id
    or new.operation_key is distinct from old.operation_key
    or new.source_file_name is distinct from old.source_file_name
    or new.source_file_size is distinct from old.source_file_size
    or new.source_mime_type is distinct from old.source_mime_type
    or new.source_file_hash is distinct from old.source_file_hash
    or new.detected_format is distinct from old.detected_format
    or new.created_by is distinct from old.created_by
    or new.created_at is distinct from old.created_at then
    raise exception 'immutable quote import field';
  end if;
  if old.status in ('APPROVED','REJECTED') then
    raise exception 'finalized quote imports are immutable';
  end if;
  if not (
    (old.status = 'UPLOADED' and new.status in ('UPLOADED','PARSED','VALIDATION_ERROR','REJECTED')) or
    (old.status = 'PARSED' and new.status in ('PARSED','MAPPING_REQUIRED','READY_FOR_REVIEW','VALIDATION_ERROR','REJECTED')) or
    (old.status = 'MAPPING_REQUIRED' and new.status in ('MAPPING_REQUIRED','READY_FOR_REVIEW','VALIDATION_ERROR','REJECTED')) or
    (old.status = 'READY_FOR_REVIEW' and new.status in ('READY_FOR_REVIEW','APPROVED','VALIDATION_ERROR','REJECTED')) or
    (old.status = 'VALIDATION_ERROR' and new.status in ('VALIDATION_ERROR','REJECTED'))
  ) then
    raise exception 'invalid quote import status transition';
  end if;
  if new.status = 'APPROVED' and (new.approved_by is distinct from auth.uid() or new.approved_at is null) then
    raise exception 'approved_by and approved_at must be derived from the authenticated actor';
  end if;
  if new.status <> 'APPROVED' and (new.approved_by is not null or new.approved_at is not null) then
    raise exception 'approved fields require APPROVED status';
  end if;
  if new.status <> 'REJECTED' and new.rejected_at is not null then
    raise exception 'rejected_at requires REJECTED status';
  end if;
  return new;
end;
$$;
revoke all on function public.guard_quote_import_operation_update() from public;
drop trigger if exists quote_import_operations_guard_update on public.quote_import_operations;
create trigger quote_import_operations_guard_update before update on public.quote_import_operations for each row execute function public.guard_quote_import_operation_update();

create or replace function public.guard_quote_import_row_update()
returns trigger language plpgsql set search_path = '' as $$
begin
  if new.id is distinct from old.id or new.import_operation_id is distinct from old.import_operation_id or new.source_row_number is distinct from old.source_row_number or new.created_at is distinct from old.created_at then
    raise exception 'immutable quote import row field';
  end if;
  return new;
end;
$$;
revoke all on function public.guard_quote_import_row_update() from public;
drop trigger if exists quote_import_rows_guard_update on public.quote_import_rows;
create trigger quote_import_rows_guard_update before update on public.quote_import_rows for each row execute function public.guard_quote_import_row_update();

create or replace view public.quote_import_duplicate_candidates as
select a.id, a.organization_id, a.site_id, a.operation_key, a.source_file_hash, a.business_fingerprint,
       exists (select 1 from public.quote_import_operations b where b.organization_id = a.organization_id and b.site_id = a.site_id and b.source_file_hash = a.source_file_hash and b.id <> a.id) as exact_file_duplicate,
       exists (select 1 from public.quote_import_operations b where b.organization_id = a.organization_id and b.site_id = a.site_id and a.business_fingerprint is not null and b.business_fingerprint = a.business_fingerprint and b.id <> a.id) as possible_business_duplicate
from public.quote_import_operations a;
