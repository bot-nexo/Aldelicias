import Link from "next/link";
import { z } from "zod";

import { InventoryMovementForms } from "@/components/admin/inventory/inventory-movement-forms";
import { requireActiveUserProfile } from "@/lib/auth/session";
import { createClient } from "@/lib/supabase/server";

type SearchParams = Promise<Record<string, string | string[] | undefined>>;

const uuidSchema = z.string().uuid();
const offsetSchema = z.coerce.number().int().min(0).max(100_000);
const pageSize = 50;

function formatQuantity(value: number) {
  return new Intl.NumberFormat("es-CO", {
    maximumFractionDigits: 3,
    minimumFractionDigits: 0,
  }).format(value);
}

function movementLabel(type: string) {
  const labels: Record<string, string> = {
    PURCHASE: "Compra",
    SALE: "Venta",
    WASTAGE: "Merma",
    ADJUSTMENT: "Ajuste",
    TRANSFER_IN: "Traslado de entrada",
    TRANSFER_OUT: "Traslado de salida",
    RETURN: "Devolución",
    REVERSAL: "Reversión",
  };

  return labels[type] ?? type;
}

function inventoryHref(
  productId: string | null,
  locationId: string | null,
  offset: number,
) {
  const params = new URLSearchParams();
  if (productId) params.set("product", productId);
  if (locationId) params.set("location", locationId);
  if (offset > 0) params.set("offset", String(offset));
  const query = params.toString();
  return query ? `/admin/inventario?${query}` : "/admin/inventario";
}

