-- Shared timestamp helper. No business tables or demo data are created here.
revoke create on schema public from public;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = pg_catalog.timezone('utc', pg_catalog.now());
  return new;
end;
$$;

revoke all on function public.set_updated_at() from public;

-- Storage path helpers are deliberately non-throwing. They validate the exact
-- four-segment convention before any UUID cast used by Storage RLS.
create or replace function public.storage_path_has_expected_shape(path text)
returns boolean
language sql immutable
set search_path = ''
as $$
  select path is not null
    and path !~ '[[:cntrl:]]'
    and path !~ '(^|/)\.\.(/|$)'
    and path !~ '^/'
    and path !~ '/$'
    and path !~ '//'
    and path ~ '^[^/]+/[^/]+/[^/]+/[^/]+$';
$$;

create or replace function public.storage_path_organization_id(path text)
returns uuid
language sql immutable
set search_path = ''
as $$
  select case when public.storage_path_has_expected_shape(path)
    and pg_catalog.split_part(path, '/', 1) ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'
    then pg_catalog.split_part(path, '/', 1)::uuid else null end;
$$;

create or replace function public.storage_path_site_id(path text)
returns uuid
language sql immutable
set search_path = ''
as $$
  select case when public.storage_path_has_expected_shape(path)
    and pg_catalog.split_part(path, '/', 2) ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'
    then pg_catalog.split_part(path, '/', 2)::uuid else null end;
$$;

create or replace function public.storage_path_import_operation_id(path text)
returns uuid
language sql immutable
set search_path = ''
as $$
  select case when public.storage_path_has_expected_shape(path)
    and pg_catalog.split_part(path, '/', 3) ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'
    then pg_catalog.split_part(path, '/', 3)::uuid else null end;
$$;

revoke all on function public.storage_path_has_expected_shape(text) from public;
revoke all on function public.storage_path_organization_id(text) from public;
revoke all on function public.storage_path_site_id(text) from public;
revoke all on function public.storage_path_import_operation_id(text) from public;
