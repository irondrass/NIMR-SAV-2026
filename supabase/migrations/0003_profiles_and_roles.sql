create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete restrict,
  email text check (email is null or email = lower(btrim(email))),
  display_name text check (display_name is null or length(display_name) <= 160),
  active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.roles (
  id smallint generated always as identity primary key,
  code text not null unique check (code in ('ADMIN_TECHNIQUE','DIRECTEUR_SAV','CHEF_ATELIER','IMPORT_DEVIS','TECHNICIEN','CONTROLE_QUALITE','RESPONSABLE_GARANTIE','LECTURE_SEULE')),
  description text not null
);

insert into public.roles (code, description) values
  ('ADMIN_TECHNIQUE', 'Administration technique contrôlée'),
  ('DIRECTEUR_SAV', 'Direction du SAV'),
  ('CHEF_ATELIER', 'Pilotage atelier'),
  ('IMPORT_DEVIS', 'Import et revue des devis'),
  ('TECHNICIEN', 'Exécution technique'),
  ('CONTROLE_QUALITE', 'Contrôle qualité'),
  ('RESPONSABLE_GARANTIE', 'Gestion garantie'),
  ('LECTURE_SEULE', 'Consultation selon périmètre')
on conflict (code) do nothing;

create table if not exists public.profile_roles (
  profile_id uuid not null references public.profiles(id) on delete restrict,
  role_id smallint not null references public.roles(id) on delete restrict,
  assigned_at timestamptz not null default timezone('utc', now()),
  assigned_by uuid references public.profiles(id) on delete restrict,
  primary key (profile_id, role_id)
);

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at before update on public.profiles for each row execute function public.set_updated_at();

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, email, display_name)
  values (new.id, pg_catalog.lower(new.email), nullif(coalesce(new.raw_user_meta_data ->> 'display_name', ''), ''))
  on conflict (id) do nothing;
  return new;
end;
$$;
revoke all on function public.handle_new_user() from public;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute function public.handle_new_user();
