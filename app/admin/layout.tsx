import type { ReactNode } from "react";

import { AdminShell } from "@/components/admin/admin-shell";
import { requireActiveUserProfile } from "@/lib/auth/session";

export const dynamic = "force-dynamic";

export default async function AdminLayout({
  children,
}: Readonly<{ children: ReactNode }>) {
  const profile = await requireActiveUserProfile();

  return <AdminShell profile={profile}>{children}</AdminShell>;
}
