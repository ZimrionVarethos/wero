-- Five distinct pending reports hide the post pending review. The threshold is configurable.
create or replace function public.hide_post_at_report_threshold()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  pending_count integer;
  threshold_value integer;
begin
  select count(*)::integer into pending_count
  from public.community_reports r
  where r.post_id = new.post_id and r.status = 'PENDING';

  select s.hide_threshold into threshold_value
  from public.community_settings s
  where s.id = 1;

  if pending_count >= coalesce(threshold_value, 5) then
    update public.community_posts
    set status = 'HIDDEN_PENDING_REVIEW'::public.post_status
    where id = new.post_id
      and status = 'PUBLISHED'::public.post_status;
  end if;

  return new;
end;
$$;

drop trigger if exists community_report_threshold on public.community_reports;
create trigger community_report_threshold
after insert on public.community_reports
for each row execute function public.hide_post_at_report_threshold();

-- Keep client delete as a soft-delete RPC/server action rather than granting hard DELETE on posts.
create or replace function public.soft_delete_own_community_post(p_post_id uuid)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  affected integer;
begin
  if (select auth.uid()) is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  update public.community_posts
  set status = 'DELETED'::public.post_status
  where id = p_post_id
    and author_id = (select auth.uid())
    and status in ('PUBLISHED'::public.post_status, 'HIDDEN_PENDING_REVIEW'::public.post_status);

  get diagnostics affected = row_count;
  return affected = 1;
end;
$$;

revoke all on function public.soft_delete_own_community_post(uuid) from public, anon;
grant execute on function public.soft_delete_own_community_post(uuid) to authenticated;
revoke all on function public.hide_post_at_report_threshold() from public, anon, authenticated;

-- Moderation runs as one database transaction: update post, resolve pending reports, append action.
create or replace function public.review_community_post(
  p_post_id uuid,
  p_action text,
  p_reason text
)
returns public.post_status
language plpgsql
security definer
set search_path = ''
as $$
declare
  actor uuid;
  current_status public.post_status;
  next_status public.post_status;
begin
  actor := (select auth.uid());
  if actor is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  if not (
    public.has_role('COMMUNITY_MODERATOR'::public.app_role)
    or public.has_role('SUPER_ADMIN'::public.app_role)
  ) then
    raise exception 'Moderator role required' using errcode = '42501';
  end if;

  if p_action not in ('HIDE', 'RESTORE', 'REMOVE', 'MARK_NO_VIOLATION') then
    raise exception 'Unsupported moderation action' using errcode = '22023';
  end if;

  if p_reason is null or char_length(btrim(p_reason)) not between 1 and 1000 then
    raise exception 'A moderation reason is required' using errcode = '22023';
  end if;

  select p.status into current_status
  from public.community_posts p
  where p.id = p_post_id
  for update;

  if current_status is null then
    raise exception 'Post not found' using errcode = 'P0002';
  end if;

  if current_status = 'DELETED'::public.post_status then
    raise exception 'Deleted posts cannot be moderated' using errcode = '22023';
  end if;

  next_status := case
    when p_action = 'HIDE' then 'HIDDEN_PENDING_REVIEW'::public.post_status
    when p_action = 'REMOVE' then 'REMOVED'::public.post_status
    else 'PUBLISHED'::public.post_status
  end;

  update public.community_posts
  set status = next_status
  where id = p_post_id;

  insert into public.community_moderation_actions(post_id, moderator_id, action, reason)
  values (p_post_id, actor, p_action, btrim(p_reason));

  update public.community_reports
  set status = case
        when p_action in ('RESTORE', 'MARK_NO_VIOLATION')
          then 'DISMISSED'::public.report_status
        else 'REVIEWED_ACTION'::public.report_status
      end,
      reviewed_at = now(),
      reviewer_id = actor,
      resolution = btrim(p_reason)
  where post_id = p_post_id
    and status = 'PENDING'::public.report_status;

  return next_status;
end;
$$;

revoke all on function public.review_community_post(uuid, text, text) from public, anon;
grant execute on function public.review_community_post(uuid, text, text) to authenticated;
