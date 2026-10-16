-- 20261014001300_community_posts_profiles_fkey_and_anon_grants.sql
-- 1. Add foreign key from community_posts.author_id to profiles(id)
-- 2. Grant SELECT to anon on public community tables and add public read policies

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'community_posts_profiles_fkey'
  ) THEN
    ALTER TABLE public.community_posts
      ADD CONSTRAINT community_posts_profiles_fkey
      FOREIGN KEY (author_id) REFERENCES public.profiles(id)
      ON DELETE CASCADE;
  END IF;
END $$;

GRANT SELECT ON public.community_posts TO anon;
GRANT SELECT ON public.community_post_images TO anon;
GRANT SELECT ON public.community_post_hazards TO anon;
GRANT SELECT ON public.hazard_tags TO anon;
GRANT SELECT ON public.profiles TO anon;
GRANT SELECT ON public.regions TO anon;
GRANT SELECT ON public.community_categories TO anon;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policy WHERE polname = 'community_posts_read_anon'
  ) THEN
    CREATE POLICY community_posts_read_anon ON public.community_posts
      FOR SELECT TO anon
      USING (status = 'PUBLISHED');
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policy WHERE polname = 'community_post_images_read_anon'
  ) THEN
    CREATE POLICY community_post_images_read_anon ON public.community_post_images
      FOR SELECT TO anon
      USING (EXISTS (
        SELECT 1 FROM public.community_posts p 
        WHERE p.id = community_post_images.post_id AND p.status = 'PUBLISHED'
      ));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policy WHERE polname = 'community_post_hazards_read_anon'
  ) THEN
    CREATE POLICY community_post_hazards_read_anon ON public.community_post_hazards
      FOR SELECT TO anon
      USING (EXISTS (
        SELECT 1 FROM public.community_posts p 
        WHERE p.id = community_post_hazards.post_id AND p.status = 'PUBLISHED'
      ));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policy WHERE polname = 'hazard_tags_read_anon'
  ) THEN
    CREATE POLICY hazard_tags_read_anon ON public.hazard_tags
      FOR SELECT TO anon
      USING (is_active = true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policy WHERE polname = 'profiles_read_anon'
  ) THEN
    CREATE POLICY profiles_read_anon ON public.profiles
      FOR SELECT TO anon
      USING (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policy WHERE polname = 'regions_read_anon'
  ) THEN
    CREATE POLICY regions_read_anon ON public.regions
      FOR SELECT TO anon
      USING (is_active = true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policy WHERE polname = 'categories_read_anon'
  ) THEN
    CREATE POLICY categories_read_anon ON public.community_categories
      FOR SELECT TO anon
      USING (is_active = true);
  END IF;
END $$;
