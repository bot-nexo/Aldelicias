# ALDELICIAS

## Especificación Técnica — Base de Datos + Reglas de Negocio

**Versión:** 1.0
**Estado:** Diseño técnico
**Proyecto:** Plataforma web + sistema administrativo AlDelicias
**Stack objetivo:** Next.js + React + TypeScript + PostgreSQL/Supabase + Vercel
**Fuente de verdad:** Este documento, junto con `PROJECT.md`, `ARCHITECTURE.md`, `UX.md` y `AI_RULES.md`.

---

# 1. PROPÓSITO

Este documento define la estructura de datos, relaciones y reglas de negocio fundamentales de AlDelicias.

Su objetivo es evitar que el desarrollo se realice mediante decisiones aisladas.

Cualquier desarrollador o asistente de programación debe consultar este documento antes de modificar:

* base de datos;
* ventas;
* compras;
* inventario;
* caja;
* gastos;
* productos;
* proveedores;
* usuarios;
* eventos;
* métricas.

Una modificación que contradiga este documento debe considerarse un cambio de arquitectura y debe documentarse antes de implementarse.

---

# 2. PRINCIPIOS DE ARQUITECTURA

## 2.1 Las transacciones son históricas

Ventas, compras, movimientos de inventario, movimientos de caja y gastos no deben eliminarse físicamente.

Cuando corresponda, se cambia su estado.

Ejemplo:

```text
ACTIVE
CANCELLED
VOID
```

---

## 2.2 El inventario funciona mediante movimientos

No se debe depender únicamente de modificar una columna `stock`.

El stock se deriva de movimientos de inventario.

Ejemplo:

```text
COMPRA       +100
VENTA         -20
VENTA          -5
MERMA          -3
AJUSTE        +10
------------------
STOCK ACTUAL   82
```

Puede existir un campo cacheado de stock actual por rendimiento, pero la trazabilidad debe conservarse.

---

# 3. MULTI-NEGOCIO / FUTURO

Aunque inicialmente AlDelicias tendrá un solo negocio, la arquitectura debe evitar quedar atada a una única van.

Se utilizará:

```text
businesses
```

como entidad raíz.

Actualmente:

```text
AlDelicias
```

En el futuro podría existir:

```text
AlDelicias
 ├── Van 01
 ├── Van 02
 └── Van 03
```

Esto permitirá crecer sin rediseñar toda la base.

---

# 4. ENTIDADES PRINCIPALES

El sistema tendrá inicialmente:

```text
businesses
users
roles
vehicles
locations

categories
products
product_images

suppliers
purchases
purchase_items

sales
sale_items
payments

inventory_movements
wastage_reasons

expense_categories
expenses

cash_registers
cash_sessions
cash_movements

events

payment_methods

audit_logs
```

---

# 5. RELACIÓN GENERAL

```text
BUSINESS
│
├── USERS
│
├── VEHICLES
│
├── LOCATIONS
│
├── CATEGORIES
│    └── PRODUCTS
│          └── PRODUCT_IMAGES
│
├── SUPPLIERS
│    └── PURCHASES
│          └── PURCHASE_ITEMS
│
├── SALES
│    ├── SALE_ITEMS
│    └── PAYMENTS
│
├── INVENTORY_MOVEMENTS
│
├── EXPENSES
│
├── CASH_SESSIONS
│    └── CASH_MOVEMENTS
│
├── EVENTS
│
└── AUDIT_LOGS
```

---

# 6. BUSINESSES

Representa el negocio.

### Tabla

```text
businesses
```

### Campos

```text
id                  UUID PK
name                TEXT
slug                TEXT UNIQUE
logo_url             TEXT
phone               TEXT
whatsapp             TEXT
email                TEXT
address              TEXT
timezone             TEXT
currency             TEXT
is_active            BOOLEAN
created_at           TIMESTAMPTZ
updated_at           TIMESTAMPTZ
```

