-- Fix table-level grants for authenticated role on public tables.
-- RLS policies on each table continue to enforce row-level access control,
-- author ownership, published statuses, and valid region levels.

grant select, insert, update on public.profiles to authenticated;
grant select, insert, update on public.community_posts to authenticated;
grant select, insert, update, delete on public.community_post_images to authenticated;
grant select, insert, update, delete on public.community_post_hazards to authenticated;
grant select, insert on public.community_reports to authenticated;
grant select, insert, update on public.user_preferences to authenticated;
grant select, insert, update, delete on public.user_devices to authenticated;

-- Reload schema cache in PostgREST
notify pgrst, 'reload schema';
