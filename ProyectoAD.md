
# ALDELICIAS

## Documento Maestro del Proyecto — V1.0

**Tipo:** Plataforma web + sistema administrativo
**Estado:** Diseño y arquitectura
**Objetivo:** Crear la plataforma digital integral de AlDelicias
**Usuarios:** Clientes, administrador y colaboradores
**Arquitectura:** Web pública + aplicación administrativa + backend + base de datos + almacenamiento multimedia

---

# 1. VISIÓN DEL PROYECTO

AlDelicias es un negocio gastronómico móvil orientado principalmente a oficinistas.

Actualmente opera mediante una van que ofrece productos como:

* Empanadas
* Buñuelos
* Pasteles
* Almojábanas
* Bebidas calientes
* Bebidas frías
* Otros productos que puedan incorporarse posteriormente

La plataforma tendrá dos grandes componentes:

### A. Web pública

Orientada al cliente.

Su función será:

* Presentar la marca.
* Mostrar productos.
* Mostrar precios.
* Mostrar fotografías.
* Presentar servicios para eventos.
* Capturar solicitudes comerciales.
* Redirigir conversaciones a WhatsApp.

**NO será una tienda online tradicional.**

No habrá checkout ni domicilios en esta primera versión.

---

### B. Sistema administrativo

Orientado al propietario y colaboradores.

Permitirá:

* Registrar ventas.
* Registrar compras.
* Controlar inventario.
* Administrar productos.
* Administrar proveedores.
* Registrar gastos.
* Controlar caja.
* Registrar mermas.
* Administrar eventos.
* Analizar rentabilidad.
* Consultar métricas.
* Generar reportes.
* Gestionar usuarios.
* Gestionar vehículos.

---

# 2. PRINCIPIO FUNDAMENTAL

Todo el proyecto debe cumplir esta regla:

> **Una operación debe registrarse una sola vez y producir automáticamente todas las consecuencias correspondientes.**

Ejemplo:

Registrar una venta:

```text
VENTA
 ↓
sale
 ↓
sale_items
 ↓
payment
 ↓
inventory movement
 ↓
cost of sale
 ↓
cash movement
 ↓
dashboard
 ↓
reports
```

El usuario no debe registrar manualmente la misma información en cinco módulos.

---

# 3. OBJETIVOS

## Objetivo comercial

Crear una presencia digital profesional que:

* aumente la percepción de valor de la marca;
* facilite mostrar productos;
* genere contactos empresariales;
* permita presentar AlDelicias profesionalmente.

## Objetivo operativo

Digitalizar la operación diaria.

## Objetivo administrativo

Dar al propietario información confiable para tomar decisiones.

## Objetivo financiero

Permitir conocer:

* ventas;
* costos;
* gastos;
* margen;
* resultado;
* caja;
* comportamiento histórico.

---

# 4. USUARIOS

## Cliente público

No requiere cuenta.

Puede:

* navegar;
* consultar productos;
* consultar información;
* solicitar eventos;
* abrir WhatsApp.

---

## Administrador

Acceso completo.

Puede:

* administrar usuarios;
* productos;
* proveedores;
* compras;
* ventas;
* inventario;
* caja;
* gastos;
* eventos;
* reportes;
* configuración.

---

## Colaborador

Acceso operativo.

Inicialmente podrá:

* registrar ventas;
* consultar productos;
* consultar precios;
* consultar inventario necesario para operar;
* participar en apertura/cierre de caja según permisos.

No podrá:

* modificar costos;
* consultar información financiera sensible;
* modificar configuración;
* administrar usuarios;
* eliminar información;
* modificar proveedores.

---

# 5. WEB PÚBLICA

## Rutas

```text
/
 /productos
 /productos/[slug]
 /eventos
 /contacto
```

Podremos agregar posteriormente:

```text
/nosotros
/blog
```

sin modificar la arquitectura principal.

---

# 6. HOME

La página principal debe transmitir:

### “Más que un antojo, es tu mejor pausa.”

No se utilizará una plantilla genérica.

Debe tener:

* hero visual;
* producto protagonista;
* narrativa de marca;
* categorías;
* productos destacados;
* propuesta para empresas;
* CTA WhatsApp;
* información de contacto;
* redes sociales.

---

# 7. CATÁLOGO

La web permitirá:

* navegar categorías;
* consultar productos;
* consultar precios;
* consultar descripción;
* visualizar fotografías;
* visualizar disponibilidad.

No tendrá carrito.

No tendrá checkout.

No procesará domicilios.

---

# 8. PRODUCTO PÚBLICO

