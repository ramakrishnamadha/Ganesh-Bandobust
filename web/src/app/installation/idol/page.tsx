"use client";

import { useRouter } from "next/navigation";

type DisplayValueProps = {
  label: string;
  value?: string | null;
  important?: boolean;
};

export default function InstallationIdolPage() {
  const router = useRouter();

  /*
   * IMPORTANT:
   * Stage-2 Installation API integration is intentionally not connected here.
   *
   * This Web page is a supervisory / monitoring interface.
   * It must eventually receive:
   *   1. Stage-1 Pre-Installation Idol information
   *   2. Stage-2 Installation verification information
   *   3. Officer / GPS / evidence / timestamp information
   *
   * Do not replace these unavailable states with fabricated demo data.
   */

  return (
    <main className="min-h-screen bg-slate-100">
      {/* HEADER */}

      <header className="bg-[#17365D] text-white">
        <div className="mx-auto flex max-w-6xl items-center justify-between px-6 py-5">
          <div>
            <p className="text-xs tracking-widest text-blue-200">
              STAGE 2 — INSTALLATION
            </p>

            <h1 className="mt-1 text-2xl font-bold">
              Idol-Based Installation Verification
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
        {/* API STATUS */}

        <section className="mb-6 rounded-xl border border-amber-200 bg-amber-50 p-5">
          <div className="flex flex-wrap items-start justify-between gap-3">
            <div>
              <h2 className="font-bold text-amber-900">
                Installation Data Awaiting API Integration
              </h2>

              <p className="mt-2 max-w-4xl text-sm leading-6 text-amber-800">
                This monitoring screen is prepared for Stage-1 carried-forward
                Idol information and Stage-2 Installation verification. Live
                GPID data will be connected only after the finalized Stage-2
                Installation API contract is confirmed.
              </p>
            </div>

            <span className="rounded-full bg-amber-200 px-3 py-1 text-xs font-bold text-amber-900">
              API PENDING
            </span>
          </div>
        </section>

        {/* GPID CONTEXT */}

        <section className="mb-6 rounded-xl border border-slate-200 bg-white p-5">
          <div className="flex flex-wrap items-start justify-between gap-5">
            <div>
              <p className="text-xs font-bold uppercase tracking-wider text-slate-400">
                GPID
              </p>

              <p className="mt-1 text-xl font-bold text-[#17365D]">
                Data unavailable
              </p>
            </div>

            <div className="grid gap-4 text-sm sm:grid-cols-3">
              <DisplayValue label="Police Station" />
              <DisplayValue label="Division" />
              <DisplayValue label="Zone" />
            </div>
          </div>
        </section>

        {/* MONITORING PRINCIPLE */}

        <section className="mb-6 rounded-xl border border-blue-200 bg-blue-50 p-5">
          <p className="text-xs font-bold uppercase tracking-wider text-blue-700">
            Monitoring Principle
          </p>

          <p className="mt-2 font-semibold text-slate-800">
            Stage-1 Idol Information → Stage-2 Installation Confirmation →
            Change / Deviation
          </p>

          <p className="mt-2 text-sm leading-6 text-slate-600">
            Stage-1 information remains read-only. Stage-2 should confirm the
            actual installation and separately identify any new information,
            change or deviation without overwriting the original
            Pre-Installation verification.
          </p>
        </section>

        {/* INSTALLATION STATUS */}

        <section className="mb-6 rounded-xl border border-slate-200 bg-white p-6">
          <div className="mb-5 flex flex-wrap items-center justify-between gap-3">
            <div>
              <p className="text-xs font-bold uppercase tracking-wider text-slate-400">
                Point 1
              </p>

              <h2 className="mt-1 text-lg font-bold text-slate-800">
                Idol Installation Status
              </h2>
            </div>

            <StatusUnavailable />
          </div>

          <div className="grid gap-4 md:grid-cols-2">
            <MonitoringPanel
              title="Stage-1 Pre-Installation"
              subtitle="Original verification — read only"
            >
              <DisplayValue label="Idol Installed" />
            </MonitoringPanel>

            <MonitoringPanel
              title="Stage-2 Installation"
              subtitle="Installation confirmation"
            >
              <DisplayValue label="Installation Result" />
              <DisplayValue label="Actual Installation Date" />
            </MonitoringPanel>
          </div>

          <p className="mt-4 text-sm leading-6 text-slate-500">
            If Stage-1 already records the Idol as installed, that original
            status must only be displayed. If Stage-1 records it as not
            installed, Stage-2 may contain the subsequent installation
            confirmation and actual installation date.
          </p>
        </section>

        {/* HEIGHT */}

        <section className="mb-6 rounded-xl border border-slate-200 bg-white p-6">
          <div className="mb-5">
            <p className="text-xs font-bold uppercase tracking-wider text-slate-400">
              Point 2
            </p>

            <h2 className="mt-1 text-lg font-bold text-slate-800">
              Idol Height Verification
            </h2>
          </div>

          <div className="grid gap-4 md:grid-cols-2">
            <MonitoringPanel
              title="Stage-1 Declared / Verified Height"
              subtitle="Carried forward — read only"
            >
              <DisplayValue label="Stage-1 Height" />
            </MonitoringPanel>

            <MonitoringPanel
              title="Stage-2 Actual Installation"
              subtitle="Comparison / deviation"
            >
              <DisplayValue label="Actual Height Same as Stage-1" />
              <DisplayValue label="Actual Height — Feet" />
              <DisplayValue label="Actual Height — Inches" />
            </MonitoringPanel>
          </div>
        </section>

        {/* MATERIAL */}

        <section className="mb-6 rounded-xl border border-slate-200 bg-white p-6">
          <div className="mb-5">
            <p className="text-xs font-bold uppercase tracking-wider text-slate-400">
              Point 3
            </p>

            <h2 className="mt-1 text-lg font-bold text-slate-800">
              Idol Material Verification
            </h2>
          </div>

          <div className="grid gap-4 md:grid-cols-2">
            <MonitoringPanel
              title="Stage-1 Material"
              subtitle="Carried forward — read only"
            >
              <DisplayValue label="Recorded Idol Material" />
            </MonitoringPanel>

            <MonitoringPanel
              title="Stage-2 Material"
              subtitle="Actual installation comparison"
            >
              <DisplayValue label="Actual Material Same as Stage-1" />
              <DisplayValue label="Actual Material" />
              <DisplayValue label="Deviation Remarks" />
            </MonitoringPanel>
          </div>
        </section>

        {/* PHOTO EVIDENCE */}

        <section className="mb-6 rounded-xl border border-slate-200 bg-white p-6">
          <div className="mb-5">
            <p className="text-xs font-bold uppercase tracking-wider text-slate-400">
              Point 4
            </p>

            <h2 className="mt-1 text-lg font-bold text-slate-800">
              Idol Photographic Evidence
            </h2>
          </div>

          <div className="grid gap-4 md:grid-cols-2">
            <EvidencePanel
              title="Stage-1 Idol Photo"
              description="Existing valid Pre-Installation evidence should be displayed read-only when Web-accessible."
            />

            <EvidencePanel
              title="Stage-2 Installed Idol Photo"
              description="Fresh Stage-2 evidence is expected when the Idol was not installed during Stage-1 and is subsequently installed."
            />
          </div>

          <div className="mt-4 rounded-lg border border-slate-200 bg-slate-50 px-4 py-3">
            <p className="text-xs leading-5 text-slate-500">
              Android-local file paths must not be treated as Web-viewable
              evidence. Only evidence made accessible through the finalized
              backend should be rendered here.
            </p>
          </div>
        </section>

        {/* DEVIATION */}

        <section className="mb-6 rounded-xl border border-slate-200 bg-white p-6">
          <div className="mb-5 flex flex-wrap items-center justify-between gap-3">
            <div>
              <p className="text-xs font-bold uppercase tracking-wider text-slate-400">
                Point 5
              </p>

              <h2 className="mt-1 text-lg font-bold text-slate-800">
                Installation Deviation
              </h2>
            </div>

            <StatusUnavailable />
          </div>

          <div className="grid gap-4 md:grid-cols-2">
            <DisplayValue label="Any Deviation Detected" important />
            <DisplayValue label="Deviation Remarks" important />
          </div>

          <div className="mt-4">
            <EvidencePanel
              title="Supporting Deviation Evidence"
              description="Supporting evidence should be displayed where it was captured for an Installation deviation."
            />
          </div>
        </section>

        {/* OFFICER / AUDIT */}

        <section className="rounded-xl border border-slate-200 bg-white p-6">
          <div className="mb-5">
            <p className="text-xs font-bold uppercase tracking-wider text-slate-400">
              Verification Record
            </p>

            <h2 className="mt-1 text-lg font-bold text-slate-800">
              Officer, Time & Location
            </h2>
          </div>

          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
            <DisplayValue label="Verified By" />
            <DisplayValue label="Rank / Unit" />
            <DisplayValue label="Verification Date & Time" />
            <DisplayValue label="GPS Location" />
          </div>
        </section>
      </div>
    </main>
  );
}

