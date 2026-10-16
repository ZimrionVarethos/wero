import 'server-only';
import { createHash } from 'crypto';
import type { PoolClient } from 'pg';
import { pool } from '@/lib/db';

export type AuditTargetType = 'SOS' | 'EVACUATION_POINT' | 'DISASTER_EVENT' | 'COMMUNITY_POST' | 'AUDIT';

export type AuditAction =
  | 'SOS_VIEWED'
  | 'SOS_STATUS_CHANGED'
  | 'EVAC_CREATED'
  | 'EVAC_UPDATED'
  | 'EVAC_DELETED'
  | 'ADMIN_BROADCAST'
  | 'BROADCAST_DELETED'
  | 'MODERATION_ACTION'
  | 'AUDIT_EXPORTED';

export interface AuditEntry {
  actorId: string;
  action: AuditAction;
  targetType: AuditTargetType;
  targetId?: string | null;
  metadata?: Record<string, string | number | boolean | null | string[]>;
}

interface HashedRow {
  occurred_at: string;
  actor_id: string | null;
  action: string;
  target_type: string;
  target_id: string | null;
  metadata: unknown;
}

// Arbitrary constant so every writer serialises on the same advisory lock.
const AUDIT_LOCK_KEY = 72620001;

/** JSON with sorted keys, so the hash survives jsonb reordering keys on storage. */
function canonical(value: unknown): string {
  if (value === null || value === undefined) return 'null';
  if (Array.isArray(value)) return `[${value.map(canonical).join(',')}]`;
  if (typeof value === 'object') {
    const obj = value as Record<string, unknown>;
    return `{${Object.keys(obj)
      .filter((k) => obj[k] !== undefined)
      .sort()
      .map((k) => `${JSON.stringify(k)}:${canonical(obj[k])}`)
      .join(',')}}`;
  }
  return JSON.stringify(value);
}

function rowHash(prevHash: string | null, row: HashedRow): string {
  return createHash('sha256').update(`${prevHash ?? ''}|${canonical(row)}`).digest('hex');
}

/**
 * Appends an audit row linked to the previous signed row by a SHA-256 chain.
 * Pass a client that is already inside a transaction to commit the audit row
 * atomically with the change it describes.
 */
export async function writeAudit(entry: AuditEntry, client?: PoolClient): Promise<void> {
  const own = !client;
  const c = client ?? (await pool.connect());
  try {
    if (own) await c.query('BEGIN');
    await c.query('select pg_advisory_xact_lock($1)', [AUDIT_LOCK_KEY]);
    const prev = await c.query<{ row_hash: string }>(
      'select row_hash from public.audit_logs where row_hash is not null order by id desc limit 1',
    );
    const prevHash = prev.rows[0]?.row_hash ?? null;
    const row: HashedRow = {
      occurred_at: new Date().toISOString(),
      // Postgres returns uuids in lower case, so hash them that way too.
      actor_id: entry.actorId.toLowerCase(),
      action: entry.action,
      target_type: entry.targetType,
      target_id: entry.targetId?.toLowerCase() ?? null,
      metadata: entry.metadata ?? {},
    };
    await c.query(
      `insert into public.audit_logs
         (occurred_at, actor_id, action, target_type, target_id, metadata, prev_hash, row_hash)
       values ($1, $2, $3, $4, $5, $6, $7, $8)`,
      [row.occurred_at, row.actor_id, row.action, row.target_type, row.target_id, JSON.stringify(row.metadata), prevHash, rowHash(prevHash, row)],
    );
    if (own) await c.query('COMMIT');
  } catch (error) {
    if (own) await c.query('ROLLBACK').catch(() => undefined);
    throw error;
  } finally {
    if (own) c.release();
  }
}

export interface ChainResult {
  ok: boolean;
  checked: number;
  unsigned: number;
  brokenAtId: number | null;
}

/**
 * Recomputes every signed row. Rows written by database functions (for example
 * TRIGGER_SOS from the mobile app) carry no hash and are counted as unsigned.
 */
export async function verifyAuditChain(): Promise<ChainResult> {
  const [signed, unsigned] = await Promise.all([
    pool.query<{
      id: string;
      occurred_at: Date;
      actor_id: string | null;
      action: string;
      target_type: string;
      target_id: string | null;
      metadata: unknown;
      prev_hash: string | null;
      row_hash: string;
    }>(
      `select id, occurred_at, actor_id, action, target_type, target_id, metadata, prev_hash, row_hash
       from public.audit_logs where row_hash is not null order by id`,
    ),
    pool.query<{ n: number }>('select count(*)::int as n from public.audit_logs where row_hash is null'),
  ]);

  let prevHash: string | null = null;
  for (let i = 0; i < signed.rows.length; i++) {
    const r = signed.rows[i];
    const expected = rowHash(prevHash, {
      occurred_at: r.occurred_at.toISOString(),
      actor_id: r.actor_id,
      action: r.action,
      target_type: r.target_type,
      target_id: r.target_id,
      metadata: r.metadata,
    });
    if (r.prev_hash !== prevHash || r.row_hash !== expected) {
      return { ok: false, checked: i, unsigned: unsigned.rows[0].n, brokenAtId: Number(r.id) };
    }
    prevHash = r.row_hash;
  }
  return { ok: true, checked: signed.rows.length, unsigned: unsigned.rows[0].n, brokenAtId: null };
}
