-- Workshop task foundation: executable work derived from repair-order lines.

create type public.workshop_task_priority as enum ('LOW', 'NORMAL', 'HIGH', 'URGENT');
create type public.workshop_task_status as enum ('READY', 'PLANNED', 'IN_PROGRESS', 'COMPLETED', 'ON_HOLD', 'CANCELLED');
create type public.workshop_task_dependency_type as enum ('FINISH_TO_START');

create or replace function public.normalize_workshop_code(p_value text)
returns text language sql immutable security invoker set search_path = ''
as $$
  select nullif(trim(both '_' from upper(regexp_replace(btrim(p_value), '[^A-Za-z0-9]+', '_', 'g'))), '')
$$;

alter table public.repair_orders add constraint repair_orders_scope_key unique (id, organization_id, site_id);
alter table public.repair_order_lines add constraint repair_order_lines_order_key unique (id, repair_order_id);

create table public.workshop_tasks (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id),
  site_id uuid not null references public.sites(id),
  repair_order_id uuid not null,
  source_repair_order_line_id uuid not null,
  task_key text not null,
  task_sequence integer not null,
  task_label text,
  task_category text,
  planned_duration_minutes integer not null,
  priority public.workshop_task_priority not null default 'NORMAL',
  status public.workshop_task_status not null default 'READY',
  technical_notes text,
  hold_reason text,
  created_by uuid not null references auth.users(id),
  updated_by uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  version integer not null default 1,
  constraint workshop_tasks_scope_fk foreign key (repair_order_id, organization_id, site_id)
    references public.repair_orders(id, organization_id, site_id),
  constraint workshop_tasks_source_fk foreign key (source_repair_order_line_id, repair_order_id)
    references public.repair_order_lines(id, repair_order_id),
  constraint workshop_tasks_scope_unique unique (id, organization_id, site_id),
  constraint workshop_tasks_key_check check (length(task_key) between 1 and 80 and task_key = public.normalize_workshop_code(task_key)),
  constraint workshop_tasks_sequence_check check (task_sequence > 0),
  constraint workshop_tasks_duration_check check (planned_duration_minutes > 0),
  constraint workshop_tasks_label_check check (task_label is null or length(btrim(task_label)) between 1 and 240),
  constraint workshop_tasks_category_check check (task_category is null or length(btrim(task_category)) between 1 and 80),
  constraint workshop_tasks_notes_check check (technical_notes is null or length(btrim(technical_notes)) between 1 and 4000),
  constraint workshop_tasks_hold_reason_check check (status <> 'ON_HOLD' or (hold_reason is not null and length(btrim(hold_reason)) between 1 and 500)),
  constraint workshop_tasks_version_check check (version > 0),
  constraint workshop_tasks_source_key_unique unique (source_repair_order_line_id, task_key),
  constraint workshop_tasks_source_sequence_unique unique (source_repair_order_line_id, task_sequence)
);

create table public.task_dependencies (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id),
  site_id uuid not null references public.sites(id),
  predecessor_task_id uuid not null,
  successor_task_id uuid not null,
  dependency_type public.workshop_task_dependency_type not null default 'FINISH_TO_START',
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  constraint task_dependencies_predecessor_fk foreign key (predecessor_task_id, organization_id, site_id)
    references public.workshop_tasks(id, organization_id, site_id),
  constraint task_dependencies_successor_fk foreign key (successor_task_id, organization_id, site_id)
    references public.workshop_tasks(id, organization_id, site_id),
  constraint task_dependencies_not_self check (predecessor_task_id <> successor_task_id),
  constraint task_dependencies_pair_unique unique (predecessor_task_id, successor_task_id)
);

create table public.task_skill_requirements (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id),
  site_id uuid not null references public.sites(id),
  task_id uuid not null,
  skill_code text not null,
  is_mandatory boolean not null default true,
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  constraint task_skill_requirements_task_fk foreign key (task_id, organization_id, site_id)
    references public.workshop_tasks(id, organization_id, site_id),
  constraint task_skill_requirements_code_check check (length(skill_code) between 1 and 80 and skill_code = public.normalize_workshop_code(skill_code)),
  constraint task_skill_requirements_unique unique (task_id, skill_code)
);

