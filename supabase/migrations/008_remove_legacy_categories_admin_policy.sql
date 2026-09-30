-- Remove the legacy FOR ALL categories policy so category DELETE is not enabled by RLS.
-- Keep the scoped SELECT, INSERT, and UPDATE policies introduced by migration 007.

drop policy if exists categories_admin on public.categories;