### Valores iniciales

```text
name     = AlDelicias
currency = COP
timezone = America/Bogota
```

---

# 7. USERS

Usuarios internos.

```text
users
```

Campos:

```text
id                  UUID PK
business_id         UUID FK
auth_user_id        UUID UNIQUE
full_name           TEXT
email               TEXT
phone               TEXT
role_id             UUID FK
is_active            BOOLEAN
created_at           TIMESTAMPTZ
updated_at           TIMESTAMPTZ
last_login_at        TIMESTAMPTZ
```

La autenticación real será gestionada por Supabase Auth.

`users` contiene información de negocio/perfil.

---

# 8. ROLES

Inicialmente:

```text
ADMIN
COLLABORATOR
```

El diseño debe permitir posteriormente:

```text
MANAGER
ACCOUNTANT
SUPERVISOR
```

sin modificar las entidades principales.

---

# 9. PERMISOS

No se recomienda codificar permisos directamente dentro de cada componente.

Conceptualmente:

```text
roles
role_permissions
permissions
```

Ejemplos:

```text
sales.create
sales.view
sales.cancel

products.create
products.update
products.delete

purchases.create
purchases.view

inventory.view
inventory.adjust
inventory.wastage

expenses.create
expenses.view

cash.open
cash.close
cash.view

reports.view

users.manage
settings.manage
```

---

# 10. VEHICLES

Representa las vans.

```text
vehicles
```

Campos:

```text
id                  UUID PK
business_id         UUID FK
name                TEXT
plate               TEXT
description         TEXT
is_active            BOOLEAN
created_at           TIMESTAMPTZ
updated_at           TIMESTAMPTZ
```

Ejemplo:

```text
Van 01
```

La placa puede ser opcional inicialmente.

---

# 11. LOCATIONS

Permite representar lugares físicos/lógicos.

Inicialmente:

```text
Van 01
```

Pero puede evolucionar a:

```text
Almacén
Van 01
Van 02
Bodega
```

Campos:

```text
id                  UUID PK
business_id         UUID FK
vehicle_id          UUID FK NULL
name                TEXT
type                TEXT
is_active            BOOLEAN
created_at           TIMESTAMPTZ
updated_at           TIMESTAMPTZ
```

Tipos:

```text
WAREHOUSE
VEHICLE
OTHER
```

---

# 12. CATEGORIES

Categorías de productos.

Ejemplos:

```text
Empanadas
Buñuelos
Pasteles
Almojábanas
Bebidas calientes
Bebidas frías
```

Campos:

```text
id                  UUID PK
business_id         UUID FK
name                TEXT
slug                TEXT
description         TEXT
image_url            TEXT
sort_order           INTEGER
is_active            BOOLEAN
created_at           TIMESTAMPTZ
updated_at           TIMESTAMPTZ
```

---

# 13. PRODUCTS

Representa cualquier producto vendible.

```text
products
```

Campos:

```text
id                  UUID PK
business_id         UUID FK
category_id         UUID FK

name                TEXT
slug                TEXT
short_description   TEXT
description         TEXT

sku                 TEXT NULL

sale_price          NUMERIC(12,2)

cost_price          NUMERIC(12,2) NULL

track_inventory     BOOLEAN
minimum_stock       NUMERIC(12,3)

is_featured         BOOLEAN
status              TEXT

sort_order           INTEGER

created_at           TIMESTAMPTZ
updated_at           TIMESTAMPTZ
```

Estados:

```text
DRAFT
PUBLISHED
HIDDEN
OUT_OF_STOCK
```

---

# 14. REGLA IMPORTANTE SOBRE PRECIOS

Cambiar el precio de un producto no modifica ventas históricas.

Ejemplo:

```text
Producto actual:
$4.500
```

Una venta antigua puede haber sido:

```text
$4.000
```

La venta conserva:

```text
unit_price = 4000
```

---

# 15. PRODUCT_IMAGES

