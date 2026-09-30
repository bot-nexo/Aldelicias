import { createElement } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { describe, expect, it, vi } from "vitest";

vi.mock("@/app/admin/productos/actions", () => ({
  createProduct: vi.fn(),
  updateProduct: vi.fn(),
}));

import { ProductForm } from "@/components/admin/products/product-form";

describe("Product form categories", () => {
  it("renders real categories and selects the product's current category", () => {
    const html = renderToStaticMarkup(
      createElement(ProductForm, {
        categories: [
          { id: "category-1", name: "Salados" },
          { id: "category-2", name: "Bebidas" },
        ],
        initialValues: { categoryId: "category-2" },
        mode: "edit",
        productId: "product-1",
      }),
    );

    expect(html).toContain('name="categoryId"');
    expect(html).toContain("Salados");
    expect(html).toContain("Bebidas");
    expect(html).toContain(
      '<option value="category-2" selected="">Bebidas</option>',
    );
  });
});
