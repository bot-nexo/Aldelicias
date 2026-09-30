# AlDelicias — 004_business_rules_tests.md

## Pruebas críticas antes de producción

### Venta
- Venta con un producto.
- Venta con varios productos.
- Venta con varios métodos de pago.
- Pago inferior al total: debe fallar.
- Pago superior al total: debe fallar.
- Stock insuficiente: debe fallar sin dejar registros parciales.
- Producto inactivo: debe fallar.
- Precio histórico debe quedar en `sale_items`.
- Costo histórico debe quedar en `sale_items`.

### Inventario
- Compra aumenta stock.
- Venta disminuye stock.
- Merma disminuye stock.
- Anulación devuelve stock.
- Dos ventas concurrentes no pueden vender más unidades que las disponibles.

### Seguridad
- Usuario de negocio A no puede leer negocio B.
- Colaborador no puede modificar precios.
- Colaborador no puede administrar usuarios.
- Colaborador no puede alterar movimientos históricos directamente.
- Usuario no autenticado no puede acceder al panel.

### Caja
Pendiente de implementar como función transaccional después de definir:
- qué métodos afectan caja física;
- si Nequi/Daviplata/transferencias se concilian por separado;
- si cada jornada tiene una sola caja;
- quién puede abrir/cerrar;
- qué ocurre con diferencias.

### Compras
Pendiente de implementar como función transaccional después de definir:
- pago inmediato vs crédito;
- si la compra registra salida de caja;
- si una compra puede quedar parcialmente pagada.
