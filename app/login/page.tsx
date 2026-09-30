import { LoginForm } from "@/components/auth/login-form";
import { hasPublicSupabaseEnv } from "@/lib/env";

type LoginPageProps = {
  searchParams: Promise<{ reason?: string }>;
};

export default async function LoginPage({ searchParams }: LoginPageProps) {
  const { reason } = await searchParams;
  const isConfigured = hasPublicSupabaseEnv();

  return (
    <main className="mx-auto grid min-h-screen w-full max-w-6xl content-center gap-12 px-5 py-10 md:grid-cols-[minmax(0,1fr)_minmax(20rem,0.8fr)] md:gap-20 md:px-10">
      <section className="flex flex-col justify-center">
        <p className="text-sm font-bold text-[var(--color-accent)] uppercase">
          AlDelicias
        </p>
        <h1 className="mt-3 max-w-md text-3xl leading-tight font-semibold sm:text-4xl">
          Administración del negocio
        </h1>
        <p className="mt-4 max-w-md text-base leading-7 text-[var(--color-ink-muted)]">
          Acceso privado para usuarios vinculados a AlDelicias.
        </p>
        <div
          aria-hidden="true"
          className="mt-8 flex h-1.5 w-28 overflow-hidden rounded-full"
        >
          <span className="w-2/3 bg-[var(--color-accent)]" />
          <span className="w-1/3 bg-[#d3a447]" />
        </div>
      </section>

      <section
        aria-labelledby="login-title"
        className="w-full max-w-md self-center md:justify-self-end"
      >
        <h2 className="text-xl font-semibold" id="login-title">
          Iniciar sesión
        </h2>
        <p className="mt-2 text-sm text-[var(--color-ink-muted)]">
          Usa las credenciales de tu cuenta administrativa.
        </p>

        {reason === "access" ? (
          <p
            className="mt-5 rounded-md border border-[var(--color-border)] bg-[var(--color-surface-muted)] p-3 text-sm"
            role="status"
          >
            La sesión no tiene un perfil interno activo asociado. Contacta al
            administrador del negocio.
          </p>
        ) : null}

        {!isConfigured ? (
          <div
            className="mt-6 border-l-4 border-[var(--color-accent)] bg-[var(--color-surface-muted)] p-4 text-sm leading-6"
            role="status"
          >
            <p className="font-semibold">Supabase aún no está configurado.</p>
            <p className="mt-1">
              Define <code>NEXT_PUBLIC_SUPABASE_URL</code> y{" "}
              <code>NEXT_PUBLIC_SUPABASE_ANON_KEY</code> en{" "}
              <code>.env.local</code> y reinicia el servidor.
            </p>
          </div>
        ) : (
          <LoginForm />
        )}
      </section>
    </main>
  );
}