```text
product_images
```

Campos:

```text
id                  UUID PK
product_id          UUID FK
storage_path        TEXT
public_url          TEXT
alt_text            TEXT
sort_order           INTEGER
is_primary           BOOLEAN
created_at           TIMESTAMPTZ
```

Las imágenes NO se almacenan como BLOB/base64 dentro de PostgreSQL.

Se almacenan en Storage.

---

# 16. SUPPLIERS

```text
suppliers
```

Campos:

```text
id                  UUID PK
business_id         UUID FK
name                TEXT
contact_name        TEXT
phone               TEXT
whatsapp             TEXT
email                TEXT
address              TEXT
notes                TEXT
is_active            BOOLEAN
created_at           TIMESTAMPTZ
updated_at           TIMESTAMPTZ
```

---

# 17. PURCHASES

Cabecera de compra.

```text
purchases
```

Campos:

```text
id                  UUID PK
business_id         UUID FK
supplier_id         UUID FK

location_id         UUID FK
vehicle_id          UUID FK NULL

purchase_number     TEXT

purchase_date       TIMESTAMPTZ

subtotal             NUMERIC(12,2)
discount_total       NUMERIC(12,2)
total                NUMERIC(12,2)

status               TEXT

notes                TEXT

created_by           UUID FK
created_at           TIMESTAMPTZ
updated_at           TIMESTAMPTZ
```

Estados:

```text
DRAFT
CONFIRMED
CANCELLED
```

---

# 18. PURCHASE_ITEMS

```text
purchase_items
```

Campos:

```text
id                  UUID PK
purchase_id         UUID FK
product_id          UUID FK

product_name_snapshot TEXT

quantity             NUMERIC(12,3)

unit_cost            NUMERIC(12,2)

subtotal             NUMERIC(12,2)

created_at           TIMESTAMPTZ
```

El nombre se guarda como snapshot para proteger el historial.

---

# 19. REGLA DE COMPRA

Cuando una compra pasa a `CONFIRMED`:

```text
PURCHASE
   ↓
PURCHASE_ITEMS
   ↓
INVENTORY_MOVEMENTS
   ↓
STOCK +
```

Una compra en `DRAFT` no modifica inventario.

Una compra `CANCELLED` debe generar el movimiento compensatorio correspondiente si previamente había afectado inventario.

---

# 20. SALES

Cabecera de venta.

```text
sales
```

Campos:

```text
id                  UUID PK
business_id         UUID FK

sale_number         TEXT

user_id             UUID FK
vehicle_id          UUID FK NULL
location_id         UUID FK NULL

sold_at             TIMESTAMPTZ

subtotal             NUMERIC(12,2)
discount_total       NUMERIC(12,2)
total                NUMERIC(12,2)

total_cost           NUMERIC(12,2)

gross_profit         NUMERIC(12,2)

status               TEXT

notes                TEXT

created_at           TIMESTAMPTZ
updated_at           TIMESTAMPTZ
```

Estados:

```text
COMPLETED
CANCELLED
```

---

# 21. SALE_ITEMS

```text
sale_items
```

Campos:

```text
id                  UUID PK
sale_id             UUID FK
product_id          UUID FK

product_name_snapshot TEXT

quantity             NUMERIC(12,3)

unit_price            NUMERIC(12,2)

unit_cost             NUMERIC(12,2)

subtotal              NUMERIC(12,2)

cost_total            NUMERIC(12,2)

created_at            TIMESTAMPTZ
```

---

# 22. REGLA CRÍTICA DE SALE_ITEMS

Cuando se registra una venta se captura:

```text
nombre actual
precio actual
costo actual
```

como snapshot.

Por tanto, si mañana:

```text
precio = $5.000
costo = $3.000
```

la venta de ayer puede conservar:

```text
precio = $4.000
costo = $2.400
```

Esto permite reportes históricos confiables.

---

# 23. PAYMENTS

