import Link from "next/link";
import { notFound } from "next/navigation";

import {
  createCategory,
  deactivateCategory,
  updateCategory,
} from "@/app/admin/productos/actions";
import { requireActiveUserProfile } from "@/lib/auth/session";
import { createClient } from "@/lib/supabase/server";

export default async function ProductCategoriesPage() {
  const profile = await requireActiveUserProfile();
  if (profile.role !== "ADMIN") notFound();

  const supabase = await createClient();
  const { data: categories, error } = await supabase
    .from("categories")
    .select("id, name, slug, description, sort_order, is_active")
    .eq("business_id", profile.business_id)
    .order("sort_order", { ascending: true })
    .order("name", { ascending: true });

  if (error) {
    throw new Error("No se pudieron cargar las categorías del negocio.");
  }

  return (
    <section className="space-y-8">
      <div className="flex flex-col gap-4 border-b border-[var(--color-border)] pb-6 sm:flex-row sm:items-end sm:justify-between">
        <div>
          <p className="text-xs font-semibold tracking-[0.14em] text-[var(--color-accent)] uppercase">
            Catálogo
          </p>
          <h1 className="mt-2 text-2xl font-semibold">Categorías</h1>
          <p className="mt-2 text-sm text-[var(--color-ink-muted)]">
            Organiza los productos de este negocio.
          </p>
        </div>
        <Link
          className="inline-flex items-center justify-center rounded-md border border-[var(--color-border)] bg-white px-3.5 py-2 text-sm font-medium text-[var(--color-ink)] transition hover:bg-[var(--color-surface-muted)]"
          href="/admin/productos"
        >
          Volver a productos
        </Link>
      </div>

      <form
        action={createCategory}
        className="grid gap-4 border-b border-[var(--color-border)] pb-6 md:grid-cols-2"
      >
        <h2 className="text-base font-semibold md:col-span-2">
          Nueva categoría
        </h2>
        <label className="space-y-2 text-sm font-medium">
          <span>Nombre</span>
          <input
            className="w-full rounded-md border border-[var(--color-border)] bg-white px-3 py-2.5 outline-none focus-visible:outline-2 focus-visible:outline-[var(--color-ring)]"
            maxLength={100}
            name="name"
            required
          />
        </label>
        <label className="space-y-2 text-sm font-medium">
          <span>Slug</span>
          <input
            className="w-full rounded-md border border-[var(--color-border)] bg-white px-3 py-2.5 outline-none focus-visible:outline-2 focus-visible:outline-[var(--color-ring)]"
            maxLength={120}
            name="slug"
            required
          />
        </label>
        <label className="space-y-2 text-sm font-medium md:col-span-2">
          <span>Descripción</span>
          <textarea
            className="min-h-20 w-full rounded-md border border-[var(--color-border)] bg-white px-3 py-2.5 outline-none focus-visible:outline-2 focus-visible:outline-[var(--color-ring)]"
            name="description"
          />
        </label>
        <label className="space-y-2 text-sm font-medium">
          <span>Orden</span>
          <input
            className="w-full rounded-md border border-[var(--color-border)] bg-white px-3 py-2.5 outline-none focus-visible:outline-2 focus-visible:outline-[var(--color-ring)]"
            defaultValue={0}
            min={0}
            name="sortOrder"
            type="number"
          />
        </label>
        <div className="flex items-end md:justify-end">
          <button
            className="inline-flex min-h-10 items-center justify-center rounded-md bg-[var(--color-ink)] px-4 text-sm font-medium text-white hover:opacity-95"
            type="submit"
          >
            Crear categoría
          </button>
        </div>
      </form>

      <div>
        <div className="mb-3 flex items-center justify-between gap-3">
          <h2 className="text-base font-semibold">Categorías del negocio</h2>
          <span className="text-sm text-[var(--color-ink-muted)]">
            {categories?.length ?? 0} registros
          </span>
        </div>
        {!categories?.length ? (
          <p className="border-y border-[var(--color-border)] py-8 text-center text-sm text-[var(--color-ink-muted)]">
            Aún no hay categorías.
          </p>
        ) : (
          <div className="divide-y divide-[var(--color-border)] border-y border-[var(--color-border)]">
            {categories.map((category) => (
              <div
                className="grid gap-4 py-5 lg:grid-cols-[minmax(0,1fr)_auto]"
                key={category.id}
              >
                <form
                  action={updateCategory.bind(null, category.id)}
                  className="grid gap-3 sm:grid-cols-2"
                >
                  <label className="space-y-1.5 text-sm font-medium">
                    <span>Nombre</span>
                    <input
                      className="w-full rounded-md border border-[var(--color-border)] bg-white px-3 py-2 outline-none focus-visible:outline-2 focus-visible:outline-[var(--color-ring)]"
                      defaultValue={category.name}
                      maxLength={100}
                      name="name"
                      required
                    />
                  </label>
                  <label className="space-y-1.5 text-sm font-medium">
                    <span>Slug</span>
                    <input
                      className="w-full rounded-md border border-[var(--color-border)] bg-white px-3 py-2 outline-none focus-visible:outline-2 focus-visible:outline-[var(--color-ring)]"
                      defaultValue={category.slug}
                      maxLength={120}
                      name="slug"
                      required
                    />
                  </label>
                  <label className="space-y-1.5 text-sm font-medium sm:col-span-2">
                    <span>Descripción</span>
                    <input
                      className="w-full rounded-md border border-[var(--color-border)] bg-white px-3 py-2 outline-none focus-visible:outline-2 focus-visible:outline-[var(--color-ring)]"
                      defaultValue={category.description ?? ""}
                      name="description"
                    />
                  </label>
                  <label className="space-y-1.5 text-sm font-medium">
                    <span>Orden</span>
                    <input
                      className="w-full rounded-md border border-[var(--color-border)] bg-white px-3 py-2 outline-none focus-visible:outline-2 focus-visible:outline-[var(--color-ring)]"
                      defaultValue={category.sort_order}
                      min={0}
                      name="sortOrder"
                      type="number"
                    />
                  </label>
                  <div className="flex flex-wrap items-end justify-between gap-3">
                    <label className="flex min-h-10 items-center gap-2 text-sm">
                      <input
                        defaultChecked={category.is_active}
                        name="isActive"
                        type="checkbox"
                      />
                      Activa
                    </label>
                    <button
                      className="min-h-10 rounded-md border border-[var(--color-border)] bg-white px-3 text-sm font-medium hover:bg-[var(--color-surface-muted)]"
                      type="submit"
                    >
                      Guardar
                    </button>
                  </div>
                </form>
                {category.is_active && (
                  <form
                    action={deactivateCategory.bind(null, category.id)}
                    className="flex items-end lg:justify-end"
                  >
                    <button
                      className="min-h-10 rounded-md px-3 text-sm font-medium text-[var(--color-ink-muted)] hover:bg-[var(--color-surface-muted)] hover:text-[var(--color-ink)]"
                      type="submit"
                    >
                      Desactivar
                    </button>
                  </form>
                )}
              </div>
            ))}
          </div>
        )}
      </div>
    </section>
  );
}
