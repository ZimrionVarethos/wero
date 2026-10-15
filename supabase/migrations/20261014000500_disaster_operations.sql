-- Data structures for alerts, evacuation, trusted contacts, SOS, and audit.
-- Ingestion and sensitive SOS mutations should be performed by trusted server-side functions.

create table if not exists public.disaster_events (
  id uuid primary key default gen_random_uuid(),
  source text not null,
  source_event_id text not null,
  disaster_type text not null,
  severity text not null check (severity in ('AWAS', 'SIAGA', 'WASPADA', 'INFO', 'UNKNOWN')),
  magnitude numeric,
  depth_km numeric,
  epicenter geography(POINT, 4326),
  affected_area geography(MULTIPOLYGON, 4326),
  region_id uuid references public.regions(id),
  headline text not null,
  source_url text,
  source_published_at timestamptz,
  occurred_at timestamptz,
  source_payload jsonb not null default '{}'::jsonb,
  is_published boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(source, source_event_id)
);

create index if not exists disaster_events_recent_idx
  on public.disaster_events(is_published, occurred_at desc, created_at desc);
create index if not exists disaster_events_type_severity_idx
  on public.disaster_events(disaster_type, severity, occurred_at desc);
create index if not exists disaster_events_region_idx
  on public.disaster_events(region_id, occurred_at desc);
create index if not exists disaster_events_epicenter_gix
  on public.disaster_events using gist(epicenter);
create index if not exists disaster_events_area_gix
  on public.disaster_events using gist(affected_area);
create index if not exists disaster_events_headline_trgm
  on public.disaster_events using gin(headline extensions.gin_trgm_ops);

drop trigger if exists disaster_events_set_updated_at on public.disaster_events;
create trigger disaster_events_set_updated_at
before update on public.disaster_events
for each row execute function public.set_updated_at();