Cada producto tendrá:

```text
Nombre
Descripción corta
Descripción
Precio
Categoría
Fotografía principal
Galería
Disponibilidad
```

URL:

```text
/productos/[slug]
```

Ejemplo:

```text
/productos/empanada-de-carne
```

---

# 9. EVENTOS

La web tendrá una sección específica:

### Eventos empresariales

Tipos posibles:

* reuniones;
* celebraciones;
* coffee breaks;
* eventos corporativos;
* desayunos;
* otros.

Formulario:

```text
Nombre
Empresa
WhatsApp
Correo
Fecha
Número de personas
Tipo de evento
Productos de interés
Mensaje
```

Al enviarlo:

```text
Formulario
   ↓
Guardar lead
   ↓
Abrir WhatsApp
```

---

# 10. WHATSAPP

WhatsApp será el principal canal comercial.

El sistema podrá generar mensajes prellenados.

Ejemplo conceptual:

```text
Hola, soy Carlos de Empresa XYZ.

Estoy interesado en un servicio para:
40 personas

Fecha:
18 de octubre

Me interesan:
Empanadas
Buñuelos
Bebidas
```

El administrador podrá cambiar posteriormente el número de WhatsApp desde configuración.

---

# 11. ADMINISTRACIÓN

Ruta:

```text
/admin
```

La aplicación administrativa tendrá navegación lateral.

```text
DASHBOARD

OPERACIÓN
  Ventas
  Compras
  Inventario
  Mermas
  Caja

NEGOCIO
  Productos
  Proveedores
  Gastos
  Eventos

ANÁLISIS
  Métricas
  Reportes

CONFIGURACIÓN
  Usuarios
  Vehículos
  Métodos de pago
  Categorías
  Configuración
```

---

# 12. DASHBOARD

Debe responder:

> ¿Cómo está funcionando AlDelicias?

Indicadores:

```text
Ventas
Costos
Gastos
Caja
Resultado operativo
```

Filtros:

```text
Hoy
Ayer
7 días
30 días
Este mes
Mes anterior
Personalizado
```

---

# 13. MÉTRICAS

## Ventas

* ventas totales;
* número de ventas;
* ticket promedio;
* unidades;
* ventas por producto;
* ventas por categoría;
* ventas por método de pago;
* ventas por vehículo;
* ventas por usuario;
* evolución temporal.

## Costos

* costo de ventas;
* costo unitario;
* costo promedio;
* margen;
* margen por producto;
* evolución de costos.

## Gastos

* gastos totales;
* gastos por categoría;
* gastos por período;
* gastos por vehículo.

## Inventario

* stock;
* stock mínimo;
* agotados;
* rotación;
* mermas;
* valor del inventario.

## Eventos

* nuevos;
* contactados;
* cotización;
* confirmados;
* realizados;
* perdidos.

---

# 14. DIFERENCIA CRÍTICA

El sistema debe diferenciar:

### Ventas

Dinero generado.

### Costo de ventas

Costo de los productos efectivamente vendidos.

### Gastos

Costos operativos.

### Inventario

Productos todavía existentes.

### Caja

Dinero disponible/movimientos reales.

No se deben mezclar estas cinco cosas.

---

# 15. FÓRMULA PRINCIPAL

```text
VENTAS
-
COSTO DE VENTAS
=
MARGEN BRUTO

MARGEN BRUTO
-
GASTOS OPERATIVOS
=
RESULTADO OPERATIVO
```

Caja se calcula independientemente mediante movimientos financieros.

---

# 16. VENTAS

Ruta:

```text
/admin/ventas
```

Funciones:

* nueva venta;
* historial;
* búsqueda;
* filtros;
* detalle;
* anulación.

---

# 17. NUEVA VENTA

Flujo:

```text
Nueva venta
 ↓
Buscar producto
 ↓
Seleccionar
 ↓
Cantidad
 ↓
Carrito
 ↓
Método de pago
 ↓
Confirmar
 ↓
Venta registrada
 ↓
Nueva venta
```

Debe ser extremadamente rápida.

---

# 18. VENTA

Una venta tendrá:

```text
ID
Número
Fecha
Hora
Usuario
Vehículo
Ubicación
Productos
Cantidades
Precios
Costo
Descuento
Total
Método(s) de pago
Estado
```

---

# 19. REGLA DE VENTAS

Las ventas **no se eliminan**.

Si existe un error:

### ANULAR VENTA

Debe solicitar:

```text
Motivo
```

Y registrar auditoría.

---

# 20. HISTORIAL

Cada venta conserva:

* nombre del producto al momento de la venta;
* precio al momento de la venta;
* costo al momento de la venta.

Esto evita alterar información histórica.

---

# 21. COMPRAS

Ruta:

```text
/admin/compras
```

Una compra contiene:

```text
Proveedor
Fecha
Usuario
Ubicación
Referencia
Productos
Cantidades
Costo unitario
Total
Estado
```

---

# 22. COMPRAS → INVENTARIO

Al registrar una compra:

```text
COMPRA
 ↓
purchase
 ↓
purchase_items
 ↓
inventory_movement
 ↓
STOCK +
```

No se actualizará el stock manualmente.

---

# 23. PROVEEDORES

Cada proveedor tendrá:

```text
Nombre
Contacto
Teléfono
WhatsApp
Email
Dirección
Notas
Estado
```

Y podremos consultar:

### Historial de compras

### Productos suministrados

### Últimos costos

---

# 24. PRODUCTOS

Cada producto tendrá:

```text
ID
Nombre
Slug
Categoría
Descripción
Precio
SKU
Estado
Destacado
Orden
Control de inventario
Stock mínimo
```

Estados:

```text
DRAFT
PUBLISHED
HIDDEN
OUT_OF_STOCK
```

---

# 25. IMÁGENES

Cada producto podrá tener varias fotografías.

El administrador podrá:

* subir;
* eliminar;
* reordenar;
* elegir portada.

El sistema optimizará automáticamente:

* tamaño;
* formato;
* thumbnails;
* versiones responsive.

Las imágenes se almacenarán en Storage/CDN, no directamente dentro de PostgreSQL.

---

# 26. INVENTARIO

El inventario funcionará mediante movimientos.

Tipos:

```text
PURCHASE
SALE
WASTAGE
ADJUSTMENT
TRANSFER
RETURN
```

Nunca dependeremos únicamente de:

```text stock = 72
```

Sino de la trazabilidad:

```text
+100 compra
-20 venta
-5 venta
-3 merma
```

---

# 27. MERMAS

Se registrará:

```text
Producto
Cantidad
Costo
Motivo
Vehículo/ubicación
Usuario
Fecha
Observación
```

Motivos configurables.

---

# 28. INSUMOS Y COMPONENTES

El sistema también manejará:

* bolsas;
* servilletas;
* salsas;
* vasos;
* tapas;
* pitillos;
* cajas;
* otros.

Cada uno puede tener:

```text
Costo
Unidad
Stock
Stock mínimo
```

---

# 29. COSTO REAL ESTIMADO

Ejemplo:

```text
Producto: Empanada

Costo proveedor       $2.200
Bolsa                    $120
Servilleta                $30
Salsa                     $80
Otros                     $40
----------------------------
Costo real estimado    $2.470
```

Precio:

```text
$4.000
```

Margen estimado:

```text
$1.530
```

---

# 30. GASTOS

Categorías iniciales:

```text
Personal
Combustible
Vehículo
Alquiler
Empaques
Publicidad
Mantenimiento
Otros
```

Cada gasto tendrá:

```text
Categoría
Descripción
Monto
Fecha
Usuario
Vehículo
Método de pago
Comprobante
Notas
```

---

# 31. CAJA

La caja será independiente del resultado contable/operativo.

Tendrá:

### Apertura

```text
Monto inicial
Usuario
Fecha/hora
Ubicación
```

### Movimientos

```text
Ventas
Gastos
Retiros
Depósitos
Ajustes
```

### Cierre

```text
Caja esperada
Caja contada
Diferencia
Motivo
Usuario
```

---

# 32. DIFERENCIA DE CAJA

Si:

```text
Esperado: $280.000
Contado:   $265.000
```

El sistema muestra:

> Diferencia: -$15.000

Y exige explicación.

No se modifica silenciosamente.

---

# 33. MÉTODOS DE PAGO

El administrador podrá activar/desactivar:

* efectivo;
* Nequi;
* Daviplata;
* transferencia;
* tarjeta;
* otros.

La base soportará **una venta con múltiples métodos de pago**, aunque inicialmente la interfaz pueda simplificar el flujo.

---

# 34. EVENTOS / CRM

Estados:

```text
NEW
CONTACTED
QUOTE
CONFIRMED
COMPLETED
LOST
```

Cada lead conservará:

```text
Nombre
Empresa
WhatsApp
Correo
Fecha evento
Personas
Tipo
Productos
Mensaje
Estado
Origen
```

---

# 35. USUARIOS

Cada colaborador tendrá:

```text
Nombre
Correo
Teléfono
Rol
Estado
Fecha creación
Último acceso
```

