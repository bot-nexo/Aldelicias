"use client";

import { useActionState } from "react";

import {
  registerInventoryAdjustment,
  registerWastage,
  type InventoryActionState,
} from "@/app/admin/inventario/actions";

type InventoryOption = {
  productId: string;
  productName: string;
  locationId: string;
  locationName: string;
  stock: number;
};

type InventoryMovementFormsProps = {
  options: InventoryOption[];
  canAdjust: boolean;
};

const initialState: InventoryActionState = { status: "idle", message: "" };

function InventoryActionFeedback({ state }: { state: InventoryActionState }) {
  if (state.status === "idle") return null;

  return (
    <p
      className={`text-sm ${state.status === "error" ? "text-rose-700" : "text-emerald-700"}`}
      role={state.status === "error" ? "alert" : "status"}
    >
      {state.message}
    </p>
  );
}

function InventoryOptionList({ options }: { options: InventoryOption[] }) {
  return options.map((option, index) => (
    <option
      key={`${option.productId}-${option.locationId}-${index}`}
      value={`${option.productId}|${option.locationId}`}
    >
      {option.productName} · {option.locationName} · {option.stock} disponibles
    </option>
  ));
}

function parseOption(value: FormDataEntryValue | null) {
  if (typeof value !== "string") return { productId: "", locationId: "" };
  const [productId = "", locationId = ""] = value.split("|");
  return { productId, locationId };
}

export function InventoryMovementForms({
  options,
  canAdjust,
}: InventoryMovementFormsProps) {
  const [wastageState, wastageAction, isWastagePending] = useActionState(
    async (previousState: InventoryActionState, formData: FormData) => {
      const { productId, locationId } = parseOption(
        formData.get("productLocation"),
      );
      formData.set("productId", productId);
      formData.set("locationId", locationId);
      return registerWastage(previousState, formData);
    },
    initialState,
  );
  const [adjustmentState, adjustmentAction, isAdjustmentPending] =
    useActionState(
      async (previousState: InventoryActionState, formData: FormData) => {
        const { productId, locationId } = parseOption(
          formData.get("productLocation"),
        );
        formData.set("productId", productId);
        formData.set("locationId", locationId);
        return registerInventoryAdjustment(previousState, formData);
      },
      initialState,
    );

  if (options.length === 0) {
    return (
      <p className="border-y border-[var(--color-border)] py-5 text-sm text-[var(--color-ink-muted)]">
        No hay productos con inventario rastreable y ubicaciones activas para
        registrar movimientos.
      </p>
    );
  }

  return (
    <section aria-labelledby="inventory-actions-title" className="space-y-4">
      <h2 className="text-lg font-semibold" id="inventory-actions-title">
        Registrar movimiento
      </h2>
      <div
        className={`grid gap-6 ${canAdjust ? "lg:grid-cols-2" : "max-w-2xl"}`}
      >
        <form
          action={wastageAction}
          className="space-y-4 border-y border-[var(--color-border)] py-5"
        >
          <div>
            <h3 className="font-semibold">Merma</h3>
            <p className="mt-1 text-sm text-[var(--color-ink-muted)]">
              La cantidad se descuenta del stock disponible.
            </p>
          </div>
          <label className="block space-y-1.5 text-sm font-medium">
            <span>Producto y ubicación</span>
            <select
              className="w-full rounded-md border border-[var(--color-border)] bg-white px-3 py-2.5 outline-none focus-visible:outline-2 focus-visible:outline-[var(--color-ring)]"
              defaultValue=""
              name="productLocation"
              required
            >
              <option disabled value="">
                Seleccionar
              </option>
              <InventoryOptionList options={options} />
            </select>
          </label>
          <label className="block space-y-1.5 text-sm font-medium">
            <span>Cantidad</span>
            <input
              className="w-full rounded-md border border-[var(--color-border)] bg-white px-3 py-2.5 outline-none focus-visible:outline-2 focus-visible:outline-[var(--color-ring)]"
              min="0.001"
              name="quantity"
              required
              step="0.001"
              type="number"
            />
          </label>
          <label className="block space-y-1.5 text-sm font-medium">
            <span>Motivo</span>
            <textarea
              className="min-h-20 w-full rounded-md border border-[var(--color-border)] bg-white px-3 py-2.5 outline-none focus-visible:outline-2 focus-visible:outline-[var(--color-ring)]"
              maxLength={500}
              minLength={3}
              name="reason"
              required
            />
          </label>
          <InventoryActionFeedback state={wastageState} />
          <button
            className="min-h-10 rounded-md bg-[var(--color-ink)] px-4 text-sm font-medium text-white hover:opacity-95 disabled:opacity-50"
            disabled={isWastagePending}
            type="submit"
          >
            {isWastagePending ? "Registrando…" : "Registrar merma"}
          </button>
        </form>

        {canAdjust && (
          <form
            action={adjustmentAction}
            className="space-y-4 border-y border-[var(--color-border)] py-5"
          >
            <div>
              <h3 className="font-semibold">Ajuste administrativo</h3>
              <p className="mt-1 text-sm text-[var(--color-ink-muted)]">
                Diferencia firmada: positiva para aumentar, negativa para
                disminuir.
              </p>
            </div>
            <label className="block space-y-1.5 text-sm font-medium">
              <span>Producto y ubicación</span>
              <select
                className="w-full rounded-md border border-[var(--color-border)] bg-white px-3 py-2.5 outline-none focus-visible:outline-2 focus-visible:outline-[var(--color-ring)]"
                defaultValue=""
                name="productLocation"
                required
              >
                <option disabled value="">
                  Seleccionar
                </option>
                <InventoryOptionList options={options} />
              </select>
            </label>
            <label className="block space-y-1.5 text-sm font-medium">
              <span>Diferencia de unidades</span>
              <input
                className="w-full rounded-md border border-[var(--color-border)] bg-white px-3 py-2.5 outline-none focus-visible:outline-2 focus-visible:outline-[var(--color-ring)]"
                name="delta"
                required
                step="0.001"
                type="number"
              />
            </label>
            <label className="block space-y-1.5 text-sm font-medium">
              <span>Motivo</span>
              <textarea
                className="min-h-20 w-full rounded-md border border-[var(--color-border)] bg-white px-3 py-2.5 outline-none focus-visible:outline-2 focus-visible:outline-[var(--color-ring)]"
                maxLength={500}
                minLength={3}
                name="reason"
                required
              />
            </label>
            <InventoryActionFeedback state={adjustmentState} />
            <button
              className="min-h-10 rounded-md border border-[var(--color-border)] bg-white px-4 text-sm font-medium hover:bg-[var(--color-surface-muted)] disabled:opacity-50"
              disabled={isAdjustmentPending}
              type="submit"
            >
              {isAdjustmentPending ? "Guardando…" : "Registrar ajuste"}
            </button>
          </form>
        )}
      </div>
    </section>
  );
}
