"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";

type User = {
  username: string;
  officerName: string;
  role: string;
  policeStation: string;
  sector: string;
};

type GpidMasterResponse = {
  success: boolean;
  total?: number;
  records?: unknown[];
  message?: string;
};

export default function Dashboard() {
  const router = useRouter();

  const [user, setUser] = useState<User | null>(null);
  const [totalGpids, setTotalGpids] = useState<number | null>(null);
  const [gpidLoading, setGpidLoading] = useState(true);
  const [gpidError, setGpidError] = useState("");

  useEffect(() => {
    const savedUser = localStorage.getItem("ganesh_user");

    if (!savedUser) {
      router.push("/");
      return;
    }

    try {
      setUser(JSON.parse(savedUser) as User);
    } catch (error) {
      console.error("Invalid saved user:", error);
      localStorage.removeItem("ganesh_user");
      router.push("/");
    }
  }, [router]);

  useEffect(() => {
    let active = true;

    async function loadGpids() {
      try {
        setGpidError("");

        const response = await fetch("/api/festivity/gpid-master", {
          method: "GET",
          cache: "no-store",
        });

        const data = (await response.json()) as GpidMasterResponse;

        if (!response.ok || !data.success) {
          throw new Error(
            data.message || "Unable to load live GPID data.",
          );
        }

        if (!active) return;

        const total =
          typeof data.total === "number"
            ? data.total
            : Array.isArray(data.records)
              ? data.records.length
              : 0;

        setTotalGpids(total);
      } catch (error) {
        if (!active) return;

        console.error("Dashboard GPID error:", error);

        setGpidError(
          error instanceof Error
            ? error.message
            : "Unable to load live GPID data.",
        );
      } finally {
        if (active) {
          setGpidLoading(false);
        }
      }
    }

    void loadGpids();

    const timer = window.setInterval(() => {
      void loadGpids();
    }, 60000);

    return () => {
      active = false;
      window.clearInterval(timer);
    };
  }, []);

  const logout = () => {
    localStorage.removeItem("ganesh_user");
    router.push("/");
  };

  if (!user) {
    return (
      <main className="min-h-screen flex items-center justify-center">
        Loading...
      </main>
    );
  }

  const totalValue = gpidLoading
    ? "..."
    : gpidError
      ? "—"
      : (totalGpids ?? 0).toLocaleString();

  const dashboardCards = [
    {
      title: "Total GPIDs",
      value: totalValue,
    },
    {
      title: "Pre-Installation Completed",
      value: "0",
    },
    {
      title: "Verification Pending",
      value: totalValue,
    },
    {
      title: "Exceptions / NO Cases",
      value: "0",
    },
    {
      title: "Re-Verification Pending",
      value: "0",
    },
    {
      title: "NOCs Pending",
      value: "0",
    },
    {
      title: "Hyper Sensitive",
      value: "0",
    },
    {
      title: "Critical Locations",
      value: "0",
    },
  ];

  const stages = [
    {
      number: 1,
      name: "Pre-Installation",
      status: "ACTIVE",
      active: true,
      route: "/pre-installation",
    },
    {
      number: 2,
      name: "Installation",
      status: "AVAILABLE",
      active: true,
      route: "/installation",
    },
    {
      number: 3,
      name: "During Festivity",
      status: "ACTIVE",
      active: true,
      route: "/festivity",
    },
    {
      number: 4,
      name: "Immersion",
      status: "Pending Configuration",
      active: false,
      route: "",
    },
    {
      number: 5,
      name: "Post-Immersion",
      status: "Pending Configuration",
      active: false,
      route: "",
    },
  ];

  const menuItems = [
    {
      label: "Dashboard",
      action: () => router.push("/dashboard"),
    },
    {
      label: "Applications / GPIDs",
      action: () => {},
    },
    {
      label: "Daily Visitings",
      action: () => {},
    },
    {
      label: "Festival Five Stage",
      action: () => router.push("/dashboard"),
    },
    {
      label: "Live Tracking",
      action: () => {},
    },
    {
      label: "Reports & Analytics",
      action: () => {},
    },
    {
      label: "Settings / Administration",
      action: () => {},
    },
  ];

  return (
    <main className="min-h-screen bg-slate-100">
      <header className="bg-[#17365D] text-white">
        <div className="mx-auto flex max-w-7xl items-center justify-between gap-6 px-6 py-5">
          <div>
            <p className="text-xs tracking-widest text-blue-200">
              OFFICIAL USE
            </p>

            <h1 className="text-xl font-bold md:text-2xl">
              Ganesh Festival Bandobust Management System
            </h1>
          </div>

          <div className="hidden text-right sm:block">
            <p className="text-xs tracking-wide text-blue-200">
              LOGGED IN AS
            </p>

            <p className="text-sm font-bold text-white">
              {user.officerName}
            </p>

            <p className="text-xs text-blue-100">
              {user.username} • {user.role}
            </p>
          </div>
        </div>
      </header>

      <div className="mx-auto flex max-w-7xl">
        <aside className="min-h-[calc(100vh-88px)] w-64 shrink-0 border-r border-slate-200 bg-white">
          <div className="p-4">
            <div className="mb-5 rounded-xl bg-slate-50 p-4">
              <p className="text-xs font-semibold uppercase tracking-wide text-slate-500">
                Logged-in Officer
              </p>

              <p className="mt-1 font-bold text-slate-800">
                {user.officerName}
              </p>

              <p className="text-xs text-slate-500">
                {user.role}
              </p>
            </div>

            <nav className="space-y-1">
              {menuItems.map((item) => (
                <button
                  key={item.label}
                  type="button"
                  onClick={item.action}
                  className={`w-full rounded-lg px-4 py-3 text-left text-sm font-semibold transition ${
                    item.label === "Dashboard"
                      ? "bg-[#17365D] text-white"
                      : "text-slate-700 hover:bg-slate-100"
                  }`}
                >
                  {item.label}
                </button>
              ))}
            </nav>

            <div className="my-4 border-t border-slate-200" />

            <div className="space-y-1">
              <button
                type="button"
                onClick={logout}
                className="w-full rounded-lg px-4 py-3 text-left text-sm font-semibold text-red-700 transition hover:bg-red-50"
              >
                Logout
              </button>
            </div>
          </div>
        </aside>

        <div className="min-w-0 flex-1 px-6 py-8">
          <section className="mb-7 rounded-xl bg-white p-5 shadow-sm">
            <div className="grid gap-5 md:grid-cols-4">
              <div>
                <p className="text-xs text-slate-500">
                  Officer
                </p>

                <p className="font-bold text-slate-800">
                  {user.officerName}
                </p>
              </div>

              <div>
                <p className="text-xs text-slate-500">
                  Role
                </p>

                <p className="font-bold text-slate-800">
                  {user.role}
                </p>
              </div>

              <div>
                <p className="text-xs text-slate-500">
                  Police Station
                </p>

                <p className="font-bold text-slate-800">
                  {user.policeStation}
                </p>
              </div>

              <div>
                <p className="text-xs text-slate-500">
                  Sector
                </p>

                <p className="font-bold text-slate-800">
                  {user.sector || "-"}
                </p>
              </div>
            </div>
          </section>

          <div className="mb-4 flex flex-wrap items-center justify-between gap-3">
            <h2 className="text-2xl font-bold text-slate-800">
              Dashboard
            </h2>

            <span
              className={`rounded-full px-3 py-1 text-xs font-bold ${
                gpidLoading
                  ? "bg-amber-100 text-amber-800"
                  : gpidError
                    ? "bg-red-100 text-red-800"
                    : "bg-emerald-100 text-emerald-800"
              }`}
            >
              {gpidLoading
                ? "LOADING GPID DATA"
                : gpidError
                  ? "GPID DATA ERROR"
                  : "LIVE GPID DATA"}
            </span>
          </div>

          {gpidError && (
            <div className="mb-5 rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
              {gpidError}
            </div>
          )}

          <section className="mb-10 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
            {dashboardCards.map((card) => (
              <div
                key={card.title}
                className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm"
              >
                <div className="text-3xl font-bold text-[#17365D]">
                  {card.value}
                </div>

                <p className="mt-2 text-sm text-slate-600">
                  {card.title}
                </p>
              </div>
            ))}
          </section>

          <div className="mb-4 flex items-center justify-between">
            <h2 className="text-2xl font-bold text-slate-800">
              Festival Stages
            </h2>
          </div>

          <section className="space-y-3">
            {stages.map((stage) => (
              <button
                key={stage.number}
                type="button"
                onClick={() => {
                  if (stage.active && stage.route) {
                    router.push(stage.route);
                  }
                }}
                className={`flex w-full items-center justify-between rounded-xl border bg-white px-5 py-5 text-left transition ${
                  stage.active
                    ? "cursor-pointer border-blue-300 hover:border-blue-500"
                    : "cursor-default border-slate-200"
                }`}
              >
                <div className="flex items-center gap-4">
                  <div
                    className={`flex h-10 w-10 items-center justify-center rounded-full font-bold ${
                      stage.active
                        ? "bg-[#17365D] text-white"
                        : "bg-slate-200 text-slate-500"
                    }`}
                  >
                    {stage.number}
                  </div>

                  <div>
                    <p className="font-bold text-slate-800">
                      {stage.name}
                    </p>

                    <p
                      className={`text-sm ${
                        stage.active
                          ? "text-green-600"
                          : "text-slate-400"
                      }`}
                    >
                      {stage.status}
                    </p>
                  </div>
                </div>

                {stage.active && (
                  <span className="font-semibold text-[#17365D]">
                    Open →
                  </span>
                )}
              </button>
            ))}
          </section>
        </div>
      </div>
    </main>
  );
}