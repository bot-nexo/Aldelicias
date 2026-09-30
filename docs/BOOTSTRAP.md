# Bootstrap de aplicación

## Stack

- Next.js 16 App Router, React 19 y TypeScript estricto.
- Tailwind CSS 4 y una primitiva `Button` accesible para iniciar el sistema UI.
- Supabase Auth con `@supabase/ssr`, cookies renovadas por `proxy.ts` y clientes separados por entorno.
- Zod para validar configuración; Vitest para pruebas unitarias.
- ESLint 10 con reglas oficiales de Next.js y TypeScript; Prettier con plugin Tailwind.

## Alcance y fase

Este bootstrap sigue el alcance explícito de la tarea actual y `AGENTS.md`. Un documento técnico V1.0 anterior denomina “Fase 5” a la web pública; esa numeración no cambia aquí el alcance ni autoriza construirla. El Master Context y los SQL heredados se conservan como están.

## Configuración local

1. Instalar Node.js 24 o superior.
2. Ejecutar `npm install`.
3. Copiar `.env.example` a `.env.local` y completar `NEXT_PUBLIC_SUPABASE_URL` y `NEXT_PUBLIC_SUPABASE_ANON_KEY` desde el proyecto Supabase.
4. Ejecutar `npm run dev` y abrir `http://localhost:3000`.

La clave `anon`/publishable es pública y está protegida por RLS; no usar una service-role key en el navegador. El cliente no define ni consume una clave de servicio.

## Autenticación y autorización

- El login usa email y contraseña de Supabase Auth; no hay registro público.
- `proxy.ts` renueva cookies y rechaza `/admin` sin usuario autenticado.
- `app/admin/layout.tsx` verifica de nuevo el usuario con `auth.getUser()` y exige un registro activo en `public.users` vinculado por `auth_user_id`.
- La consulta del perfil se ejecuta con la clave pública y queda sujeta a las políticas RLS existentes. La autorización de negocio debe mantenerse también en PostgreSQL/RPC; el shell no concede permisos de módulos.
- No se crea automáticamente un negocio, perfil, usuario inicial ni rol. El alta inicial requiere configuración administrativa confiable en Supabase y no debe exponerse en una ruta pública.
- Los roles están tipados, pero la matriz central de permisos de módulos es trabajo posterior y no se simula en el frontend.

## Tipos y migraciones

`types/database.ts` cubre por ahora `users`, `roles` y funciones de identidad que usa la sesión. Debe ampliarse desde el esquema SQL revisado a medida que la aplicación consuma otras tablas.

Los cuatro archivos SQL existentes permanecen en la raíz, con sus nombres y contenidos intactos; `004_business_rules_tests.md` sigue siendo una matriz documental. `supabase/migrations/` es una estructura de destino documentada, no una copia ni un conjunto aplicado por Supabase CLI. La adopción exige revisar orden, formato y estado de aplicación; no renumerar ni reescribir migraciones que pudieran haberse ejecutado.

## Verificaciones

- `npm run lint`
- `npm run typecheck`
- `npm test`
- `npm run format:check`
- `npm run build`

El acceso real requiere credenciales de un proyecto Supabase y un Auth user enlazado con un perfil activo en `public.users`. Sin variables configuradas, el servidor arranca y el login muestra el requisito de configuración; `/admin` permanece bloqueado.
