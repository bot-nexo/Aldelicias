# AlDelicias — Coding Agent Instructions

Before changing code, read:

`ALDELICIAS_MASTER_CONTEXT.md`

That document is the source of truth for business rules, architecture, roadmap and constraints.

## Non-negotiable rules

- Do not invent undefined business rules.
- Do not bypass RLS.
- Do not expose service-role secrets to the client.
- Financial and inventory mutations must be transactional.
- Historical transactions must not be silently rewritten.
- Every business-owned record must respect `business_id`.
- Frontend authorization is not sufficient; backend/database authorization is mandatory.
- Do not build future features before their phase.
- Inspect existing code before creating new abstractions.
- Keep public website and admin platform distinct.
- Update documentation when architecture or business behavior changes.
- Add tests for critical business flows.

## Current phase

Repository/application bootstrap.

Build the foundation first:

1. Next.js + TypeScript
2. Tailwind/UI system
3. Supabase clients
4. Environment validation
5. Auth/session
6. Protected admin routes
7. Typed database layer
8. Migration structure
9. Testing/linting/formatting
10. Admin shell
11. Documentation

Then follow the roadmap in the master context.

<!-- BEGIN:nextjs-agent-rules -->

# This is NOT the Next.js you know

This version has breaking changes — APIs, conventions, and file structure may all differ from your training data. Read the relevant guide in `node_modules/next/dist/docs/` (resolved from this file's directory; in monorepos the `next` package may not be visible from the repo root) before writing any code. Heed deprecation notices.

This block is written and re-added by `next dev` — verify at `node_modules/next/dist/server/lib/generate-agent-files.js`. Removing it from a diff only re-creates the uncommitted change; committing it with your work keeps the tree clean.

<!-- END:nextjs-agent-rules -->
