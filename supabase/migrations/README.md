# Migraciones Supabase

Este directorio establece el destino para futuras migraciones incrementales de la aplicación.

Los archivos `001_initial_schema.sql`, `002_rls_and_security.sql`, `003_business_functions.sql` y `005_finance_inventory_v2.sql` siguen en la raíz y no se han movido, copiado, renumerado ni modificado. Antes de adoptar Supabase CLI, confirmar qué scripts se aplicaron en cada entorno y preparar una estrategia de baseline sin volver a ejecutar DDL existente.

`004_business_rules_tests.md` es una matriz documental, no una migración SQL. Las reglas pendientes de caja/compras continúan pendientes; este bootstrap no agrega funciones de negocio ni seeds.
