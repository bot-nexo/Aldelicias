# AlDelicias — Reglas financieras cerradas V2

## Métodos de pago

El negocio inicia con:
- Efectivo
- Nequi
- Daviplata
- Transferencia bancaria

El administrador puede activar/desactivar cada método.

Solo efectivo afecta la caja física por defecto.

## Compras

Una compra puede ser:
- Contado
- Crédito

Las compras a crédito crean una cuenta por pagar al proveedor.

Una cuenta por pagar conserva:
- valor original
- valor pagado
- saldo
- fecha de vencimiento
- estado

Estados:
- UNPAID
- PARTIAL
- PAID

## Gastos

Se pueden registrar gastos como:
- pago colaborador
- alquiler de vehículo
- combustible
- mantenimiento
- insumos
- otros

Cada gasto puede registrar medio de pago.

## Caja

La caja tiene:
- apertura
- movimientos
- cierre
- valor esperado
- valor contado
- diferencia

La diferencia queda registrada para análisis.

## Costos indirectos

Se podrán definir componentes:
- bolsa
- servilleta
- salsa
- vaso
- tapa
- otros

Un producto puede consumir varios componentes.

Ejemplo:

Empanada:
- bolsa: 1
- servilleta: 1
- salsa: 1

El sistema calcula el costo indirecto unitario.

Los costos deben tener historial para no modificar la rentabilidad histórica.

## Rentabilidad

Se preparan tres niveles:

Ventas
→ costo directo del producto
→ costo indirecto
→ utilidad bruta

Y posteriormente:
→ gastos operativos asignables
→ utilidad estimada/neta.

La rentabilidad histórica se basa en snapshots, no en el precio/costo actual del producto.
