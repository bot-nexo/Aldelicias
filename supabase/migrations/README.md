# Migraciones Supabase

Este directorio establece el destino para futuras migraciones incrementales de la aplicación.

Los archivos `001_initial_schema.sql`, `002_rls_and_security.sql`, `003_business_functions.sql` y `005_finance_inventory_v2.sql` siguen en la raíz y no se han movido, copiado, renumerado ni modificado. Antes de adoptar Supabase CLI, confirmar qué scripts se aplicaron en cada entorno y preparar una estrategia de baseline sin volver a ejecutar DDL existente.

`006_architecture_hardening.sql`, `007_category_management_rls.sql` y `008_remove_legacy_categories_admin_policy.sql` son migraciones incrementales. La 008 elimina únicamente la policy heredada `categories_admin` (`FOR ALL`) de `public.categories`; conserva las policies `categories_admin_insert`, `categories_admin_update`, `categories_business_select` y `categories_read`, y no modifica filas. Aplicarla después de 007.

`tests/integration/category_policy_008.sql` comprueba tras aplicar 008 que no quede una policy administrativa `FOR ALL` y que sigan presentes las cuatro policies preservadas. Ejecutarla en una base de pruebas aislada, no en producción.

`009_product_image_storage_management.sql` crea el bucket público `product-images` para servir imágenes del catálogo, limita carga/lectura administrativa/eliminación a productos del negocio activo, y agrega policies restrictivas para que una policy permisiva más amplia no extienda esos permisos. También agrega funciones RLS-invoker para registrar, seleccionar la imagen principal y reordenar. La migración falla si detecta más de una imagen principal preexistente por producto; resuelve esos datos antes de aplicarla, no los corrige automáticamente. La interfaz limita JPEG/PNG/WebP a 5 MB y 2400 × 2400 px.

`tests/integration/product_image_storage_009.sql` comprueba el bucket, policies, índice de imagen principal y funciones después de aplicar 009. Ejecutarla en una base de pruebas aislada.

`004_business_rules_tests.md` es una matriz documental, no una migración SQL. Las reglas pendientes de caja/compras continúan pendientes; este bootstrap no agrega funciones de negocio ni seeds.
