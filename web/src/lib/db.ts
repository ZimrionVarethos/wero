import { Pool } from 'pg';

const defaultDbUrl =
  'postgresql://postgres.rxoqjkgfldnicjaxsygt:0004025438Zimrion@aws-0-ap-southeast-2.pooler.supabase.com:5432/postgres';

const connectionString = process.env.DATABASE_URL || defaultDbUrl;

declare global {
  // eslint-disable-next-line no-var
  var __dbPool: Pool | undefined;
}

export const pool =
  global.__dbPool ||
  new Pool({
    connectionString,
    max: 10,
    idleTimeoutMillis: 30000,
    connectionTimeoutMillis: 5000,
    ssl: { rejectUnauthorized: false },
  });

if (process.env.NODE_ENV !== 'production') {
  global.__dbPool = pool;
}

