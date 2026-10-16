-- RLS and least-privilege grants.
-- This migration deliberately keeps privileged SOS writes out of the mobile client.

alter table public.regions enable row level security;
alter table public.profiles enable row level security;
alter table public.user_preferences enable row level security;
alter table public.user_devices enable row level security;
alter table public.user_roles enable row level security;
alter table public.community_categories enable row level security;
alter table public.hazard_tags enable row level security;
alter table public.community_settings enable row level security;
alter table public.community_posts enable row level security;
alter table public.community_post_images enable row level security;
alter table public.community_post_hazards enable row level security;
alter table public.community_reports enable row level security;
alter table public.community_moderation_actions enable row level security;
alter table public.disaster_events enable row level security;
alter table public.evacuation_points enable row level security;
alter table public.trusted_contacts enable row level security;
alter table public.user_last_locations enable row level security;
alter table public.sos_events enable row level security;
alter table public.sos_recipients enable row level security;
alter table public.responder_claims enable row level security;
alter table public.audit_logs enable row level security;

-- Regions are readable by authenticated users; changing them is restricted to super admins.
create policy regions_read_active on public.regions
for select to authenticated using (is_active = true or (select public.has_role('SUPER_ADMIN')));
create policy regions_super_admin_write on public.regions
for all to authenticated
using ((select public.has_role('SUPER_ADMIN')))
with check ((select public.has_role('SUPER_ADMIN')));

-- A minimum profile is visible to signed-in community users; no phone/email is stored here.
create policy profiles_read_authenticated on public.profiles
for select to authenticated using (true);
create policy profiles_update_self on public.profiles
for update to authenticated using (id = (select auth.uid()))
with check (
  id = (select auth.uid())
  and (
    region_id is null
    or exists (
      select 1 from public.regions r
      where r.id = region_id and r.is_active = true
        and r.level in ('REGENCY'::public.region_level, 'CITY'::public.region_level)
    )
  )
);

create policy user_preferences_read_own on public.user_preferences
for select to authenticated using (user_id = (select auth.uid()));
create policy user_preferences_insert_own on public.user_preferences
for insert to authenticated with check (user_id = (select auth.uid()));
create policy user_preferences_update_own on public.user_preferences
for update to authenticated using (user_id = (select auth.uid()))
with check (user_id = (select auth.uid()));

create policy user_devices_read_own on public.user_devices
for select to authenticated using (user_id = (select auth.uid()));
create policy user_devices_insert_own on public.user_devices
for insert to authenticated with check (user_id = (select auth.uid()));
create policy user_devices_update_own on public.user_devices
for update to authenticated using (user_id = (select auth.uid()))
with check (user_id = (select auth.uid()));
create policy user_devices_delete_own on public.user_devices
for delete to authenticated using (user_id = (select auth.uid()));

create policy user_roles_read_self_or_superadmin on public.user_roles
for select to authenticated
using (user_id = (select auth.uid()) or (select public.has_role('SUPER_ADMIN')));

create policy categories_read_active on public.community_categories
for select to authenticated using (is_active or (select public.has_role('COMMUNITY_MODERATOR')) or (select public.has_role('SUPER_ADMIN')));
create policy hazard_tags_read_active on public.hazard_tags
for select to authenticated using (is_active or (select public.has_role('COMMUNITY_MODERATOR')) or (select public.has_role('SUPER_ADMIN')));
create policy community_settings_read_authenticated on public.community_settings
for select to authenticated using (true);
create policy community_settings_super_admin_write on public.community_settings
for all to authenticated
using ((select public.has_role('SUPER_ADMIN')))
with check ((select public.has_role('SUPER_ADMIN')));

-- A national post is visible to authenticated users. A local post is visible to profiles
-- whose region matches the post's region. Authors and moderators can inspect their own/reviewed items.
create policy community_posts_read_visible on public.community_posts
for select to authenticated
using (
  author_id = (select auth.uid())
  or (select public.has_role('COMMUNITY_MODERATOR'))
  or (select public.has_role('SUPER_ADMIN'))
  or (
    status = 'PUBLISHED'
    and (
      scope = 'NATIONAL'
      or (
        scope = 'LOCAL'
        and region_id = (
          select p.region_id from public.profiles p where p.id = (select auth.uid())
        )
      )
    )
  )
);

create policy community_posts_insert_own_published on public.community_posts
for insert to authenticated
with check (
  author_id = (select auth.uid())
  and status = 'PUBLISHED'
  and (
    (
      scope = 'NATIONAL'
      and region_id is not distinct from (
        select p.region_id from public.profiles p where p.id = (select auth.uid())
      )
    )
    or (
      scope = 'LOCAL'
      and region_id = (
        select p.region_id from public.profiles p where p.id = (select auth.uid())
      )
    )
  )
);

