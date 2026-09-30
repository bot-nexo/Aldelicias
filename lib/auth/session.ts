import "server-only";

import { redirect } from "next/navigation";

import { createClient } from "@/lib/supabase/server";
import type { UserProfile } from "@/types/database";

export async function getActiveUserProfile(): Promise<UserProfile | null> {
  const supabase = await createClient();
  const {
    data: { user },
    error: authError,
  } = await supabase.auth.getUser();

  if (authError) throw new Error("No se pudo validar la sesión.");
  if (!user) return null;

  const { data: profile, error: profileError } = await supabase
    .from("users")
    .select("id, business_id, full_name, email, role_id, is_active")
    .eq("auth_user_id", user.id)
    .eq("is_active", true)
    .maybeSingle();

  if (profileError)
    throw new Error("No se pudo validar el perfil administrativo.");
  if (!profile) return null;

  const { data: role, error: roleError } = await supabase
    .from("roles")
    .select("name")
    .eq("id", profile.role_id)
    .maybeSingle();

  if (roleError || !role)
    throw new Error("No se pudo validar el rol del usuario.");
  return { ...profile, role: role.name };
}

export async function requireActiveUserProfile() {
  const profile = await getActiveUserProfile();
  if (!profile) redirect("/login?reason=access");
  return profile;
}