Una venta puede tener uno o varios pagos.

```text
payments
```

Campos:

```text
id                  UUID PK
sale_id             UUID FK
payment_method_id   UUID FK
amount              NUMERIC(12,2)
created_at           TIMESTAMPTZ
```

Regla:

```text
SUM(payments.amount) = sales.total
```

Una venta no puede quedar confirmada si los pagos no cuadran, salvo que exista una regla explícita para crédito/pendiente en una futura versión.

---

# 24. PAYMENT_METHODS

```text
payment_methods
```

Inicialmente:

```text
EFECTIVO
NEQUI
DAVIPLATA
TRANSFERENCIA
TARJETA
```

El administrador podrá activar/desactivar métodos.

Campos:

```text
id                  UUID PK
business_id         UUID FK
name                TEXT
code                TEXT
is_active            BOOLEAN
sort_order           INTEGER
created_at           TIMESTAMPTZ
```

---

# 25. INVENTORY_MOVEMENTS

Entidad fundamental.

```text
inventory_movements
```

Campos:

```text
id                  UUID PK
business_id         UUID FK

product_id          UUID FK
location_id         UUID FK

movement_type       TEXT

quantity             NUMERIC(12,3)

unit_cost            NUMERIC(12,2)
total_cost           NUMERIC(12,2)

reference_type      TEXT
reference_id        UUID NULL

reason              TEXT NULL

created_by           UUID FK
created_at           TIMESTAMPTZ
```

Tipos:

```text
PURCHASE
SALE
WASTAGE
ADJUSTMENT
TRANSFER_IN
TRANSFER_OUT
RETURN
REVERSAL
```

---

# 26. INVENTARIO

Conceptualmente:

```text
STOCK =
SUM(entradas)
-
SUM(salidas)
```

El sistema puede mantener una tabla/cache de stock actual para acelerar consultas, pero los movimientos son la fuente de trazabilidad.

---

# 27. MERMAS

```text
wastage_reasons
```

Ejemplos:

```text
Producto dañado
Producto vencido
Producto sobrante
Error de preparación
Pérdida
Otro
```

Una merma genera:

```text
inventory_movement
movement_type = WASTAGE
```

---

# 28. EXPENSE_CATEGORIES

Categorías:

```text
Personal
Vehículo
Combustible
Alquiler
Empaques
Publicidad
Mantenimiento
Servicios
Otros
```

La lista debe ser configurable.

---

# 29. EXPENSES

```text
expenses
```

Campos:

```text
id                  UUID PK
business_id         UUID FK

category_id         UUID FK

vehicle_id          UUID FK NULL
user_id             UUID FK

description         TEXT
amount              NUMERIC(12,2)

expense_date        TIMESTAMPTZ

payment_method_id   UUID FK NULL

receipt_url         TEXT NULL

notes               TEXT NULL

status              TEXT

created_at           TIMESTAMPTZ
updated_at           TIMESTAMPTZ
```

Estados:

```text
ACTIVE
CANCELLED
```

---

# 30. REGLA DE GASTOS

Registrar un gasto no modifica inventario.

Puede modificar caja si fue pagado desde una caja administrada por el sistema.

Por tanto:

```text
GASTO
 ├── Resultado operativo
 └── Caja
```

si corresponde.

---

# 31. CASH_REGISTERS

Representa una caja lógica.

```text
cash_registers
```

Campos:

```text
id
business_id
name
location_id
is_active
created_at
updated_at
```

---

# 32. CASH_SESSIONS

Una sesión representa una jornada de caja.

```text
cash_sessions
```

Campos:

```text
id
cash_register_id
opened_by
opened_at

opening_amount

closed_by
closed_at

expected_amount
counted_amount
difference

status
```

Estados:

```text
OPEN
CLOSED
```

---

# 33. CASH_MOVEMENTS

```text
cash_movements
```

Tipos:

```text
SALE
EXPENSE
WITHDRAWAL
DEPOSIT
ADJUSTMENT
OPENING
CLOSING
REVERSAL
```

Campos:

```text
id
cash_session_id

movement_type
amount

reference_type
reference_id

description

created_by
created_at
```

---

# 34. REGLA DE CAJA

La caja esperada se calcula:

```text
APERTURA
+
ENTRADAS
-
SALIDAS
=
CAJA ESPERADA
```

Al cerrar:

```text
CAJA CONTADA
-
CAJA ESPERADA
=
DIFERENCIA
```

Una diferencia no debe modificar silenciosamente los movimientos anteriores.

---

# 35. EVENTS

Representa oportunidades comerciales para eventos.

```text
events
```

Campos:

```text
id
business_id

customer_name
company_name

phone
email

event_date
guest_count

event_type

message

status

source

assigned_to

created_at
updated_at
```

Estados:

```text
NEW
CONTACTED
QUOTE
CONFIRMED
COMPLETED
LOST
```

---

# 36. EVENT FLOW

```text
WEB
 ↓
FORMULARIO
 ↓
EVENT
status = NEW
 ↓
ADMIN CONTACTA
 ↓
CONTACTED
 ↓
COTIZACIÓN
 ↓
QUOTE
 ↓
CONFIRMED
 ↓
COMPLETED
```

Si el cliente no continúa:

```text
LOST
```

---

# 37. AUDIT_LOGS

Todas las operaciones sensibles deben generar auditoría.

```text
audit_logs
```

Campos:

```text
id
business_id

user_id

action
entity_type
entity_id

old_values
new_values

ip_address NULL
user_agent NULL

created_at
```

Ejemplos:

```text
CREATE_PRODUCT
UPDATE_PRODUCT
CANCEL_SALE
CONFIRM_PURCHASE
REGISTER_EXPENSE
CLOSE_CASH
ADJUST_INVENTORY
CHANGE_PRICE
CHANGE_USER_ROLE
```

---

# 38. INTEGRIDAD DE DATOS

La base debe utilizar:

### Primary Keys

UUID.

### Foreign Keys

Para garantizar relaciones.

### Unique Constraints

Por ejemplo:

```text
business_id + slug
business_id + sku
business_id + sale_number
business_id + purchase_number
```

### Check Constraints

Ejemplo:

```text
quantity > 0
amount >= 0
price >= 0
```

---

# 39. TRANSACCIONES

Operaciones críticas deben ejecutarse dentro de una transacción.

Especialmente:

### Venta

```text
crear venta
+
crear items
+
crear pagos
+
crear movimientos inventario
+
registrar caja
```

Todo debe confirmarse correctamente.

Si una parte falla:

```text
ROLLBACK
```

No debe quedar una venta creada con inventario sin actualizar.

---

# 40. VENTA — TRANSACCIÓN COMPLETA

```text
BEGIN

validar usuario
validar productos
validar stock
obtener precios
obtener costos

crear SALE

crear SALE_ITEMS

crear PAYMENTS

crear INVENTORY_MOVEMENTS

crear CASH_MOVEMENTS si corresponde

crear AUDIT_LOG

COMMIT
```

---

# 41. COMPRA — TRANSACCIÓN COMPLETA

```text
BEGIN

validar usuario
validar proveedor

crear PURCHASE

crear PURCHASE_ITEMS

crear INVENTORY_MOVEMENTS

crear AUDIT_LOG

COMMIT
```

---

# 42. ANULACIÓN DE VENTA

Nunca:

```text
DELETE FROM sales
```

Debe hacerse:

```text
SALE
status = CANCELLED
```

y crear movimientos compensatorios.

Ejemplo:

Venta:

```text
-2 inventario
```

Anulación:

```text
+2 inventario
```

La caja/pago también debe compensarse según corresponda.

---

# 43. ELIMINACIÓN DE PRODUCTOS

Un producto que tiene historial no debe eliminarse físicamente.

