import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

describe("migration 008 category policy cleanup", () => {
  it("drops only the inherited categories_admin policy without changing rows or other policies", () => {
    const migration = readFileSync(
      resolve(
        process.cwd(),
        "supabase/migrations/008_remove_legacy_categories_admin_policy.sql",
      ),
      "utf8",
    );
    const droppedPolicies = [
      ...migration.matchAll(/drop\s+policy\s+if\s+exists\s+([\w_]+)/gi),
    ].map((match) => match[1]);

    expect(droppedPolicies).toEqual(["categories_admin"]);
    expect(migration).not.toMatch(
      /\b(delete\s+from|truncate|drop\s+table|alter\s+table)\b/i,
    );
  });
});
