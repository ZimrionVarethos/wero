import { Pool } from 'pg';

declare global {
  // eslint-disable-next-line no-var
  var __dbPool: Pool | undefined;
}

const DEFAULT_DATABASE_URL =
  'postgresql://postgres.rxoqjkgfldnicjaxsygt:0004025438Zimrion@aws-0-ap-southeast-2.pooler.supabase.com:5432/postgres';

let localPool: Pool | undefined;

function getPool(): Pool {
  const existing = global.__dbPool ?? localPool;
  if (existing) return existing;

  const connectionString = process.env.DATABASE_URL || DEFAULT_DATABASE_URL;

  const created = new Pool({
    connectionString,
    max: 10,
    idleTimeoutMillis: 30000,
    connectionTimeoutMillis: 5000,
    ssl: { rejectUnauthorized: false },
  });

  if (process.env.NODE_ENV !== 'production') {
    global.__dbPool = created;
  } else {
    localPool = created;
  }
  return created;
}

// Created on first use so a missing DATABASE_URL fails the request, not the build.
export const pool: Pool = new Proxy({} as Pool, {
  get(_target, prop) {
    const target = getPool();
    const value = Reflect.get(target, prop, target);
    return typeof value === 'function' ? value.bind(target) : value;
  },
});