Se debe:

```text
is_active = false
```

o:

```text
status = HIDDEN
```

Esto evita romper referencias históricas.

---

# 44. CÁLCULO DE COSTO

Para la primera versión se utilizará un costo vigente por producto.

El costo puede provenir del último costo registrado o del costo configurado.

La estrategia exacta de valoración de inventario debe quedar centralizada en una función.

No se debe implementar la misma fórmula en:

* dashboard;
* ventas;
* reportes;
* producto;
* inventario.

Debe existir una única fuente de cálculo.

---

# 45. COSTO DEL PRODUCTO

Inicialmente:

```text
unit_cost
```

puede representar el costo de adquisición del producto.

Los insumos indirectos:

```text
bolsa
servilleta
salsa
vaso
etc.
```

podrán incorporarse como costos adicionales.

Para una futura versión puede evolucionarse hacia:

```text
products
recipes / product_components
inventory_items
```

sin romper ventas históricas.

---

# 46. MARGEN

```text
gross_profit =
sale_total - total_cost
```

Margen porcentual:

```text
gross_margin =
gross_profit / sale_total * 100
```

Si `sale_total = 0`, no se calcula porcentaje.

---

# 47. RESULTADO OPERATIVO

```text
gross_profit
-
operating_expenses
=
operating_result
```

No debe confundirse con:

```text
cash balance
```

---

# 48. DASHBOARD

El dashboard debe utilizar consultas agregadas.

No debe cargar todas las ventas históricas al navegador para calcular métricas.

Ejemplo:

```text
SELECT
SUM(total),
COUNT(*),
SUM(total_cost)
FROM sales
WHERE ...
```

Las consultas deben ejecutarse en servidor/base de datos.

---

# 49. FILTROS TEMPORALES

Todos los reportes deben soportar:

```text
HOY
AYER
ÚLTIMOS 7 DÍAS
ESTE MES
MES ANTERIOR
RANGO PERSONALIZADO
```

Las fechas deben manejarse usando:

```text
America/Bogota
```

para presentación y reglas de negocio locales.

La base de datos utilizará `TIMESTAMPTZ`.

---

# 50. PAGINACIÓN

Las tablas administrativas no deben cargar miles de registros de una vez.

Utilizar:

```text
pagination
```

o cursor pagination cuando corresponda.

Ejemplo:

```text
50 registros por página
```

---

# 51. BÚSQUEDA

Productos:

```text
name
sku
category
status
```

Ventas:

```text
sale_number
date
user
payment
```

Proveedores:

```text
name
contact
```

---

# 52. RLS — SUPABASE

Toda tabla relacionada con negocio debe protegerse mediante Row Level Security.

Regla conceptual:

```text
usuario autenticado
+
pertenece al business
=
puede acceder a los datos permitidos
```

Nunca depender solamente del frontend para separar negocios o roles.

---

# 53. AUTORIZACIÓN

Ejemplo:

Un colaborador puede:

```text
crear venta
ver productos
consultar precios
```

Pero no:

```text
cambiar precio
ver costo
eliminar usuario
ver reportes financieros completos
```

El servidor debe validar esto.

---

# 54. API / SERVER ACTIONS

Las operaciones críticas estarán detrás de funciones del servidor.

Ejemplos conceptuales:

```text
createSale()
cancelSale()

createPurchase()
confirmPurchase()

registerWastage()
adjustInventory()

createExpense()

openCashSession()
closeCashSession()

createProduct()
updateProduct()
```

Los componentes no deben escribir directamente lógica financiera compleja.

---

# 55. VALIDACIÓN CON ZOD

Cada operación tendrá schema.

Ejemplo conceptual:

```text
CreateSaleSchema

items:
  mínimo 1

quantity:
  > 0

payment:
  amount >= 0

total:
  >= 0
```

Los schemas deben utilizarse tanto para seguridad como para experiencia de usuario.

---

