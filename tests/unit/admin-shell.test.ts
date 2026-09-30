import { createElement } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { describe, expect, it, vi } from "vitest";

vi.mock("next/navigation", () => ({
  useRouter: () => ({
    push: vi.fn(),
    refresh: vi.fn(),
  }),
}));

import { AdminShell } from "@/components/admin/admin-shell";

describe("Admin shell navigation", () => {
  it("shows the products section in the admin navigation", () => {
    const children = createElement("div", null, "Contenido");
    const html = renderToStaticMarkup(
      createElement(AdminShell, {
        profile: {
          id: "user-1",
          business_id: "business-1",
          full_name: "Ana Gómez",
          email: "ana@aldelicias.co",
          role_id: "role-1",
          is_active: true,
          role: "ADMIN",
        },
        children,
      }),
    );

    expect(html).toContain("Productos");
    expect(html).toContain("/admin/productos");
  });
});
