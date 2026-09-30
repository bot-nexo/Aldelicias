type ProductRecord = {
  id: string;
  name: string;
  category: string;
  status: "DRAFT" | "PUBLISHED" | "HIDDEN" | "OUT_OF_STOCK";
  price: number;
  cost: number;
  stock: number;
  minimumStock: number;
};

type ProductListProps = {
  products: readonly ProductRecord[];
};

const statusStyles: Record<ProductRecord["status"], string> = {
  DRAFT: "bg-slate-200 text-slate-700",
  PUBLISHED: "bg-emerald-100 text-emerald-700",
  HIDDEN: "bg-amber-100 text-amber-700",
  OUT_OF_STOCK: "bg-rose-100 text-rose-700",
};

function formatCurrency(value: number) {
  return new Intl.NumberFormat("es-CO", {
    style: "currency",
    currency: "COP",
    maximumFractionDigits: 0,
  }).format(value);
}

export function ProductList({ products }: ProductListProps) {
  return (
    <div className="overflow-hidden rounded-2xl border border-[var(--color-border)] bg-[var(--color-surface)]">
      <div className="overflow-x-auto">
        <table className="min-w-full text-left text-sm">
          <thead className="bg-[var(--color-surface-muted)] text-[var(--color-ink-muted)]">
            <tr>
              <th className="px-4 py-3 font-medium">Producto</th>
              <th className="px-4 py-3 font-medium">Categoría</th>
              <th className="px-4 py-3 font-medium">Estado</th>
              <th className="px-4 py-3 font-medium">Precio</th>
              <th className="px-4 py-3 font-medium">Stock</th>
              <th className="px-4 py-3 font-medium">Acciones</th>
            </tr>
          </thead>
          <tbody>
            {products.map((product) => (
              <tr key={product.id} className="border-t border-[var(--color-border)]">
                <td className="px-4 py-3">
                  <div>
                    <p className="font-medium text-[var(--color-ink)]">{product.name}</p>
                    <p className="text-xs text-[var(--color-ink-muted)]">
                      Costo {formatCurrency(product.cost)}
                    </p>
                  </div>
                </td>
                <td className="px-4 py-3 text-[var(--color-ink-muted)]">
                  {product.category}
                </td>
                <td className="px-4 py-3">
                  <span
                    className={`inline-flex rounded-full px-2.5 py-1 text-xs font-medium ${statusStyles[product.status]}`}
                  >
                    {product.status}
                  </span>
                </td>
                <td className="px-4 py-3 font-medium text-[var(--color-ink)]">
                  {formatCurrency(product.price)}
                </td>
                <td className="px-4 py-3 text-[var(--color-ink-muted)]">
                  {product.stock} / {product.minimumStock}
                </td>
                <td className="px-4 py-3">
                  <div className="flex items-center gap-2">
                    <button
                      className="text-sm font-medium text-[var(--color-accent)] hover:text-[var(--color-accent-hover)]"
                      type="button"
                    >
                      Editar
                    </button>
                    <button
                      className="text-sm font-medium text-[var(--color-ink-muted)] hover:text-[var(--color-ink)]"
                      type="button"
                    >
                      Ver
                    </button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
