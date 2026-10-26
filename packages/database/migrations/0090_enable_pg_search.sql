-- Custom SQL migration file, put your code below! --
-- pg_search is optional: plain PostgreSQL services (Aiven, RDS, Neon projects without the
-- extension) run LobeHub with FTS_SEARCH_PROVIDER=pg_like or elasticsearch, so a missing
-- extension must not block the remaining migrations. The pg_search provider still fails
-- visibly at query time when its extension or BM25 indexes are absent.
-- Editing this shipped migration is safe: Drizzle only compares `created_at`, so databases
-- that already applied it never re-run it.
-- Neon caveat: pg_search still appears in pg_available_extensions, but CREATE EXTENSION
-- is rejected there (error 42501, "extension pg_search is deprecated and no longer
-- allowed"). Checking availability alone is therefore not enough: a failed CREATE must
-- also be caught and skipped, otherwise the whole db:migrate aborts on Neon.
-- On Neon, also set FTS_SEARCH_PROVIDER=pg_like in the deployment environment:
-- after migrations, scripts/migrateServerDB checks pg_search readiness and aborts
-- if the provider is still the default pg_search and the extension is absent.
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_available_extensions WHERE name = 'pg_search') THEN
    BEGIN
      CREATE EXTENSION IF NOT EXISTS pg_search;
    EXCEPTION
      WHEN insufficient_privilege THEN
        RAISE NOTICE 'pg_search is listed as available but cannot be created on this database (e.g. Neon deprecated it); skipping BM25 search setup, use FTS_SEARCH_PROVIDER=pg_like';
      WHEN OTHERS THEN
        RAISE NOTICE 'pg_search could not be created (%); skipping BM25 search setup, use FTS_SEARCH_PROVIDER=pg_like', SQLERRM;
    END;
  ELSE
    RAISE NOTICE 'pg_search is not available on this database; skipping BM25 search setup';
  END IF;
END $$;
