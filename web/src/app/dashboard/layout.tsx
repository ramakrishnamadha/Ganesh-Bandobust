import type { ReactNode } from "react";
import { cookies } from "next/headers";
import { redirect } from "next/navigation";

import { prisma } from "@/lib/prisma";

import {
  SESSION_COOKIE_NAME,
  verifySessionToken,
} from "@/lib/server/auth";
import DashboardNav from "@/components/DashboardNav";

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
    <div className="min-h-screen bg-gray-50 flex flex-col">
      <DashboardNav />
      <main className="flex-1 w-full max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
        {children}
      </main>
    </div>
  );
}