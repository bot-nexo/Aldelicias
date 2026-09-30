# ALDELICIAS — MASTER PROJECT CONTEXT & COPILOT DEVELOPMENT GUIDE

**Version:** 1.0  
**Date:** 2026-09-30  
**Project status:** Architecture definition completed; implementation phase begins.  
**Document purpose:** This is the primary context document for any coding agent (especially GitHub Copilot/Copilot Chat). It must be read before making architectural or implementation decisions.

---

# 1. PROJECT IDENTITY

## 1.1 What is AlDelicias?

AlDelicias is a Colombian food business focused on serving office workers with ready-to-eat products from a mobile van.

Main product categories include:

- Pasteles
- Buñuelos
- Empanadas
- Almojábanas
- Hot drinks
- Cold drinks
- Future products may be added

The business currently has **one van/location**, but the architecture MUST support multiple vans/locations in the future.

The business has:

- Owner / administrator
- Collaborator(s)
- Suppliers
- Physical inventory
- Sales
- Expenses
- Cash management
- Supplier credit
- Business/event orders
- Public product catalog

---

# 2. MAIN PRODUCT VISION

AlDelicias is NOT only a website.

It is a small business operating platform composed of two connected products:

## A. PUBLIC WEBSITE

Purpose:

- Show the AlDelicias brand.
- Present products professionally.
- Make the customer want to interact with the brand.
- Show product categories.
- Show multiple product images.
- Present prices where appropriate.
- Allow customers to contact AlDelicias through WhatsApp.
- Support corporate events, meetings and planned orders.
- No normal online delivery checkout at this stage.
- No delivery system is required currently.

The website must feel:

- Modern
- Premium
- Original
- Fast
- Memorable
- Professional
- Clearly designed for AlDelicias

DO NOT use generic food-delivery templates.

The visual identity must be based on the approved AlDelicias logo direction.

## B. ADMINISTRATIVE PLATFORM

Purpose:

Give the owner control over the business.

The administrator must be able to understand:

- How much was sold
- What was sold
- What products are profitable
- What products are moving
- What was purchased
- What is owed to suppliers
- What was spent
- What is in inventory
- What was wasted
- How much cash should exist
- How much cash actually exists
- Differences in cash
- Gross profit
- Estimated net profit
- Performance by day/week/month/custom date range

---

# 3. CURRENT BUSINESS RULES — SOURCE OF TRUTH

Do not contradict these rules unless the owner explicitly changes them.

## Payment methods

Initial methods:

1. Cash
2. Nequi
3. Daviplata
4. Bank transfer

The administrator can activate/deactivate accepted payment methods.

By default:

- CASH affects physical cash.
- NEQUI does not affect physical cash.
- DAVIPLATA does not affect physical cash.
- BANK_TRANSFER does not affect physical cash.

The architecture must allow future payment methods.

---

# 4. USERS AND ROLES

Initial roles:

## ADMIN

Can:

- Manage products
- Manage prices
- Manage categories
- Manage suppliers
- Manage payment methods
- Register purchases
- Register supplier payments
- Register expenses
- Manage inventory
- Register wastage
- Manage cash
- View all metrics
- View reports
- Manage collaborators
- Configure the business
- Manage event leads

## COLLABORATOR

Operational access only.

Can eventually:

- Register sales
- View products needed for operation
- Operate assigned cash register
- Perform permitted inventory operations

Cannot:

- Change critical financial configuration
- Change product prices without permission
- Manage users
- Alter historical transactions
- Change business configuration

The exact collaborator permissions must remain centralized in the authorization layer.

Never scatter role checks throughout UI code without corresponding backend enforcement.

---

# 5. BUSINESS STRUCTURE

The database is multi-business ready.

Every business-owned entity must be scoped by:

`business_id`

This is mandatory.

Never create business data without a valid `business_id`.

The current business has one van, but future versions may have multiple:

- vans
- warehouses
- sales locations

The system therefore uses:

