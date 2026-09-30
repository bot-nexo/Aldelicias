# AlDelicias — ERD V1.0

```mermaid
erDiagram
    BUSINESSES ||--o{ USERS : has
    ROLES ||--o{ USERS : assigns
    BUSINESSES ||--o{ VEHICLES : owns
    BUSINESSES ||--o{ LOCATIONS : has
    VEHICLES ||--o{ LOCATIONS : serves

    BUSINESSES ||--o{ CATEGORIES : has
    CATEGORIES ||--o{ PRODUCTS : contains
    PRODUCTS ||--o{ PRODUCT_IMAGES : has

    BUSINESSES ||--o{ SUPPLIERS : has
    SUPPLIERS ||--o{ PURCHASES : supplies
    PURCHASES ||--|{ PURCHASE_ITEMS : contains
    PRODUCTS ||--o{ PURCHASE_ITEMS : purchased

    BUSINESSES ||--o{ SALES : records
    SALES ||--|{ SALE_ITEMS : contains
    PRODUCTS ||--o{ SALE_ITEMS : sold
    SALES ||--|{ PAYMENTS : paid_by
    PAYMENT_METHODS ||--o{ PAYMENTS : uses

    PRODUCTS ||--o{ INVENTORY_MOVEMENTS : moves
    LOCATIONS ||--o{ INVENTORY_MOVEMENTS : occurs_at

    EXPENSE_CATEGORIES ||--o{ EXPENSES : categorizes
    PAYMENT_METHODS ||--o{ EXPENSES : paid_with
    VEHICLES ||--o{ EXPENSES : relates_to

    CASH_REGISTERS ||--o{ CASH_SESSIONS : opens
    CASH_SESSIONS ||--o{ CASH_MOVEMENTS : contains

    BUSINESSES ||--o{ EVENTS : receives
    USERS ||--o{ EVENTS : assigned

    BUSINESSES ||--o{ AUDIT_LOGS : records
    USERS ||--o{ AUDIT_LOGS : performs
```

## Decisiones clave

1. `businesses` permite futuras vans/sucursales sin rediseñar la aplicación.
2. `sales`, `purchases`, `expenses` y `inventory_movements` son históricos.
3. No se borran físicamente transacciones.
4. `sale_items` conserva precio/costo/nombre como snapshot.
5. `inventory_movements` es la fuente de trazabilidad del inventario.
6. `cash_movements` permite conciliar caja.
7. `product_images` guarda referencias a Supabase Storage, no binarios en PostgreSQL.
8. RLS debe aislar los registros por `business_id`.
9. Las operaciones financieras e inventario deben ser transaccionales.
10. Los costos indirectos (bolsas, servilletas, salsas, etc.) quedan preparados para una futura capa de componentes/recetas; no deben inventarse como costo del producto hasta definir el modelo operativo.

## Flujo central

```text
PROVEEDOR
   ↓
COMPRA
   ↓
PURCHASE_ITEMS
   ↓
INVENTORY_MOVEMENTS (+)
   ↓
STOCK

PRODUCTO
   ↓
VENTA
   ↓
SALE_ITEMS
   ├── PAYMENT
   ├── INVENTORY_MOVEMENT (-)
   └── CASH_MOVEMENT

GASTO
   ├── EXPENSE
   └── CASH_MOVEMENT (si aplica)

TODO
   ↓
DASHBOARD / REPORTES
```
