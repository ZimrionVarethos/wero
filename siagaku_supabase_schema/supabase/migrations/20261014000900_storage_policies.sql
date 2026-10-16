-- Run only AFTER creating a PRIVATE Supabase Storage bucket named 'community-images'.
-- Configure allowed MIME types and max file size in the Supabase Dashboard.
-- Recommended object name: <auth.uid>/<post_id>/<random-file-name>.<ext>
-- This file changes policies only; use the Storage API/Dashboard to create and manage buckets.

create policy community_images_upload_own_folder
on storage.objects
for insert to authenticated
with check (
  bucket_id = 'community-images'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

create policy community_images_read_if_post_visible
on storage.objects
for select to authenticated
using (
  bucket_id = 'community-images'
  and exists (
    select 1
    from public.community_post_images pi
    join public.community_posts p on p.id = pi.post_id
    where pi.storage_path = name
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

create policy community_images_delete_own_folder
on storage.objects
for delete to authenticated
using (
  bucket_id = 'community-images'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);
