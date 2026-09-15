"use client";

import { useRouter } from "next/navigation";

const checkingModules = [
  {
    number: "01",
    title: "Anti-Desecration Drill",
    description:
      "Monitor checking of Idol, Mandap, Laddu, Hundi, jewellery/valuables, inside the Mandap and around the Mandap.",
  },
  {
    number: "02",
    title: "Volunteers",
    description:
      "Monitor volunteer availability, number of volunteers, identified volunteers and action taken when volunteers are unavailable.",
  },
  {
    number: "03",
    title: "Lighting",
    description:
      "Monitor lighting availability inside and around the Mandap during the applicable checking period.",
  },
  {
    number: "04",
    title: "Sanitation",
    description:
      "Monitor sanitation conditions inside and around the Mandap and action taken for deficiencies.",
  },
  {
    number: "05",
    title: "Pooja & Night Safety",
    description:
      "Monitor pooja-related status and continuing safety of Laddu, Hundi, Deepam and other applicable arrangements.",
  },
  {
    number: "06",
    title: "Sound / Time Compliance",
    description:
      "Monitor sound-system and permitted-time compliance and identify violations requiring action.",
  },
  {
    number: "07",
    title: "Fire & Safety Follow-up",
    description:
      "Monitor continuing fire and safety arrangements carried forward from earlier verification stages.",
  },
  {
    number: "08",
    title: "Follow-up & Action Required",
    description:
      "Monitor adverse findings, instructions, action taken, pending follow-up and subsequent compliance.",
  },
];

