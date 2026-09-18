import type { ReactNode } from "react";
import SidebarNav from "@/components/SidebarNav";

export default function InstallationLayout({
  children,
}: {
  children: ReactNode;
}) {
  return (
    <div className="min-h-screen bg-slate-100 flex flex-col md:flex-row">
      <SidebarNav />
      <main className="flex-1 w-full p-4 sm:p-6 lg:p-8 min-w-0">
        {children}
      </main>
    </div>
  );
}