function MonitoringPanel({
  title,
  subtitle,
  children,
}: {
  title: string;
  subtitle: string;
  children: React.ReactNode;
}) {
  return (
    <div className="rounded-xl border border-slate-200 bg-slate-50 p-5">
      <h3 className="font-bold text-slate-800">{title}</h3>

      <p className="mt-1 text-xs text-slate-500">{subtitle}</p>

      <div className="mt-4 space-y-3">{children}</div>
    </div>
  );
}

function DisplayValue({
  label,
  value,
  important = false,
}: DisplayValueProps) {
  return (
    <div
      className={`rounded-lg border p-4 ${
        important
          ? "border-amber-200 bg-amber-50"
          : "border-slate-200 bg-white"
      }`}
    >
      <p
        className={`text-xs font-semibold ${
          important ? "text-amber-700" : "text-slate-500"
        }`}
      >
        {label}
      </p>

      <p className="mt-1 font-semibold text-slate-700">
        {value || "Data unavailable"}
      </p>
    </div>
  );
}

function StatusUnavailable() {
  return (
    <span className="rounded-full bg-slate-100 px-3 py-1 text-xs font-bold text-slate-600">
      DATA UNAVAILABLE
    </span>
  );
}

function EvidencePanel({
  title,
  description,
}: {
  title: string;
  description: string;
}) {
  return (
    <div className="rounded-xl border border-dashed border-slate-300 bg-slate-50 p-5">
      <p className="font-bold text-slate-700">{title}</p>

      <p className="mt-2 text-sm leading-6 text-slate-500">{description}</p>

      <div className="mt-4 flex min-h-28 items-center justify-center rounded-lg border border-slate-200 bg-white">
        <span className="text-sm font-medium text-slate-400">
          Evidence unavailable
        </span>
      </div>
    </div>
  );
}