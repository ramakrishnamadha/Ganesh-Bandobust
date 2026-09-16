"use client";

import { useRouter } from "next/navigation";

export default function SpectacularExhibitionPage() {
  const router = useRouter();

  return (
    <main className="min-h-screen bg-slate-100">
      <header className="bg-[#17365D] text-white">
        <div className="mx-auto flex max-w-6xl items-center justify-between px-6 py-5">
          <div>
            <p className="text-xs tracking-widest text-blue-200">
              STAGE 2 — INSTALLATION
            </p>

            <h1 className="mt-1 text-2xl font-bold">
              Spectacular Exhibition Setup
            </h1>

            <p className="mt-1 text-sm text-blue-100">
              Monitoring & Supervisory View
            </p>
          </div>

          <button
            type="button"
            onClick={() => router.push("/installation")}
            className="rounded-lg border border-white/30 px-4 py-2 hover:bg-white/10"
          >
            ? Installation
          </button>
        </div>
      </header>

      <div className="mx-auto max-w-6xl px-6 py-8">
        <section className="mb-6 rounded-xl border border-blue-200 bg-blue-50 p-5">
          <p className="text-xs font-bold uppercase tracking-wider text-blue-700">
            Exhibition Monitoring
          </p>

          <h2 className="mt-2 text-xl font-bold text-slate-800">
            Spectacular / Special Exhibition Setup
          </h2>

          <p className="mt-2 text-sm leading-6 text-slate-600">
            Supervisory monitoring of special exhibition arrangements,
            permissions, safety issues, violations and action-required cases
            during the Installation Stage.
          </p>
        </section>

        <section className="grid gap-5 md:grid-cols-2">
          <SetupCard title="Exhibition Available">
            Monitor whether any spectacular or special exhibition setup is present.
          </SetupCard>

          <SetupCard title="Permission Status">
            Monitor whether the required permission or approval is available.
          </SetupCard>

          <SetupCard title="Safety Arrangements">
            Monitor safety precautions provided for the exhibition setup.
          </SetupCard>

          <SetupCard title="Crowd Impact">
            Monitor possible crowd congregation or movement impact.
          </SetupCard>

          <SetupCard title="Traffic Impact">
            Monitor whether the exhibition setup creates any traffic obstruction or risk.
          </SetupCard>

          <SetupCard title="Violation / Action Required">
            Monitor violations, instructions issued and corrective action required.
          </SetupCard>
        </section>

        <section className="mt-8 rounded-xl border border-amber-200 bg-amber-50 p-5">
          <h2 className="font-bold text-amber-900">
            API Integration Pending
          </h2>

          <p className="mt-2 text-sm leading-6 text-amber-800">
            Live Stage-2 exhibition data will be displayed after the
            Installation API and persistence workflow are connected.
          </p>
        </section>
      </div>
    </main>
  );
}

function SetupCard({
  title,
  children,
}: {
  title: string;
  children: React.ReactNode;
}) {
  return (
    <div className="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
      <h3 className="text-lg font-bold text-slate-800">
        {title}
      </h3>

      <p className="mt-2 text-sm leading-6 text-slate-500">
        {children}
      </p>

      <div className="mt-4">
        <span className="rounded-full bg-slate-100 px-3 py-1 text-xs font-semibold text-slate-600">
          Data unavailable
        </span>
      </div>
    </div>
  );
}
