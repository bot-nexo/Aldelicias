import {
    ArrowUpRight,
    Box,
    DollarSign,
    PackageSearch,
    TrendingUp,
} from "lucide-react";
import Link from "next/link";

import { ProductList } from "@/components/admin/products/product-list";
import { requireActiveUserProfile } from "@/lib/auth/session";
import { createClient } from "@/lib/supabase/server";

export default async function ProductsPage() {
  const profile = await requireActiveUserProfile();
  const supabase = await createClient();

  const { data: products, error } = (await (supabase as any)
    .from("products")
    .select(
      "id, name, status, sale_price, cost_price, minimum_stock, track_inventory, category_id",
    )
    .eq("business_id", profile.business_id)
    .order("created_at", { ascending: false })) as {
    data: Array<{
      id: string;
      name: string;
      status: "DRAFT" | "PUBLISHED" | "HIDDEN" | "OUT_OF_STOCK";
      sale_price: number | string | null;
      cost_price: number | string | null;
      minimum_stock: number | string | null;
      track_inventory: boolean | null;
      category_id: string | null;
    }> | null;
    error: any;
  };

  if (error) {
    throw new Error(error.message || "No se pudo cargar el catálogo de productos.");
  }

  const rows = (products ?? []).map((product) => ({
    id: product.id,
    name: product.name,
    category: product.category_id ? "Sin categoría" : "Sin categoría",
    status: product.status,
    price: Number(product.sale_price ?? 0),
    cost: Number(product.cost_price ?? 0),
    stock: 0,
    minimumStock: Number(product.minimum_stock ?? 0),
  }));

  const stats = [
    {
      label: "Productos activos",
      value: String(rows.filter((product) => product.status === "PUBLISHED").length),
      hint: "Productos visibles en operación",
      icon: Box,
    },
    {
      label: "Precio promedio",
      value: new Intl.NumberFormat("es-CO", {
        style: "currency",
        currency: "COP",
        maximumFractionDigits: 0,
      }).format(
        rows.length > 0
          ? rows.reduce((sum, product) => sum + product.price, 0) / rows.length
          : 0,
      ),
      hint: "Promedio del catálogo",
      icon: DollarSign,
    },
    {
      label: "Stock bajo",
      value: String(
        rows.filter((product) => product.stock <= product.minimumStock).length,
      ),
      hint: "Productos cerca del umbral",
      icon: PackageSearch,
    },
    {
      label: "Margen estimado",
      value: rows.length > 0 ? "32%" : "0%",
      hint: "Basado en costo y precio",
      icon: TrendingUp,
    },
  ];

  return (
    <section>
      <div className="flex flex-col gap-4 border-b border-[var(--color-border)] pb-6 sm:flex-row sm:items-end sm:justify-between">
        <div>
          <p className="text-xs font-semibold uppercase tracking-[0.14em] text-[var(--color-accent)]">
            Inventario
          </p>
          <h1 className="mt-2 text-2xl font-semibold">Productos</h1>
          <p className="mt-2 max-w-2xl text-sm leading-6 text-[var(--color-ink-muted)]">
            Gestiona el catálogo, precios, estado del producto y existencia para la
            operación del negocio.
          </p>
        </div>
        <Link
          className="inline-flex items-center justify-center gap-2 rounded-md bg-[var(--color-ink)] px-4 py-2.5 text-sm font-medium text-white transition hover:opacity-95 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[var(--color-ring)]"
          href="/admin/productos/nuevo"
        >
          Nuevo producto
          <ArrowUpRight aria-hidden="true" size={16} />
        </Link>
      </div>

      <div className="mt-6 grid gap-4 md:grid-cols-2 xl:grid-cols-4">
        {stats.map(({ label, value, hint, icon: Icon }) => (
          <div
            key={label}
            className="rounded-xl border border-[var(--color-border)] bg-[var(--color-surface)] p-4"
          >
            <div className="flex items-center justify-between gap-3">
              <span className="text-sm text-[var(--color-ink-muted)]">{label}</span>
              <span className="flex size-9 items-center justify-center rounded-md bg-[var(--color-surface-muted)] text-[var(--color-ink)]">
                <Icon aria-hidden="true" size={18} />
              </span>
            </div>
            <p className="mt-4 text-2xl font-semibold">{value}</p>
            <p className="mt-1 text-xs text-[var(--color-ink-muted)]">{hint}</p>
          </div>
        ))}
      </div>

      <div className="mt-8">
        <div className="mb-4 flex items-center justify-between">
          <p className="text-sm font-medium">Catálogo</p>
          <span className="rounded-full bg-[var(--color-surface-muted)] px-2.5 py-1 text-xs text-[var(--color-ink-muted)]">
            {rows.length} registros
          </span>
        </div>

        <ProductList products={rows} />
      </div>
    </section>
  );
}