create table public.task_resource_requirements (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id),
  site_id uuid not null references public.sites(id),
  task_id uuid not null,
  resource_capability_code text not null,
  quantity_required numeric(10,3) not null default 1,
  is_mandatory boolean not null default true,
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  constraint task_resource_requirements_task_fk foreign key (task_id, organization_id, site_id)
    references public.workshop_tasks(id, organization_id, site_id),
  constraint task_resource_requirements_code_check check (length(resource_capability_code) between 1 and 80 and resource_capability_code = public.normalize_workshop_code(resource_capability_code)),
  constraint task_resource_requirements_quantity_check check (quantity_required > 0),
  constraint task_resource_requirements_unique unique (task_id, resource_capability_code)
);

create index workshop_tasks_scope_idx on public.workshop_tasks (organization_id, site_id, status);
create index workshop_tasks_source_idx on public.workshop_tasks (source_repair_order_line_id, task_sequence);
create index task_dependencies_successor_idx on public.task_dependencies (successor_task_id);
create index task_skill_requirements_task_idx on public.task_skill_requirements (task_id);
create index task_resource_requirements_task_idx on public.task_resource_requirements (task_id);

create or replace function public.guard_workshop_task_mutation()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
  if tg_op = 'DELETE' then raise exception 'workshop tasks cannot be physically deleted' using errcode = '42501'; end if;
  if new.id is distinct from old.id or new.organization_id is distinct from old.organization_id
    or new.site_id is distinct from old.site_id or new.repair_order_id is distinct from old.repair_order_id
    or new.source_repair_order_line_id is distinct from old.source_repair_order_line_id
    or new.task_key is distinct from old.task_key or new.task_sequence is distinct from old.task_sequence
    or new.created_by is distinct from old.created_by or new.created_at is distinct from old.created_at
  then raise exception 'workshop task source identity is immutable' using errcode = '42501'; end if;
  return new;
end;
$$;

create trigger workshop_tasks_mutation_guard before update or delete on public.workshop_tasks
for each row execute function public.guard_workshop_task_mutation();

create or replace function public.guard_workshop_task_child_mutation()
returns trigger language plpgsql security definer set search_path = ''
as $$ begin raise exception 'workshop task requirements and dependencies are immutable' using errcode = '42501'; end; $$;

create trigger task_dependencies_mutation_guard before update or delete on public.task_dependencies
for each row execute function public.guard_workshop_task_child_mutation();
create trigger task_skill_requirements_mutation_guard before update or delete on public.task_skill_requirements
for each row execute function public.guard_workshop_task_child_mutation();
create trigger task_resource_requirements_mutation_guard before update or delete on public.task_resource_requirements
for each row execute function public.guard_workshop_task_child_mutation();

create or replace function public.create_workshop_task_from_repair_order_line(
  p_source_repair_order_line_id uuid, p_task_key text, p_task_sequence integer,
  p_planned_duration_minutes integer, p_priority public.workshop_task_priority default 'NORMAL',
  p_task_label text default null, p_task_category text default null, p_technical_notes text default null
)
returns uuid language plpgsql security definer set search_path = ''
as $$
declare
  v_actor uuid := auth.uid(); v_line public.repair_order_lines%rowtype; v_order public.repair_orders%rowtype; v_task_id uuid;
  v_key text := public.normalize_workshop_code(p_task_key);
  v_label text := nullif(btrim(p_task_label), '');
  v_category text := nullif(btrim(p_task_category), '');
  v_notes text := nullif(btrim(p_technical_notes), '');