# 56. ESTRUCTURA DEL CÓDIGO

```text
app/
components/
lib/
  calculations/
  permissions/
  validations/
  services/
  db/
  auth/
types/
supabase/
  migrations/
  seed/
tests/
docs/
```

---

# 57. SERVICES

La lógica de negocio compleja debe vivir en servicios.

Ejemplo:

```text
lib/services/sales/create-sale.ts
lib/services/sales/cancel-sale.ts

lib/services/purchases/create-purchase.ts

lib/services/inventory/register-movement.ts

lib/services/cash/open-session.ts
lib/services/cash/close-session.ts
```

Esto facilita testing y mantenimiento.

---

# 58. REGLA PARA COPILOT

Antes de generar código, Copilot debe:

1. Identificar el módulo.
2. Revisar las tablas relacionadas.
3. Revisar las reglas de negocio.
4. Revisar permisos.
5. Revisar dependencias.
6. Determinar qué entidades se modifican.
7. Determinar qué efectos secundarios existen.
8. Implementar.
9. Crear/actualizar tests.
10. Actualizar documentación cuando corresponda.

---

# 59. NUNCA HACER ESTO

Copilot no debe:

```text
crear tablas sin migración
duplicar cálculos
borrar transacciones
ignorar permisos
confiar solamente en frontend
modificar datos históricos
guardar secretos en código
guardar imágenes en PostgreSQL
hacer queries ilimitadas
crear endpoints sin autorización
```

---

# 60. ÍNDICES PRINCIPALES

Se deberán evaluar índices sobre:

```text
sales.business_id
sales.sold_at
sales.status

sale_items.sale_id
sale_items.product_id

inventory_movements.product_id
inventory_movements.location_id
inventory_movements.created_at

purchases.business_id
purchases.purchase_date

expenses.business_id
expenses.expense_date

events.business_id
events.status

audit_logs.business_id
audit_logs.created_at
```

Los índices definitivos se ajustarán según consultas reales.

---

# 61. BACKUPS

La base de producción debe contar con respaldo.

Además:

* migraciones versionadas;
* repositorio Git;
* almacenamiento externo de archivos;
* estrategia de recuperación.

Nunca considerar:

> “Está en Supabase”

como estrategia completa de backup.

---

# 62. OBSERVABILIDAD

Se debe registrar:

* errores;
* fallos de operaciones críticas;
* errores de autenticación;
* problemas de API;
* fallos de imágenes.

En producción se recomienda integrar posteriormente una herramienta de error tracking.

---

# 63. TESTS MÍNIMOS

## Ventas

```text
crear venta válida
rechazar venta sin productos
rechazar cantidad inválida
rechazar stock insuficiente
validar pagos
actualizar inventario
actualizar caja
```

## Compras

```text
crear compra
actualizar inventario
validar proveedor
```

## Inventario

```text
compra +
venta -
merma -
ajuste
anulación +
```

## Caja

```text
abrir
registrar
cerrar
calcular diferencia
```

## Permisos

```text
admin permitido
colaborador restringido
```

---

# 64. PRIMERA MIGRACIÓN

La primera migración deberá crear la infraestructura base:

```text
businesses
roles
users
vehicles
locations
categories
products
product_images
suppliers
payment_methods
expense_categories
wastage_reasons
```

La segunda:

```text
purchases
purchase_items
```

La tercera:

```text
sales
sale_items
payments
```

La cuarta:

```text
inventory_movements
```

La quinta:

```text
expenses
```

La sexta:

```text
cash_registers
cash_sessions
cash_movements
```

La séptima:

```text
events
```

La octava:

```text
audit_logs
```

---

# 65. ENUMS

Se recomienda utilizar enums PostgreSQL para estados realmente cerrados.

Ejemplos:

```text
sale_status
purchase_status
product_status
cash_session_status
event_status
inventory_movement_type
expense_status
```

Para categorías que el administrador debe poder modificar, utilizar tablas.

