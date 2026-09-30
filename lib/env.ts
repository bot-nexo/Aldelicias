import { z } from "zod";

export const publicSupabaseEnvSchema = z.object({
  url: z.url(),
  anonKey: z.string().min(1),
});

export function getPublicSupabaseEnv() {
  return publicSupabaseEnvSchema.parse({
    url: process.env.NEXT_PUBLIC_SUPABASE_URL,
    anonKey: process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY,
  });
}

export function hasPublicSupabaseEnv() {
  return publicSupabaseEnvSchema.safeParse({
    url: process.env.NEXT_PUBLIC_SUPABASE_URL,
    anonKey: process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY,
  }).success;
}
