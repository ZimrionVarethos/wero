-- Shared identity, roles, and administrative regions.
do $$ begin
  create type public.region_level as enum
    ('COUNTRY', 'PROVINCE', 'REGENCY', 'CITY', 'DISTRICT', 'VILLAGE');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.app_role as enum
    ('CITIZEN', 'VOLUNTEER', 'COMMUNITY_MODERATOR', 'GOVERNMENT_ADMIN', 'SUPER_ADMIN');
exception when duplicate_object then null; end $$;

create table if not exists public.regions (
  id uuid primary key default gen_random_uuid(),
  code text unique,
  name text not null,
  level public.region_level not null,
  parent_id uuid references public.regions(id),
  boundary geography(MULTIPOLYGON, 4326),
  buffer_m integer not null default 3000 check (buffer_m >= 0),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (parent_id, name, level)
);

create index if not exists regions_parent_idx on public.regions(parent_id);
create index if not exists regions_level_active_idx on public.regions(level, is_active);
create index if not exists regions_boundary_gix on public.regions using gist(boundary);

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default 'Pengguna'
    check (char_length(display_name) between 1 and 80),
  avatar_path text,
  region_id uuid references public.regions(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists profiles_region_idx on public.profiles(region_id);


-- Private per-user settings are not exposed through the public profile row.
create table if not exists public.user_preferences (
  user_id uuid primary key references auth.users(id) on delete cascade,
  helping_enabled boolean not null default false,
  updated_at timestamptz not null default now()
);

-- Roles are not stored in the editable profile row.
-- Push tokens are private to the account and may be registered by multiple devices.
create table if not exists public.user_devices (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  platform text not null check (platform in ('ANDROID', 'IOS', 'WEB')),
  push_token text not null unique,
  last_seen_at timestamptz not null default now(),
  disabled_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists user_devices_user_active_idx
  on public.user_devices(user_id, disabled_at, last_seen_at desc);

create table if not exists public.user_roles (
  user_id uuid not null references auth.users(id) on delete cascade,
  role public.app_role not null default 'CITIZEN',
  assigned_by uuid references auth.users(id),
  assigned_at timestamptz not null default now(),
  primary key(user_id, role)
);

create or replace function public.has_role(_role public.app_role)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.user_roles ur
    where ur.user_id = (select auth.uid())
      and ur.role = _role
  );
$$;

revoke all on function public.has_role(public.app_role) from public, anon;
grant execute on function public.has_role(public.app_role) to authenticated;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create trigger user_preferences_set_updated_at
before update on public.user_preferences
for each row execute function public.set_updated_at();

create trigger user_devices_set_updated_at
before update on public.user_devices
for each row execute function public.set_updated_at();

create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  new_display_name text;
begin
  new_display_name := nullif(
    left(btrim(coalesce(new.raw_user_meta_data ->> 'display_name', '')), 80),
    ''
  );
  insert into public.profiles(id, display_name)
  values (new.id, coalesce(new_display_name, 'Pengguna'))
  on conflict (id) do nothing;

  insert into public.user_roles(user_id, role)
  values (new.id, 'CITIZEN'::public.app_role)
  on conflict do nothing;

  insert into public.user_preferences(user_id)
  values (new.id)
  on conflict do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created_siagaku on auth.users;
create trigger on_auth_user_created_siagaku
after insert on auth.users
for each row execute function public.handle_new_auth_user();

revoke all on function public.handle_new_auth_user() from public, anon, authenticated;
revoke all on function public.set_updated_at() from public, anon, authenticated;

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

drop trigger if exists regions_set_updated_at on public.regions;
create trigger regions_set_updated_at
before update on public.regions
for each row execute function public.set_updated_at();

-- Assign moderator/admin roles only through a trusted server or controlled SQL migration.
-- Do not create a client-facing role assignment function.
