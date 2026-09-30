import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

describe("product image storage migration", () => {
  it("creates a public catalog bucket with scoped authenticated storage policies", () => {
    const migration = readFileSync(
      resolve(
        process.cwd(),
        "supabase/migrations/009_product_image_storage_management.sql",
      ),
      "utf8",
    );

    expect(migration).toContain("'product-images'");
    expect(migration).toContain("'image/jpeg', 'image/png', 'image/webp'");
    expect(migration).toMatch(
      /create policy product_image_storage_insert_admin on storage\.objects\s+for insert to authenticated/i,
    );
    expect(migration).toMatch(
      /create policy product_image_storage_delete_admin on storage\.objects\s+for delete to authenticated/i,
    );
    expect(
      migration.match(/create policy product_image_storage_/g),
    ).toHaveLength(6);
    expect(migration).toContain("public.current_business_id()");
    expect(migration).toContain("public.is_admin()");
    expect(migration).toMatch(/as restrictive for insert to public/i);
    expect(migration).toMatch(/as restrictive for update to public/i);
    expect(migration).toMatch(/as restrictive for delete to public/i);
    expect(migration).toContain("product_images_one_primary_per_product");
    expect(migration).not.toMatch(/\b(delete\s+from|truncate|drop\s+table)\b/i);
  });
});
