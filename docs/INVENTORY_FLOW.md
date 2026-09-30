# Flujo de inventario

## Alcance

El módulo de inventario consulta existencias y movimientos por producto y ubicación; permite registrar mermas a usuarios con permiso `WASTAGE` y ajustes manuales únicamente a ADMIN con permiso `INVENTORY_ADMIN`. Las entradas de compras y salidas de ventas siguen originándose en sus RPC existentes; este módulo no crea ni modifica esos procesos.

## Fuente de verdad y signo

`public.inventory_movements` es el libro histórico y la única fuente de verdad del stock. Cada fila representa el cambio firmado de unidades:

- Entrada: cantidad positiva, como `PURCHASE`, `TRANSFER_IN` o `RETURN`.
- Salida: cantidad negativa, como `SALE`, `WASTAGE` o `TRANSFER_OUT`.
- Ajuste: diferencia firmada entre conteo físico y stock registrado; positiva o negativa.
- Reversión: movimiento compensatorio con el signo opuesto al movimiento original.

El stock de un producto en una ubicación se reconstruye como la suma de `quantity` para ese `business_id`, producto y ubicación. No se mantiene una columna mutable de stock. Los productos con `track_inventory = false` no aparecen como existencias controladas.

## Flujos

### Consulta e historial

1. El servidor valida la sesión y el perfil activo.
2. El RPC de existencias solo devuelve productos y ubicaciones del negocio autenticado, con cantidad calculada desde movimientos.
3. El RPC de historial filtra por el mismo negocio y permite filtros por producto/ubicación y paginación.
4. La vista expone producto, ubicación, tipo, cantidad firmada, motivo o referencia de origen, autor y fecha/hora; no expone costos unitarios a colaboradores.

### Entrada y salida operacional

Las RPC existentes de compras y ventas continúan creando movimientos `PURCHASE` y `SALE`, respectivamente. El módulo de inventario solo los presenta; no registra compras ni ventas ni cambia sus RPC.

### Merma

1. ADMIN o COLLABORATOR con permiso `WASTAGE` selecciona producto y ubicación, ingresa cantidad y motivo.
2. La RPC existente `register_wastage` valida negocio, ubicación activa, seguimiento de inventario y permiso.
3. Bloquea la fila del producto, vuelve a calcular existencias y rechaza cantidad no positiva o stock insuficiente.
4. Inserta un movimiento `WASTAGE` con cantidad negativa, autor, motivo y fecha; registra auditoría.

### Ajuste manual

1. Solo ADMIN con permiso `INVENTORY_ADMIN` puede registrar una diferencia de conteo y un motivo.
2. La nueva RPC valida el producto y ubicación del negocio, bloquea la fila del producto y calcula el stock actual dentro de la transacción.
3. Rechaza delta cero y cualquier delta que deje el stock negativo.
4. Inserta `ADJUSTMENT` con delta firmado, autor, motivo y fecha; no modifica precios ni introduce valoración financiera; registra auditoría.
5. COLLABORATOR no puede invocar el ajuste ni escribir directamente en `inventory_movements`.

## Seguridad e integridad

- El `business_id` se deriva de la sesión en PostgreSQL, nunca de un valor confiado al formulario.
- Un trigger comprueba que negocio, producto, ubicación y autor de cada nuevo movimiento correspondan al mismo negocio; la migración aborta ante filas históricas inconsistentes en vez de reescribirlas.
- Se mantiene RLS de lectura administrativa sobre la tabla base. Los RPC de lectura autorizados devuelven únicamente columnas operativas y aplican el filtro de negocio explícitamente.
- Las operaciones críticas usan transacciones PostgreSQL. Las RPC existentes de compra, venta y merma, y el nuevo ajuste, bloquean la fila del producto; así se serializan sus cambios por producto y se vuelve a comprobar stock bajo el bloqueo.
- Los movimientos son append-only: no se editan ni eliminan; una corrección futura debe registrarse como movimiento compensatorio autorizado.
- No se cambia el esquema de productos, ventas, compras, caja ni finanzas; solo se consume la relación actual para calcular existencias.

## Migración y pruebas

La inspección encontró que el esquema ya tiene `inventory_movements`, tipos de movimiento, cantidades firmadas en los RPC activos e índice de producto/ubicación. Faltan el límite de negocio entre las referencias, inmutabilidad explícita, RPC de ajuste, RPCs de lectura operativa e interfaz. Se resolverán de forma incremental en una migración nueva, sin editar migraciones históricas.

Las pruebas de base de datos deben cubrir permisos por rol, aislamiento multi-business, producto/ubicación/autor incompatibles, stock insuficiente, delta negativo, movimientos append-only, suma firmada e intercalado concurrente de merma/ajuste con salidas.