export default async function InventoryPage({
  searchParams,
}: {
  searchParams: SearchParams;
}) {
  const profile = await requireActiveUserProfile();
  const filters = await searchParams;
  const requestedProduct = Array.isArray(filters.product)
    ? filters.product[0]
    : filters.product;
  const requestedLocation = Array.isArray(filters.location)
    ? filters.location[0]
    : filters.location;
  const requestedOffset = Array.isArray(filters.offset)
    ? filters.offset[0]
    : filters.offset;
  const productId =
    requestedProduct && uuidSchema.safeParse(requestedProduct).success
      ? requestedProduct
      : null;
  const locationId =
    requestedLocation && uuidSchema.safeParse(requestedLocation).success
      ? requestedLocation
      : null;
  const offset = offsetSchema.safeParse(requestedOffset ?? 0).success
    ? offsetSchema.parse(requestedOffset ?? 0)
    : 0;

  const supabase = await createClient();
  const [
    { data: stockRows, error: stockError },
    { data: movements, error: historyError },
  ] = await Promise.all([
    supabase.rpc("get_inventory_stock"),
    supabase.rpc("get_inventory_movement_history", {
      p_product_id: productId,
      p_location_id: locationId,
      p_limit: pageSize,
      p_offset: offset,
    }),
  ]);

  if (stockError || historyError) {
    throw new Error("No se pudo cargar la información de inventario.");
  }

  const inventory = stockRows ?? [];
  const productStockTotals = inventory.reduce((totals, row) => {
    totals.set(
      row.product_id,
      (totals.get(row.product_id) ?? 0) + row.current_stock,
    );
    return totals;
  }, new Map<string, number>());
  const inventoryWithTotals = inventory.map((row) => ({
    ...row,
    business_stock: productStockTotals.get(row.product_id) ?? 0,
  }));
  const visibleStock = inventoryWithTotals.filter(
    (row) =>
      (!productId || row.product_id === productId) &&
      (!locationId || row.location_id === locationId),
  );
  const trackedProductCount = new Set(inventory.map((row) => row.product_id))
    .size;
  const lowStockCount = new Set(
    inventoryWithTotals
      .filter((row) => row.business_stock <= row.minimum_stock)
      .map((row) => row.product_id),
  ).size;
  const products = Array.from(
    new Map(
      inventory.map((row) => [row.product_id, row.product_name]),
    ).entries(),
  );
  const locations = Array.from(
    new Map(
      inventory.map((row) => [row.location_id, row.location_name]),
    ).entries(),
  );
  const canAdjust = profile.role === "ADMIN";

  return (
    <section className="space-y-8">
      <div className="flex flex-col gap-4 border-b border-[var(--color-border)] pb-6 sm:flex-row sm:items-end sm:justify-between">
        <div>
          <p className="text-xs font-semibold tracking-[0.14em] text-[var(--color-accent)] uppercase">
            Operación
          </p>
          <h1 className="mt-2 text-2xl font-semibold">Inventario</h1>
          <p className="mt-2 max-w-2xl text-sm leading-6 text-[var(--color-ink-muted)]">
            Existencias por ubicación y trazabilidad de cada movimiento.
          </p>
        </div>
        <Link
          className="inline-flex min-h-10 items-center justify-center rounded-md border border-[var(--color-border)] bg-white px-3.5 text-sm font-medium text-[var(--color-ink)] hover:bg-[var(--color-surface-muted)]"
          href="/admin/productos"
        >
          Ver productos
        </Link>
      </div>

      <div className="grid gap-4 sm:grid-cols-2">
        <div className="border-b border-[var(--color-border)] pb-4">
          <p className="text-sm text-[var(--color-ink-muted)]">
            Productos con inventario
          </p>
          <p className="mt-2 text-2xl font-semibold">{trackedProductCount}</p>
        </div>
        <div className="border-b border-[var(--color-border)] pb-4">
          <p className="text-sm text-[var(--color-ink-muted)]">
            Existencias en o bajo el mínimo
          </p>
          <p className="mt-2 text-2xl font-semibold">{lowStockCount}</p>
        </div>
      </div>

      <section aria-labelledby="inventory-stock-title" className="space-y-4">
        <div className="flex flex-col gap-3 sm:flex-row sm:items-end sm:justify-between">
          <div>
            <h2 className="text-lg font-semibold" id="inventory-stock-title">
              Existencias actuales
            </h2>
            <p className="mt-1 text-sm text-[var(--color-ink-muted)]">
              Calculadas desde el historial de movimientos.
            </p>
          </div>
          <form
            className="grid gap-2 sm:grid-cols-[minmax(0,1fr)_minmax(0,1fr)_auto]"
            method="get"
          >
            <label className="sr-only" htmlFor="inventory-product-filter">
              Filtrar por producto
            </label>
            <select
              className="min-h-10 rounded-md border border-[var(--color-border)] bg-white px-3 text-sm"
              defaultValue={productId ?? ""}
              id="inventory-product-filter"
              name="product"
            >
              <option value="">Todos los productos</option>
              {products.map(([id, name]) => (
                <option key={id} value={id}>
                  {name}
                </option>
              ))}
            </select>
            <label className="sr-only" htmlFor="inventory-location-filter">
              Filtrar por ubicación
            </label>
            <select
              className="min-h-10 rounded-md border border-[var(--color-border)] bg-white px-3 text-sm"
              defaultValue={locationId ?? ""}
              id="inventory-location-filter"
              name="location"
            >
              <option value="">Todas las ubicaciones</option>
              {locations.map(([id, name]) => (
                <option key={id} value={id}>
                  {name}
                </option>
              ))}
            </select>
            <button
              className="min-h-10 rounded-md border border-[var(--color-border)] bg-white px-3 text-sm font-medium hover:bg-[var(--color-surface-muted)]"
              type="submit"
            >
              Filtrar
            </button>
          </form>
        </div>

        {visibleStock.length === 0 ? (
          <p className="border-y border-[var(--color-border)] py-8 text-center text-sm text-[var(--color-ink-muted)]">
            No hay productos con inventario rastreable para mostrar.
          </p>
        ) : (
          <div className="overflow-x-auto border-y border-[var(--color-border)]">
            <table className="min-w-full text-left text-sm">
              <thead className="bg-[var(--color-surface-muted)] text-[var(--color-ink-muted)]">
                <tr>
                  <th className="px-4 py-3 font-medium">Producto</th>
                  <th className="px-4 py-3 font-medium">Ubicación</th>
                  <th className="px-4 py-3 font-medium">Stock ubicación</th>
                  <th className="px-4 py-3 font-medium">Total negocio</th>
                  <th className="px-4 py-3 font-medium">Mínimo producto</th>
                  <th className="px-4 py-3 font-medium">Estado</th>
                </tr>
              </thead>
              <tbody>
                {visibleStock.map((row) => {
                  const isLow = row.business_stock <= row.minimum_stock;
                  return (
                    <tr
                      className="border-t border-[var(--color-border)]"
                      key={`${row.product_id}-${row.location_id}`}
                    >
                      <td className="px-4 py-3">
                        <p className="font-medium">{row.product_name}</p>
                        {row.sku && (
                          <p className="text-xs text-[var(--color-ink-muted)]">
                            {row.sku}
                          </p>
                        )}
                      </td>
                      <td className="px-4 py-3 text-[var(--color-ink-muted)]">
                        {row.location_name}
                      </td>
                      <td className="px-4 py-3 font-semibold">
                        {formatQuantity(row.current_stock)}
                      </td>
                      <td className="px-4 py-3 font-semibold">
                        {formatQuantity(row.business_stock)}
                      </td>
                      <td className="px-4 py-3 text-[var(--color-ink-muted)]">
                        {formatQuantity(row.minimum_stock)}
                      </td>
                      <td className="px-4 py-3">
                        <span
                          className={
                            isLow ? "text-rose-700" : "text-emerald-700"
                          }
                        >
                          {isLow ? "Stock bajo" : "Disponible"}
                        </span>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </section>

      <InventoryMovementForms
        canAdjust={canAdjust}
        options={inventory.map((row) => ({
          productId: row.product_id,
          productName: row.product_name,
          locationId: row.location_id,
          locationName: row.location_name,
          stock: row.current_stock,
        }))}
      />

      <section aria-labelledby="inventory-history-title" className="space-y-4">
        <div className="flex flex-col gap-3 sm:flex-row sm:items-end sm:justify-between">
          <div>
            <h2 className="text-lg font-semibold" id="inventory-history-title">
              Historial de movimientos
            </h2>
            <p className="mt-1 text-sm text-[var(--color-ink-muted)]">
              Registro ordenado por fecha, con autor y motivo o referencia.
            </p>
          </div>
          <p className="text-sm text-[var(--color-ink-muted)]">
            {movements?.length ?? 0} movimientos
          </p>
        </div>

        {!movements?.length ? (
          <p className="border-y border-[var(--color-border)] py-8 text-center text-sm text-[var(--color-ink-muted)]">
            No hay movimientos para estos filtros.
          </p>
        ) : (
          <div className="overflow-x-auto border-y border-[var(--color-border)]">
            <table className="min-w-full text-left text-sm">
              <thead className="bg-[var(--color-surface-muted)] text-[var(--color-ink-muted)]">
                <tr>
                  <th className="px-4 py-3 font-medium">Fecha</th>
                  <th className="px-4 py-3 font-medium">Producto</th>
                  <th className="px-4 py-3 font-medium">Ubicación</th>
                  <th className="px-4 py-3 font-medium">Movimiento</th>
                  <th className="px-4 py-3 font-medium">Cantidad</th>
                  <th className="px-4 py-3 font-medium">Motivo / referencia</th>
                  <th className="px-4 py-3 font-medium">Realizado por</th>
                </tr>
              </thead>
              <tbody>
                {movements.map((movement) => (
                  <tr
                    className="border-t border-[var(--color-border)]"
                    key={movement.movement_id}
                  >
                    <td className="px-4 py-3 whitespace-nowrap text-[var(--color-ink-muted)]">
                      {new Intl.DateTimeFormat("es-CO", {
                        dateStyle: "short",
                        timeStyle: "short",
                      }).format(new Date(movement.created_at))}
                    </td>
                    <td className="px-4 py-3 font-medium">
                      {movement.product_name}
                    </td>
                    <td className="px-4 py-3 text-[var(--color-ink-muted)]">
                      {movement.location_name}
                    </td>
                    <td className="px-4 py-3">
                      {movementLabel(movement.movement_type)}
                    </td>
                    <td
                      className={`px-4 py-3 font-semibold ${movement.quantity < 0 ? "text-rose-700" : "text-emerald-700"}`}
                    >
                      {movement.quantity > 0 ? "+" : ""}
                      {formatQuantity(movement.quantity)}
                    </td>
                    <td className="max-w-xs px-4 py-3 text-[var(--color-ink-muted)]">
                      {movement.reason ??
                        (movement.reference_type
                          ? `${movementLabel(movement.reference_type)}${movement.reference_id ? ` · ${movement.reference_id.slice(0, 8)}` : ""}`
                          : movementLabel(movement.movement_type))}
                    </td>
                    <td className="px-4 py-3 text-[var(--color-ink-muted)]">
                      {movement.created_by_name}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

        <div className="flex justify-end gap-2">
          {offset > 0 && (
            <Link
              className="inline-flex min-h-9 items-center rounded-md border border-[var(--color-border)] px-3 text-sm hover:bg-[var(--color-surface-muted)]"
              href={inventoryHref(
                productId,
                locationId,
                Math.max(0, offset - pageSize),
              )}
            >
              Anteriores
            </Link>
          )}
          {(movements?.length ?? 0) === pageSize && (
            <Link
              className="inline-flex min-h-9 items-center rounded-md border border-[var(--color-border)] px-3 text-sm hover:bg-[var(--color-surface-muted)]"
              href={inventoryHref(productId, locationId, offset + pageSize)}
            >
              Siguientes
            </Link>
          )}
        </div>
      </section>
    </section>
  );
}
