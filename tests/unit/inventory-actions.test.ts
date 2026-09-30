import { beforeEach, describe, expect, it, vi } from "vitest";

const { createClient, requireActiveUserProfile, rpc } = vi.hoisted(() => ({
  createClient: vi.fn(),
  requireActiveUserProfile: vi.fn(),
  rpc: vi.fn(),
}));

vi.mock("next/cache", () => ({ revalidatePath: vi.fn() }));
vi.mock("@/lib/auth/session", () => ({ requireActiveUserProfile }));
vi.mock("@/lib/supabase/server", () => ({ createClient }));

import {
  registerInventoryAdjustment,
  registerWastage,
} from "@/app/admin/inventario/actions";

function form(values: Record<string, string>) {
  const formData = new FormData();
  for (const [key, value] of Object.entries(values)) formData.set(key, value);
  return formData;
}

const validMovement = {
  productId: "30000000-0000-4000-8000-000000000001",
  locationId: "40000000-0000-4000-8000-000000000001",
};

describe("inventory actions", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    requireActiveUserProfile.mockResolvedValue({ role: "ADMIN" });
    rpc.mockResolvedValue({ error: null });
    createClient.mockResolvedValue({ rpc });
  });

  it("routes valid wastage to the existing database RPC", async () => {
    const result = await registerWastage(
      { status: "idle", message: "" },
      form({ ...validMovement, quantity: "1.250", reason: "Producto vencido" }),
    );

    expect(result).toEqual({ status: "success", message: "Merma registrada." });
    expect(rpc).toHaveBeenCalledWith("register_wastage", {
      p_product_id: validMovement.productId,
      p_location_id: validMovement.locationId,
      p_quantity: 1.25,
      p_reason: "Producto vencido",
    });
  });

  it("blocks a collaborator adjustment before calling the database", async () => {
    requireActiveUserProfile.mockResolvedValue({ role: "COLLABORATOR" });

    const result = await registerInventoryAdjustment(
      { status: "idle", message: "" },
      form({ ...validMovement, delta: "2", reason: "Conteo físico" }),
    );

    expect(result).toEqual({
      status: "error",
      message: "Solo ADMIN puede realizar ajustes.",
    });
    expect(rpc).not.toHaveBeenCalled();
  });

  it("routes valid admin adjustments to the transactional database RPC", async () => {
    const result = await registerInventoryAdjustment(
      { status: "idle", message: "" },
      form({ ...validMovement, delta: "-0.500", reason: "Conteo físico" }),
    );

    expect(result).toEqual({
      status: "success",
      message: "Ajuste registrado.",
    });
    expect(rpc).toHaveBeenCalledWith("adjust_inventory_stock", {
      p_product_id: validMovement.productId,
      p_location_id: validMovement.locationId,
      p_delta: -0.5,
      p_reason: "Conteo físico",
    });
  });
});
