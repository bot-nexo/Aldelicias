import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

describe("inventory migration contract", () => {
  it("adds scoped reads, admin adjustments, movement integrity, and append-only history", () => {
    const migration = readFileSync(
      resolve(
        process.cwd(),
        "supabase/migrations/010_inventory_management.sql",
      ),
      "utf8",
    );

    expect(migration).toMatch(/get_inventory_stock/i);
    expect(migration).toMatch(/get_inventory_movement_history/i);
    expect(migration).toMatch(/adjust_inventory_stock/i);
    expect(migration).toMatch(/app_private\.actor\([\s\S]*?'INVENTORY_ADMIN'/i);
    expect(migration).toMatch(/current_business_id\(\)/i);
    expect(migration).toMatch(/before insert on public\.inventory_movements/i);
    expect(migration).toMatch(
      /before update or delete on public\.inventory_movements/i,
    );
    expect(migration).toMatch(/for update/i);
    expect(migration).toMatch(/insufficient stock|negative stock/i);
  });
});
