import { beforeEach, describe, expect, it, vi } from "vitest";

const {
  createClient,
  requireActiveUserProfile,
  revalidatePath,
  redirect,
  query,
} = vi.hoisted(() => {
  const query = {
    eq: vi.fn(),
    maybeSingle: vi.fn(),
    select: vi.fn(),
    update: vi.fn(),
  };
  query.eq.mockReturnValue(query);
  query.select.mockReturnValue(query);
  query.update.mockReturnValue(query);

  return {
    createClient: vi.fn(),
    requireActiveUserProfile: vi.fn(),
    revalidatePath: vi.fn(),
    redirect: vi.fn(),
    query,
  };
});

vi.mock("next/cache", () => ({ revalidatePath }));
vi.mock("next/navigation", () => ({ redirect }));
vi.mock("@/lib/auth/session", () => ({ requireActiveUserProfile }));
vi.mock("@/lib/supabase/server", () => ({ createClient }));

import { createCategory, hideProduct } from "@/app/admin/productos/actions";

describe("product actions", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    query.eq.mockReturnValue(query);
    query.select.mockReturnValue(query);
    query.update.mockReturnValue(query);
    query.maybeSingle.mockResolvedValue({
      data: { id: "product-1" },
      error: null,
    });
    requireActiveUserProfile.mockResolvedValue({
      business_id: "business-1",
      role: "ADMIN",
    });
    createClient.mockResolvedValue({
      from: vi.fn().mockReturnValue(query),
    });
  });

  it("hides a product within the active business without deleting it", async () => {
    await hideProduct("product-1", new FormData());

    expect(query.update).toHaveBeenCalledWith({ status: "HIDDEN" });
    expect(query.eq).toHaveBeenCalledWith("id", "product-1");
    expect(query.eq).toHaveBeenCalledWith("business_id", "business-1");
    expect(revalidatePath).toHaveBeenCalledWith("/admin/productos");
    expect(redirect).toHaveBeenCalledWith("/admin/productos");
  });

  it("rejects category management for collaborators before accessing the database", async () => {
    requireActiveUserProfile.mockResolvedValue({
      business_id: "business-1",
      role: "COLLABORATOR",
    });

    await expect(createCategory(new FormData())).rejects.toThrow(
      "Solo un administrador puede gestionar categorías.",
    );
    expect(createClient).not.toHaveBeenCalled();
  });
});
