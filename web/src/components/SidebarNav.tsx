"use client";

import { useState, useEffect } from "react";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";

type SubMenuItem = {
  name: string;
  href: string;
  badgeLabel?: string;
  activeBg: string;
  inactiveBg: string;
  badgeColor: string;
  badgeTextColor: string;
};

type MenuItem = {
  name: string;
  href?: string;
  activeCardStyle: string;
  inactiveCardStyle: string;
  iconBoxActive: string;
  iconBoxInactive: string;
  icon: (props: { className?: string }) => React.ReactNode;
  children?: SubMenuItem[];
};

export default function SidebarNav() {
  const pathname = usePathname();
  const router = useRouter();
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const [isLoggingOut, setIsLoggingOut] = useState(false);
  const [logoutError, setLogoutError] = useState("");

  const handleLogout = async () => {
    if (isLoggingOut) return;
    setIsLoggingOut(true);
    setLogoutError("");

    try {
      const response = await fetch("/api/auth/logout", {
        method: "POST",
      });

      if (response.ok) {
        router.push("/");
        router.refresh();
      } else {
        setLogoutError("Failed to logout. Please try again.");
        setIsLoggingOut(false);
      }
    } catch (error) {
      setLogoutError("An error occurred during logout.");
      setIsLoggingOut(false);
    }
  };

  // Check if current route is within Festival Five Stage
  const isFestivalRoute =
    pathname.startsWith("/pre-installation") ||
    pathname.startsWith("/installation") ||
    pathname.startsWith("/festivity") ||
    pathname.startsWith("/dashboard/checking") ||
    pathname.startsWith("/dashboard/verification");

  const isSettingsRoute = pathname.startsWith("/dashboard/settings");

  const [festivalExpanded, setFestivalExpanded] = useState(isFestivalRoute);
  const [settingsExpanded, setSettingsExpanded] = useState(isSettingsRoute);

  useEffect(() => {
    if (isFestivalRoute) {
      setFestivalExpanded(true);
    }
    if (isSettingsRoute) {
      setSettingsExpanded(true);
    }
  }, [isFestivalRoute, isSettingsRoute]);

  const menuItems: MenuItem[] = [
    {
      name: "Dashboard",
      href: "/dashboard",
      activeCardStyle:
        "bg-gradient-to-r from-blue-600 to-blue-500 text-white shadow-lg shadow-blue-500/30 ring-2 ring-blue-400 font-bold",
      inactiveCardStyle:
        "bg-blue-950/40 text-blue-100 hover:bg-blue-900/60 hover:text-white border border-blue-800/40 font-semibold hover:shadow-md hover:shadow-blue-900/20",
      iconBoxActive: "bg-white/20 text-white",
      iconBoxInactive: "bg-blue-500/20 text-blue-300 group-hover:bg-blue-500/30",
      icon: ({ className = "w-5 h-5" }) => (
        <svg
          className={className}
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
        >
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeWidth={2}
            d="M4 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2V6zM14 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2V6zM4 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2v-2zM14 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2v-2z"
          />
        </svg>
      ),
    },
    {
      name: "Applications / GPIDs",
      href: "/dashboard/applications",
      activeCardStyle:
        "bg-gradient-to-r from-indigo-600 to-indigo-500 text-white shadow-lg shadow-indigo-500/30 ring-2 ring-indigo-400 font-bold",
      inactiveCardStyle:
        "bg-indigo-950/40 text-indigo-100 hover:bg-indigo-900/60 hover:text-white border border-indigo-800/40 font-semibold hover:shadow-md hover:shadow-indigo-900/20",
      iconBoxActive: "bg-white/20 text-white",
      iconBoxInactive:
        "bg-indigo-500/20 text-indigo-300 group-hover:bg-indigo-500/30",
      icon: ({ className = "w-5 h-5" }) => (
        <svg
          className={className}
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
        >
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeWidth={2}
            d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
          />
        </svg>
      ),
    },
    {
      name: "Daily Visitings",
      href: "/dashboard/visitings",
      activeCardStyle:
        "bg-gradient-to-r from-cyan-600 to-sky-500 text-white shadow-lg shadow-cyan-500/30 ring-2 ring-cyan-400 font-bold",
      inactiveCardStyle:
        "bg-cyan-950/40 text-cyan-100 hover:bg-cyan-900/60 hover:text-white border border-cyan-800/40 font-semibold hover:shadow-md hover:shadow-cyan-900/20",
      iconBoxActive: "bg-white/20 text-white",
      iconBoxInactive: "bg-cyan-500/20 text-cyan-300 group-hover:bg-cyan-500/30",
      icon: ({ className = "w-5 h-5" }) => (
        <svg
          className={className}
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
        >
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeWidth={2}
            d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"
          />
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeWidth={2}
            d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"
          />
        </svg>
      ),
    },
    {
      name: "Festival Five Stage",
      activeCardStyle:
        "bg-gradient-to-r from-pink-600 to-rose-500 text-white shadow-lg shadow-pink-500/30 ring-2 ring-pink-400 font-bold",
      inactiveCardStyle:
        "bg-pink-950/40 text-pink-100 hover:bg-pink-900/60 hover:text-white border border-pink-800/40 font-semibold hover:shadow-md hover:shadow-pink-900/20",
      iconBoxActive: "bg-white/20 text-white",
      iconBoxInactive: "bg-pink-500/20 text-pink-300 group-hover:bg-pink-500/30",
      icon: ({ className = "w-5 h-5" }) => (
        <svg
          className={className}
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
        >
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeWidth={2}
            d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10"
          />
        </svg>
      ),
      children: [
        {
          name: "Pre-Installation",
          href: "/pre-installation",
          badgeLabel: "STAGE 1",
          activeBg:
            "bg-gradient-to-r from-orange-600 to-amber-500 text-white font-bold ring-2 ring-orange-400 shadow-md shadow-orange-600/30",
          inactiveBg:
            "bg-orange-950/30 text-orange-200 border border-orange-800/40 hover:bg-orange-900/50 hover:text-white",
          badgeColor: "bg-orange-500",
          badgeTextColor: "text-orange-200",
        },
        {
          name: "Installation",
          href: "/installation",
          badgeLabel: "STAGE 2",
          activeBg:
            "bg-gradient-to-r from-purple-600 to-indigo-500 text-white font-bold ring-2 ring-purple-400 shadow-md shadow-purple-600/30",
          inactiveBg:
            "bg-purple-950/30 text-purple-200 border border-purple-800/40 hover:bg-purple-900/50 hover:text-white",
          badgeColor: "bg-purple-500",
          badgeTextColor: "text-purple-200",
        },
        {
          name: "During Festivity",
          href: "/festivity",
          badgeLabel: "STAGE 3",
          activeBg:
            "bg-gradient-to-r from-green-600 to-emerald-500 text-white font-bold ring-2 ring-green-400 shadow-md shadow-green-600/30",
          inactiveBg:
            "bg-green-950/30 text-green-200 border border-green-800/40 hover:bg-green-900/50 hover:text-white",
          badgeColor: "bg-green-500",
          badgeTextColor: "text-green-200",
        },
        {
          name: "Checking / Inspection",
          href: "/dashboard/checking",
          badgeLabel: "TOOL",
          activeBg:
            "bg-gradient-to-r from-teal-600 to-cyan-500 text-white font-bold ring-2 ring-teal-400 shadow-md shadow-teal-600/30",
          inactiveBg:
            "bg-teal-950/30 text-teal-200 border border-teal-800/40 hover:bg-teal-900/50 hover:text-white",
          badgeColor: "bg-teal-500",
          badgeTextColor: "text-teal-200",
        },
        {
          name: "Immersion",
          href: "/dashboard/verification",
          badgeLabel: "STAGE 4",
          activeBg:
            "bg-gradient-to-r from-blue-600 to-indigo-600 text-white font-bold ring-2 ring-blue-400 shadow-md shadow-blue-600/30",
          inactiveBg:
            "bg-blue-950/30 text-blue-200 border border-blue-800/40 hover:bg-blue-900/50 hover:text-white",
          badgeColor: "bg-blue-500",
          badgeTextColor: "text-blue-200",
        },
        {
          name: "Post-Immersion",
          href: "/dashboard/verification",
          badgeLabel: "STAGE 5",
          activeBg:
            "bg-gradient-to-r from-emerald-600 to-teal-600 text-white font-bold ring-2 ring-emerald-400 shadow-md shadow-emerald-600/30",
          inactiveBg:
            "bg-emerald-950/30 text-emerald-200 border border-emerald-800/40 hover:bg-emerald-900/50 hover:text-white",
          badgeColor: "bg-emerald-500",
          badgeTextColor: "text-emerald-200",
        },
      ],
    },
    {
      name: "Live Tracking",
      href: "/live-tracking",
      activeCardStyle:
        "bg-gradient-to-r from-red-600 to-rose-600 text-white shadow-lg shadow-red-500/30 ring-2 ring-red-400 font-bold",
      inactiveCardStyle:
        "bg-red-950/40 text-red-100 hover:bg-red-900/60 hover:text-white border border-red-800/40 font-semibold hover:shadow-md hover:shadow-red-900/20",
      iconBoxActive: "bg-white/20 text-white",
      iconBoxInactive: "bg-red-500/20 text-red-300 group-hover:bg-red-500/30",
      icon: ({ className = "w-5 h-5" }) => (
        <svg
          className={className}
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
        >
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeWidth={2}
            d="M8.111 16.404a5.5 5.5 0 017.778 0M12 20h.01m-7.08-7.071a10 10 0 0114.142 0M1.394 9.393c5.857-5.857 15.355-5.857 21.213 0"
          />
        </svg>
      ),
    },
    {
      name: "Reports & Analytics",
      href: "/dashboard/reports",
      activeCardStyle:
        "bg-gradient-to-r from-violet-600 to-purple-500 text-white shadow-lg shadow-violet-500/30 ring-2 ring-violet-400 font-bold",
      inactiveCardStyle:
        "bg-violet-950/40 text-violet-100 hover:bg-violet-900/60 hover:text-white border border-violet-800/40 font-semibold hover:shadow-md hover:shadow-violet-900/20",
      iconBoxActive: "bg-white/20 text-white",
      iconBoxInactive:
        "bg-violet-500/20 text-violet-300 group-hover:bg-violet-500/30",
      icon: ({ className = "w-5 h-5" }) => (
        <svg
          className={className}
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
        >
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeWidth={2}
            d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"
          />
        </svg>
      ),
    },
    {
      name: "Settings / Administration",
      activeCardStyle:
        "bg-gradient-to-r from-slate-600 to-blue-600 text-white shadow-lg shadow-slate-500/30 ring-2 ring-slate-400 font-bold",
      inactiveCardStyle:
        "bg-slate-800/60 text-slate-200 hover:bg-slate-700/80 hover:text-white border border-slate-700/60 font-semibold hover:shadow-md hover:shadow-slate-900/20",
      iconBoxActive: "bg-white/20 text-white",
      iconBoxInactive:
        "bg-slate-500/20 text-slate-300 group-hover:bg-slate-500/30",
      icon: ({ className = "w-5 h-5" }) => (
        <svg
          className={className}
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
        >
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeWidth={2}
            d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"
          />
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeWidth={2}
            d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"
          />
        </svg>
      ),
      children: [
        {
          name: "Add Wings & Hierarchy",
          href: "/dashboard/settings/wings",
          badgeLabel: "WINGS",
          activeBg:
            "bg-gradient-to-r from-slate-600 to-blue-600 text-white font-bold ring-2 ring-slate-400 shadow-md",
          inactiveBg:
            "bg-slate-950/30 text-slate-200 border border-slate-800/40 hover:bg-slate-900/50 hover:text-white",
          badgeColor: "bg-slate-500",
          badgeTextColor: "text-slate-200",
        },
        {
          name: "Role Allotment",
          href: "/dashboard/settings/role-allotment",
          badgeLabel: "ALLOTMENT",
          activeBg:
            "bg-gradient-to-r from-blue-600 to-indigo-600 text-white font-bold ring-2 ring-blue-400 shadow-md",
          inactiveBg:
            "bg-blue-950/30 text-blue-200 border border-blue-800/40 hover:bg-blue-900/50 hover:text-white",
          badgeColor: "bg-indigo-500",
          badgeTextColor: "text-indigo-200",
        },
        {
          name: "User Directory Hub",
          href: "/dashboard/settings",
          badgeLabel: "HUB",
          activeBg:
            "bg-gradient-to-r from-slate-700 to-slate-800 text-white font-bold ring-2 ring-slate-400 shadow-md",
          inactiveBg:
            "bg-slate-950/30 text-slate-300 border border-slate-800/40 hover:bg-slate-900/50 hover:text-white",
          badgeColor: "bg-slate-600",
          badgeTextColor: "text-slate-200",
        },
      ],
    },
  ];

  const renderNavItems = () => (
    <nav className="space-y-3 px-3.5 py-5">
      {menuItems.map((item) => {
        const hasChildren = Boolean(item.children && item.children.length > 0);
        const isFestival = item.name === "Festival Five Stage";
        const isSettings = item.name === "Settings / Administration";
        const isExpanded = isFestival ? festivalExpanded : isSettings ? settingsExpanded : false;

        const isActive = item.href
          ? item.href === "/dashboard"
            ? pathname === "/dashboard"
            : pathname === item.href
          : isFestival ? isFestivalRoute : isSettingsRoute;

        return (
          <div key={item.name} className="space-y-2">
            {hasChildren ? (
              <button
                type="button"
                onClick={() => {
                  if (isFestival) setFestivalExpanded(!festivalExpanded);
                  if (isSettings) setSettingsExpanded(!settingsExpanded);
                }}
                className={`group flex w-full items-center justify-between rounded-2xl px-4 py-3.5 text-left transition-all duration-200 ${
                  isActive ? item.activeCardStyle : item.inactiveCardStyle
                }`}
              >
                <div className="flex items-center gap-3.5">
                  <div
                    className={`flex h-10 w-10 items-center justify-center rounded-xl transition-colors ${
                      isActive ? item.iconBoxActive : item.iconBoxInactive
                    }`}
                  >
                    <item.icon className="h-5 w-5" />
                  </div>
                  <span className="text-sm font-extrabold tracking-wide">
                    {item.name}
                  </span>
                </div>
                <svg
                  className={`h-4 w-4 transition-transform duration-200 ${
                    isActive ? "text-white" : "text-slate-400 group-hover:text-white"
                  } ${isExpanded ? "rotate-180" : ""}`}
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2.5}
                    d="M19 9l-7 7-7-7"
                  />
                </svg>
              </button>
            ) : (
              <Link
                href={item.href || "#"}
                onClick={() => setMobileMenuOpen(false)}
                className={`group flex items-center gap-3.5 rounded-2xl px-4 py-3.5 transition-all duration-200 ${
                  isActive ? item.activeCardStyle : item.inactiveCardStyle
                }`}
              >
                <div
                  className={`flex h-10 w-10 items-center justify-center rounded-xl transition-colors ${
                    isActive ? item.iconBoxActive : item.iconBoxInactive
                  }`}
                >
                  <item.icon className="h-5 w-5" />
                </div>
                <span className="text-sm tracking-wide">{item.name}</span>
              </Link>
            )}

            {/* EXPANDABLE CHILD ITEMS */}
            {hasChildren && isExpanded && (
              <div className="ml-3 space-y-2 border-l-2 border-slate-500/40 pl-3 pt-1 pb-1">
                {item.children?.map((child) => {
                  const isChildActive = pathname === child.href || (child.href !== "/dashboard/settings" && pathname.startsWith(child.href));

                  return (
                    <Link
                      key={child.name}
                      href={child.href}
                      onClick={() => setMobileMenuOpen(false)}
                      className={`group flex items-center justify-between rounded-xl px-3.5 py-2.5 text-xs transition-all duration-200 ${
                        isChildActive
                          ? child.activeBg
                          : child.inactiveBg
                      }`}
                    >
                      <div className="flex items-center gap-2.5">
                        <span
                          className={`h-2.5 w-2.5 rounded-full ${child.badgeColor}`}
                        />
                        <span className="font-semibold">{child.name}</span>
                      </div>
                      {child.badgeLabel && (
                        <span
                          className={`rounded-md px-1.5 py-0.5 text-[10px] font-black tracking-wider uppercase bg-slate-950/80 ${child.badgeTextColor}`}
                        >
                          {child.badgeLabel}
                        </span>
                      )}
                    </Link>
                  );
                })}
              </div>
            )}
          </div>
        );
      })}
    </nav>
  );

  const renderLogoutButton = () => (
    <div className="px-4 pb-4">
      {logoutError && (
        <p className="mb-2 text-xs font-semibold text-red-400 text-center">
          {logoutError}
        </p>
      )}
      <button
        type="button"
        onClick={handleLogout}
        disabled={isLoggingOut}
        className="flex w-full items-center justify-center gap-2 rounded-xl border border-red-800/40 bg-red-950/40 px-4 py-3 text-sm font-bold text-red-400 transition-all duration-200 hover:bg-red-900/60 hover:text-white disabled:cursor-not-allowed disabled:opacity-50"
      >
        {isLoggingOut ? (
          <span className="animate-pulse">Logging out...</span>
        ) : (
          <>
            <svg
              className="h-5 w-5"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1"
              />
            </svg>
            <span>Logout</span>
          </>
        )}
      </button>
    </div>
  );

  return (
    <>
      {/* MOBILE TOP BAR */}
      <header className="flex h-16 items-center justify-between border-b border-slate-800 bg-[#0A1128] px-4 text-white md:hidden">
        <div className="flex items-center gap-3">
          <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-gradient-to-tr from-blue-600 to-indigo-600 font-black text-white shadow-md">
            GB
          </div>
          <div>
            <p className="text-xs font-black tracking-wider uppercase text-white">
              GANESH BANDOBUST
            </p>
            <p className="text-[10px] font-bold text-blue-400">
              HYDERABAD CITY POLICE
            </p>
          </div>
        </div>

        <button
          type="button"
          onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
          aria-label="Toggle Navigation Menu"
          className="rounded-xl border border-slate-700 bg-slate-800 p-2 text-slate-300 hover:text-white"
        >
          <svg
            className="h-6 w-6"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            {mobileMenuOpen ? (
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M6 18L18 6M6 6l12 12"
              />
            ) : (
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M4 6h16M4 12h16M4 18h16"
              />
            )}
          </svg>
        </button>
      </header>

      {/* MOBILE DRAWER OVERLAY */}
      {mobileMenuOpen && (
        <div className="fixed inset-0 z-50 flex md:hidden">
          <div
            className="fixed inset-0 bg-slate-950/80 backdrop-blur-sm"
            onClick={() => setMobileMenuOpen(false)}
          />
          <div className="relative flex w-4/5 max-w-xs flex-col bg-[#0A1128] text-white shadow-2xl">
            <div className="flex items-center justify-between border-b border-slate-800 px-5 py-4">
              <div className="flex items-center gap-2.5">
                <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-gradient-to-tr from-blue-600 to-indigo-600 font-black text-white shadow-md">
                  GB
                </div>
                <div>
                  <p className="text-xs font-black tracking-wider uppercase text-white">
                    GANESH BANDOBUST
                  </p>
                  <p className="text-[10px] font-bold text-blue-400">
                    HYDERABAD CITY POLICE
                  </p>
                </div>
              </div>
              <button
                type="button"
                onClick={() => setMobileMenuOpen(false)}
                className="text-slate-400 hover:text-white font-bold text-lg"
              >
                ✕
              </button>
            </div>
            <div className="flex-1 overflow-y-auto">{renderNavItems()}</div>
            <div className="border-t border-slate-800/80 pt-4 mt-auto shrink-0">
              {renderLogoutButton()}
            </div>
          </div>
        </div>
      )}

      {/* DESKTOP PERMANENT SIDEBAR */}
      <aside className="hidden w-72 flex-col border-r border-slate-800/80 bg-[#0A1128] text-white md:flex min-h-screen shrink-0">
        <div className="flex items-center gap-3.5 border-b border-slate-800/80 px-5 py-5">
          <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-gradient-to-tr from-blue-600 to-indigo-600 text-white font-black shadow-lg shadow-blue-600/30 ring-1 ring-white/20">
            GB
          </div>
          <div>
            <h1 className="text-sm font-black tracking-wider text-white uppercase">
              GANESH BANDOBUST
            </h1>
            <p className="text-[11px] font-bold tracking-wide text-blue-400">
              2026 • HYDERABAD CITY POLICE
            </p>
          </div>
        </div>

        <div className="flex-1 overflow-y-auto">{renderNavItems()}</div>

        <div className="border-t border-slate-800/80 p-4 pb-2 shrink-0">
          <div className="rounded-2xl bg-slate-900/80 border border-slate-800 p-3.5 text-xs">
            <p className="font-extrabold text-slate-200 uppercase tracking-wider text-[11px]">
              Command Cockpit
            </p>
            <p className="mt-0.5 text-[11px] font-medium text-slate-400">
              Monitoring & Supervisory View
            </p>
          </div>
        </div>
        <div className="shrink-0">
          {renderLogoutButton()}
        </div>
      </aside>
    </>
  );
}
