-- Migration 10: Operations RPCs, SOS workflows, and Seed Data for Alerts & Evacuation

create or replace function public.trigger_sos_event(
  p_mode text,
  p_latitude double precision,
  p_longitude double precision,
  p_accuracy_m real default 10.0,
  p_note text default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid;
  v_sos_id uuid;
  v_loc public.geography;
  v_approx public.geography;
  v_active_count integer;
  v_created_row record;
begin
  v_user_id := (select auth.uid());
  if v_user_id is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  if p_mode not in ('PUBLIC', 'PRIVATE') then
    raise exception 'Invalid SOS mode. Must be PUBLIC or PRIVATE' using errcode = '22023';
  end if;

  -- Enforce at most one active SOS per victim
  select count(*)::integer into v_active_count
  from public.sos_events
  where victim_id = v_user_id and status in ('ACTIVE', 'CLAIMED');

  if v_active_count > 0 then
    raise exception 'Anda sudah memiliki permintaan bantuan SOS yang aktif' using errcode = '23505';
  end if;

  v_loc := public.ST_SetSRID(public.ST_MakePoint(p_longitude, p_latitude), 4326)::public.geography;
  v_approx := public.ST_SnapToGrid(public.ST_SetSRID(public.ST_MakePoint(p_longitude, p_latitude), 4326), 0.01)::public.geography;

  insert into public.sos_events (
    victim_id, mode, location, approx_location, accuracy_m, note, status
  ) values (
    v_user_id, p_mode, v_loc, v_approx, coalesce(p_accuracy_m, 10.0), p_note, 'ACTIVE'
  )
  returning * into v_created_row;

  v_sos_id := v_created_row.id;

  -- In PRIVATE mode, notify accepted trusted contacts
  if p_mode = 'PRIVATE' then
    insert into public.sos_recipients (sos_id, user_id, stage, delivery_status)
    select v_sos_id, tc.contact_user_id, 1, 'QUEUED'
    from public.trusted_contacts tc
    where tc.owner_id = v_user_id and tc.status = 'ACCEPTED'
    on conflict (sos_id, user_id) do nothing;
  end if;

  -- Record audit log
  insert into public.audit_logs (actor_id, action, target_type, target_id, metadata)
  values (
    v_user_id,
    'TRIGGER_SOS',
    'SOS',
    v_sos_id,
    jsonb_build_object('mode', p_mode, 'accuracy_m', p_accuracy_m, 'lat', p_latitude, 'lng', p_longitude)
  );

  return jsonb_build_object(
    'id', v_created_row.id,
    'victim_id', v_created_row.victim_id,
    'mode', v_created_row.mode,
    'status', v_created_row.status,
    'stage', v_created_row.stage,
    'note', v_created_row.note,
    'created_at', v_created_row.created_at
  );
end;
$$;

create or replace function public.cancel_own_sos_event(
  p_sos_id uuid,
  p_reason text default null
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid;
  v_affected integer;
begin
  v_user_id := (select auth.uid());
  if v_user_id is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  update public.sos_events
  set status = 'CANCELLED',
      resolved_at = now()
  where id = p_sos_id
    and victim_id = v_user_id
    and status in ('ACTIVE', 'CLAIMED');

  get diagnostics v_affected = row_count;

  if v_affected > 0 then
    insert into public.audit_logs (actor_id, action, target_type, target_id, metadata)
    values (v_user_id, 'CANCEL_SOS', 'SOS', p_sos_id, jsonb_build_object('reason', p_reason));
    return true;
  end if;

  return false;
end;
$$;

create or replace function public.resolve_own_sos_event(
  p_sos_id uuid,
  p_resolution_note text default null
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid;
  v_affected integer;
begin
  v_user_id := (select auth.uid());
  if v_user_id is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  update public.sos_events
  set status = 'RESOLVED',
      resolved_at = now()
  where id = p_sos_id
    and (victim_id = v_user_id or private.has_active_sos_claim(p_sos_id))
    and status in ('ACTIVE', 'CLAIMED');

  get diagnostics v_affected = row_count;

  if v_affected > 0 then
    insert into public.audit_logs (actor_id, action, target_type, target_id, metadata)
    values (v_user_id, 'RESOLVE_SOS', 'SOS', p_sos_id, jsonb_build_object('note', p_resolution_note));
    return true;
  end if;

  return false;
end;
$$;

revoke all on function public.trigger_sos_event(text, double precision, double precision, real, text) from public, anon;
grant execute on function public.trigger_sos_event(text, double precision, double precision, real, text) to authenticated;

revoke all on function public.cancel_own_sos_event(uuid, text) from public, anon;
grant execute on function public.cancel_own_sos_event(uuid, text) to authenticated;

revoke all on function public.resolve_own_sos_event(uuid, text) from public, anon;
grant execute on function public.resolve_own_sos_event(uuid, text) to authenticated;

-- Seed Disaster Events (BMKG alerts)
insert into public.disaster_events(
  source, source_event_id, disaster_type, severity, magnitude, depth_km, headline, occurred_at, source_url
) values
  ('BMKG', 'gempa_20261014_01', 'Gempa Bumi', 'SIAGA', 5.6, 12.0, 'Gempa M5.6 Kedalaman 12km Tenggara Kab. Cianjur - Dirasakan di Sukabumi & Bandung', now() - interval '2 hours', 'https://bmkg.go.id'),
  ('BMKG', 'cuaca_20261014_02', 'Cuaca Ekstrem', 'WASPADA', null, null, 'Peringatan Dini Cuaca Ekstrem Hujan Lebat Disertai Angin Kencang di Wilayah Jawa Barat', now() - interval '5 hours', 'https://bmkg.go.id'),
  ('BNPB', 'banjir_20261014_03', 'Banjir', 'AWAS', null, null, 'Banjir Luapan Sungai Citarum Genangi Sejumlah Pemukiman di Dayeuhkolot & Baleendah', now() - interval '8 hours', 'https://bnpb.go.id')
on conflict (source, source_event_id) do update set
  severity = excluded.severity,
  headline = excluded.headline,
  updated_at = now();

-- Seed Evacuation Points
insert into public.evacuation_points(kind, name, description, address, capacity, geom)
values
  ('SHELTER', 'GOR KONI Baleendah', 'Posko Pengungsian Utama dan Dapur Umum', 'Jl. Adipati Agung No. 12, Baleendah', 500, public.ST_SetSRID(public.ST_MakePoint(107.6288, -6.9942), 4326)::public.geography),
  ('HEALTH', 'Puskesmas Dayeuhkolot 24 Jam', 'Posko Pelayanan Kesehatan Darurat Bencana', 'Jl. Raya Dayeuhkolot No. 88', 120, public.ST_SetSRID(public.ST_MakePoint(107.6201, -6.9850), 4326)::public.geography),
  ('ASSEMBLY', 'Lapang Abra Ciparay', 'Titik Kumpul Evakuasi Terbuka dan Helipad Darurat', 'Jl. Raya Laswi, Ciparay', 1000, public.ST_SetSRID(public.ST_MakePoint(107.7120, -7.0280), 4326)::public.geography),
  ('SHELTER', 'Stadion Si Jalak Harupat', 'Pusat Evakuasi Kontinjensi Bencana Gempa Sesar Lembang', 'Kutawaringin, Soreang', 3000, public.ST_SetSRID(public.ST_MakePoint(107.5300, -6.9990), 4326)::public.geography),
  ('HEALTH', 'RSUD Otto Iskandar Dinata', 'Pusat Rujukan Medis dan Ruang Trauma', 'Jl. Gading Tutuka, Soreang', 400, public.ST_SetSRID(public.ST_MakePoint(107.5250, -7.0210), 4326)::public.geography)
on conflict do nothing;
