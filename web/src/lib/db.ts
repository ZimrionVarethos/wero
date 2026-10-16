import { Pool } from 'pg';

declare global {
  // eslint-disable-next-line no-var
  var __dbPool: Pool | undefined;
}

let localPool: Pool | undefined;

function getPool(): Pool {
  const existing = global.__dbPool ?? localPool;
  if (existing) return existing;

  const connectionString = process.env.DATABASE_URL;
  if (!connectionString) {
    throw new Error(
      'DATABASE_URL is not set. Add it to web/.env.local for local development ' +
        '(see web/.env.example) or to the hosting environment variables.',
    );
  }

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
