-- Supabase extensions required by this schema.
-- Prefer enabling extensions in the Supabase Dashboard if project policy requires it.
create schema if not exists extensions;
create extension if not exists postgis with schema extensions;
create extension if not exists pg_trgm with schema extensions;
