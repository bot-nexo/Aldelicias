"use server";

import { revalidatePath } from "next/cache";
import { z } from "zod";

import { requireActiveUserProfile } from "@/lib/auth/session";
import { createClient } from "@/lib/supabase/server";

export type InventoryActionState = {
  status: "idle" | "success" | "error";
  message: string;
};

const wastageSchema = z.object({
  productId: z.string().uuid("Selecciona un producto válido."),
  locationId: z.string().uuid("Selecciona una ubicación válida."),
  quantity: z.coerce
    .number()
    .positive("La cantidad debe ser mayor que cero.")
    .refine(
      (value) =>
        Number.isFinite(value) &&
        Math.abs(value * 1000 - Math.round(value * 1000)) < 1e-7,
      "La cantidad admite hasta tres decimales.",
    ),
  reason: z.string().trim().min(3, "Indica el motivo de la merma.").max(500),
});

const adjustmentSchema = z.object({
  productId: z.string().uuid("Selecciona un producto válido."),
  locationId: z.string().uuid("Selecciona una ubicación válida."),
  delta: z.coerce
    .number()
    .refine((value) => value !== 0, "El ajuste no puede ser cero.")
    .refine(
      (value) =>
        Number.isFinite(value) &&
        Math.abs(value * 1000 - Math.round(value * 1000)) < 1e-7,
      "El ajuste admite hasta tres decimales.",
    ),
  reason: z.string().trim().min(3, "Indica el motivo del ajuste.").max(500),
});

export async function registerWastage(
  previousState: InventoryActionState,
  formData: FormData,
): Promise<InventoryActionState> {
  void previousState;
  const parsed = wastageSchema.safeParse({
    productId: formData.get("productId"),
    locationId: formData.get("locationId"),
    quantity: formData.get("quantity"),
    reason: formData.get("reason"),
  });

  if (!parsed.success) {
    return {
      status: "error",
      message:
        parsed.error.issues[0]?.message ?? "Revisa los datos de la merma.",
    };
  }

  await requireActiveUserProfile();
  const supabase = await createClient();
  const { error } = await supabase.rpc("register_wastage", {
    p_product_id: parsed.data.productId,
    p_location_id: parsed.data.locationId,
    p_quantity: parsed.data.quantity,
    p_reason: parsed.data.reason,
  });

  if (error) {
    return {
      status: "error",
      message: /insufficient stock/i.test(error.message)
        ? "La cantidad supera las existencias disponibles."
        : "No se pudo registrar la merma. Verifica producto, ubicación y permisos.",
    };
  }

  revalidatePath("/admin/inventario");
  return { status: "success", message: "Merma registrada." };
}

export async function registerInventoryAdjustment(
  previousState: InventoryActionState,
  formData: FormData,
): Promise<InventoryActionState> {
  void previousState;
  const profile = await requireActiveUserProfile();
  if (profile.role !== "ADMIN") {
    return { status: "error", message: "Solo ADMIN puede realizar ajustes." };
  }

  const parsed = adjustmentSchema.safeParse({
    productId: formData.get("productId"),
    locationId: formData.get("locationId"),
    delta: formData.get("delta"),
    reason: formData.get("reason"),
  });

  if (!parsed.success) {
    return {
      status: "error",
      message:
        parsed.error.issues[0]?.message ?? "Revisa los datos del ajuste.",
    };
  }

  const supabase = await createClient();
  const { error } = await supabase.rpc("adjust_inventory_stock", {
    p_product_id: parsed.data.productId,
    p_location_id: parsed.data.locationId,
    p_delta: parsed.data.delta,
    p_reason: parsed.data.reason,
  });

  if (error) {
    return {
      status: "error",
      message: /negative stock/i.test(error.message)
        ? "El ajuste no puede dejar existencias negativas."
        : "No se pudo registrar el ajuste. Verifica producto, ubicación y permisos.",
    };
  }

  revalidatePath("/admin/inventario");
  return { status: "success", message: "Ajuste registrado." };
}