export default function FestivityPage() {
  const router = useRouter();

  /*
   * STAGE 3 — FESTIVITY PERIOD
   *
   * Web is primarily a monitoring and supervisory interface.
   *
   * Each Mobile checking visit must eventually remain a separate,
   * auditable record. Repeated checks must not overwrite previous checks.
   *
   * Live Stage-3 API integration is intentionally not connected here
   * until the server contract is finalized.
   */

  return (
    <main className="min-h-screen bg-slate-100">
      {/* HEADER */}

      <header className="bg-[#17365D] text-white">
        <div className="mx-auto flex max-w-7xl items-center justify-between px-6 py-5">
          <div>
            <p className="text-xs tracking-widest text-blue-200">
              GANESH BANDOBUST 2026
            </p>

            <h1 className="mt-1 text-2xl font-bold">
              Stage 3 — Festivity Period
            </h1>

            <p className="mt-1 text-sm text-blue-100">
              During Festivity Monitoring & Supervisory Interface
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

      <div className="mx-auto max-w-7xl px-6 py-8">
        {/* PERIOD */}

        <section className="mb-6 rounded-xl border border-blue-200 bg-blue-50 p-5">
          <div className="flex flex-wrap items-center justify-between gap-4">
            <div>
              <p className="text-xs font-bold uppercase tracking-wider text-blue-700">
                Stage 3 Operational Period
              </p>

              <p className="mt-2 text-lg font-bold text-slate-800">
                14 September 2026 — 24 September 2026
              </p>

              <p className="mt-1 text-sm text-slate-600">
                Day 1 to Day 11 — repeated field checking and supervisory
                monitoring of each GPID.
              </p>
            </div>

            <span className="rounded-full bg-amber-100 px-4 py-2 text-xs font-bold text-amber-800">
              API INTEGRATION PENDING
            </span>
          </div>
        </section>

        {/* CHECKING PRINCIPLE */}

        <section className="mb-6 rounded-xl border border-[#17365D] bg-white p-6 shadow-sm">
          <div className="flex flex-wrap items-start justify-between gap-4">
            <div className="max-w-4xl">
              <p className="text-xs font-bold uppercase tracking-wider text-[#17365D]">
                Central Stage-3 Workflow
              </p>

              <h2 className="mt-2 text-3xl font-bold text-[#17365D]">
                CHECKING
              </h2>

              <p className="mt-3 text-sm leading-6 text-slate-600">
                Every visit to a GPID during the Festivity Period must remain
                as an independent checking record. Subsequent visits or
                supervisory checks must not overwrite an earlier officer's
                observations, evidence, action or remarks.
              </p>
            </div>

            <button
              type="button"
              onClick={() => router.push("/festivity/checking")}
              className="rounded-lg bg-[#17365D] px-5 py-3 text-sm font-bold text-white hover:bg-[#244d7e]"
            >
              Open CHECKING →
            </button>
          </div>
        </section>

        {/* SUMMARY */}

        <section className="mb-6 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
          <SummaryCard label="Total GPIDs" />
          <SummaryCard label="Checked Today" />
          <SummaryCard label="Pending / Unchecked" />
          <SummaryCard label="Adverse Findings" />
          <SummaryCard label="Follow-up Pending" />
          <SummaryCard label="SB Disagreements" />
          <SummaryCard label="Senior Officer Remarks" />
          <SummaryCard label="Repeated Checks" />
        </section>

        {/* FILTERS PLACEHOLDER */}

        <section className="mb-6 rounded-xl border border-slate-200 bg-white p-5">
          <div className="flex flex-wrap items-center justify-between gap-4">
            <div>
              <h2 className="text-lg font-bold text-slate-800">
                Festivity Monitoring
              </h2>

              <p className="mt-1 text-sm text-slate-500">
                Hierarchy, date/day, GPID and status filters will be connected
                to the finalized Stage-3 data contract and role permissions.
              </p>
            </div>

            <span className="rounded-full bg-slate-100 px-3 py-1 text-xs font-bold text-slate-600">
              DATA UNAVAILABLE
            </span>
          </div>
        </section>

        {/* MODULES */}

        <section className="grid gap-5 md:grid-cols-2">
          {checkingModules.map((module) => (
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

                  <div className="mt-4">
                    <span className="rounded-full bg-blue-50 px-3 py-1 text-xs font-semibold text-blue-700">
                      CHECKING MONITORING
                    </span>
                  </div>
                </div>
              </div>
            </article>
          ))}
        </section>

        {/* SB / SENIOR OFFICER */}

        <section className="mt-8 rounded-xl border border-purple-200 bg-purple-50 p-6">
          <p className="text-xs font-bold uppercase tracking-wider text-purple-700">
            Cross Verification & Supervision
          </p>

          <h2 className="mt-1 text-lg font-bold text-slate-800">
            SB Cross Verification & Senior Officer Remarks
          </h2>

          <div className="mt-5 grid gap-4 md:grid-cols-2">
            <SupervisionCard
              title="SB Cross Verification"
              description="Original checking information remains unchanged. SB assessment will separately record AGREED or DISAGREED, with mandatory remarks when disagreed."
            />

            <SupervisionCard
              title="Senior Officer Remarks"
              description="Senior officer remarks may be recorded through the application or represented by captured Physical Point Book evidence where applicable."
            />
          </div>
        </section>

        {/* AUDIT PRINCIPLE */}

        <section className="mt-6 rounded-xl border border-slate-300 bg-slate-50 p-5">
          <h2 className="font-bold text-slate-800">
            Stage-3 Audit Principle
          </h2>

          <p className="mt-2 text-sm leading-6 text-slate-600">
            Every checking visit must ultimately preserve the GPID, festival
            day/date, checking time, officer identity, rank/unit, GPS,
            individual findings, remarks, action taken, evidence and submission
            timestamp. Follow-up checks, SB assessments and Senior Officer
            remarks must remain separately attributable and auditable.
          </p>
        </section>
      </div>
    </main>
  );
}

function SummaryCard({ label }: { label: string }) {
  return (
    <div className="rounded-xl border border-slate-200 bg-white p-5">
      <p className="text-sm font-medium text-slate-500">{label}</p>

      <p className="mt-2 text-3xl font-bold text-[#17365D]">—</p>
    </div>
  );
}

function SupervisionCard({
  title,
  description,
}: {
  title: string;
  description: string;
}) {
  return (
    <div className="rounded-xl border border-purple-200 bg-white p-5">
      <h3 className="font-bold text-slate-800">{title}</h3>

      <p className="mt-2 text-sm leading-6 text-slate-600">
        {description}
      </p>

      <p className="mt-4 text-sm font-semibold text-slate-400">
        Data unavailable
      </p>
    </div>
  );
}