---

# 66. SNAPSHOTS

Las siguientes entidades deben conservar snapshots cuando corresponda:

### Sale item

```text
product_name_snapshot
unit_price
unit_cost
```

### Purchase item

```text
product_name_snapshot
unit_cost
```

Esto protege los datos históricos.

---

# 67. CONCURRENCIA

Una venta no puede permitir que dos usuarios vendan simultáneamente más stock del disponible.

La operación de inventario debe ser atómica.

Conceptualmente:

```text
BEGIN
LOCK / atomic validation
validate stock
create movement
update stock/cache
COMMIT
```

Esto debe probarse explícitamente.

---

# 68. MONEDA

La aplicación trabajará inicialmente en:

```text
COP
```

Los valores monetarios no deben almacenarse como `float`.

Usar:

```text
NUMERIC(12,2)
```

o una representación entera consistente.

Nunca utilizar JavaScript `float` como fuente de verdad financiera.

---

# 69. FECHAS

Base:

```text
TIMESTAMPTZ
```

Aplicación:

```text
America/Bogota
```

No almacenar fechas críticas como strings.

---

# 70. REGLA DE DISEÑO FUTURO

La arquitectura debe permitir posteriormente:

```text
múltiples vans
múltiples colaboradores
más productos
más categorías
más proveedores
eventos
más métodos de pago
reportes avanzados
recetas/componentes
```

sin tener que rehacer ventas e inventario.

---

# 71. ORDEN DE IMPLEMENTACIÓN

```text
1. Database foundation
2. Auth
3. Roles/RLS
4. Design System
5. Products
6. Suppliers
7. Purchases
8. Inventory
9. Sales
10. Payments
11. Cash
12. Expenses
13. Dashboard
14. Events/CRM
15. Reports
16. Public website integration
17. Testing
18. Security audit
19. Performance
20. Production
```

---

# 72. CRITERIO DE ACEPTACIÓN DE CADA MÓDULO

Un módulo solo se considera terminado cuando posee:

```text
UI
+
Responsive
+
Validación
+
Backend
+
Database
+
Permissions
+
Error handling
+
Loading states
+
Empty states
+
Audit
+
Tests
+
Documentation
```

---

# 73. ESTADO DEL DISEÑO

### DEFINIDO

* arquitectura general;
* stack;
* usuarios;
* roles;
* productos;
* proveedores;
* compras;
* ventas;
* pagos;
* inventario;
* mermas;
* gastos;
* caja;
* eventos;
* auditoría;
* métricas;
* reportes;
* seguridad;
* testing;
* deployment.

### PENDIENTE DE CONFIGURACIÓN

* dominio definitivo;
* número oficial de WhatsApp;
* datos reales del negocio;
* categorías definitivas;
* productos iniciales;
* costos iniciales;
* métodos de pago inicialmente habilitados;
* valores de stock mínimo;
* categorías de gastos definitivas;
* datos de la primera van;
* usuarios reales.

Estos datos no deben inventarse durante el desarrollo.

---

# 74. PRINCIPIO FINAL

AlDelicias no se debe desarrollar como una colección de pantallas.

Debe desarrollarse como un sistema conectado:

```text
PRODUCTOS
     ↓
COMPRAS
     ↓
INVENTARIO
     ↓
VENTAS
     ↓
PAGOS
     ↓
CAJA
     ↓
COSTOS
     ↓
MÉTRICAS
     ↓
REPORTES
     ↓
DECISIONES DEL NEGOCIO
```

Y paralelamente:

```text
WEB
 ↓
CLIENTES
 ↓
EVENTOS
 ↓
WHATSAPP
 ↓
OPORTUNIDADES COMERCIALES
```

La interfaz debe ocultar esta complejidad al usuario, pero la arquitectura debe conservar toda la trazabilidad.

**Este documento es la referencia técnica V1.0 para continuar el desarrollo.**