begin
  if v_actor is null then raise exception 'authenticated actor required' using errcode = '42501'; end if;
  if not (public.has_role('CHEF_ATELIER') or public.has_role('DIRECTEUR_SAV') or public.has_role('ADMIN_TECHNIQUE')) then
    raise exception 'workshop task creation is not authorized' using errcode = '42501'; end if;
  select * into v_line from public.repair_order_lines where id = p_source_repair_order_line_id;
  select * into v_order from public.repair_orders where id = v_line.repair_order_id;
  if not found or v_line.id is null or v_order.id is null or not public.has_site_access(v_order.site_id, 'OPERATE') then
    raise exception 'source repair-order line is not authorized' using errcode = '42501'; end if;
  if v_key is null then raise exception 'task key is required' using errcode = '22023'; end if;
  if p_task_sequence is null or p_task_sequence <= 0 then raise exception 'task sequence must be positive' using errcode = '22023'; end if;
  if p_planned_duration_minutes is null or p_planned_duration_minutes <= 0 then raise exception 'planned duration must be positive' using errcode = '22023'; end if;
  insert into public.workshop_tasks (organization_id, site_id, repair_order_id, source_repair_order_line_id, task_key, task_sequence, task_label, task_category, planned_duration_minutes, priority, technical_notes, created_by, updated_by)
  values (v_order.organization_id, v_order.site_id, v_line.repair_order_id, v_line.id, v_key, p_task_sequence, v_label, v_category, p_planned_duration_minutes, p_priority, v_notes, v_actor, v_actor)
  returning id into v_task_id;
  perform public.append_audit_event(v_order.organization_id, v_order.site_id, 'WORKSHOP_TASK.CREATED', 'WORKSHOP_TASK', v_task_id,
    jsonb_build_object('source_repair_order_line_id', v_line.id, 'task_key', v_key, 'task_sequence', p_task_sequence, 'planned_duration_minutes', p_planned_duration_minutes, 'priority', p_priority::text));
  return v_task_id;
end;
$$;

create or replace function public.transition_workshop_task(
  p_task_id uuid, p_expected_version integer, p_new_status public.workshop_task_status, p_hold_reason text default null
)
returns uuid language plpgsql security definer set search_path = ''
as $$
declare
  v_actor uuid := auth.uid(); v_task public.workshop_tasks%rowtype; v_reason text := nullif(btrim(p_hold_reason), ''); v_allowed boolean := false;
begin
  if v_actor is null then raise exception 'authenticated actor required' using errcode = '42501'; end if;
  if not (public.has_role('CHEF_ATELIER') or public.has_role('DIRECTEUR_SAV') or public.has_role('ADMIN_TECHNIQUE')) then
    raise exception 'workshop task transition is not authorized' using errcode = '42501'; end if;
  select * into v_task from public.workshop_tasks where id = p_task_id for update;
  if not found or not public.has_site_access(v_task.site_id, 'OPERATE') then raise exception 'workshop task is not authorized' using errcode = '42501'; end if;
  if p_expected_version is distinct from v_task.version then raise exception 'stale workshop task version' using errcode = '40001'; end if;
  v_allowed := (v_task.status, p_new_status) in (
    ('READY','PLANNED'), ('READY','ON_HOLD'), ('READY','CANCELLED'),
    ('PLANNED','IN_PROGRESS'), ('PLANNED','ON_HOLD'), ('PLANNED','CANCELLED'),
    ('IN_PROGRESS','COMPLETED'), ('IN_PROGRESS','ON_HOLD'), ('IN_PROGRESS','CANCELLED'),
    ('ON_HOLD','READY'), ('ON_HOLD','PLANNED'), ('ON_HOLD','IN_PROGRESS'), ('ON_HOLD','CANCELLED')
  );
  if not v_allowed then raise exception 'invalid workshop task status transition' using errcode = '22023'; end if;
  if p_new_status = 'ON_HOLD' and v_reason is null then raise exception 'hold reason is required' using errcode = '22023'; end if;
  update public.workshop_tasks set status = p_new_status, hold_reason = case when p_new_status = 'ON_HOLD' then v_reason else null end, updated_by = v_actor, updated_at = now(), version = version + 1 where id = p_task_id;
  perform public.append_audit_event(v_task.organization_id, v_task.site_id,
    case when p_new_status = 'ON_HOLD' then 'WORKSHOP_TASK.ON_HOLD' else 'WORKSHOP_TASK.STATUS_CHANGED' end,
    'WORKSHOP_TASK', v_task.id, jsonb_build_object('previous_status', v_task.status::text, 'new_status', p_new_status::text, 'previous_version', v_task.version, 'new_version', v_task.version + 1, 'hold_reason', case when p_new_status = 'ON_HOLD' then v_reason else null end));
  return p_task_id;
