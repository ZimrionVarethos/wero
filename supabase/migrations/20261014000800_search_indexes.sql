-- Additional indexes for filters and searches.
-- Some indexes are already created next to their tables; this file is safe to extend.

create index if not exists community_posts_published_at_idx
  on public.community_posts(published_at desc, id desc)
  where status = 'PUBLISHED';

create index if not exists community_posts_region_published_idx
  on public.community_posts(region_id, published_at desc, id desc)
  where scope = 'LOCAL' and status = 'PUBLISHED';

create index if not exists community_posts_national_published_idx
  on public.community_posts(published_at desc, id desc)
  where scope = 'NATIONAL' and status = 'PUBLISHED';

create index if not exists community_reports_reason_created_idx
  on public.community_reports(reason_code, created_at desc);

create index if not exists community_reports_reviewer_idx
  on public.community_reports(reviewer_id, reviewed_at desc);

create index if not exists evacuation_points_name_lower_idx
  on public.evacuation_points(lower(name));

create index if not exists disaster_events_headline_search_gin
  on public.disaster_events using gin(to_tsvector('simple', coalesce(headline, '')));

-- General audit search is constrained by role. Do not build broad indexes over sensitive metadata
-- until actual query patterns and retention requirements are understood.