create policy community_posts_update_own_published on public.community_posts
for update to authenticated
using (author_id = (select auth.uid()) and status = 'PUBLISHED')
with check (author_id = (select auth.uid()) and status = 'PUBLISHED');

create policy community_post_images_read_visible on public.community_post_images
for select to authenticated
using (
  exists (
    select 1 from public.community_posts p
    where p.id = post_id
      and (
        p.author_id = (select auth.uid())
        or (select public.has_role('COMMUNITY_MODERATOR'))
        or (select public.has_role('SUPER_ADMIN'))
        or (
          p.status = 'PUBLISHED'
          and (
            p.scope = 'NATIONAL'
            or p.region_id = (
              select pr.region_id from public.profiles pr where pr.id = (select auth.uid())
            )
          )
        )
      )
  )
);

create policy community_post_images_insert_own on public.community_post_images
for insert to authenticated
with check (
  exists (
    select 1 from public.community_posts p
    where p.id = post_id and p.author_id = (select auth.uid()) and p.status = 'PUBLISHED'
  )
  and split_part(storage_path, '/', 1) = (select auth.uid())::text
);

create policy community_post_images_delete_own on public.community_post_images
for delete to authenticated
using (
  exists (
    select 1 from public.community_posts p
    where p.id = post_id and p.author_id = (select auth.uid())
  )
);

create policy community_post_hazards_read_visible on public.community_post_hazards
for select to authenticated
using (
  exists (select 1 from public.community_posts p where p.id = post_id)
);
create policy community_post_hazards_insert_own on public.community_post_hazards
for insert to authenticated
with check (
  exists (
    select 1 from public.community_posts p
    where p.id = post_id and p.author_id = (select auth.uid()) and p.status = 'PUBLISHED'
  )
);
create policy community_post_hazards_delete_own on public.community_post_hazards
for delete to authenticated
using (
  exists (
    select 1 from public.community_posts p
    where p.id = post_id and p.author_id = (select auth.uid())
  )
);

create policy community_reports_read_reporter_or_moderator on public.community_reports
for select to authenticated
using (
  reporter_id = (select auth.uid())
  or (select public.has_role('COMMUNITY_MODERATOR'))
  or (select public.has_role('SUPER_ADMIN'))
);
create policy community_reports_insert_own on public.community_reports
for insert to authenticated
with check (
  reporter_id = (select auth.uid())
  and exists (
    select 1 from public.community_posts p
    where p.id = post_id
      and p.author_id <> (select auth.uid())
      and p.status = 'PUBLISHED'
  )
);
create policy moderation_actions_read_moderator on public.community_moderation_actions
for select to authenticated
using ((select public.has_role('COMMUNITY_MODERATOR')) or (select public.has_role('SUPER_ADMIN')));
create policy disaster_events_read_published on public.disaster_events
for select to authenticated using (is_published or (select public.has_role('GOVERNMENT_ADMIN')) or (select public.has_role('SUPER_ADMIN')));

create policy evacuation_points_read_active on public.evacuation_points
for select to authenticated using (is_active or (select public.has_role('GOVERNMENT_ADMIN')) or (select public.has_role('SUPER_ADMIN')));
create policy evacuation_points_admin_write on public.evacuation_points
for all to authenticated
using ((select public.has_role('GOVERNMENT_ADMIN')) or (select public.has_role('SUPER_ADMIN')))
with check ((select public.has_role('GOVERNMENT_ADMIN')) or (select public.has_role('SUPER_ADMIN')));

create policy trusted_contacts_read_participant on public.trusted_contacts
for select to authenticated
using (owner_id = (select auth.uid()) or contact_user_id = (select auth.uid()));
create policy trusted_contacts_insert_owner_pending on public.trusted_contacts
for insert to authenticated
with check (owner_id = (select auth.uid()) and status = 'PENDING');
create policy trusted_contacts_delete_participant on public.trusted_contacts
for delete to authenticated
using (owner_id = (select auth.uid()) or contact_user_id = (select auth.uid()));

create policy user_last_locations_read_own on public.user_last_locations
for select to authenticated using (user_id = (select auth.uid()));
create policy user_last_locations_insert_own on public.user_last_locations
for insert to authenticated with check (user_id = (select auth.uid()));
create policy user_last_locations_update_own on public.user_last_locations
for update to authenticated using (user_id = (select auth.uid()))
with check (user_id = (select auth.uid()));
