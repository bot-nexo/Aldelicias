"use client";

import { useState } from "react";
import { LogOut } from "lucide-react";
import { useRouter } from "next/navigation";

import { createClient } from "@/lib/supabase/client";

export function SignOutButton() {
  const router = useRouter();
  const [error, setError] = useState<string | null>(null);

  async function handleSignOut() {
    setError(null);
    const { error: signOutError } = await createClient().auth.signOut();
    if (signOutError) {
      setError("No se pudo cerrar la sesión. Inténtalo de nuevo.");
      return;
    }

    router.replace("/login");
    router.refresh();
  }

  return (
    <div>
      <button
        aria-label="Cerrar sesión"
        className="inline-flex min-h-10 items-center justify-center gap-2 rounded-md px-3 text-sm text-[var(--color-ink-muted)] transition hover:bg-[var(--color-surface-muted)] hover:text-[var(--color-ink)] focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[var(--color-ring)]"
        onClick={handleSignOut}
        title="Cerrar sesión"
        type="button"
      >
        <LogOut aria-hidden="true" size={17} />
        <span className="hidden sm:inline">Salir</span>
      </button>
      {error ? (
        <p
          aria-live="polite"
          className="mt-2 max-w-48 text-xs text-[var(--color-accent)]"
          role="alert"
        >
          {error}
        </p>
      ) : null}
    </div>
  );
}