create table if not exists public.evacuation_points (
  id uuid primary key default gen_random_uuid(),
  kind text not null check (kind in ('ASSEMBLY', 'SHELTER', 'HEALTH', 'ROUTE', 'WATER', 'OTHER')),
  name text not null,
  description text,
  address text,
  geom geography(GEOMETRY, 4326) not null,
  region_id uuid references public.regions(id),
  capacity integer check (capacity is null or capacity >= 0),
  source text,
  source_url text,
  verified_at timestamptz,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists evacuation_points_region_kind_idx
  on public.evacuation_points(region_id, kind, is_active);
create index if not exists evacuation_points_geom_gix
  on public.evacuation_points using gist(geom);
create index if not exists evacuation_points_name_trgm
  on public.evacuation_points using gin(name extensions.gin_trgm_ops);

drop trigger if exists evacuation_points_set_updated_at on public.evacuation_points;
create trigger evacuation_points_set_updated_at
before update on public.evacuation_points
for each row execute function public.set_updated_at();

create table if not exists public.trusted_contacts (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  contact_user_id uuid not null references auth.users(id) on delete cascade,
  status text not null default 'PENDING' check (status in ('PENDING', 'ACCEPTED', 'REVOKED')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (owner_id <> contact_user_id),
  unique(owner_id, contact_user_id)
);

create index if not exists trusted_contacts_contact_idx
  on public.trusted_contacts(contact_user_id, status);

drop trigger if exists trusted_contacts_set_updated_at on public.trusted_contacts;
create trigger trusted_contacts_set_updated_at
before update on public.trusted_contacts
for each row execute function public.set_updated_at();

-- Exact coordinates are sensitive. Client access is limited to the user's own latest location.
create table if not exists public.user_last_locations (
  user_id uuid primary key references auth.users(id) on delete cascade,
  location geography(POINT, 4326) not null,
  accuracy_m real check (accuracy_m is null or accuracy_m >= 0),
  recorded_at timestamptz not null default now(),
  consented boolean not null default false
);

create index if not exists user_last_locations_gix
  on public.user_last_locations using gist(location);
create index if not exists user_last_locations_recorded_idx
  on public.user_last_locations(recorded_at);

create table if not exists public.sos_events (
  id uuid primary key default gen_random_uuid(),
  victim_id uuid not null references auth.users(id) on delete restrict,
  mode text not null check (mode in ('PUBLIC', 'PRIVATE')),
  escalation text not null default 'NONE' check (escalation in ('NONE', 'TO_PUBLIC', 'TO_POSKO')),
  location geography(POINT, 4326) not null,
  approx_location geography(POINT, 4326) not null,
  accuracy_m real check (accuracy_m is null or accuracy_m >= 0),
  stage smallint not null default 1 check (stage >= 1),
  status text not null default 'ACTIVE'
    check (status in ('ACTIVE', 'CLAIMED', 'RESOLVED', 'CANCELLED', 'EXPIRED')),
  note text check (note is null or char_length(note) <= 1000),
  created_at timestamptz not null default now(),
  stage_changed_at timestamptz not null default now(),
  resolved_at timestamptz
);

create unique index if not exists sos_one_active_per_victim_idx
  on public.sos_events(victim_id)
  where status in ('ACTIVE', 'CLAIMED');
create index if not exists sos_status_created_idx
  on public.sos_events(status, created_at desc);
create index if not exists sos_location_gix
  on public.sos_events using gist(location);
create index if not exists sos_approx_location_gix
  on public.sos_events using gist(approx_location);

create table if not exists public.sos_recipients (
  sos_id uuid not null references public.sos_events(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  stage smallint not null default 1,
  notified_at timestamptz not null default now(),
  delivery_status text not null default 'QUEUED'
    check (delivery_status in ('QUEUED', 'SENT', 'FAILED', 'ACKNOWLEDGED')),
  primary key(sos_id, user_id)
);

create table if not exists public.responder_claims (
  id uuid primary key default gen_random_uuid(),
  sos_id uuid not null references public.sos_events(id) on delete cascade,
  responder_id uuid not null references auth.users(id) on delete restrict,
  status text not null default 'EN_ROUTE'
    check (status in ('EN_ROUTE', 'ARRIVED', 'RELEASED')),
  claimed_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(sos_id, responder_id)
);

create index if not exists responder_claims_responder_idx
  on public.responder_claims(responder_id, status);

drop trigger if exists responder_claims_set_updated_at on public.responder_claims;
create trigger responder_claims_set_updated_at
before update on public.responder_claims
for each row execute function public.set_updated_at();


-- Helper avoids recursive RLS when SOS visibility depends on an active responder claim.
-- Keep the private schema out of exposed Data API schemas in Supabase settings.
create schema if not exists private;
revoke all on schema private from public, anon, authenticated;
grant usage on schema private to authenticated;

create or replace function private.has_active_sos_claim(p_sos_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.responder_claims rc
    where rc.sos_id = p_sos_id
      and rc.responder_id = (select auth.uid())
      and rc.status in ('EN_ROUTE', 'ARRIVED')
  );
$$;

revoke all on function private.has_active_sos_claim(uuid) from public, anon, authenticated;
grant execute on function private.has_active_sos_claim(uuid) to authenticated;

create table if not exists public.audit_logs (
  id bigint generated always as identity primary key,
  occurred_at timestamptz not null default now(),
  actor_id uuid references auth.users(id) on delete set null,
  action text not null,
  target_type text not null,
  target_id uuid,
  metadata jsonb not null default '{}'::jsonb,
  prev_hash text,
  row_hash text
);

create index if not exists audit_logs_recent_idx
  on public.audit_logs(occurred_at desc);
create index if not exists audit_logs_actor_idx
  on public.audit_logs(actor_id, occurred_at desc);
create index if not exists audit_logs_target_idx
  on public.audit_logs(target_type, target_id, occurred_at desc);

-- Audit writes should be performed by trusted server-side code.
-- If tamper-evident chained hashes are required, implement canonical serialization and verify-chain jobs.