- `businesses`
- `vehicles`
- `locations`

---

# 6. PRODUCTS

Products have:

- name
- slug
- SKU
- short description
- full description
- category
- sale price
- cost price
- inventory tracking
- minimum stock
- featured flag
- status
- ordering position
- multiple images

Product statuses:

- DRAFT
- PUBLISHED
- HIDDEN
- OUT_OF_STOCK

Images must be stored in object storage, not inside PostgreSQL as binary data.

Recommended storage:

Supabase Storage.

`product_images` stores references such as:

- storage_path
- public_url
- alt_text
- sort_order
- is_primary

---

# 7. PRODUCT IMAGE STANDARD

The public website must use professional product imagery.

Image system requirements:

- Multiple images per product
- One primary image
- Responsive image rendering
- Lazy loading where appropriate
- Modern formats when supported
- Reasonable maximum upload dimensions
- Consistent aspect ratios where possible
- Alt text
- Optimized delivery

Do not load huge original images directly into the website.

The admin should eventually be able to:

- Upload
- Reorder
- Select primary image
- Remove images
- Edit alt text

---

# 8. SALES

A sale contains:

- sale number
- user
- vehicle
- location
- date/time
- items
- payments
- subtotal
- discount
- total
- product cost
- indirect cost
- gross profit
- estimated net profit
- status

Sale statuses:

- COMPLETED
- CANCELLED

Every sale item stores historical snapshots:

- product name
- quantity
- unit price
- unit cost
- indirect cost
- total cost

This is essential.

Never calculate historical reports using the CURRENT product price/cost.

---

# 9. SALES PAYMENT RULE

A sale may have multiple payment records.

Example:

Total = $100,000

- Cash = $40,000
- Nequi = $30,000
- Transfer = $30,000

The sum of payments MUST equal the sale total.

The transaction must fail if:

`payment_total != sale_total`

No partial database state may remain after a failed sale.

---

# 10. INVENTORY

Inventory is movement-based.

Do NOT use a simple mutable `stock` field as the sole source of truth.

Inventory movements include:

- PURCHASE
- SALE
- WASTAGE
- ADJUSTMENT
- TRANSFER_IN
- TRANSFER_OUT
- RETURN
- REVERSAL

Stock is derived from movements.

Basic logic:

```text
STOCK =
PURCHASE
+ TRANSFER_IN
+ RETURN
+ ADJUSTMENT
+ REVERSAL
- SALE
- WASTAGE
- TRANSFER_OUT
```

Every inventory movement must be traceable.

---

# 11. PURCHASES

A purchase has:

- supplier
- location
- vehicle when relevant
- purchase number
- date
- items
- subtotal
- total
- status
- notes
- creator

Purchases may be:

- CONTADO
- CRÉDITO

Credit purchases create an accounts-payable record.

---

# 12. ACCOUNTS PAYABLE

Supplier account payable stores:

- original amount
- paid amount
- outstanding amount
- due date
- status

Statuses:

- UNPAID
- PARTIAL
- PAID

Example:

Purchase = $500,000

Paid = $200,000

Outstanding = $300,000

Status = PARTIAL

Never allow:

`paid_amount > original_amount`

---

# 13. EXPENSES

Expenses may include:

- collaborator payment
- vehicle rental
- fuel
- maintenance
- supplies
- packaging
- administrative expenses
- other business expenses

Expenses contain:

- category
- description
- amount
- date
- payment method
- vehicle when applicable
- notes
- receipt reference when available

Expenses may affect physical cash depending on their payment method/configuration.

---

# 14. CASH MANAGEMENT

The system must support physical cash control.

A cash register has:

- opening
- movements
- closing

Opening:

- operator
- timestamp
- opening amount

Closing:

- expected amount
- counted amount
- difference
- closing operator
- timestamp

Formula:

```text
DIFFERENCE = COUNTED_AMOUNT - EXPECTED_AMOUNT
```

The difference must never be silently discarded.

Example:

