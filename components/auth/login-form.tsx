"use client";

import { useState, type FormEvent } from "react";
import { ArrowRight } from "lucide-react";
import { useRouter } from "next/navigation";

import { Button } from "@/components/ui/button";
import { createClient } from "@/lib/supabase/client";

export function LoginForm() {
  const router = useRouter();
  const [error, setError] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setError(null);
    setIsSubmitting(true);

    const formData = new FormData(event.currentTarget);
    try {
      const supabase = createClient();
      const { error: signInError } = await supabase.auth.signInWithPassword({
        email: String(formData.get("email")).trim(),
        password: String(formData.get("password")),
      });

      if (signInError) {
        setError(
          "No se pudo iniciar sesión. Verifica tus datos e inténtalo de nuevo.",
        );
        return;
      }

      router.replace("/admin");
      router.refresh();
    } catch {
      setError("No se pudo conectar con el servicio de autenticación.");
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <form className="mt-8 grid gap-5" onSubmit={handleSubmit}>
      <label className="grid gap-2 text-sm font-medium" htmlFor="email">
        Correo electrónico
        <input
          autoComplete="username"
          className="min-h-12 rounded-md border border-[var(--color-border)] bg-white px-3 text-base transition outline-none focus:border-[var(--color-accent)] focus:ring-2 focus:ring-[var(--color-accent)]/20"
          id="email"
          name="email"
          required
          type="email"
        />
      </label>
      <label className="grid gap-2 text-sm font-medium" htmlFor="password">
        Contraseña
        <input
          autoComplete="current-password"
          className="min-h-12 rounded-md border border-[var(--color-border)] bg-white px-3 text-base transition outline-none focus:border-[var(--color-accent)] focus:ring-2 focus:ring-[var(--color-accent)]/20"
          id="password"
          name="password"
          required
          type="password"
        />
      </label>
      {error ? (
        <p
          aria-live="polite"
          className="text-sm text-[var(--color-accent)]"
          role="alert"
        >
          {error}
        </p>
      ) : null}
      <Button className="mt-1 w-full" disabled={isSubmitting} type="submit">
        {isSubmitting ? "Validando acceso…" : "Ingresar"}
        <ArrowRight aria-hidden="true" size={17} />
      </Button>
    </form>
  );
}
