"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

export default function DashboardNav() {
  const pathname = usePathname();

  const tabs = [
    { name: "Dashboard", href: "/dashboard" },
    { name: "Applications", href: "/dashboard/applications" },
    { name: "5 Stages", href: "/dashboard/verification" },
    { name: "Visitings", href: "/dashboard/visitings" },
    { name: "Reports", href: "/dashboard/reports" },
    { name: "Settings", href: "/dashboard/settings" },
  ];

  return (
    <div className="border-b border-gray-200 bg-white shadow-sm">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="overflow-x-auto">
          <div className="flex h-16 min-w-max items-center gap-6">
            {tabs.map((tab) => {
              const isActive =
                tab.href === "/dashboard"
                  ? pathname === "/dashboard"
                  : pathname.startsWith(tab.href);

              return (
                <Link
                  key={tab.name}
                  href={tab.href}
                  className={`inline-flex h-16 items-center border-b-2 px-1 text-sm font-semibold transition-colors duration-200 ${
                    isActive
                      ? "border-blue-600 text-blue-700"
                      : "border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-800"
                  }`}
                >
                  {tab.name}
                </Link>
              );
            })}
          </div>
        </div>
      </div>
    </div>
  );
}