Expected: $350,000
Counted: $340,000

Difference:

`-$10,000`

This must remain visible in reporting.

Only appropriate payment movements affect physical cash.

---

# 15. INDIRECT COSTS

AlDelicias wants to know the true cost of selling products.

Examples:

- bag
- napkin
- sauce
- cup
- lid
- packaging
- other consumables

These are represented as `cost_components`.

A product may consume multiple components.

Example:

```text
EMPANADA

1 bag
1 napkin
1 sauce
```

The system calculates:

```text
INDIRECT UNIT COST =
SUM(component.quantity × component.unit_cost)
```

The current component cost must NOT rewrite historical sales.

Cost history is therefore maintained.

---

# 16. PROFITABILITY MODEL

The system must eventually expose:

```text
SALES
- DIRECT PRODUCT COST
- INDIRECT PRODUCT COST
= GROSS PROFIT

GROSS PROFIT
- OPERATING EXPENSES
= ESTIMATED NET PROFIT
```

Important distinction:

This is an internal management metric.

It is NOT an official Colombian accounting/tax system.

The project does not currently implement:

- DIAN electronic invoicing
- official tax accounting
- legal accounting books
- payroll compliance
- fiscal reporting

Do not add these unless the owner explicitly requests them.

---

# 17. DASHBOARD

The dashboard must allow date filters:

- Today
- Yesterday
- This week
- This month
- Custom date range

Core KPIs:

- Sales
- Number of sales
- Average ticket
- Product cost
- Indirect cost
- Gross profit
- Expenses
- Estimated net profit
- Cash difference
- Accounts payable
- Low-stock products

Additional future metrics:

- Top products
- Slow products
- Sales by payment method
- Sales by vehicle
- Sales by category
- Sales by day
- Sales by hour
- Expense breakdown

Do not overload the first screen.

The dashboard must prioritize actionable information.

---

# 18. EVENT / CORPORATE ORDER MODULE

The public website does NOT process normal delivery orders.

It does allow planned business/event inquiries.

Examples:

- corporate meetings
- office events
- celebrations
- scheduled group orders

Event lead information may include:

- customer name
- company
- phone
- email
- event date
- guest count
- event type
- message
- status

Statuses:

- NEW
- CONTACTED
- QUOTE
- CONFIRMED
- COMPLETED
- LOST

WhatsApp is the primary conversion channel for now.

---

# 19. RECOMMENDED TECH STACK

Unless a later architectural decision explicitly changes it:

## Frontend

- Next.js
- React
- TypeScript
- Tailwind CSS
- shadcn/ui or similarly controlled component primitives
- modern client/server rendering strategy

## Backend

Supabase:

- PostgreSQL
- Auth
- Storage
- Row Level Security
- RPC / PostgreSQL functions

The application server should not duplicate business rules that belong in transactional database functions.

## Validation

- Zod or equivalent schema validation

## Charts

- Recharts or equivalent lightweight charting solution

## Deployment

Recommended:

- Vercel for Next.js
- Supabase for database/auth/storage

---

# 20. ARCHITECTURAL PRINCIPLES

## Principle 1 — Database is authoritative

Financial/inventory integrity must be enforced at database level.

## Principle 2 — UI is not security

Never trust frontend permission checks.

Backend/RLS must enforce authorization.

## Principle 3 — Transactions are atomic

A sale is either completely successful or completely rolled back.

Same principle applies to:

- purchases
- supplier payments
- inventory adjustments
- cash operations

## Principle 4 — History is immutable

Do not silently edit historical financial transactions.

Use:

- reversal
- cancellation
- adjustment
- audit log

when correction is required.

## Principle 5 — Current values do not rewrite history

Historical sale cost must remain historical.

## Principle 6 — Business isolation

Every query must respect `business_id`.

## Principle 7 — Performance

Do not make the dashboard calculate huge datasets in the browser.

Use:

- SQL views
- materialized views when justified
- indexed queries
- server-side aggregation

---