No se compartirán cuentas.

Cada persona tendrá su usuario.

Esto permite:

> saber quién hizo qué.

---

# 36. AUDITORÍA

Acciones sensibles generan:

```text
Usuario
Acción
Entidad
ID
Valor anterior
Valor nuevo
Fecha
Hora
```

Ejemplo:

```text
Carlos
Cambió precio
Empanada
$3.500 → $4.000
30/09/2026 09:32
```

---

# 37. VEHÍCULOS

Aunque actualmente exista una sola van:

```text
Van 01
```

la arquitectura soportará:

```text
Van 01
Van 02
Van 03
```

Las operaciones podrán relacionarse con un vehículo.

Esto permitirá posteriormente:

### Ventas por vehículo

### Gastos por vehículo

### Inventario por vehículo

---

# 38. STACK TECNOLÓGICO PROPUESTO

## Frontend

### Next.js + React + TypeScript

Razones:

* excelente rendimiento;
* SSR/SSG;
* SEO;
* routing;
* optimización de imágenes;
* arquitectura escalable;
* TypeScript;
* buen ecosistema.

---

# 39. UI

### Tailwind CSS

Para construir el sistema visual rápidamente y mantener consistencia.

Pero:

> **No se utilizará una plantilla visual prefabricada.**

Tailwind será solamente la herramienta de construcción.

---

# 40. Componentes

Podemos utilizar una base accesible de componentes tipo:

### shadcn/ui

Pero únicamente como infraestructura.

El diseño final será propio de AlDelicias.

---

# 41. Backend

Inicialmente:

### Next.js Server Actions / Route Handlers

para operaciones propias de la aplicación.

No necesitamos crear un backend separado innecesariamente si la arquitectura no lo requiere.

Esto reduce complejidad.

---

# 42. Base de datos

### PostgreSQL

Será la base de datos principal.

Y recomiendo:

### Supabase

para:

* PostgreSQL;
* autenticación;
* Storage;
* Row Level Security;
* APIs;
* infraestructura administrada.

---

# 43. Autenticación

### Supabase Auth

Con:

* email/password;
* recuperación;
* sesiones;
* roles propios.

Más adelante podríamos incorporar:

* magic links;
* OAuth;
* MFA.

No son necesarios para el MVP.

---

# 44. Storage

Las fotografías:

```text
Supabase Storage
```

o un almacenamiento compatible con CDN.

Estructura:

```text
products/
  product-id/
    original
    optimized
    thumbnails
```

La base de datos solamente guarda referencias.

---

# 45. CDN

Las imágenes públicas deben servirse mediante CDN.

El navegador nunca debería descargar una fotografía original gigantesca si solamente necesita una miniatura.

---

# 46. Hosting

### Vercel

Para la aplicación Next.js.

Arquitectura:

```text
GitHub
   ↓
Vercel
   ↓
Next.js
   ↓
Supabase
```

---

# 47. Código fuente

### GitHub

Ramas:

```text
main
develop
feature/*
fix/*
```

Regla:

**No se trabaja directamente sobre `main`.**

---

# 48. Ambientes

Tendremos:

```text
LOCAL
 ↓
DEVELOPMENT
 ↓
STAGING
 ↓
PRODUCTION
```

En un proyecto pequeño podemos simplificar infraestructura, pero conceptualmente estos ambientes deben existir.

---

# 49. Variables de entorno

Nunca se colocarán secretos directamente en el código.

Ejemplo:

```text
NEXT_PUBLIC_SUPABASE_URL
NEXT_PUBLIC_SUPABASE_ANON_KEY
SUPABASE_SERVICE_ROLE_KEY
```

Las claves privadas solamente existirán del lado servidor.

---

# 50. Seguridad

Obligatorio:

* HTTPS;
* autenticación;
* autorización;
* RLS;
* validación server-side;
* sanitización;
* protección de endpoints;
* control de roles;
* auditoría;
* manejo seguro de archivos.

Nunca confiar únicamente en validaciones del frontend.

---

# 51. VALIDACIÓN

Recomiendo:

### Zod

Para validar:

* formularios;
* API;
* Server Actions;
* datos provenientes del cliente.

Ejemplo conceptual:

```text
precio
→ debe ser número
→ mayor o igual a 0

cantidad
→ entero
→ mayor que 0
```

---

# 52. ORM / ACCESO A DATOS

Podemos utilizar:

### Supabase JS

para operaciones normales.

Para consultas complejas también podemos usar SQL/PostgreSQL directamente mediante funciones/queries bien controladas.

