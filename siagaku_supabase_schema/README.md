# Supabase schema starter — Siagaku / Wero

This package contains an initial Supabase/PostgreSQL migration set for the Siagaku/Wero disaster-readiness app. It is a **starting schema**, not a claim that the database has been deployed or tested against a live Supabase project.

## Recommended architecture

- Flutter mobile uses `supabase_flutter` with the project's publishable key and the signed-in user's session.
- Next.js hosts the landing page and web admin dashboard. Do **not** combine Next.js and Vite in one app; choose Next.js for this project.
- Supabase provides PostgreSQL, Auth, RLS, Storage, Realtime, and Edge Functions.
- Use RLS for every table exposed to the Data API.
- Put privileged cross-user actions (SOS creation/fan-out, exact SOS location access, moderation decisions, BMKG ingestion, FCM sends, and trusted-contact acceptance) behind authenticated Edge Functions or narrowly scoped database functions. Community moderation decisions use `review_community_post`, which checks moderator roles and records the decision transactionally.
- Never ship Supabase secret/service-role keys in Flutter, browser JavaScript, or source control.

## Migrations

This package uses Supabase CLI-compatible timestamped migrations in `supabase/migrations/`. Copy the `supabase/` directory to the repository root, review each migration, then run it against a disposable development project first using the Supabase CLI. Follow the official Supabase CLI setup and migration workflow for your environment. Do not apply an unreviewed starter schema directly to production.

Apply order:
1. `20261014000100_extensions.sql`
2. `20261014000200_identity_regions.sql`
3. `20261014000300_community_tables.sql`
4. `20261014000400_community_functions.sql`
5. `20261014000500_disaster_operations.sql`
6. `20261014000600_rls_community_policies.sql`
7. `20261014000700_rls_operations_policies.sql`
8. `20261014000800_search_indexes.sql`
9. `20261014000900_storage_policies.sql`

Review RLS/grants carefully and run role-based tests before production.

## Extensions

The first migration attempts to enable PostGIS and `pg_trgm` in the `extensions` schema. If extension creation through SQL is not allowed in the project, enable them in the Supabase Dashboard first. PostGIS supports spatial boundaries and point searches; `pg_trgm` supports fuzzy text matching.

## Storage setup

Create a **private** bucket named `community-images` in Supabase Storage. Configure upload limits and allowed MIME types to match the app policy (for example JPEG, PNG, WebP). Create the bucket before applying the final storage policy migration. The policies restrict users to uploads under their own user-ID folder and allow reads when an image belongs to a post the viewer is allowed to access.

Recommended object path: `<auth-user-id>/<post-id>/<random-file-name>.<ext>`. Avoid overwriting object names; use unique paths.

## Important assumptions

- A `LOCAL` post is visible in the Local feed only when its region matches the viewer's profile region.
- A `NATIONAL` post is visible in the National feed. Whether the National feed should also include all LOCAL posts remains a product decision; this schema keeps `scope` explicit.
- Five distinct pending reports hide a published post pending moderation. The threshold is stored in `community_settings`.
- Each post supports up to four images.
- Feed reads require authentication in this starter schema. If anonymous public reading is desired, design a deliberate RLS policy.
- Categories and hazard tags are seed examples and can be revised.
- Seed/import the Indonesian administrative regions and boundaries before relying on local feed or region-based admin access.

## Important implementation boundary

Flutter can perform user-scoped CRUD directly through Supabase when RLS and SQL grants permit it. It must not decide report thresholds, grant admin roles, expose precise SOS locations, broadcast emergency notifications, ingest official alerts, or approve moderation. Those actions require server-side authorization and transactional logic.

## Search

- Posts use PostgreSQL full-text search (`tsvector` + GIN) and a trigram index on titles.
- Evacuation points use text indexes and PostGIS spatial indexes.
- Alerts use indexes on type, severity, region, date, and headline search.
- SOS/admin lists use status/time indexes and permission-aware server queries.
- Use server-side pagination. Offline search can only search cached content.

## Not yet production-ready

The schema still needs execution and testing in a real Supabase development project; import/seed scripts for regional boundaries; complete tests of all RLS policies; a signed-in admin bootstrap procedure; FCM/BMKG/AI Edge Functions; RAG vector table once model dimensions are chosen; retention and backup policy; and operational monitoring.