end;
$$;

create or replace function public.create_workshop_task_dependency(
  p_predecessor_task_id uuid, p_successor_task_id uuid, p_dependency_type public.workshop_task_dependency_type default 'FINISH_TO_START'
)
returns uuid language plpgsql security definer set search_path = ''
as $$
declare v_actor uuid := auth.uid(); v_org uuid; v_site uuid; v_id uuid;
begin
  if v_actor is null or not (public.has_role('CHEF_ATELIER') or public.has_role('DIRECTEUR_SAV') or public.has_role('ADMIN_TECHNIQUE')) then raise exception 'dependency creation is not authorized' using errcode = '42501'; end if;
  select p.organization_id, p.site_id into v_org, v_site from public.workshop_tasks p join public.workshop_tasks s on s.id = p_successor_task_id where p.id = p_predecessor_task_id and p.organization_id = s.organization_id and p.site_id = s.site_id;
  if v_org is null or not public.has_site_access(v_site, 'OPERATE') then raise exception 'dependency tasks are not authorized' using errcode = '42501'; end if;
  if p_predecessor_task_id = p_successor_task_id then raise exception 'self dependency is not allowed' using errcode = '22023'; end if;
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(v_org::text || ':' || v_site::text, 0));
  if exists (with recursive reachable(task_id) as (select p_successor_task_id union select d.successor_task_id from reachable r join public.task_dependencies d on d.predecessor_task_id = r.task_id where d.organization_id = v_org and d.site_id = v_site) select 1 from reachable where task_id = p_predecessor_task_id) then raise exception 'dependency cycle is not allowed' using errcode = '22023'; end if;
  insert into public.task_dependencies (organization_id, site_id, predecessor_task_id, successor_task_id, dependency_type, created_by) values (v_org, v_site, p_predecessor_task_id, p_successor_task_id, p_dependency_type, v_actor) returning id into v_id;
  perform public.append_audit_event(v_org, v_site, 'WORKSHOP_TASK.DEPENDENCY_CREATED', 'TASK_DEPENDENCY', v_id, jsonb_build_object('predecessor_task_id', p_predecessor_task_id, 'successor_task_id', p_successor_task_id, 'dependency_type', p_dependency_type::text));
  return v_id;
end;
$$;

create or replace function public.create_workshop_task_skill_requirement(p_task_id uuid, p_skill_code text, p_is_mandatory boolean default true)
returns uuid language plpgsql security definer set search_path = ''
as $$
declare v_actor uuid := auth.uid(); v_task public.workshop_tasks%rowtype; v_code text := public.normalize_workshop_code(p_skill_code); v_id uuid;
begin
  if v_actor is null or not (public.has_role('CHEF_ATELIER') or public.has_role('DIRECTEUR_SAV') or public.has_role('ADMIN_TECHNIQUE')) then raise exception 'skill requirement creation is not authorized' using errcode = '42501'; end if;
  select * into v_task from public.workshop_tasks where id = p_task_id;
  if not found or not public.has_site_access(v_task.site_id, 'OPERATE') then raise exception 'workshop task is not authorized' using errcode = '42501'; end if;
  if v_code is null then raise exception 'skill code is required' using errcode = '22023'; end if;
  insert into public.task_skill_requirements (organization_id, site_id, task_id, skill_code, is_mandatory, created_by) values (v_task.organization_id, v_task.site_id, v_task.id, v_code, p_is_mandatory, v_actor) returning id into v_id;
  perform public.append_audit_event(v_task.organization_id, v_task.site_id, 'WORKSHOP_TASK.SKILL_REQUIRED', 'TASK_SKILL_REQUIREMENT', v_id, jsonb_build_object('task_id', v_task.id, 'skill_code', v_code, 'is_mandatory', p_is_mandatory));
  return v_id;