No quiero agregar un ORM pesado sin necesidad.

---

# 53. REPORTES

Los reportes no deberían recalcular todo desde cero en el frontend.

La lógica importante estará en PostgreSQL/backend.

Ejemplo:

```text
Ventas del mes
↓
consulta SQL
↓
agregación
↓
respuesta
↓
gráfico
```

---

# 54. REPORTES PRINCIPALES

### Ventas

Por:

* día;
* semana;
* mes;
* rango;
* producto;
* categoría;
* usuario;
* vehículo;
* método de pago.

### Gastos

Por:

* categoría;
* período;
* vehículo.

### Inventario

* movimientos;
* mermas;
* stock;
* valor.

### Rentabilidad

* producto;
* categoría;
* período.

---

# 55. RESPONSIVE

## Cliente

Mobile first.

## Administración

Desktop first.

Pero:

### Nueva venta

Debe funcionar perfectamente en móvil/tablet.

Porque es una pantalla operacional.

---

# 56. ACCESIBILIDAD

Desde el comienzo:

* navegación por teclado;
* contraste;
* labels;
* focus states;
* tamaños táctiles adecuados;
* textos alternativos;
* semántica HTML;
* lectores de pantalla.

No se agregará al final.

---

# 57. SEO

La web pública tendrá:

* metadata;
* Open Graph;
* sitemap;
* robots;
* URLs amigables;
* títulos;
* descriptions;
* datos estructurados cuando corresponda.

---

# 58. PERFORMANCE

Objetivos:

### Web pública

Prioridad máxima.

* imágenes optimizadas;
* lazy loading;
* fuentes optimizadas;
* JavaScript mínimo;
* Server Components donde sea conveniente;
* caching;
* CDN.

### Admin

Prioridad:

* velocidad de interacción;
* tablas eficientes;
* consultas paginadas;
* filtros server-side.

---

# 59. IMÁGENES DE PRODUCTOS

Proceso:

```text
Administrador sube foto
        ↓
Validación
        ↓
Storage
        ↓
Optimización
        ↓
Generación de tamaños
        ↓
CDN
        ↓
Web
```

Formatos modernos cuando sean compatibles:

### WebP / AVIF

manteniendo fallback adecuado.

---

# 60. MANEJO DE IMÁGENES

Nunca guardar:

```text
base64
```

dentro de PostgreSQL.

La base de datos guarda:

```text
storage_path
```

y metadata.

---

# 61. ESTRUCTURA DE PROYECTO

Una estructura inicial podría ser:

```text
aldelicias/
│
├── app/
│   ├── (public)/
│   │   ├── page.tsx
│   │   ├── productos/
│   │   ├── eventos/
│   │   └── contacto/
│   │
│   ├── (admin)/
│   │   └── admin/
│   │       ├── dashboard/
│   │       ├── ventas/
│   │       ├── compras/
│   │       ├── inventario/
│   │       ├── caja/
│   │       ├── productos/
│   │       ├── proveedores/
│   │       ├── gastos/
│   │       ├── eventos/
│   │       ├── reportes/
│   │       └── configuracion/
│   │
│   └── api/
│
├── components/
│   ├── ui/
│   ├── public/
│   ├── admin/
│   ├── charts/
│   └── forms/
│
├── lib/
│   ├── auth/
│   ├── db/
│   ├── validations/
│   ├── calculations/
│   ├── permissions/
│   └── utils/
│
├── types/
│
├── hooks/
│
├── public/
│
├── supabase/
│   ├── migrations/
│   ├── seed/
│   └── functions/
│
├── tests/
│
└── docs/
```

---

# 62. `lib/calculations`

Quiero separar expresamente las reglas de negocio.

Ejemplo:

```text
calculateSaleTotal()
calculateProductCost()
calculateGrossMargin()
calculateOperatingResult()
calculateExpectedCash()
calculateInventoryValue()
```

Así la lógica financiera no queda enterrada dentro de componentes React.

---

# 63. `lib/permissions`

También estará centralizado:

```text
canCreateSale()
canCancelSale()
canViewCosts()
canManageProducts()
canManageUsers()
canCloseCash()
```

Esto reduce errores de permisos.

---

# 64. MIGRACIONES

La base de datos se construirá mediante migraciones.

Ejemplo:

```text
001_initial_schema.sql
002_roles.sql
003_products.sql
004_sales.sql
005_inventory.sql
006_purchases.sql
...
```

Nunca dependeremos de:

> “el programador creó la tabla manualmente en Supabase”.

Todo cambio estructural debe quedar versionado.

---

# 65. SEEDS

