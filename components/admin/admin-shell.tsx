import Link from "next/link";
import { LayoutDashboard, Store } from "lucide-react";
import type { ReactNode } from "react";

import { SignOutButton } from "@/components/auth/sign-out-button";
import type { UserProfile } from "@/types/database";

type AdminShellProps = {
  children: ReactNode;
  profile: UserProfile;
};

export function AdminShell({ children, profile }: AdminShellProps) {
  return (
    <div className="min-h-screen lg:flex">
      <aside className="hidden w-64 shrink-0 flex-col border-r border-[var(--color-border)] bg-[var(--color-surface)] lg:flex">
        <Link
          className="flex h-20 items-center gap-3 border-b border-[var(--color-border)] px-6"
          href="/admin"
        >
          <span className="flex size-10 items-center justify-center rounded-md bg-[var(--color-ink)] text-white">
            <Store aria-hidden="true" size={20} />
          </span>
          <span className="leading-tight">
            <span className="block text-sm font-bold">AlDelicias</span>
            <span className="text-xs text-[var(--color-ink-muted)]">
              Operaciones
            </span>
          </span>
        </Link>
        <nav aria-label="Navegación administrativa" className="flex-1 p-4">
          <Link
            aria-current="page"
            className="flex min-h-11 items-center gap-3 rounded-md bg-[var(--color-surface-muted)] px-3 text-sm font-semibold"
            href="/admin"
          >
            <LayoutDashboard aria-hidden="true" size={18} />
            Inicio
          </Link>
        </nav>
        <div className="flex items-center justify-between gap-2 border-t border-[var(--color-border)] p-4">
          <div className="min-w-0">
            <p className="truncate text-sm font-medium">{profile.full_name}</p>
            <p className="text-xs text-[var(--color-ink-muted)]">
              {profile.role === "ADMIN" ? "Administrador" : "Colaborador"}
            </p>
          </div>
          <SignOutButton />
        </div>
      </aside>

      <div className="min-w-0 flex-1">
        <header className="sticky top-0 z-10 flex min-h-16 items-center justify-between border-b border-[var(--color-border)] bg-[var(--color-surface)] px-4 lg:hidden">
          <Link className="text-sm font-bold" href="/admin">
            AlDelicias{" "}
            <span className="font-normal text-[var(--color-ink-muted)]">
              / Inicio
            </span>
          </Link>
          <div className="flex items-center gap-2">
            <span className="max-w-36 truncate text-sm">
              {profile.full_name}
            </span>
            <SignOutButton />
          </div>
        </header>
        <main className="mx-auto min-h-[calc(100vh-4rem)] w-full max-w-6xl px-5 py-8 sm:px-8 lg:px-10 lg:py-10">
          {children}
        </main>
      </div>
    </div>
  );
}
