"use client";

import { Button } from "@/components/ui/button";

export default function GlobalError({
  reset,
}: {
  error: Error;
  reset: () => void;
}) {
  return (
    <html lang="es">
      <body>
        <main className="mx-auto flex min-h-screen max-w-xl flex-col justify-center px-5 py-12">
          <p className="text-sm font-semibold text-[var(--color-accent)]">
            AlDelicias
          </p>
          <h1 className="mt-3 text-2xl font-semibold">
            La aplicación encontró un problema
          </h1>
          <p className="mt-2 text-sm leading-6 text-[var(--color-ink-muted)]">
            Intenta cargar de nuevo. Si el problema continúa, contacta al
            administrador.
          </p>
          <Button
            className="mt-6 w-fit"
            onClick={reset}
            type="button"
            variant="secondary"
          >
            Reintentar
          </Button>
        </main>
      </body>
    </html>
  );
}