Tendremos datos iniciales controlados:

```text
roles
expense_categories
payment_methods
wastage_reasons
event_statuses
```

Esto permite levantar el proyecto desde cero.

---

# 66. TESTING

No quiero que las pruebas se hagan únicamente haciendo clic manualmente.

Tendremos tres niveles.

### Unit tests

Para cálculos:

```text
Costo
Margen
Total
Caja
```

### Integration tests

Para:

```text
Venta → Inventario
Compra → Inventario
Gasto → Caja
```

### E2E

Para flujos completos:

```text
Login
→ Venta
→ Pago
→ Confirmación
→ Inventario
```

---

# 67. CASO DE PRUEBA CRÍTICO

Crear venta:

```text
2 empanadas
$4.000
```

Debe:

```text
Venta +$8.000
Inventario -2
Costo correspondiente
Pago registrado
Caja actualizada
Dashboard actualizado
Auditoría registrada
```

Si alguna de esas cosas falla, el test falla.

---

# 68. SEGUNDO CASO CRÍTICO

Registrar compra:

```text
100 empanadas
$2.200
```

Debe:

```text
Compra registrada
Inventario +100
Proveedor actualizado
Costo registrado
Historial creado
```

---

# 69. TERCER CASO

Anular venta.

Debe:

```text
Venta → ANULADA

Inventario → movimiento compensatorio

Caja → movimiento compensatorio

Métricas → excluir venta anulada

Auditoría → registrar acción
```

No se borra la venta.

---

# 70. CUARTO CASO

Cambiar precio.

```text
Antes:
$4.000

Después:
$4.500
```

Las ventas anteriores deben continuar mostrando:

**$4.000**

Las nuevas:

**$4.500**

---

# 71. QUINTO CASO

Cambiar costo.

Las ventas históricas conservan:

**su costo snapshot.**

Esto protege todos los reportes históricos.

---

# 72. FLUJO COMPLETO DEL NEGOCIO

Esta es una de las partes que quiero que Copilot tenga siempre presente:

```text
                 PRODUCTO
                    │
              ┌─────┴─────┐
              │           │
           COMPRA       PRECIO
              │           │
              ▼           │
          INVENTARIO      │
              │           │
              └─────┬─────┘
                    │
                  VENTA
                    │
          ┌─────────┼─────────┐
          ▼         ▼         ▼
       DINERO    INVENTARIO  COSTO
          │         │         │
          └─────────┼─────────┘
                    ▼
                 MÉTRICAS
                    │
                    ▼
                DASHBOARD
```

Paralelamente:

```text
GASTOS
  ↓
CAJA
  ↓
RESULTADO

EVENTOS
  ↓
LEAD
  ↓
WHATSAPP
  ↓
SEGUIMIENTO
```

---

# 73. FLUJO DEL CLIENTE

```text
Instagram / Google / QR / recomendación
                  ↓
             WEB ALDELICIAS
                  ↓
          Explora productos
                  ↓
           Conoce la marca
                  ↓
          Quiere hacer evento
                  ↓
          Formulario evento
                  ↓
             Lead guardado
                  ↓
              WhatsApp
                  ↓
              Negociación
                  ↓
             Confirmación
```

---

# 74. FLUJO DEL COLABORADOR

```text
LOGIN
 ↓
ABRIR CAJA
 ↓
NUEVA VENTA
 ↓
SELECCIONAR PRODUCTOS
 ↓
MÉTODO DE PAGO
 ↓
CONFIRMAR
 ↓
INVENTARIO ACTUALIZADO
 ↓
SIGUIENTE VENTA
 ↓
CIERRE
```

---

# 75. FLUJO DEL ADMINISTRADOR

```text
LOGIN
 ↓
DASHBOARD
 ↓
ANALIZA
 ↓
Detecta problema
 ↓
Entra al módulo
 ↓
Toma decisión
 ↓
Sistema registra cambio
 ↓
Dashboard actualizado
```

---

# 76. ROADMAP DEFINITIVO

## FASE 0 — Documentación

* requisitos;
* reglas;
* arquitectura;
* UX;
* base de datos;
* stack.

### Resultado:

**Especificación aprobada.**

---

## FASE 1 — Setup

* GitHub;
* Next.js;
* TypeScript;
* Tailwind;
* Supabase;
* Vercel;
* ambientes;
* variables;
* lint;
* testing.

---

## FASE 2 — Design System

* colores;
* tipografías;
* logo;
* favicon;
* botones;
* inputs;
* cards;
* tablas;
* estados;
* responsive.

---

