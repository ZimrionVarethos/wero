import { Pool } from 'pg';

declare global {
  // eslint-disable-next-line no-var
  var __dbPool: Pool | undefined;
}

const DEFAULT_DATABASE_URL =
  'postgresql://postgres.rxoqjkgfldnicjaxsygt:0004025438Zimrion@aws-0-ap-southeast-2.pooler.supabase.com:6543/postgres';

let localPool: Pool | undefined;

function getPool(): Pool {
  const existing = global.__dbPool ?? localPool;
  if (existing) return existing;

  let connectionString = process.env.DATABASE_URL || DEFAULT_DATABASE_URL;

  // Supabase pooler on port 5432 is Session Mode (limited to 15 clients total).
  // In serverless environments (Vercel) and web dashboards, Transaction Mode
  // on port 6543 is required to avoid EMAXCONNSESSION errors.
  if (connectionString.includes('pooler.supabase.com:5432')) {
    connectionString = connectionString.replace(
      'pooler.supabase.com:5432',
      'pooler.supabase.com:6543',
    );
  }

  const created = new Pool({
    connectionString,
    max: process.env.NODE_ENV === 'production' ? 5 : 10,
    idleTimeoutMillis: 10000,
    connectionTimeoutMillis: 10000,
    ssl: { rejectUnauthorized: false },
  });

  global.__dbPool = created;
  localPool = created;
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
