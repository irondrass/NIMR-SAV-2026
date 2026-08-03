create table if not exists public.audit_events (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid references public.organizations(id) on delete restrict,
  site_id uuid,
  actor_profile_id uuid references public.profiles(id) on delete restrict,
  event_type text not null check (length(btrim(event_type)) between 1 and 100),
  entity_type text not null check (length(btrim(entity_type)) between 1 and 100),
  entity_id uuid,
  event_data jsonb not null default '{}'::jsonb check (jsonb_typeof(event_data) = 'object'),
  request_id text check (request_id is null or length(request_id) <= 160),
  created_at timestamptz not null default timezone('utc', now()),
  foreign key (site_id, organization_id) references public.sites(id, organization_id) on delete restrict
);
create index if not exists audit_events_scope_idx on public.audit_events (organization_id, site_id, created_at desc);
create index if not exists audit_events_entity_idx on public.audit_events (entity_type, entity_id, created_at desc);

create or replace function public.prevent_audit_mutation()
returns trigger language plpgsql set search_path = '' as $$
begin
  raise exception 'audit_events is append-only';
end;
$$;
revoke all on function public.prevent_audit_mutation() from public;
drop trigger if exists audit_events_no_update on public.audit_events;
create trigger audit_events_no_update before update or delete on public.audit_events for each row execute function public.prevent_audit_mutation();

create or replace function public.append_audit_event(
  p_organization_id uuid,
  p_site_id uuid,
  p_event_type text,
  p_entity_type text,
  p_entity_id uuid default null,
  p_event_data jsonb default '{}'::jsonb,
  p_request_id text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare actor uuid := public.current_profile_id(); result_id uuid;
begin
  if actor is null or p_event_type is null or p_event_type !~ '^[A-Z][A-Z0-9_.-]{1,99}$' or p_entity_type is null or p_entity_type !~ '^[A-Z][A-Z0-9_.-]{1,99}$' then
    raise exception 'invalid audit actor or event type';
  end if;
  if p_event_data is null or pg_catalog.jsonb_typeof(p_event_data) <> 'object' or pg_catalog.pg_column_size(p_event_data) > 32768 or p_event_data::text ~* '(password|secret|token|authorization|service[_-]role)' then
    raise exception 'audit event data is invalid or sensitive';
  end if;
  if p_site_id is null then
    if not public.is_admin_technique() or not public.has_organization_access(p_organization_id) then raise exception 'global audit events require technical administration'; end if;
  else
    if not exists (select 1 from public.sites s where s.id = p_site_id and s.organization_id = p_organization_id) or not public.has_site_access(p_site_id, 'OPERATE') then raise exception 'audit scope is not authorized'; end if;
  end if;
  insert into public.audit_events (organization_id, site_id, actor_profile_id, event_type, entity_type, entity_id, event_data, request_id)
  values (p_organization_id, p_site_id, actor, p_event_type, p_entity_type, p_entity_id, p_event_data, p_request_id)
  returning id into result_id;
  return result_id;
end;
$$;
revoke all on function public.append_audit_event(uuid,uuid,text,text,uuid,jsonb,text) from public;
