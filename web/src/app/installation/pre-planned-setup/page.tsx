"use client";

import { useRouter } from "next/navigation";

export default function PrePlannedSetupPage() {
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
              Pre-Planned Installation Setup
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
            ← Installation
          </button>
        </div>
      </header>

      <div className="mx-auto max-w-6xl px-6 py-8">
        <section className="mb-6 rounded-xl border border-blue-200 bg-blue-50 p-5">
          <p className="text-xs font-bold uppercase tracking-wider text-blue-700">
            Installation Safety Monitoring
          </p>

          <h2 className="mt-2 text-xl font-bold text-slate-800">
            Pre-Planned Setup
          </h2>

          <p className="mt-2 text-sm leading-6 text-slate-600">
            Supervisory monitoring of Laddu, Hundi, jewellery, cash or
            currency garlands and other valuable articles placed at the
            Ganesh point.
          </p>
        </section>

        <section className="grid gap-5 md:grid-cols-2">
          <SetupCard title="Laddu">
            Monitor whether Laddu arrangements and safety precautions are in place.
          </SetupCard>

          <SetupCard title="Hundi">
            Monitor whether the Hundi is properly secured and protected.
          </SetupCard>

          <SetupCard title="Jewellery / Valuables">
            Monitor safety arrangements for jewellery and other valuable articles.
          </SetupCard>

          <SetupCard title="Cash / Currency Garlands">
            Monitor safety arrangements for cash or currency garlands, where applicable.
          </SetupCard>

          <SetupCard title="Other Valuable Articles">
            Monitor any other valuable article placed at the Ganesh point.
          </SetupCard>

          <SetupCard title="Safety Arrangements">
            Monitor guards, locking, CCTV or other available protective arrangements.
          </SetupCard>
        </section>

        <section className="mt-8 rounded-xl border border-amber-200 bg-amber-50 p-5">
          <h2 className="font-bold text-amber-900">
            API Integration Pending
          </h2>

          <p className="mt-2 text-sm leading-6 text-amber-800">
            Live Stage-2 data will be displayed after the Installation API
            and persistence workflow are connected.
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