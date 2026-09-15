"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

export default function DashboardNav() {
  const pathname = usePathname();

  const tabs = [
    { name: "Applications", href: "/dashboard" },
    { name: "Verification Stages", href: "/dashboard/verification" },
    { name: "Checking", href: "/dashboard/checking" },
    { name: "Reports", href: "/dashboard/reports" },
  ];

  return (
    <div className="bg-white shadow-sm border-b border-gray-200">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between h-16">
          <div className="flex">
            <div className="hidden sm:-my-px sm:ml-6 sm:flex sm:space-x-8">
              {tabs.map((tab) => {
                // Exact match for dashboard to avoid highlighting it on sub-routes
                const isActive =
                  tab.href === "/dashboard"
                    ? pathname === "/dashboard"
                    : pathname.startsWith(tab.href);
                return (
                  <Link
                    key={tab.name}
                    href={tab.href}
                    className={`${
                      isActive
                        ? "border-blue-500 text-gray-900"
                        : "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300"
                    } inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium transition-colors duration-200`}
                  >
                    {tab.name}
                  </Link>
                );
              })}
            </div>
          </div>
          
          {/* Mobile menu could go here if needed later */}
          <div className="flex items-center sm:hidden">
            <span className="text-gray-500 font-medium">Dashboard Menu</span>
          </div>
        </div>
      </div>
    </div>
  );
}
