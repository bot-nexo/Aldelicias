import { createProduct, updateProduct } from "@/app/admin/productos/actions";

type ProductFormProps = {
  mode?: "create" | "edit";
  productId?: string;
  initialValues?: {
    name?: string;
    slug?: string;
    categoryId?: string | null;
    status?: "DRAFT" | "PUBLISHED" | "HIDDEN" | "OUT_OF_STOCK";
    salePrice?: number | string;
    costPrice?: number | string;
    shortDescription?: string;
    minimumStock?: number | string;
    trackInventory?: boolean;
  };
  categories?: Array<{ id: string; name: string; isActive?: boolean }>;
};

const statusOptions = ["DRAFT", "PUBLISHED", "HIDDEN", "OUT_OF_STOCK"] as const;

export function ProductForm({
  mode = "create",
  productId,
  initialValues,
  categories = [],
}: ProductFormProps) {
  const submitAction =
    mode === "edit" && productId
      ? (formData: FormData) => updateProduct(productId, formData)
      : createProduct;

  return (
    <form
      action={submitAction}
      className="space-y-6 rounded-2xl border border-[var(--color-border)] bg-[var(--color-surface)] p-5 sm:p-6"
    >
      <div className="grid gap-5 md:grid-cols-2">
        <label className="space-y-2 text-sm font-medium text-[var(--color-ink)]">
          <span>Nombre</span>
          <input
            className="w-full rounded-lg border border-[var(--color-border)] bg-white px-3 py-2.5 text-sm text-[var(--color-ink)] transition outline-none focus:border-[var(--color-ring)] focus:ring-2 focus:ring-[var(--color-ring)]/20"
            defaultValue={initialValues?.name ?? ""}
            name="name"
            placeholder="Ej. Buñuelo de queso"
            type="text"
          />
        </label>

        <label className="space-y-2 text-sm font-medium text-[var(--color-ink)]">
          <span>Slug</span>
          <input
            className="w-full rounded-lg border border-[var(--color-border)] bg-white px-3 py-2.5 text-sm text-[var(--color-ink)] transition outline-none focus:border-[var(--color-ring)] focus:ring-2 focus:ring-[var(--color-ring)]/20"
            defaultValue={initialValues?.slug ?? ""}
            name="slug"
            placeholder="empanada-queso"
            type="text"
          />
        </label>

        <label className="space-y-2 text-sm font-medium text-[var(--color-ink)]">
          <span>Estado</span>
          <select
            className="w-full rounded-lg border border-[var(--color-border)] bg-white px-3 py-2.5 text-sm text-[var(--color-ink)] transition outline-none focus:border-[var(--color-ring)] focus:ring-2 focus:ring-[var(--color-ring)]/20"
            defaultValue={initialValues?.status ?? "DRAFT"}
            name="status"
          >
            {statusOptions.map((status) => (
              <option key={status} value={status}>
                {status}
              </option>
            ))}
          </select>
        </label>

        <label className="space-y-2 text-sm font-medium text-[var(--color-ink)]">
          <span>Categoría</span>
          <select
            className="w-full rounded-lg border border-[var(--color-border)] bg-white px-3 py-2.5 text-sm text-[var(--color-ink)] transition outline-none focus:border-[var(--color-ring)] focus:ring-2 focus:ring-[var(--color-ring)]/20"
            defaultValue={initialValues?.categoryId ?? ""}
            name="categoryId"
          >
            <option value="">Sin categoría</option>
            {categories.map((category) => (
              <option key={category.id} value={category.id}>
                {category.name}
                {category.isActive === false ? " (inactiva)" : ""}
              </option>
            ))}
          </select>
        </label>

        <label className="space-y-2 text-sm font-medium text-[var(--color-ink)]">
          <span>Precio de venta</span>
          <input
            className="w-full rounded-lg border border-[var(--color-border)] bg-white px-3 py-2.5 text-sm text-[var(--color-ink)] transition outline-none focus:border-[var(--color-ring)] focus:ring-2 focus:ring-[var(--color-ring)]/20"
            defaultValue={initialValues?.salePrice ?? ""}
            min="0"
            name="salePrice"
            step="0.01"
            type="number"
          />
        </label>

        <label className="space-y-2 text-sm font-medium text-[var(--color-ink)]">
          <span>Costo estimado</span>
          <input
            className="w-full rounded-lg border border-[var(--color-border)] bg-white px-3 py-2.5 text-sm text-[var(--color-ink)] transition outline-none focus:border-[var(--color-ring)] focus:ring-2 focus:ring-[var(--color-ring)]/20"
            defaultValue={initialValues?.costPrice ?? ""}
            min="0"
            name="costPrice"
            step="0.01"
            type="number"
          />
        </label>

        <label className="space-y-2 text-sm font-medium text-[var(--color-ink)]">
          <span>Stock mínimo</span>
          <input
            className="w-full rounded-lg border border-[var(--color-border)] bg-white px-3 py-2.5 text-sm text-[var(--color-ink)] transition outline-none focus:border-[var(--color-ring)] focus:ring-2 focus:ring-[var(--color-ring)]/20"
            defaultValue={initialValues?.minimumStock ?? 0}
            min="0"
            name="minimumStock"
            type="number"
          />
        </label>

        <label className="space-y-2 text-sm font-medium text-[var(--color-ink)] md:col-span-2">
          <span>Descripción breve</span>
          <textarea
            className="min-h-28 w-full rounded-lg border border-[var(--color-border)] bg-white px-3 py-2.5 text-sm text-[var(--color-ink)] transition outline-none focus:border-[var(--color-ring)] focus:ring-2 focus:ring-[var(--color-ring)]/20"
            defaultValue={initialValues?.shortDescription ?? ""}
            name="shortDescription"
            placeholder="Describe el producto para el catálogo y la operación."
          />
        </label>
      </div>

      <div className="grid gap-5 rounded-xl border border-[var(--color-border)] bg-[var(--color-surface-muted)] p-4 md:grid-cols-2">
        <label className="flex items-center gap-3 text-sm font-medium text-[var(--color-ink)]">
          <input
            defaultChecked={initialValues?.trackInventory ?? false}
            name="trackInventory"
            type="checkbox"
          />
          Rastrear inventario
        </label>
      </div>

      <div className="flex flex-col gap-3 sm:flex-row sm:justify-end">
        <button
          className="inline-flex items-center justify-center rounded-md border border-[var(--color-border)] bg-white px-4 py-2.5 text-sm font-medium text-[var(--color-ink)] transition hover:bg-[var(--color-surface-muted)]"
          type="button"
        >
          Cancelar
        </button>
        <button
          className="inline-flex items-center justify-center rounded-md bg-[var(--color-ink)] px-4 py-2.5 text-sm font-medium text-white transition hover:opacity-95"
          type="submit"
        >
          {mode === "edit" ? "Guardar cambios" : "Crear producto"}
        </button>
      </div>
    </form>
  );
}
