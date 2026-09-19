import type { ReactNode } from "react";
import { cookies } from "next/headers";
import { redirect } from "next/navigation";

import { prisma } from "@/lib/prisma";

import {
  SESSION_COOKIE_NAME,
  verifySessionToken,
} from "@/lib/server/auth";
import SidebarNav from "@/components/SidebarNav";

export default async function DashboardLayout({
  children,
}: {
  children: ReactNode;
}) {
  const cookieStore = await cookies();

  const token = cookieStore.get(SESSION_COOKIE_NAME)?.value;

  const session = verifySessionToken(token);

  // No valid signed login session.
  if (!session) {
    redirect("/");
  }

  // Always check the current database record.
  // Do not rely only on localStorage or the old cookie value.
  const user = await prisma.user.findUnique({
    where: {
      id: session.userId,
    },
    select: {
      status: true,
      mustChangePassword: true,
    },
  });

  if (!user || user.status !== "ACTIVE") {
    redirect("/");
  }

  // A first-time user cannot manually bypass the password-change page.
  if (user.mustChangePassword) {
    redirect("/change-password");
  }

  return (
    <div className="min-h-screen bg-slate-100 flex flex-col md:flex-row">
      <SidebarNav />
      <main className="flex-1 w-full p-4 sm:p-6 lg:p-8 min-w-0">
        {children}
      </main>
    </div>
  );
}