# 21. PROJECT STRUCTURE

Recommended repository:

```text
aldelicias/
├── app/
│   ├── (public)/
│   │   ├── page.tsx
│   │   ├── productos/
│   │   ├── eventos/
│   │   └── contacto/
│   │
│   ├── admin/
│   │   ├── dashboard/
│   │   ├── ventas/
│   │   ├── productos/
│   │   ├── inventario/
│   │   ├── compras/
│   │   ├── proveedores/
│   │   ├── gastos/
│   │   ├── caja/
│   │   ├── reportes/
│   │   ├── eventos/
│   │   └── configuracion/
│   │
│   └── api/
│
├── components/
│   ├── ui/
│   ├── public/
│   ├── admin/
│   ├── dashboard/
│   ├── products/
│   ├── sales/
│   ├── inventory/
│   ├── purchases/
│   ├── expenses/
│   └── cash/
│
├── lib/
│   ├── supabase/
│   ├── auth/
│   ├── permissions/
│   ├── validation/
│   ├── formatting/
│   └── calculations/
│
├── services/
│   ├── products/
│   ├── sales/
│   ├── inventory/
│   ├── purchases/
│   ├── expenses/
│   ├── cash/
│   └── reports/
│
├── types/
│
├── supabase/
│   ├── migrations/
│   ├── seed.sql
│   └── functions/
│
├── public/
│
├── docs/
│   ├── ARCHITECTURE.md
│   ├── BUSINESS_RULES.md
│   ├── DATABASE.md
│   ├── UX_UI.md
│   └── CHANGELOG.md
│
├── tests/
│   ├── unit/
│   ├── integration/
│   └── e2e/
│
└── README.md
```

The exact structure can evolve, but the separation of responsibilities must remain.

---

# 22. ROUTING

Public:

```text
/
 /productos
 /productos/[slug]
 /eventos
 /contacto
```

Admin:

```text
/admin
/admin/dashboard
/admin/ventas
/admin/productos
/admin/inventario
/admin/compras
/admin/proveedores
/admin/gastos
/admin/caja
/admin/reportes
/admin/eventos
/admin/configuracion
```

Authentication:

```text
/login
```

Unauthorized users must never reach admin data.

---

# 23. DATABASE MIGRATION ORDER

The current migration sequence is:

```text
001_initial_schema.sql
002_rls_and_security.sql
003_business_functions.sql
005_finance_inventory_v2.sql
```

Before production, migrations must be cleaned and renumbered consistently if the repository adopts a strict migration ordering.

Future migrations should be incremental.

NEVER rewrite an already deployed migration.

---

# 24. NEXT DEVELOPMENT PHASE

The next implementation sequence is:

## STEP 1 — Repository bootstrap

Create:

- Next.js app
- TypeScript
- Tailwind
- component system
- ESLint
- formatting
- environment handling

## STEP 2 — Supabase

Configure:

- project
- database
- Auth
- Storage
- migrations
- local development if available

## STEP 3 — Authentication

Implement:

- login
- session
- protected admin routes
- user profile
- role loading

## STEP 4 — Admin shell

Build:

- sidebar
- top bar
- responsive navigation
- business context
- user menu
- notifications area

## STEP 5 — Products

Build:

- product CRUD
- category CRUD
- image upload
- image management
- pricing
- inventory settings

## STEP 6 — Inventory

Build:

- stock view
- movement history
- adjustments
- wastage
- minimum-stock alerts

## STEP 7 — Purchases

Build:

- supplier CRUD
- purchase registration
- contado/crédito
- accounts payable
- supplier payments

## STEP 8 — Sales

Build:

- product selection
- cart
- multi-payment
- transaction confirmation
- receipt/summary
- stock deduction

## STEP 9 — Cash

Build:

- cash register
- opening
- movements
- closing
- difference report

## STEP 10 — Expenses

Build:

- categories
- expense registration
- payment method
- reports

## STEP 11 — Cost model

Build:

- components
- product-component relations
- cost history
- profitability calculations

## STEP 12 — Dashboard

Build:

- KPI cards
- charts
- date filters
- profitability
- inventory warnings
- accounts payable
- cash differences

## STEP 13 — Public website

Build the distinctive AlDelicias experience.

## STEP 14 — Events / WhatsApp

Build:

- event inquiry form
- lead management
- WhatsApp CTA
- admin event pipeline

## STEP 15 — QA

Test:

- permissions
- transactions
- concurrent inventory
- payments
- cash
- reports
- responsive UI
- image performance

---

# 25. UX/UI DIRECTION

The public site must NOT resemble:

- generic restaurant templates
- generic delivery apps
- generic WordPress food themes
- cloned Rappi/Uber Eats interfaces

The design should feel like an original digital identity for AlDelicias.

The visual language should communicate:

- freshness
- warmth
- movement
- office convenience
- appetite
- craftsmanship
- modern Colombian food culture

The approved logo direction should remain the brand anchor.

The admin interface should prioritize:

- clarity
- speed
- low cognitive load
- readable financial information
- obvious actions
- mobile/tablet usability

---

# 26. IMAGE HANDLING

Public product images should use optimized responsive delivery.

Admin upload flow:

```text
Select image
→ validate file
→ upload Storage
→ save storage reference
→ generate/serve optimized variants where supported
→ associate with product
→ mark primary image if selected
```

Do not store image binaries in PostgreSQL.

---

# 27. ERROR HANDLING

Every user-facing operation must have:

- loading state
- success state
- error state
- validation state
- empty state

Financial errors must be explicit.

Example:

Bad:

> Error.

Good:

> No se pudo registrar la venta porque el stock disponible de Empanada es 3 y estás intentando vender 5.

Never expose raw database errors to normal users.

Log technical details securely.

---

# 28. AUDIT

Important actions must create audit records.

Examples:

- create sale
- cancel sale
- create purchase
- register supplier payment
- change product price
- adjust inventory
- register wastage
- open cash
- close cash
- modify payment methods
- create/update users

Audit records should include:

- business
- user
- action
- entity
- entity id
- old values when appropriate
- new values when appropriate
- timestamp

---

# 29. SECURITY REQUIREMENTS

Never:

- expose Supabase service-role key to browser
- trust role from client state
- bypass RLS for convenience
- put secrets in Git
- accept arbitrary business_id from client without validating ownership
- allow direct manipulation of historical financial records
- build admin authorization only in React

Environment variables must be used for secrets.

---

# 30. TESTING REQUIREMENTS

Every critical business flow requires tests.

Minimum:

### Sales

- normal sale
- multiple items
- multiple payment methods
- insufficient stock
- incorrect payment total
- cancelled sale

### Purchases

- cash purchase
- credit purchase
- partial supplier payment
- complete supplier payment

### Inventory

- purchase increases stock
- sale decreases stock
- wastage decreases stock
- adjustment
- reversal

### Cash

- open
- sale movement
- expense movement
- close
- difference

### Security

- admin access
- collaborator restrictions
- cross-business isolation

---

# 31. DEFINITION OF DONE

A feature is NOT done because the UI exists.

A feature is done only when:

- UI works
- validation works
- backend works
- database transaction works
- permissions work
- errors are handled
- loading/empty states exist
- audit requirements are satisfied
- relevant tests exist
- responsive behavior is verified
- documentation is updated

---

# 32. COPILOT OPERATING RULES

These rules are mandatory for the coding agent.

## Rule 1

READ THIS DOCUMENT before beginning implementation.

## Rule 2

Do not invent business rules.

If a rule is not defined:

- identify the gap
- propose options
- ask the owner when the decision affects data integrity

## Rule 3

Do not silently change architecture.

If changing:

- database model
- stack
- authentication
- payment logic
- inventory model
- financial calculations

document the decision first.

## Rule 4

Always inspect existing code before creating duplicate code.

## Rule 5

