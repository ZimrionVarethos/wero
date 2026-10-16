-- Add generated latitude and longitude columns from PostGIS geom for direct client consumption
alter table public.evacuation_points 
add column if not exists latitude double precision generated always as (st_y(geom::geometry)) stored,
add column if not exists longitude double precision generated always as (st_x(geom::geometry)) stored;

-- Allow public read access to active evacuation points and published disaster events
drop policy if exists evacuation_points_read_active on public.evacuation_points;
create policy evacuation_points_read_active on public.evacuation_points
for select to anon, authenticated using (is_active);

drop policy if exists disaster_events_read_published on public.disaster_events;
create policy disaster_events_read_published on public.disaster_events
for select to anon, authenticated using (is_published);

grant select on public.regions to anon, authenticated;
grant select on public.community_categories to anon, authenticated;
grant select on public.hazard_tags to anon, authenticated;
grant select on public.community_settings to anon, authenticated;
grant select on public.disaster_events to anon, authenticated;
grant select on public.evacuation_points to anon, authenticated;

notify pgrst, 'reload schema';
