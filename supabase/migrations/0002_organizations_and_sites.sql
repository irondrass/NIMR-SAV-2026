create table if not exists public.organizations (
  id uuid primary key default gen_random_uuid(),
  code text not null unique check (length(btrim(code)) between 1 and 64),
  name text not null check (length(btrim(name)) between 1 and 160),
  active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.sites (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete restrict,
  code text not null check (length(btrim(code)) between 1 and 64),
  name text not null check (length(btrim(name)) between 1 and 160),
  city text check (city is null or length(city) <= 120),
  active boolean not null default true,
  timezone text not null default 'Africa/Tunis' check (length(btrim(timezone)) between 1 and 80),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (organization_id, code),
  unique (id, organization_id)
);

create index if not exists sites_organization_active_idx on public.sites (organization_id, active);
drop trigger if exists organizations_set_updated_at on public.organizations;
create trigger organizations_set_updated_at before update on public.organizations for each row execute function public.set_updated_at();
drop trigger if exists sites_set_updated_at on public.sites;
create trigger sites_set_updated_at before update on public.sites for each row execute function public.set_updated_at();

