export type Severity = 'AWAS' | 'SIAGA' | 'WASPADA' | 'AMAN' | 'INFO';
export type SosStatus = 'ACTIVE' | 'CLAIMED' | 'RESOLVED' | 'CANCELLED' | 'EXPIRED';
export type AdminRole = 'SUPER_ADMIN' | 'GOVERNMENT_ADMIN' | 'COMMUNITY_MODERATOR';

export interface AdminMe {
  userId: string;
  email: string | null;
  displayName: string;
  roles: AdminRole[];
  isSuper: boolean;
  regionId: string | null;
  regionName: string | null;
}

export interface SosRow {
  id: string;
  mode: 'PUBLIC' | 'PRIVATE';
  escalation: string;
  stage: number;
  status: SosStatus;
  created_at: string;
  stage_changed_at: string;
  resolved_at: string | null;
  approx_lat: number;
  approx_lng: number;
  victim_first_name: string;
  responders: number;
  inside_region: boolean;
}

export interface SosResponder {
  name: string;
  status: 'EN_ROUTE' | 'ARRIVED';
  claimed_at: string;
}

export interface SosDetail {
  id: string;
  mode: 'PUBLIC' | 'PRIVATE';
  escalation: string;
  stage: number;
  status: SosStatus;
  note: string | null;
  accuracy_m: number | null;
  created_at: string;
  stage_changed_at: string;
  resolved_at: string | null;
  lat: number;
  lng: number;
  victim_name: string;
  inside_region: boolean;
  responders: SosResponder[];
}

export type EvacKind = 'ASSEMBLY' | 'SHELTER' | 'HEALTH' | 'WATER' | 'OTHER' | 'ROUTE';

export interface EvacPoint {
  id: string;
  kind: EvacKind;
  name: string;
  description: string | null;
  address: string | null;
  capacity: number | null;
  is_active: boolean;
  latitude: number;
  longitude: number;
  source: string | null;
  region_id: string | null;
  region_name: string | null;
  updated_at: string;
}

export interface Region {
  id: string;
  name: string;
  level: string;
}

export interface BroadcastRow {
  id: string;
  disaster_type: string;
  severity: Severity;
  headline: string;
  message: string | null;
  target_type: 'ALL' | 'SPECIFIC' | null;
  target_regions: string[] | null;
  fcm: { delivered: boolean } | null;
  sent_by: string | null;
  created_at: string;
}

export interface AuditRow {
  id: string;
  occurred_at: string;
  action: string;
  target_type: string;
  target_id: string | null;
  metadata: Record<string, unknown>;
  actor_id: string | null;
  actor_name: string;
  signed: boolean;
}

export interface ModerationReport {
  report_id: string;
  post_id: string;
  reason_code: string;
  details: string | null;
  report_status: 'PENDING' | 'REVIEWED_ACTION' | 'DISMISSED';
  report_created_at: string;
  resolution: string | null;
  post_title: string | null;
  post_body: string | null;
  post_status: string | null;
  post_report_count: number;
  author_name: string | null;
}

export interface ModerationHistory {
  id: string;
  post_id: string;
  action: string;
  reason: string;
  created_at: string;
  post_title: string | null;
  moderator_name: string | null;
}

export interface DashboardStats {
  sos: { waiting: number; claimed: number; resolved_24h: number; oldest_waiting_at: string | null };
  evacuation: { active: number; inactive: number; capacity: number };
  pendingReports: number;
  broadcasts7d: number;
}
