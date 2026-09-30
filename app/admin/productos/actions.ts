"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { z } from "zod";

import { requireActiveUserProfile } from "@/lib/auth/session";
import { createClient } from "@/lib/supabase/server";

const productSchema = z.object({
  name: z.string().trim().min(2, "El nombre del producto es obligatorio."),
  slug: z
    .string()
    .trim()
    .min(2, "El slug debe tener al menos 2 caracteres."),
  shortDescription: z.string().trim().optional().default(""),
  salePrice: z.coerce.number().min(0, "El precio debe ser mayor o igual a cero."),
  costPrice: z.coerce.number().min(0, "El costo debe ser mayor o igual a cero."),
  status: z.enum(["DRAFT", "PUBLISHED", "HIDDEN", "OUT_OF_STOCK"]),
  trackInventory: z
    .string()
    .optional()
    .transform((value) => value === "on"),
  minimumStock: z.coerce.number().min(0, "El stock mínimo no puede ser negativo."),
});

export async function createProduct(formData: FormData) {
  const profile = await requireActiveUserProfile();

  const parsed = productSchema.safeParse({
    name: formData.get("name"),
    slug: formData.get("slug"),
    shortDescription: formData.get("shortDescription"),
    salePrice: formData.get("salePrice"),
    costPrice: formData.get("costPrice"),
    status: formData.get("status"),
    trackInventory: formData.get("trackInventory"),
    minimumStock: formData.get("minimumStock"),
  });

  if (!parsed.success) {
    throw new Error(parsed.error.issues[0]?.message ?? "Datos del producto inválidos.");
  }

  const payload = parsed.data;
  const supabase = await createClient();

  const { error } = (await (supabase as any).from("products").insert({
    business_id: profile.business_id,
    name: payload.name,
    slug: payload.slug,
    short_description: payload.shortDescription || null,
    sale_price: payload.salePrice,
    cost_price: payload.costPrice || null,
    status: payload.status,
    track_inventory: payload.trackInventory,
    minimum_stock: payload.minimumStock,
  })) as { error: any };

  if (error) {
    throw new Error(error.message || "No se pudo crear el producto.");
  }

  revalidatePath("/admin/productos");
  redirect("/admin/productos");
}