## FASE 3 — Base de datos

* schema;
* enums;
* relaciones;
* índices;
* RLS;
* migraciones;
* seeds.

---

## FASE 4 — Autenticación

* login;
* sesión;
* roles;
* permisos;
* protección de rutas.

---

## FASE 5 — Web pública

* Home;
* catálogo;
* producto;
* eventos;
* contacto;
* WhatsApp;
* SEO;
* responsive.

---

## FASE 6 — Productos

* CRUD;
* categorías;
* precios;
* imágenes;
* publicación.

---

## FASE 7 — Compras y proveedores

* proveedores;
* compras;
* costos;
* historial.

---

## FASE 8 — Inventario

* stock;
* movimientos;
* mermas;
* ajustes;
* transferencias.

---

## FASE 9 — Ventas

* nueva venta;
* carrito;
* pagos;
* historial;
* anulación.

---

## FASE 10 — Caja

* apertura;
* movimientos;
* cierre;
* diferencias.

---

## FASE 11 — Gastos

* categorías;
* gastos;
* comprobantes;
* reportes.

---

## FASE 12 — Dashboard

* KPIs;
* gráficos;
* filtros;
* rentabilidad;
* alertas.

---

## FASE 13 — Eventos / CRM

* leads;
* estados;
* seguimiento;
* WhatsApp.

---

## FASE 14 — Reportes

* ventas;
* costos;
* gastos;
* inventario;
* rentabilidad;
* eventos.

---

## FASE 15 — QA

* unit tests;
* integration;
* E2E;
* seguridad;
* responsive;
* performance.

---

## FASE 16 — Producción

```text
Build
 ↓
Deploy
 ↓
Dominio
 ↓
SSL
 ↓
Variables
 ↓
Database production
 ↓
Storage
 ↓
Backups
 ↓
Monitoring
 ↓
Launch
```

---

# 77. DEFINICIÓN DE “TERMINADO”

Una funcionalidad no se considera terminada porque:

> “el botón funciona”.

Debe cumplir:

```text
UI
+
UX
+
Validación
+
Backend
+
Base de datos
+
Permisos
+
Auditoría
+
Manejo de errores
+
Responsive
+
Testing
```

Por ejemplo:

### “Crear venta” terminada significa:

* interfaz;
* validación;
* autorización;
* transacción backend;
* registro venta;
* items;
* pagos;
* inventario;
* costo;
* caja;
* auditoría;
* feedback;
* pruebas.

---

# 78. REGLAS QUE COPILOT DEBE RESPETAR

Te recomiendo que este bloque esté literalmente en un archivo:

```text
/docs/AI_RULES.md
```

### Reglas críticas

1. No eliminar ventas.
2. No eliminar compras.
3. No modificar históricamente una transacción.
4. Toda operación financiera debe ser auditable.
5. Toda modificación sensible debe registrar auditoría.
6. No confiar en validaciones únicamente del frontend.
7. Toda autorización debe validarse en servidor.
8. Nunca exponer secretos al cliente.
9. No almacenar imágenes como base64 en PostgreSQL.
10. No duplicar lógica financiera en múltiples componentes.
11. Las reglas de negocio deben vivir en `lib/calculations` o backend.
12. Los cambios de base de datos deben utilizar migraciones.
13. Los datos históricos deben conservar snapshots cuando corresponda.
14. Una venta afecta inventario mediante movimientos.
15. Una compra afecta inventario mediante movimientos.
16. Una merma afecta inventario mediante movimientos.
17. Las ventas anuladas no se consideran ventas válidas en métricas.
18. Caja y resultado operativo son conceptos diferentes.
19. No crear funcionalidades fuera del alcance sin documentarlas.
20. Antes de modificar arquitectura existente, revisar documentación y dependencias.

---

# 79. DOCUMENTACIÓN DEL REPOSITORIO

Quiero que el proyecto tenga:

```text
/docs
│
├── PROJECT.md
├── ARCHITECTURE.md
├── DATABASE.md
├── BUSINESS_RULES.md
├── UX.md
├── DESIGN_SYSTEM.md
├── SECURITY.md
├── API.md
├── TESTING.md
├── DEPLOYMENT.md
├── AI_RULES.md
└── CHANGELOG.md
```

Así cualquier desarrollador nuevo puede entrar y entender el proyecto.

---

# 80. FUENTE ÚNICA DE VERDAD

Esta regla es especialmente importante para trabajar con Copilot:

> **La documentación del repositorio y el código deben mantenerse sincronizados.**

Si se cambia:

### Base de datos

→ actualizar `DATABASE.md`.

