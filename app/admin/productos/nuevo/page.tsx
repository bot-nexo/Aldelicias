import Link from "next/link";

import { ProductForm } from "@/components/admin/products/product-form";
import { requireActiveUserProfile } from "@/lib/auth/session";
import { createClient } from "@/lib/supabase/server";

export default async function NewProductPage() {
  const profile = await requireActiveUserProfile();
  const supabase = await createClient();
  const { data: categories, error } = await supabase
    .from("categories")
    .select("id, name")
    .eq("business_id", profile.business_id)
    .eq("is_active", true)
    .order("sort_order", { ascending: true });

  if (error) {
    throw new Error("No se pudieron cargar las categorías del negocio.");
  }

  return (
    <section className="space-y-6">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <p className="text-xs font-semibold tracking-[0.14em] text-[var(--color-accent)] uppercase">
            Catálogo
          </p>
          <h1 className="mt-2 text-2xl font-semibold">Nuevo producto</h1>
        </div>
        <Link
          className="inline-flex items-center justify-center rounded-md border border-[var(--color-border)] bg-white px-3.5 py-2 text-sm font-medium text-[var(--color-ink)] transition hover:bg-[var(--color-surface-muted)]"
          href="/admin/productos"
        >
          Volver al listado
        </Link>
      </div>

      <ProductForm categories={categories ?? []} />
    </section>
  );
}