Prefer reusable components/services.

## Rule 6

Financial operations belong in transactional backend/database functions.

## Rule 7

Never bypass RLS just to make a feature work.

## Rule 8

Never delete historical financial records to fix mistakes.

## Rule 9

Do not implement future functionality prematurely.

Example:

Do not build delivery logistics just because the business might need it later.

## Rule 10

Keep the public website and admin platform visually/structurally distinct while sharing the same backend.

---

# 33. AGENT WORK PROTOCOL

Before every significant task, the agent should internally establish:

```text
1. What module am I changing?
2. What business rule supports it?
3. What database entities are involved?
4. What permissions are required?
5. Is this operation transactional?
6. What happens if it fails?
7. What historical data must remain immutable?
8. What tests are required?
9. Does the change affect another module?
10. Does documentation need updating?
```

After implementation:

```text
1. Verify types.
2. Verify database assumptions.
3. Verify permissions.
4. Verify error states.
5. Run relevant tests.
6. Update documentation.
7. Record architectural decisions.
```

---

# 34. CURRENT PROJECT STATUS

Completed:

- Business requirements discovery
- Core business rules
- ERD V1
- Initial PostgreSQL schema
- RLS foundation
- Initial transactional functions
- Finance/inventory architecture V2
- Payment method model
- Supplier credit model
- Cash model
- Indirect cost model
- Profitability model

Current phase:

**READY TO START APPLICATION IMPLEMENTATION**

---

# 35. IMMEDIATE NEXT TASK

The next coding task is NOT to build random screens.

The immediate task is:

## BOOTSTRAP THE REAL REPOSITORY

Create the production-oriented application foundation:

1. Next.js + TypeScript
2. Tailwind
3. UI component architecture
4. Supabase client/server configuration
5. environment validation
6. authentication foundation
7. route protection
8. typed database layer
9. migration directory
10. project documentation
11. testing foundation
12. linting/formatting
13. error boundary
14. loading states
15. admin layout shell

After this foundation is stable, implement modules in the order defined in section 24.

---

# 36. DECISION LOG

## D001 — No delivery checkout

Decision:

The public website does not currently process delivery orders.

Reason:

The business does not currently operate its own delivery system.

---

## D002 — WhatsApp for planned events

Decision:

Corporate/event inquiries use WhatsApp as the primary conversion channel.

---

## D003 — Four initial payment methods

Decision:

Cash, Nequi, Daviplata and bank transfer.

---

## D004 — Supplier credit

Decision:

Purchases can be cash or credit.

Credit creates accounts payable.

---

## D005 — Physical cash control

Decision:

The system has opening and closing cash sessions.

---

## D006 — Indirect product costs

Decision:

Packaging and consumables can become product-level cost components.

---

## D007 — Historical snapshots

Decision:

Historical sales preserve the price/cost applicable at the moment of sale.

---

## D008 — Internal management system

Decision:

The system is not currently an official tax/accounting platform.

---

# 37. DO NOT FORGET

The goal is not to build "another restaurant website."

The goal is to create:

**AlDelicias — a distinctive public food brand + a practical internal business control system.**

The owner should be able to open the dashboard and understand the state of the business without needing a spreadsheet.

The customer should open the public website and immediately understand:

- What AlDelicias sells
- Why it is different
- What products are available
- How to contact them
- How to request service for an office/event

The system should remain simple enough for a small business but architecturally strong enough to grow to multiple vans.

---

# 38. AGENT START COMMAND

When beginning work, use this mental sequence:

```text
READ MASTER CONTEXT
↓
INSPECT REPOSITORY
↓
IDENTIFY CURRENT PHASE
↓
DO NOT DUPLICATE EXISTING WORK
↓
IMPLEMENT SMALLEST COMPLETE STEP
↓
TEST
↓
DOCUMENT
↓
UPDATE CHANGELOG / DECISION LOG
↓
MOVE TO NEXT DEFINED STEP
```

**End of Master Context.**
