create table if not exists public.profile_site_access (
  profile_id uuid not null references public.profiles(id) on delete restrict,
  site_id uuid not null references public.sites(id) on delete restrict,
  access_scope text not null check (access_scope in ('READ','OPERATE','MANAGE')),
  assigned_at timestamptz not null default timezone('utc', now()),
  assigned_by uuid references public.profiles(id) on delete restrict,
  primary key (profile_id, site_id)
);
create index if not exists profile_site_access_site_idx on public.profile_site_access (site_id, access_scope);

