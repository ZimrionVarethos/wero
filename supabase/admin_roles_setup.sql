-- Dashboard role setup for the Wero web admin (web/src/app/admin).
-- Run manually in the Supabase SQL editor. This file is intentionally outside
-- migrations/ so it never runs automatically.
--
-- Roles used by the dashboard:
--   SUPER_ADMIN          all regions, can verify the audit hash chain and broadcast nationally
--   GOVERNMENT_ADMIN     one region (profiles.region_id) plus its buffer zone
--   COMMUNITY_MODERATOR  community moderation queue only
--
-- Replace the placeholder emails and region code before running.

-- 1. Super admin
insert into public.user_roles (user_id, role)
select u.id, 'SUPER_ADMIN'
from auth.users u
where u.email = 'GANTI_EMAIL_SUPER_ADMIN'
on conflict do nothing;

-- 2. Government admin for one region. The region comes from the admin's profile.
with target as (
  select u.id as user_id, r.id as region_id
  from auth.users u
  cross join public.regions r
  where u.email = 'GANTI_EMAIL_ADMIN_WILAYAH'
    and r.code = 'GANTI_KODE_WILAYAH'
)
, roles as (
  insert into public.user_roles (user_id, role)
  select user_id, 'GOVERNMENT_ADMIN' from target
  on conflict do nothing
)
insert into public.profiles (id, region_id)
select user_id, region_id from target
on conflict (id) do update set region_id = excluded.region_id, updated_at = now();

-- 3. Community moderator
insert into public.user_roles (user_id, role)
select u.id, 'COMMUNITY_MODERATOR'
from auth.users u
where u.email = 'GANTI_EMAIL_MODERATOR'
on conflict do nothing;

-- 4. Check the result
select u.email, ur.role, r.name as region
from public.user_roles ur
join auth.users u on u.id = ur.user_id
left join public.profiles p on p.id = ur.user_id
left join public.regions r on r.id = p.region_id
where ur.role in ('SUPER_ADMIN', 'GOVERNMENT_ADMIN', 'COMMUNITY_MODERATOR')
order by ur.role, u.email;

-- Regions without a boundary polygon fall back to matching the victim's profile region.
-- For accurate buffer-zone coverage, load regions.boundary (MULTIPOLYGON, SRID 4326).
