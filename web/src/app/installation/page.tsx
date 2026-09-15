"use client";

import { useRouter } from "next/navigation";

const installationModules = [
  {
    number: "01",
    title: "Idol-Based Installation Verification",
    description:
      "Monitor idol installation status, Stage-1 carried-forward details, actual installation information and deviations.",
    route: "/installation/idol",
  },
  {
    number: "02",
    title: "Geo-Tagged Based Verification",
    description:
      "Monitor Stage-1 verified location against Stage-2 installation GPS and identify location deviations.",
    route: "/installation/geo-tagged",
  },
  {
    number: "03",
    title: "Cluster & Sector Based Information",
    description:
      "View authoritative Sector and Cluster deployment information and officer details where available.",
    route: "/installation/cluster-sector",
  },
  {
    number: "04",
    title: "Documentary Setup",
    description:
      "Monitor Point Book, geo-tagging, QR Code, GPID Board, Police Notice Board and police contact display setup.",
    route: "/installation/documentary-setup",
  },
  {
    number: "05",
    title: "Pre-Planned Installation Setup",
    description:
      "Monitor Laddu, Hundi, jewellery, cash or currency garlands, other valuables and their safety arrangements.",
    route: "/installation/pre-planned-setup",
  },
  {
    number: "06",
    title: "Spectacular Exhibition Setup",
    description:
      "Monitor exhibition setup, permissions, violations, risk observations and action-required cases.",
    route: "/installation/spectacular-exhibition",
  },
];

export default function InstallationPage() {
  const router = useRouter();

  return (
    <main className="min-h-screen bg-slate-100">
      <header className="bg-[#17365D] text-white">
        <div className="mx-auto flex max-w-6xl items-center justify-between px-6 py-5">
          <div>
            <p className="text-xs tracking-widest text-blue-200">
              GANESH BANDOBUST 2026
            </p>

            <h1 className="mt-1 text-2xl font-bold">
              Stage 2 — Installation
            </h1>

            <p className="mt-1 text-sm text-blue-100">
              Monitoring & Supervisory Interface
            </p>
          </div>

          <button
            type="button"
            onClick={() => router.push("/dashboard")}
            className="rounded-lg border border-white/30 px-4 py-2 hover:bg-white/10"
          >
            ← Dashboard
          </button>
        </div>
      </header>

      <div className="mx-auto max-w-6xl px-6 py-8">
        <section className="mb-6 rounded-xl border border-blue-200 bg-blue-50 p-5">
          <p className="text-xs font-bold uppercase tracking-wider text-blue-700">
            Stage 2 Monitoring Principle
          </p>

          <p className="mt-2 font-semibold text-slate-800">
            Pre-Installation Information → Installation Confirmation →
            Change / Deviation Monitoring
          </p>

          <p className="mt-2 text-sm leading-6 text-slate-600">
            Stage-1 information will be carried forward for supervisory
            visibility. Installation verification should capture and highlight
            only the new information, confirmation, change or deviation
            recorded during Stage 2.
          </p>
        </section>

        <section className="mb-6 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
          <SummaryCard label="Total GPIDs" value="—" />
          <SummaryCard label="Installation Verified" value="—" />
          <SummaryCard label="Pending" value="—" />
          <SummaryCard label="Deviation Detected" value="—" />
        </section>

        <section className="mb-8 rounded-xl border border-slate-200 bg-white p-5">
          <div className="flex flex-wrap items-center justify-between gap-3">
            <div>
              <h2 className="text-lg font-bold text-slate-800">
                Installation Monitoring
              </h2>

              <p className="mt-1 text-sm text-slate-500">
                Select a module to view its supervisory monitoring interface.
              </p>
            </div>

            <span className="rounded-full bg-amber-100 px-3 py-1 text-xs font-bold text-amber-800">
              API INTEGRATION PENDING
            </span>
          </div>
        </section>

        <section className="grid gap-5 md:grid-cols-2">
          {installationModules.map((module) => (
            <article
              key={module.number}
              className="rounded-xl border border-slate-200 bg-white p-6 shadow-sm"
            >
              <div className="flex items-start gap-4">
                <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-lg bg-[#17365D] font-bold text-white">
                  {module.number}
                </div>

                <div className="min-w-0 flex-1">
                  <h3 className="text-lg font-bold text-slate-800">
                    {module.title}
                  </h3>

                  <p className="mt-2 text-sm leading-6 text-slate-500">
                    {module.description}
                  </p>

                  <div className="mt-5 flex items-center justify-between gap-3">
                    <span className="rounded-full bg-slate-100 px-3 py-1 text-xs font-semibold text-slate-600">
                      Monitoring
                    </span>

                    <button
                      type="button"
                      onClick={() => router.push(module.route)}
                      className="rounded-lg bg-[#17365D] px-4 py-2 text-sm font-semibold text-white hover:bg-[#244d7e]"
                    >
                      Open Module →
                    </button>
                  </div>
                </div>
              </div>
            </article>
          ))}
        </section>

        <section className="mt-8 rounded-xl border border-amber-200 bg-amber-50 p-5">
          <h2 className="font-bold text-amber-900">
            Data Integration Status
          </h2>

          <p className="mt-2 text-sm leading-6 text-amber-800">
            Stage-2 API integration is intentionally not connected in this
            Web branch yet. Summary counts and module data will remain
            unavailable until the finalized Installation API contract is
            confirmed.
          </p>
        </section>
      </div>
    </main>
  );
}

function SummaryCard({
  label,
  value,
}: {
  label: string;
  value: string;
}) {
  return (
    <div className="rounded-xl border border-slate-200 bg-white p-5">
      <p className="text-sm font-medium text-slate-500">{label}</p>

      <p className="mt-2 text-3xl font-bold text-[#17365D]">{value}</p>
    </div>
  );
}