end;
$$;

create or replace function public.create_workshop_task_resource_requirement(p_task_id uuid, p_resource_capability_code text, p_quantity_required numeric default 1, p_is_mandatory boolean default true)
returns uuid language plpgsql security definer set search_path = ''
as $$
declare v_actor uuid := auth.uid(); v_task public.workshop_tasks%rowtype; v_code text := public.normalize_workshop_code(p_resource_capability_code); v_id uuid;
begin
  if v_actor is null or not (public.has_role('CHEF_ATELIER') or public.has_role('DIRECTEUR_SAV') or public.has_role('ADMIN_TECHNIQUE')) then raise exception 'resource requirement creation is not authorized' using errcode = '42501'; end if;
  select * into v_task from public.workshop_tasks where id = p_task_id;
  if not found or not public.has_site_access(v_task.site_id, 'OPERATE') then raise exception 'workshop task is not authorized' using errcode = '42501'; end if;
  if v_code is null or p_quantity_required is null or p_quantity_required <= 0 then raise exception 'resource capability and positive quantity are required' using errcode = '22023'; end if;
  insert into public.task_resource_requirements (organization_id, site_id, task_id, resource_capability_code, quantity_required, is_mandatory, created_by) values (v_task.organization_id, v_task.site_id, v_task.id, v_code, p_quantity_required, p_is_mandatory, v_actor) returning id into v_id;
  perform public.append_audit_event(v_task.organization_id, v_task.site_id, 'WORKSHOP_TASK.RESOURCE_REQUIRED', 'TASK_RESOURCE_REQUIREMENT', v_id, jsonb_build_object('task_id', v_task.id, 'resource_capability_code', v_code, 'quantity_required', p_quantity_required, 'is_mandatory', p_is_mandatory));
  return v_id;
end;
$$;

alter table public.workshop_tasks enable row level security;
alter table public.task_dependencies enable row level security;
alter table public.task_skill_requirements enable row level security;
alter table public.task_resource_requirements enable row level security;

create policy workshop_tasks_read on public.workshop_tasks for select to authenticated using (public.has_site_access(site_id, 'READ'));
create policy task_dependencies_read on public.task_dependencies for select to authenticated using (public.has_site_access(site_id, 'READ'));
create policy task_skill_requirements_read on public.task_skill_requirements for select to authenticated using (public.has_site_access(site_id, 'READ'));
create policy task_resource_requirements_read on public.task_resource_requirements for select to authenticated using (public.has_site_access(site_id, 'READ'));

revoke all on table public.workshop_tasks, public.task_dependencies, public.task_skill_requirements, public.task_resource_requirements from anon, authenticated, public;
grant select on table public.workshop_tasks, public.task_dependencies, public.task_skill_requirements, public.task_resource_requirements to authenticated;

revoke all on function public.create_workshop_task_from_repair_order_line(uuid, text, integer, integer, public.workshop_task_priority, text, text, text) from public, anon;
revoke all on function public.transition_workshop_task(uuid, integer, public.workshop_task_status, text) from public, anon;
revoke all on function public.create_workshop_task_dependency(uuid, uuid, public.workshop_task_dependency_type) from public, anon;
revoke all on function public.create_workshop_task_skill_requirement(uuid, text, boolean) from public, anon;
revoke all on function public.create_workshop_task_resource_requirement(uuid, text, numeric, boolean) from public, anon;
grant execute on function public.create_workshop_task_from_repair_order_line(uuid, text, integer, integer, public.workshop_task_priority, text, text, text) to authenticated;
grant execute on function public.transition_workshop_task(uuid, integer, public.workshop_task_status, text) to authenticated;
grant execute on function public.create_workshop_task_dependency(uuid, uuid, public.workshop_task_dependency_type) to authenticated;
grant execute on function public.create_workshop_task_skill_requirement(uuid, text, boolean) to authenticated;
grant execute on function public.create_workshop_task_resource_requirement(uuid, text, numeric, boolean) to authenticated;
