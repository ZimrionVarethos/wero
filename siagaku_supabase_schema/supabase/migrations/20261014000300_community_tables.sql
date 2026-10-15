-- Community posts, media metadata, reports, and moderation audit.
do $$ begin
  create type public.post_scope as enum ('LOCAL', 'NATIONAL');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.post_status as enum
    ('PUBLISHED', 'HIDDEN_PENDING_REVIEW', 'REMOVED', 'DELETED');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.report_status as enum ('PENDING', 'REVIEWED_ACTION', 'DISMISSED');
exception when duplicate_object then null; end $$;

create table if not exists public.community_categories (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  name text not null unique,
  description text,
  is_active boolean not null default true,
  sort_order integer not null default 0
);

insert into public.community_categories(slug, name, sort_order)
values
  ('education-mitigation', 'Edukasi dan mitigasi', 10),
  ('preparedness-tips', 'Tips kesiapsiagaan', 20),
  ('disaster-experience', 'Pengalaman bencana', 30),
  ('area-condition', 'Informasi kondisi wilayah', 40),
  ('evacuation-facilities', 'Informasi fasilitas dan evakuasi', 50)
on conflict (slug) do nothing;

create table if not exists public.hazard_tags (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  name text not null unique,
  is_active boolean not null default true
);

insert into public.hazard_tags(slug, name)
values
  ('earthquake', 'Gempa bumi'),
  ('tsunami', 'Tsunami'),
  ('flood', 'Banjir'),
  ('extreme-weather', 'Cuaca ekstrem'),
  ('landslide', 'Longsor'),
  ('volcano', 'Erupsi gunung api'),
  ('fire', 'Kebakaran'),
  ('other', 'Lainnya')
on conflict (slug) do nothing;

create table if not exists public.community_settings (
  id smallint primary key default 1 check (id = 1),
  hide_threshold integer not null default 5 check (hide_threshold between 2 and 100),
  max_images_per_post smallint not null default 4 check (max_images_per_post between 0 and 4),
  max_body_chars integer not null default 5000 check (max_body_chars between 100 and 20000),
  updated_at timestamptz not null default now()
);

insert into public.community_settings(id) values (1)
on conflict (id) do nothing;

create table if not exists public.community_posts (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references auth.users(id) on delete restrict,
  title text check (title is null or char_length(title) <= 120),
  body text not null check (char_length(btrim(body)) between 1 and 5000),
  category_id uuid not null references public.community_categories(id),
  scope public.post_scope not null,
  -- For LOCAL this is the visibility region; for NATIONAL it records the author's region at publish time when known.
  region_id uuid references public.regions(id),
  status public.post_status not null default 'PUBLISHED',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  published_at timestamptz not null default now(),
  constraint local_post_requires_region check (scope <> 'LOCAL' or region_id is not null),
  search_document tsvector generated always as (
    setweight(to_tsvector('simple', coalesce(title, '')), 'A') ||
    setweight(to_tsvector('simple', coalesce(body, '')), 'B')
  ) stored
);

create index if not exists community_posts_feed_idx
  on public.community_posts(scope, region_id, status, published_at desc, id desc);
create index if not exists community_posts_author_idx
  on public.community_posts(author_id, created_at desc);
create index if not exists community_posts_category_idx
  on public.community_posts(category_id, status, published_at desc);
create index if not exists community_posts_search_gin
  on public.community_posts using gin(search_document);
create index if not exists community_posts_title_trgm
  on public.community_posts using gin(title extensions.gin_trgm_ops);

create table if not exists public.community_post_images (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.community_posts(id) on delete cascade,
  storage_path text not null unique,
  alt_text text check (alt_text is null or char_length(alt_text) <= 250),
  sort_order smallint not null check (sort_order between 0 and 3),
  created_at timestamptz not null default now(),
  unique(post_id, sort_order)
);

create table if not exists public.community_post_hazards (
  post_id uuid not null references public.community_posts(id) on delete cascade,
  hazard_id uuid not null references public.hazard_tags(id),
  primary key(post_id, hazard_id)
);

create index if not exists community_post_hazards_hazard_idx
  on public.community_post_hazards(hazard_id, post_id);

create table if not exists public.community_reports (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.community_posts(id) on delete cascade,
  reporter_id uuid not null references auth.users(id) on delete restrict,
  reason_code text not null check (reason_code in
    ('MISLEADING_DANGEROUS', 'SPAM', 'HARASSMENT', 'PRIVACY', 'IRRELEVANT', 'OTHER')),
  details text check (details is null or char_length(details) <= 1000),
  status public.report_status not null default 'PENDING',
  created_at timestamptz not null default now(),
  reviewed_at timestamptz,
  reviewer_id uuid references auth.users(id),
  resolution text check (resolution is null or char_length(resolution) <= 1000),
  unique(post_id, reporter_id)
);

create index if not exists community_reports_queue_idx
  on public.community_reports(status, created_at desc);
create index if not exists community_reports_post_idx
  on public.community_reports(post_id, status);

create table if not exists public.community_moderation_actions (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.community_posts(id) on delete restrict,
  moderator_id uuid not null references auth.users(id) on delete restrict,
  action text not null check (action in ('HIDE', 'RESTORE', 'REMOVE', 'MARK_NO_VIOLATION')),
  reason text not null check (char_length(btrim(reason)) between 1 and 1000),
  created_at timestamptz not null default now(),
  metadata jsonb not null default '{}'::jsonb
);

create index if not exists community_moderation_post_idx
  on public.community_moderation_actions(post_id, created_at desc);

create or replace function public.validate_community_post()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  max_chars integer;
begin
  select s.max_body_chars into max_chars
  from public.community_settings s where s.id = 1;

  if char_length(btrim(new.body)) > coalesce(max_chars, 5000) then
    raise exception 'Post body exceeds configured maximum length' using errcode = '22023';
  end if;

  return new;
end;
$$;

drop trigger if exists community_posts_set_updated_at on public.community_posts;
create trigger community_posts_set_updated_at
before update on public.community_posts
for each row execute function public.set_updated_at();

drop trigger if exists community_posts_validate_body on public.community_posts;
create trigger community_posts_validate_body
before insert or update of body on public.community_posts
for each row execute function public.validate_community_post();

revoke all on function public.validate_community_post() from public, anon, authenticated;
