import { describe, expect, it } from "vitest";

import {
  getProductImageExtension,
  validateProductImage,
} from "@/lib/products/product-image-validation";

describe("product image validation", () => {
  it("accepts supported image formats within the size and dimension limits", () => {
    expect(getProductImageExtension("image/webp")).toBe("webp");
    expect(
      validateProductImage({
        type: "image/webp",
        size: 1024,
        width: 1600,
        height: 1200,
      }),
    ).toBeNull();
  });

  it("rejects unsupported formats, oversized files, and oversized dimensions", () => {
    expect(
      validateProductImage({
        type: "image/svg+xml",
        size: 1024,
        width: 100,
        height: 100,
      }),
    ).toContain("JPEG, PNG o WebP");
    expect(
      validateProductImage({
        type: "image/jpeg",
        size: 6 * 1024 * 1024,
        width: 100,
        height: 100,
      }),
    ).toContain("5 MB");
    expect(
      validateProductImage({
        type: "image/png",
        size: 1024,
        width: 2401,
        height: 100,
      }),
    ).toContain("2400");
  });
});
