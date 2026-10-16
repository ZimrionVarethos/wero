import 'server-only';

/**
 * SOS visibility for an admin, bound to query parameter $1 (region id, or null for SUPER_ADMIN).
 *
 * With a region boundary, cases inside the boundary plus its buffer_m are visible, so nothing
 * falls into the gap between neighbouring regions. Regions without a boundary fall back to the
 * victim's registered region.
 *
 * Usage: `${SOS_SCOPE_CTE} select ... from public.sos_events s ${SOS_SCOPE_JOIN} where ${SOS_SCOPE_WHERE}`
 */
export const SOS_SCOPE_CTE = `
  with scope as (
    select r.boundary, r.buffer_m from public.regions r where r.id = $1::uuid
  )`;

export const SOS_SCOPE_JOIN = `
  left join public.profiles p on p.id = s.victim_id
  left join scope sc on true`;

export const SOS_SCOPE_WHERE = `(
    $1::uuid is null
    or (sc.boundary is not null and st_dwithin(s.location, sc.boundary, sc.buffer_m))
    or (sc.boundary is null and p.region_id = $1::uuid)
  )`;

/** True when the case is inside the region itself rather than only in the buffer zone. */
export const SOS_INSIDE_REGION = `(
    case
      when $1::uuid is null then true
      when sc.boundary is not null then st_intersects(s.location, sc.boundary)
      else p.region_id = $1::uuid
    end
  )`;

/** Evacuation points: own region, plus points not yet assigned to any region. */
export const EVAC_SCOPE_WHERE = `($1::uuid is null or e.region_id = $1::uuid or e.region_id is null)`;
