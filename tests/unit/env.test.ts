import { afterEach, describe, expect, it, vi } from "vitest";

import { hasPublicSupabaseEnv, publicSupabaseEnvSchema } from "@/lib/env";

describe("public Supabase environment", () => {
  afterEach(() => vi.unstubAllEnvs());

  it("accepts a valid URL and a non-empty public key", () => {
    expect(
      publicSupabaseEnvSchema.safeParse({
        url: "https://example.supabase.co",
        anonKey: "public-test-key",
      }).success,
    ).toBe(true);
  });

  it("rejects missing or malformed configuration", () => {
    expect(
      publicSupabaseEnvSchema.safeParse({ url: "not-a-url", anonKey: "" })
        .success,
    ).toBe(false);
  });

  it("reports whether both public environment values are present", () => {
    vi.stubEnv("NEXT_PUBLIC_SUPABASE_URL", "https://example.supabase.co");
    vi.stubEnv("NEXT_PUBLIC_SUPABASE_ANON_KEY", "public-test-key");
    expect(hasPublicSupabaseEnv()).toBe(true);

    vi.stubEnv("NEXT_PUBLIC_SUPABASE_ANON_KEY", "");
    expect(hasPublicSupabaseEnv()).toBe(false);
  });
});