### Regla de negocio

→ actualizar `BUSINESS_RULES.md`.

### UI

→ actualizar `UX.md` o `DESIGN_SYSTEM.md`.

### Arquitectura

→ actualizar `ARCHITECTURE.md`.

Así evitamos el clásico problema:

> “La documentación dice una cosa pero el código hace otra.”

---

# 81. STACK RESUMIDO

| Capa             | Tecnología              |
| ---------------- | ----------------------- |
| Frontend         | Next.js                 |
| Lenguaje         | TypeScript              |
| UI               | React                   |
| Styling          | Tailwind CSS            |
| Componentes base | shadcn/ui               |
| Backend          | Next.js Server / API    |
| Database         | PostgreSQL              |
| Backend platform | Supabase                |
| Auth             | Supabase Auth           |
| Storage          | Supabase Storage        |
| Hosting          | Vercel                  |
| Código           | GitHub                  |
| Validación       | Zod                     |
| Testing          | Vitest + Playwright     |
| CDN              | Vercel/CDN + Storage    |
| Analytics        | Por definir             |
| WhatsApp         | Deep links inicialmente |

---

# 82. ARQUITECTURA FINAL

```text
                         CLIENTE
                           │
                           ▼
                     ALDELICIAS WEB
                           │
                    Next.js / React
                           │
              ┌────────────┴────────────┐
              │                         │
         WEB PÚBLICA                 ADMIN
              │                         │
              └────────────┬────────────┘
                           │
                    SERVER / API
                           │
              ┌────────────┴────────────┐
              │                         │
          Supabase                  Vercel
              │
       ┌──────┼────────┐
       │      │        │
    Postgres Auth    Storage
       │
       ├── Products
       ├── Sales
       ├── Purchases
       ├── Inventory
       ├── Expenses
       ├── Cash
       ├── Events
       ├── Users
       └── Audit
```

---

# 83. ESTADO ACTUAL DEL PROYECTO

Con todo lo que acabamos de definir, ya tenemos:

### ✅ Concepto de producto

### ✅ Alcance

### ✅ Usuarios

### ✅ Roles

### ✅ Web pública

### ✅ Administración

### ✅ UX principal

### ✅ Wireframes iniciales

### ✅ Modelo de negocio

### ✅ Reglas financieras

### ✅ Inventario

### ✅ Compras

### ✅ Ventas

### ✅ Caja

### ✅ Gastos

### ✅ Mermas

### ✅ Proveedores

### ✅ Eventos

### ✅ Métricas

### ✅ Arquitectura de software

### ✅ Stack

### ✅ Seguridad

### ✅ Testing

### ✅ Deployment

### ✅ Roadmap

### ✅ Reglas para Copilot

### ✅ Estructura de documentación

Lo que **todavía no debemos inventar ni dar por cerrado** son detalles como credenciales, dominio definitivo, proveedor final de WhatsApp/API, valores iniciales de productos, categorías definitivas y algunos parámetros operativos. Esos se incorporarán como configuración cuando corresponda.

---

# 84. EL ORDEN CORRECTO A PARTIR DE AQUÍ

Yo no saltaría directamente a programar.

El orden profesional sería:

```text
DOCUMENTO MAESTRO
       ↓
DESIGN SYSTEM
       ↓
ERD DEFINITIVO
       ↓
MIGRACIONES SQL
       ↓
SETUP DEL PROYECTO
       ↓
AUTH + ROLES
       ↓
COMPONENTES BASE
       ↓
WEB PÚBLICA
       ↓
PRODUCTOS
       ↓
COMPRAS
       ↓
INVENTARIO
       ↓
VENTAS
       ↓
CAJA
       ↓
GASTOS
       ↓
DASHBOARD
       ↓
EVENTOS
       ↓
REPORTES
       ↓
TESTS
       ↓
QA
       ↓
PRODUCCIÓN
```

**Y aquí está la parte importante:** no vamos a dejar que Copilot vaya “inventando” el proyecto módulo por módulo. Este documento debe convertirse en el **contrato técnico del proyecto**. Cada vez que Copilot vaya a construir algo, deberá saber **qué problema resuelve, en qué módulo está, qué tablas utiliza, qué reglas debe respetar, qué permisos tiene y qué otros módulos puede afectar**.

El siguiente paso lógico es convertir todo esto en los artefactos técnicos que realmente usará el programador: **ERD completo + diccionario de datos + relaciones + enums + reglas de negocio + estructura inicial de carpetas + migraciones PostgreSQL**. Esa será la siguiente capa antes de escribir el primer módulo real.
