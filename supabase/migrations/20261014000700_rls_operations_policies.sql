-- Users can read SOS cases they created, claimed responders can see their claim relation,
-- and government admins can see cases inside their assigned region + configured buffer.
create policy sos_events_read_authorized on public.sos_events
for select to authenticated
using (
  victim_id = (select auth.uid())
  or (select public.has_role('SUPER_ADMIN'))
  or exists (
    select 1
    from public.profiles p
    join public.regions r on r.id = p.region_id
    where p.id = (select auth.uid())
      and (select public.has_role('GOVERNMENT_ADMIN'))
      and ST_DWithin(sos_events.location, r.boundary, r.buffer_m::double precision)
  )
  or (select private.has_active_sos_claim(sos_events.id))
);

create policy sos_recipients_read_participants on public.sos_recipients
for select to authenticated
using (
  user_id = (select auth.uid())
  or exists (select 1 from public.sos_events s where s.id = sos_id and s.victim_id = (select auth.uid()))
  or (select public.has_role('SUPER_ADMIN'))
);

create policy responder_claims_read_participants on public.responder_claims
for select to authenticated
using (
  responder_id = (select auth.uid())
  or exists (select 1 from public.sos_events s where s.id = sos_id and s.victim_id = (select auth.uid()))
  or (select public.has_role('SUPER_ADMIN'))
);

create policy audit_logs_read_admin on public.audit_logs
for select to authenticated
using (
  (select public.has_role('SUPER_ADMIN'))
  or exists (
    select 1 from public.profiles p
    join public.regions r on r.id = p.region_id
    join public.sos_events s on s.id = audit_logs.target_id
    where p.id = (select auth.uid())
      and (select public.has_role('GOVERNMENT_ADMIN'))
      and audit_logs.target_type = 'SOS'
      and ST_DWithin(s.location, r.boundary, r.buffer_m::double precision)
  )
);

-- Remove broad default grants before granting only the capabilities intended below.
-- RLS alone is not sufficient if a role still has table/column privileges.
revoke all on all tables in schema public from anon, authenticated;
revoke all on all sequences in schema public from anon, authenticated;
revoke execute on all functions in schema public from public, anon, authenticated;

-- Also keep future objects private by default for the migration owner.
alter default privileges in schema public revoke all on tables from anon, authenticated;
alter default privileges in schema public revoke all on sequences from anon, authenticated;
alter default privileges in schema public revoke execute on functions from public, anon, authenticated;

grant usage on schema public to authenticated;
grant execute on function public.has_role(public.app_role) to authenticated;
grant execute on function public.soft_delete_own_community_post(uuid) to authenticated;
grant execute on function public.review_community_post(uuid, text, text) to authenticated;

-- Explicit grants. RLS and SQL privileges are both required.
grant select on public.regions, public.community_categories, public.hazard_tags,
  public.community_settings, public.community_posts, public.community_post_images,
  public.community_post_hazards, public.disaster_events, public.evacuation_points,
  public.trusted_contacts, public.user_last_locations, public.sos_events,
  public.sos_recipients, public.responder_claims, public.audit_logs to authenticated;

grant select on public.profiles, public.user_roles, public.user_preferences, public.user_devices
  to authenticated;
grant insert (user_id, platform, push_token, last_seen_at, disabled_at)
  on public.user_devices to authenticated;
grant update (platform, push_token, last_seen_at, disabled_at)
  on public.user_devices to authenticated;
grant delete on public.user_devices to authenticated;
grant update (display_name, avatar_path, region_id)
  on public.profiles to authenticated;
grant update (helping_enabled) on public.user_preferences to authenticated;

grant insert (author_id, title, body, category_id, scope, region_id)
  on public.community_posts to authenticated;
grant update (title, body, category_id) on public.community_posts to authenticated;

grant insert (post_id, storage_path, alt_text, sort_order)
  on public.community_post_images to authenticated;
grant select on public.community_post_images to authenticated;
grant insert, select, delete on public.community_post_hazards to authenticated;

grant select on public.community_reports to authenticated;
grant insert (post_id, reporter_id, reason_code, details)
  on public.community_reports to authenticated;
grant select on public.community_moderation_actions to authenticated;

grant insert, update, delete on public.regions to authenticated;
grant insert, update, delete on public.community_settings to authenticated;
grant insert, update, delete on public.evacuation_points to authenticated;

grant insert, update, delete on public.trusted_contacts to authenticated;
grant insert, update on public.user_last_locations to authenticated;

-- Only the owner can see and change private responder preferences.


-- Intentionally no direct authenticated INSERT/UPDATE/DELETE grant on disaster_events,
-- sos_events, sos_recipients, responder_claims, or audit_logs.
-- Implement those mutations in an authenticated Edge Function / trusted server workflow.
