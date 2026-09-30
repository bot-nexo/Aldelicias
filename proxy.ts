import { createServerClient } from "@supabase/ssr";
import { NextResponse, type NextRequest } from "next/server";

import { getPublicSupabaseEnv, hasPublicSupabaseEnv } from "@/lib/env";
import type { Database } from "@/types/database";

export async function proxy(request: NextRequest) {
  if (!hasPublicSupabaseEnv()) {
    return NextResponse.redirect(
      new URL("/login?reason=configuration", request.url),
    );
  }

  const { url, anonKey } = getPublicSupabaseEnv();
  let response = NextResponse.next({ request });
  const supabase = createServerClient<Database>(url, anonKey, {
    cookies: {
      getAll() {
        return request.cookies.getAll();
      },
      setAll(cookiesToSet) {
        cookiesToSet.forEach(({ name, value }) =>
          request.cookies.set(name, value),
        );
        response = NextResponse.next({ request });
        cookiesToSet.forEach(({ name, value, options }) =>
          response.cookies.set(name, value, options),
        );
      },
    },
  });

  const {
    data: { user },
    error,
  } = await supabase.auth.getUser();

  if (error || !user) {
    return NextResponse.redirect(new URL("/login?reason=access", request.url));
  }

  return response;
}

export const config = {
  matcher: ["/admin/:path*"],
};
