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

export default function Dashboard() {
  const router = useRouter();

  const [user, setUser] = useState<User | null>(null);

  useEffect(() => {
    const savedUser = localStorage.getItem("ganesh_user");

    if (!savedUser) {
      router.push("/");
      return;
    }

    setUser(JSON.parse(savedUser));
  }, [router]);

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

  const dashboardCards = [
    {
      title: "Total Idols",
      value: "15,000",
    },
    {
      title: "Pre-Installation Completed",
      value: "0",
    },
    {
      title: "Verification Pending",
      value: "15,000",
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
    },
    {
      number: 2,
      name: "Installation",
      status: "Pending Configuration",
      active: false,
    },
    {
      number: 3,
      name: "During Festivity",
      status: "Pending Configuration",
      active: false,
    },
    {
      number: 4,
      name: "Immersion",
      status: "Pending Configuration",
      active: false,
    },
    {
      number: 5,
      name: "Post-Immersion",
      status: "Pending Configuration",
      active: false,
    },
  ];

  return (
    <main className="min-h-screen bg-slate-100">
      <header className="bg-[#17365D] text-white">
        <div className="max-w-7xl mx-auto px-6 py-5 flex items-center justify-between">
          <div>
            <p className="text-xs tracking-widest text-blue-200">
              OFFICIAL USE
            </p>

            <h1 className="text-xl md:text-2xl font-bold">
              Ganesh Festival Bandobust Management System
            </h1>
          </div>

          <button
            onClick={logout}
            className="border border-white/30 px-4 py-2 rounded-lg hover:bg-white/10"
          >
            Logout
          </button>
        </div>
      </header>

      <div className="max-w-7xl mx-auto px-6 py-8">

        <section className="bg-white rounded-xl shadow-sm p-5 mb-7">
          <div className="grid md:grid-cols-4 gap-5">
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

        <h2 className="text-2xl font-bold text-slate-800 mb-4">
          Dashboard
        </h2>

        <section className="grid sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-10">

          {dashboardCards.map((card) => (
            <div
              key={card.title}
              className="bg-white rounded-xl shadow-sm border border-slate-200 p-5"
            >
              <div className="text-3xl font-bold text-[#17365D]">
                {card.value}
              </div>

              <p className="text-sm text-slate-600 mt-2">
                {card.title}
              </p>
            </div>
          ))}

        </section>

        <div className="flex items-center justify-between mb-4">
          <h2 className="text-2xl font-bold text-slate-800">
            Festival Stages
          </h2>
        </div>

        <section className="space-y-3">

          {stages.map((stage) => (
            <button
              key={stage.number}
              onClick={() => {
                if (stage.number === 1) {
                  router.push("/pre-installation");
                }
              }}
              className={`w-full text-left bg-white border rounded-xl px-5 py-5 flex items-center justify-between transition ${
                stage.active
                  ? "border-blue-300 hover:border-blue-500 cursor-pointer"
                  : "border-slate-200 cursor-default"
              }`}
            >
              <div className="flex items-center gap-4">

                <div
                  className={`w-10 h-10 rounded-full flex items-center justify-center font-bold ${
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
                <span className="text-[#17365D] font-semibold">
                  Open →
                </span>
              )}

            </button>
          ))}

        </section>

      </div>
    </main>
  );
}