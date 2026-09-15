"use client";

import { useEffect, useMemo, useState } from "react";
import { useRouter } from "next/navigation";

type GpidRecord = {
  gpid: string;
  range: string | null;
  zone: string | null;
  division: string | null;
  policeStation: string | null;
  status: string | null;
};

type GpidMasterResponse = {
  success: boolean;
  fetchedAt?: string;
  total?: number;
  rangeAvailable?: boolean;
  records?: GpidRecord[];
  message?: string;
};

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

  const [records, setRecords] = useState<GpidRecord[]>([]);
  const [loadingGpids, setLoadingGpids] = useState(true);
  const [gpidError, setGpidError] = useState("");
  const [fetchedAt, setFetchedAt] = useState<string | null>(null);

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

        if (!response.ok || !data.success || !Array.isArray(data.records)) {
          throw new Error(
            data.message || "Unable to load live GPID master data.",
          );
        }

        if (!active) return;

        setRecords(data.records);
        setFetchedAt(data.fetchedAt ?? null);
      } catch (error) {
        if (!active) return;

        console.error("Festivity dashboard GPID error:", error);

        setGpidError(
          error instanceof Error
            ? error.message
            : "Unable to load live GPID master data.",
        );
      } finally {
        if (active) {
          setLoadingGpids(false);
        }
      }
    }

    void loadGpids();

    const refreshTimer = window.setInterval(() => {
      void loadGpids();
    }, 60000);

    return () => {
      active = false;
      window.clearInterval(refreshTimer);
    };
  }, []);

  const masterSummary = useMemo(() => {
    const zones = new Set<string>();
    const divisions = new Set<string>();
    const policeStations = new Set<string>();

    for (const record of records) {
      if (record.zone) zones.add(record.zone);
      if (record.division) divisions.add(record.division);
      if (record.policeStation) policeStations.add(record.policeStation);
    }

    return {
      totalGpids: records.length,
      zones: zones.size,
      divisions: divisions.size,
      policeStations: policeStations.size,
    };
  }, [records]);

  const apiLive = !loadingGpids && !gpidError && records.length > 0;

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

            <span
              className={`rounded-full px-4 py-2 text-xs font-bold ${
                loadingGpids
                  ? "bg-amber-100 text-amber-800"
                  : apiLive
                    ? "bg-emerald-100 text-emerald-800"
                    : "bg-red-100 text-red-800"
              }`}
            >
              {loadingGpids
                ? "CONNECTING LIVE GPID API"
                : apiLive
                  ? "GPID API LIVE"
                  : "GPID API ERROR"}
            </span>
          </div>

          {gpidError && (
            <div className="mt-4 rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
              {gpidError}
            </div>
          )}
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
                supervisory checks must not overwrite an earlier officer&apos;s
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
          <SummaryCard
            label="Total GPIDs"
            value={
              loadingGpids
                ? "..."
                : gpidError
                  ? "—"
                  : masterSummary.totalGpids.toLocaleString()
            }
            note="Live GPID master"
          />

          <SummaryCard
            label="Checked Today"
            value="—"
            note="Stage-3 saved visits pending"
          />

          <SummaryCard
            label="Pending / Unchecked"
            value="—"
            note="Calculated after visit persistence"
          />

          <SummaryCard
            label="Adverse Findings"
            value="—"
            note="Calculated from saved checking records"
          />

          <SummaryCard
            label="Follow-up Pending"
            value="—"
            note="Calculated from saved checking records"
          />

          <SummaryCard
            label="SB Disagreements"
            value="—"
            note="Calculated from SB audit records"
          />

          <SummaryCard
            label="Senior Officer Remarks"
            value="—"
            note="Calculated from supervisory records"
          />

          <SummaryCard
            label="Repeated Checks"
            value="—"
            note="Calculated from immutable visit history"
          />
        </section>

        {/* LIVE MASTER MONITORING */}

        <section className="mb-6 rounded-xl border border-emerald-200 bg-white p-5 shadow-sm">
          <div className="flex flex-wrap items-start justify-between gap-4">
            <div>
              <p className="text-xs font-bold uppercase tracking-wider text-emerald-700">
                Live GPID Master
              </p>

              <h2 className="mt-1 text-lg font-bold text-slate-800">
                Festivity Monitoring
              </h2>

              <p className="mt-1 text-sm text-slate-500">
                Current 2026 GPID master is connected. Stage-3 operational
                counters will populate after checking visits are persisted.
              </p>
            </div>

            <span
              className={`rounded-full px-3 py-1 text-xs font-bold ${
                apiLive
                  ? "bg-emerald-100 text-emerald-700"
                  : "bg-slate-100 text-slate-600"
              }`}
            >
              {apiLive ? "LIVE DATA" : "WAITING FOR DATA"}
            </span>
          </div>

          <div className="mt-5 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
            <MasterStat label="GPIDs" value={masterSummary.totalGpids} />
            <MasterStat label="Zones" value={masterSummary.zones} />
            <MasterStat label="Divisions" value={masterSummary.divisions} />
            <MasterStat
              label="Police Stations"
              value={masterSummary.policeStations}
            />
          </div>

          {fetchedAt && (
            <p className="mt-4 text-xs text-slate-400">
              Last live master refresh:{" "}
              {new Date(fetchedAt).toLocaleString()}
            </p>
          )}
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
              status="Awaiting saved Stage-3 records"
            />

            <SupervisionCard
              title="Senior Officer Remarks"
              description="Senior officer remarks may be recorded through the application or represented by captured Physical Point Book evidence where applicable."
              status="Awaiting saved Stage-3 records"
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

function SummaryCard({
  label,
  value,
  note,
}: {
  label: string;
  value: string;
  note?: string;
}) {
  return (
    <div className="rounded-xl border border-slate-200 bg-white p-5">
      <p className="text-sm font-medium text-slate-500">
        {label}
      </p>

      <p className="mt-2 text-3xl font-bold text-[#17365D]">
        {value}
      </p>

      {note && (
        <p className="mt-2 text-xs leading-5 text-slate-400">
          {note}
        </p>
      )}
    </div>
  );
}

function MasterStat({
  label,
  value,
}: {
  label: string;
  value: number;
}) {
  return (
    <div className="rounded-xl border border-emerald-100 bg-emerald-50 p-4">
      <p className="text-xs font-semibold uppercase tracking-wide text-emerald-700">
        {label}
      </p>

      <p className="mt-1 text-2xl font-bold text-slate-800">
        {value.toLocaleString()}
      </p>
    </div>
  );
}

function SupervisionCard({
  title,
  description,
  status,
}: {
  title: string;
  description: string;
  status: string;
}) {
  return (
    <div className="rounded-xl border border-purple-200 bg-white p-5">
      <h3 className="font-bold text-slate-800">
        {title}
      </h3>

      <p className="mt-2 text-sm leading-6 text-slate-600">
        {description}
      </p>

      <p className="mt-4 text-sm font-semibold text-slate-400">
        {status}
      </p>
    </div>
  );
}
