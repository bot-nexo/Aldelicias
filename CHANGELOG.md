# AlDelicias — CHANGELOG

## 2026-09-30 — Architecture baseline

- Established master project context.
- Defined public website + admin platform.
- Defined payment methods.
- Defined supplier credit/accounts payable.
- Defined physical cash control.
- Defined indirect product costs.
- Defined profitability model.
- Defined roles and security principles.
- Defined implementation roadmap.
- Defined Copilot operating protocol.

## 2026-09-30 — Application bootstrap

- Added Next.js App Router, React, TypeScript, Tailwind CSS and base UI primitives.
- Added Supabase SSR clients, public environment validation, session renewal and protected `/admin`.
- Added login, admin shell, loading/error states, tests and bootstrap documentation.
- Kept existing root SQL files unchanged; migration adoption remains a separate reviewed task.
- Bootstrap is awaiting review; no subsequent business phase has started.

## 2026-09-30 — Product catalog foundation

- Added Supabase-backed product listing, creation, editing, and reversible hiding.
- Connected product categories to business-scoped category records and added admin category management.
- Prepared migration `007_category_management_rls.sql`; it must be applied in each Supabase environment before relying on database-enforced category write permissions.
- Product image management and inventory movement-based stock remain pending.

## 2026-09-30 — Category policy cleanup

- Added migration `008_remove_legacy_categories_admin_policy.sql` to remove only the inherited `categories_admin FOR ALL` policy from `public.categories`.
- Preserved the category INSERT, UPDATE, and SELECT policies; the migration does not modify data.
- Added unit and PostgreSQL catalog regression checks for the migration contract.

## 2026-09-30 — Product image management

- Added migration `009_product_image_storage_management.sql` for the public catalog image bucket, business-scoped Storage policies, one-primary-image enforcement, and image management RPCs.
- Added admin image upload, alt text, primary selection, reordering, and removal to product editing.
- Added image validation and unit/integration checks; migration application and live Storage behavior still require verification in Supabase.

## Next

- Apply and verify pending migration 009 and test the complete product image workflow in Supabase.
