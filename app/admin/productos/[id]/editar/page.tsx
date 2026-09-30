import Link from "next/link";
import { notFound } from "next/navigation";

import { ProductForm } from "@/components/admin/products/product-form";
import { requireActiveUserProfile } from "@/lib/auth/session";
import { createClient } from "@/lib/supabase/server";

export default async function EditProductPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const profile = await requireActiveUserProfile();
  const supabase = await createClient();

  const { data: product, error } = await supabase
    .from("products")
    .select(
      "id, name, slug, short_description, sale_price, cost_price, status, track_inventory, minimum_stock, category_id",
    )
    .eq("id", id)
    .eq("business_id", profile.business_id)
    .single();

  const { data: allCategories, error: categoriesError } = await supabase
    .from("categories")
    .select("id, name, is_active")
    .eq("business_id", profile.business_id)
    .order("sort_order", { ascending: true });

  if (error || categoriesError || !product) {
    notFound();
  }

  const categories = (allCategories ?? [])
    .filter(
      (category) => category.is_active || category.id === product.category_id,
    )
    .map(({ id, name, is_active }) => ({ id, name, isActive: is_active }));

  return (
    <section className="space-y-6">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <p className="text-xs font-semibold tracking-[0.14em] text-[var(--color-accent)] uppercase">
            Catálogo
          </p>
          <h1 className="mt-2 text-2xl font-semibold">Editar producto</h1>
        </div>
        <Link
          className="inline-flex items-center justify-center rounded-md border border-[var(--color-border)] bg-white px-3.5 py-2 text-sm font-medium text-[var(--color-ink)] transition hover:bg-[var(--color-surface-muted)]"
          href="/admin/productos"
        >
          Volver al listado
        </Link>
      </div>

      <ProductForm
        initialValues={{
          name: product.name,
          slug: product.slug,
          categoryId: product.category_id,
          status: product.status,
          salePrice: Number(product.sale_price ?? 0),
          costPrice: Number(product.cost_price ?? 0),
          shortDescription: product.short_description ?? "",
          minimumStock: Number(product.minimum_stock ?? 0),
          trackInventory: product.track_inventory ?? false,
        }}
        mode="edit"
        productId={product.id}
        categories={categories}
      />
    </section>
  );
}
