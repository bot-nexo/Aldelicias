# AlDelicias

Plataforma administrativa y web pública para AlDelicias. El alcance de implementación actual es el **bootstrap de la aplicación**; los módulos de negocio y la web pública continúan pendientes.

## Documentación de referencia

- [Contexto maestro](ALDELICIAS_MASTER_CONTEXT.md): reglas y arquitectura del negocio.
- [Instrucciones del repositorio](AGENTS.md): restricciones para cambios de código.
- [Bootstrap de aplicación](docs/BOOTSTRAP.md): stack, autenticación, migraciones y ejecución.
- [ERD](ERD.md) y documentos de reglas financieras: modelo de datos y procesos.

## Iniciar en local

Requiere Node.js 24 o superior.

```powershell
npm install
Copy-Item .env.example .env.local
npm run dev
```

Completa en `.env.local` `NEXT_PUBLIC_SUPABASE_URL` y `NEXT_PUBLIC_SUPABASE_ANON_KEY` con los valores públicos de tu proyecto Supabase. No agregues una clave `service_role` al cliente.

Comprobaciones disponibles: `npm run lint`, `npm run typecheck`, `npm test`, `npm run format:check` y `npm run build`.

## Migraciones existentes

Los SQL numerados existentes siguen en la raíz y no han sido movidos ni alterados. Consulta [supabase/migrations/README.md](supabase/migrations/README.md) antes de adoptar Supabase CLI o ejecutar scripts en un entorno.
