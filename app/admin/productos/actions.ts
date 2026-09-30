"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { z } from "zod";

import { requireActiveUserProfile } from "@/lib/auth/session";
import { createClient } from "@/lib/supabase/server";

const productSchema = z.object({
  name: z.string().trim().min(2, "El nombre del producto es obligatorio."),
  slug: z.string().trim().min(2, "El slug debe tener al menos 2 caracteres."),
  shortDescription: z.string().trim().optional().default(""),
  categoryId: z.string().uuid().or(z.literal("")).optional().default(""),
  salePrice: z.coerce
    .number()
    .min(0, "El precio debe ser mayor o igual a cero."),
  costPrice: z.coerce
    .number()
    .min(0, "El costo debe ser mayor o igual a cero."),
  status: z.enum(["DRAFT", "PUBLISHED", "HIDDEN", "OUT_OF_STOCK"]),
  trackInventory: z
    .string()
    .optional()
    .transform((value) => value === "on"),
  minimumStock: z.coerce
    .number()
    .min(0, "El stock mínimo no puede ser negativo."),
});

const updateProductSchema = productSchema;

async function validateCategory(
  supabase: Awaited<ReturnType<typeof createClient>>,
  categoryId: string,
  businessId: string,
  existingCategoryId: string | null = null,
) {
  if (!categoryId) return null;

  const { data, error } = await supabase
    .from("categories")
    .select("id, is_active")
    .eq("id", categoryId)
    .eq("business_id", businessId)
    .eq("is_active", true)
    .maybeSingle();

  if (error || !data || (!data.is_active && data.id !== existingCategoryId)) {
    throw new Error("Selecciona una categoría activa de este negocio.");
  }

  return data.id;
}

export async function createProduct(formData: FormData) {
  const profile = await requireActiveUserProfile();

  const parsed = productSchema.safeParse({
    name: formData.get("name"),
    slug: formData.get("slug"),
    shortDescription: formData.get("shortDescription"),
    categoryId: formData.get("categoryId"),
    salePrice: formData.get("salePrice"),
    costPrice: formData.get("costPrice"),
    status: formData.get("status"),
    trackInventory: formData.get("trackInventory"),
    minimumStock: formData.get("minimumStock"),
  });

  if (!parsed.success) {
    throw new Error(
      parsed.error.issues[0]?.message ?? "Datos del producto inválidos.",
    );
  }

  const payload = parsed.data;
  const supabase = await createClient();
  const categoryId = await validateCategory(
    supabase,
    payload.categoryId,
    profile.business_id,
  );

  const { error } = await supabase.from("products").insert({
    business_id: profile.business_id,
    category_id: categoryId,
    name: payload.name,
    slug: payload.slug,
    short_description: payload.shortDescription || null,
    sale_price: payload.salePrice,
    cost_price: payload.costPrice || null,
    status: payload.status,
    track_inventory: payload.trackInventory,
    minimum_stock: payload.minimumStock,
  });

  if (error) {
    throw new Error(error.message || "No se pudo crear el producto.");
  }

  revalidatePath("/admin/productos");
  redirect("/admin/productos");
}

export async function updateProduct(productId: string, formData: FormData) {
  const profile = await requireActiveUserProfile();

  const parsed = updateProductSchema.safeParse({
    name: formData.get("name"),
    slug: formData.get("slug"),
    shortDescription: formData.get("shortDescription"),
    categoryId: formData.get("categoryId"),
    salePrice: formData.get("salePrice"),
    costPrice: formData.get("costPrice"),
    status: formData.get("status"),
    trackInventory: formData.get("trackInventory"),
    minimumStock: formData.get("minimumStock"),
  });

  if (!parsed.success) {
    throw new Error(
      parsed.error.issues[0]?.message ?? "Datos del producto inválidos.",
    );
  }

  const payload = parsed.data;
  const supabase = await createClient();
  const { data: currentProduct, error: currentProductError } = await supabase
    .from("products")
    .select("category_id")
    .eq("id", productId)
    .eq("business_id", profile.business_id)
    .maybeSingle();

  if (currentProductError || !currentProduct) {
    throw new Error("No se encontró el producto en este negocio.");
  }

  const categoryId = await validateCategory(
    supabase,
    payload.categoryId,
    profile.business_id,
    currentProduct.category_id,
  );

  const productUpdates = {
    name: payload.name,
    slug: payload.slug,
    short_description: payload.shortDescription || null,
    sale_price: payload.salePrice,
    cost_price: payload.costPrice || null,
    status: payload.status,
    track_inventory: payload.trackInventory,
    minimum_stock: payload.minimumStock,
    ...(categoryId !== currentProduct.category_id
      ? { category_id: categoryId }
      : {}),
  };

  const { error } = await supabase
    .from("products")
    .update(productUpdates)
    .eq("id", productId)
    .eq("business_id", profile.business_id);

  if (error) {
    throw new Error(error.message || "No se pudo actualizar el producto.");
  }

  revalidatePath("/admin/productos");
  redirect("/admin/productos");
}

