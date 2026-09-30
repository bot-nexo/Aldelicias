import { createElement } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { describe, expect, it } from "vitest";

import { ProductList } from "@/components/admin/products/product-list";

describe("Product list actions", () => {
  it("renders the edit link for each product in the catalog", () => {
    const html = renderToStaticMarkup(
      createElement(ProductList, {
        products: [
          {
            id: "product-1",
            name: "Empanada de queso",
            category: "Salados",
            status: "PUBLISHED",
            price: 3500,
            cost: 2100,
            stock: 18,
            minimumStock: 12,
          },
        ],
      }),
    );

    expect(html).toContain("Editar");
    expect(html).toContain("/admin/productos/product-1/editar");
  });
});
