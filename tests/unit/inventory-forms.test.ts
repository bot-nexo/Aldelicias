import { createElement } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { describe, expect, it, vi } from "vitest";

vi.mock("@/app/admin/inventario/actions", () => ({
  registerInventoryAdjustment: vi.fn(),
  registerWastage: vi.fn(),
}));

import { InventoryMovementForms } from "@/components/admin/inventory/inventory-movement-forms";

const options = [
  {
    productId: "30000000-0000-4000-8000-000000000001",
    productName: "Buñuelo",
    locationId: "40000000-0000-4000-8000-000000000001",
    locationName: "Furgón",
    stock: 8,
  },
];

describe("inventory movement forms", () => {
  it("lets collaborators register wastage without rendering manual adjustment", () => {
    const html = renderToStaticMarkup(
      createElement(InventoryMovementForms, { options, canAdjust: false }),
    );

    expect(html).toContain("Registrar merma");
    expect(html).toContain("Buñuelo · Furgón · 8 disponibles");
    expect(html).not.toContain("Ajuste administrativo");
  });

  it("renders the adjustment form for administrators", () => {
    const html = renderToStaticMarkup(
      createElement(InventoryMovementForms, { options, canAdjust: true }),
    );

    expect(html).toContain("Ajuste administrativo");
    expect(html).toContain("Registrar ajuste");
  });
});
