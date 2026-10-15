import { Pool } from 'pg';

const connectionString = process.env.DATABASE_URL || '';

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
  });

if (process.env.NODE_ENV !== 'production') {
  global.__dbPool = pool;
}
