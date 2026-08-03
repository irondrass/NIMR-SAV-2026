insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('quote-source-files', 'quote-source-files', false, 52428800, array['text/csv','application/csv','application/vnd.ms-excel','application/octet-stream'])
on conflict (id) do update set public = false;

create table if not exists public.attachments (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete restrict,
  site_id uuid not null,
  entity_type text not null check (entity_type = 'QUOTE_IMPORT'),
  entity_id uuid not null references public.quote_import_operations(id) on delete restrict,
  storage_bucket text not null check (storage_bucket = 'quote-source-files'),
  storage_path text not null check (storage_path ~ '^[0-9a-fA-F-]{36}/[0-9a-fA-F-]{36}/[0-9a-fA-F-]{36}/[^/]+$'),
  original_file_name text not null check (length(btrim(original_file_name)) between 1 and 255),
  mime_type text not null check (length(btrim(mime_type)) <= 160),
  file_size bigint not null check (file_size > 0),
  file_hash text check (file_hash is null or file_hash ~ '^[0-9a-f]{64}$'),
  uploaded_by uuid not null references public.profiles(id) on delete restrict,
  created_at timestamptz not null default timezone('utc', now()),
  foreign key (site_id, organization_id) references public.sites(id, organization_id) on delete restrict,
  unique (storage_bucket, storage_path)
);
create index if not exists attachments_entity_idx on public.attachments (entity_type, entity_id);

create or replace function public.guard_attachment_insert()
returns trigger language plpgsql set search_path = '' as $$
declare operation_row record;
begin
  select i.organization_id, i.site_id into operation_row from public.quote_import_operations i where i.id = new.entity_id;
  if operation_row.organization_id is null or new.organization_id is distinct from operation_row.organization_id or new.site_id is distinct from operation_row.site_id then
    raise exception 'attachment scope must match its quote import';
  end if;
  if new.uploaded_by is distinct from auth.uid() then raise exception 'uploaded_by must be the authenticated actor'; end if;
  return new;
end;
$$;
revoke all on function public.guard_attachment_insert() from public;
drop trigger if exists attachments_guard_insert on public.attachments;
create trigger attachments_guard_insert before insert on public.attachments for each row execute function public.guard_attachment_insert();

create or replace function public.guard_attachment_update()
returns trigger language plpgsql set search_path = '' as $$
begin
  if new.id is distinct from old.id or new.organization_id is distinct from old.organization_id or new.site_id is distinct from old.site_id or new.entity_type is distinct from old.entity_type or new.entity_id is distinct from old.entity_id or new.storage_bucket is distinct from old.storage_bucket or new.storage_path is distinct from old.storage_path or new.original_file_name is distinct from old.original_file_name or new.uploaded_by is distinct from old.uploaded_by or new.created_at is distinct from old.created_at then
    raise exception 'immutable attachment identity field';
  end if;
  return new;
end;
$$;
revoke all on function public.guard_attachment_update() from public;
drop trigger if exists attachments_guard_update on public.attachments;
create trigger attachments_guard_update before update on public.attachments for each row execute function public.guard_attachment_update();