export async function hideProduct(productId: string, formData: FormData) {
  void formData;
  const profile = await requireActiveUserProfile();
  const supabase = await createClient();

  const { data, error } = await supabase
    .from("products")
    .update({ status: "HIDDEN" })
    .eq("id", productId)
    .eq("business_id", profile.business_id)
    .select("id")
    .maybeSingle();

  if (error || !data) {
    throw new Error(error?.message || "No se pudo ocultar el producto.");
  }

  revalidatePath("/admin/productos");
  redirect("/admin/productos");
}

const categorySchema = z.object({
  name: z.string().trim().min(2, "El nombre de la categoría es obligatorio."),
  slug: z.string().trim().min(2, "El slug debe tener al menos 2 caracteres."),
  description: z.string().trim().optional().default(""),
  sortOrder: z.coerce.number().int().min(0, "El orden no puede ser negativo."),
});

const updateCategorySchema = categorySchema.extend({
  isActive: z
    .string()
    .optional()
    .transform((value) => value === "on"),
});

function assertAdmin(role: string) {
  if (role !== "ADMIN") {
    throw new Error("Solo un administrador puede gestionar categorías.");
  }
}

function revalidateCategoryViews() {
  revalidatePath("/admin/productos");
  revalidatePath("/admin/productos/nuevo");
  revalidatePath("/admin/productos/categorias");
  revalidatePath("/admin/productos/[id]/editar", "page");
}

export async function createCategory(formData: FormData) {
  const profile = await requireActiveUserProfile();
  assertAdmin(profile.role);

  const parsed = categorySchema.safeParse({
    name: formData.get("name"),
    slug: formData.get("slug"),
    description: formData.get("description"),
    sortOrder: formData.get("sortOrder"),
  });

  if (!parsed.success) {
    throw new Error(
      parsed.error.issues[0]?.message ?? "Datos de categoría inválidos.",
    );
  }

  const supabase = await createClient();
  const { error } = await supabase.from("categories").insert({
    business_id: profile.business_id,
    name: parsed.data.name,
    slug: parsed.data.slug,
    description: parsed.data.description || null,
    sort_order: parsed.data.sortOrder,
    is_active: true,
  });

  if (error) {
    throw new Error(
      error.code === "23505"
        ? "Ya existe una categoría con ese slug."
        : "No se pudo crear la categoría.",
    );
  }

  revalidateCategoryViews();
  redirect("/admin/productos/categorias");
}

export async function updateCategory(categoryId: string, formData: FormData) {
  const profile = await requireActiveUserProfile();
  assertAdmin(profile.role);

  const parsed = updateCategorySchema.safeParse({
    name: formData.get("name"),
    slug: formData.get("slug"),
    description: formData.get("description"),
    sortOrder: formData.get("sortOrder"),
    isActive: formData.get("isActive"),
  });

  if (!parsed.success) {
    throw new Error(
      parsed.error.issues[0]?.message ?? "Datos de categoría inválidos.",
    );
  }

  const supabase = await createClient();
  const { data, error } = await supabase
    .from("categories")
    .update({
      name: parsed.data.name,
      slug: parsed.data.slug,
      description: parsed.data.description || null,
      sort_order: parsed.data.sortOrder,
      is_active: parsed.data.isActive,
    })
    .eq("id", categoryId)
    .eq("business_id", profile.business_id)
    .select("id")
    .maybeSingle();

  if (error || !data) {
    throw new Error(
      error?.code === "23505"
        ? "Ya existe una categoría con ese slug."
        : "No se pudo actualizar la categoría.",
    );
  }

  revalidateCategoryViews();
  redirect("/admin/productos/categorias");
}

export async function deactivateCategory(
  categoryId: string,
  formData: FormData,
) {
  void formData;
  const profile = await requireActiveUserProfile();
  assertAdmin(profile.role);
  const supabase = await createClient();

  const { data, error } = await supabase
    .from("categories")
    .update({ is_active: false })
    .eq("id", categoryId)
    .eq("business_id", profile.business_id)
    .select("id")
    .maybeSingle();

  if (error || !data) {
    throw new Error("No se pudo desactivar la categoría.");
  }

  revalidateCategoryViews();
  redirect("/admin/productos/categorias");
}
