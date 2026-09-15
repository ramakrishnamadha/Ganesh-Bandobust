"use client";

import { useRouter } from "next/navigation";

type DisplayValueProps = {
  label: string;
  value?: string | null;
  alert?: boolean;
};

export default function GeoTaggedInstallationPage() {
  const router = useRouter();

  /*
   * Stage-2 API integration is intentionally pending.
   *
   * This is a Web supervisory / monitoring screen.
   * GPS must come from the actual Mobile verification record
   * through the finalized backend/API.
   *
   * Do NOT use browser geolocation here as a substitute.
   */

  return (
    <main className="min-h-screen bg-slate-100">
      <header className="bg-[#17365D] text-white">
        <div className="mx-auto flex max-w-6xl items-center justify-between px-6 py-5">
          <div>
            <p className="text-xs tracking-widest text-blue-200">
              STAGE 2 — INSTALLATION
            </p>

            <h1 className="mt-1 text-2xl font-bold">
              Geo-Tagged Based Verification
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
                Geo-Tagged Installation Data Awaiting API Integration
              </h2>

              <p className="mt-2 max-w-4xl text-sm leading-6 text-amber-800">
                This page is prepared to compare the Stage-1 verified GPID
                location with the GPS captured during Stage-2 Installation
                verification. Live values will be connected only after the
                finalized Installation API contract is confirmed.
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

        {/* PRINCIPLE */}

        <section className="mb-6 rounded-xl border border-blue-200 bg-blue-50 p-5">
          <p className="text-xs font-bold uppercase tracking-wider text-blue-700">
            Location Verification Principle
          </p>

          <p className="mt-2 font-semibold text-slate-800">
            Stage-1 Verified Location → Stage-2 Installation GPS → Location
            Match / Deviation
          </p>

          <p className="mt-2 text-sm leading-6 text-slate-600">
            The original Stage-1 location remains read-only. Stage-2 GPS is a
            separate verification record and must never overwrite the original
            verified coordinates.
          </p>
        </section>

        {/* STAGE 1 LOCATION */}

        <section className="mb-6 rounded-xl border border-slate-200 bg-white p-6">
          <div className="mb-5 flex flex-wrap items-center justify-between gap-3">
            <div>
              <p className="text-xs font-bold uppercase tracking-wider text-slate-400">
                Reference Location
              </p>

              <h2 className="mt-1 text-lg font-bold text-slate-800">
                Stage-1 Verified Location
              </h2>

              <p className="mt-1 text-sm text-slate-500">
                Pre-Installation information — read only
              </p>
            </div>

            <ReadOnlyBadge />
          </div>

          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
            <DisplayValue label="Latitude" />
            <DisplayValue label="Longitude" />
            <DisplayValue label="Location Verified" />
            <DisplayValue label="Stage-1 Verified At" />
          </div>

          <div className="mt-4">
            <MapPlaceholder title="Stage-1 Verified Location Map" />
          </div>
        </section>

        {/* STAGE 2 GPS */}

        <section className="mb-6 rounded-xl border border-slate-200 bg-white p-6">
          <div className="mb-5">
            <p className="text-xs font-bold uppercase tracking-wider text-slate-400">
              Installation Location
            </p>

            <h2 className="mt-1 text-lg font-bold text-slate-800">
              Stage-2 Installation GPS
            </h2>

            <p className="mt-1 text-sm text-slate-500">
              GPS captured during the Mobile Installation verification
            </p>
          </div>

          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
            <DisplayValue label="Current Latitude" />
            <DisplayValue label="Current Longitude" />
            <DisplayValue label="GPS Accuracy" />
            <DisplayValue label="Captured At" />
          </div>

          <div className="mt-4">
            <MapPlaceholder title="Stage-2 Installation Location Map" />
          </div>
        </section>

        {/* COMPARISON */}

        <section className="mb-6 rounded-xl border border-slate-200 bg-white p-6">
          <div className="mb-5 flex flex-wrap items-center justify-between gap-3">
            <div>
              <p className="text-xs font-bold uppercase tracking-wider text-slate-400">
                Location Comparison
              </p>

              <h2 className="mt-1 text-lg font-bold text-slate-800">
                Installed at Verified Location
              </h2>
            </div>

            <StatusUnavailable />
          </div>

          <div className="grid gap-4 md:grid-cols-3">
            <DisplayValue label="Installed at Verified Location" />
            <DisplayValue label="Distance from Stage-1 Location" />
            <DisplayValue label="Comparison Result" />
          </div>

          <p className="mt-4 text-sm leading-6 text-slate-500">
            The finalized server contract should provide or support the
            authoritative location-comparison result using the approved
            tolerance. This Web page must display that result rather than
            independently deciding a different tolerance.
          </p>
        </section>

        {/* DEVIATION */}

        <section className="mb-6 rounded-xl border border-red-200 bg-red-50 p-6">
          <div className="mb-5 flex flex-wrap items-center justify-between gap-3">
            <div>
              <p className="text-xs font-bold uppercase tracking-wider text-red-600">
                Exception Monitoring
              </p>

              <h2 className="mt-1 text-lg font-bold text-red-900">
                Location Deviation
              </h2>
            </div>

            <span className="rounded-full bg-slate-200 px-3 py-1 text-xs font-bold text-slate-600">
              STATUS UNAVAILABLE
            </span>
          </div>

          <div className="rounded-lg border border-red-200 bg-white p-4">
            <p className="text-sm font-bold text-red-800">
              LOCATION DEVIATION DETECTED
            </p>

            <p className="mt-2 text-sm leading-6 text-slate-500">
              This warning is displayed as the prepared exception state. It
              must become active only when the actual Stage-2 verification
              record reports a location mismatch.
            </p>
          </div>

          <div className="mt-4 grid gap-4 md:grid-cols-2">
            <DisplayValue label="Distance / Deviation in Metres" alert />
            <DisplayValue label="Reason / Remarks" alert />
          </div>

          <div className="mt-4">
            <EvidencePanel />
          </div>
        </section>

        {/* OFFICER RECORD */}

        <section className="rounded-xl border border-slate-200 bg-white p-6">
          <div className="mb-5">
            <p className="text-xs font-bold uppercase tracking-wider text-slate-400">
              Verification Record
            </p>

            <h2 className="mt-1 text-lg font-bold text-slate-800">
              Officer, Time & GPS
            </h2>
          </div>

          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
            <DisplayValue label="Verified By" />
            <DisplayValue label="Rank / Unit" />
            <DisplayValue label="Verification Date & Time" />
            <DisplayValue label="Verification GPS" />
          </div>
        </section>
      </div>
    </main>
  );
}

function DisplayValue({
  label,
  value,
  alert = false,
}: DisplayValueProps) {
  return (
    <div
      className={`rounded-lg border p-4 ${
        alert
          ? "border-red-200 bg-white"
          : "border-slate-200 bg-white"
      }`}
    >
      <p
        className={`text-xs font-semibold ${
          alert ? "text-red-600" : "text-slate-500"
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

function MapPlaceholder({ title }: { title: string }) {
  return (
    <div className="rounded-xl border border-dashed border-slate-300 bg-slate-50 p-5">
      <p className="font-semibold text-slate-700">{title}</p>

      <div className="mt-3 flex min-h-40 items-center justify-center rounded-lg border border-slate-200 bg-white">
        <span className="text-sm font-medium text-slate-400">
          Map data unavailable
        </span>
      </div>
    </div>
  );
}

function EvidencePanel() {
  return (
    <div className="rounded-xl border border-dashed border-red-300 bg-white p-5">
      <p className="font-bold text-red-800">
        Mandatory Geo-Tagged Deviation Photo
      </p>

      <p className="mt-2 text-sm leading-6 text-slate-500">
        When a genuine location mismatch is recorded, the supporting
        geo-tagged photograph captured during Stage-2 should be displayed here.
      </p>

      <div className="mt-4 flex min-h-28 items-center justify-center rounded-lg border border-slate-200 bg-slate-50">
        <span className="text-sm font-medium text-slate-400">
          Evidence unavailable
        </span>
      </div>
    </div>
  );
}

function ReadOnlyBadge() {
  return (
    <span className="rounded-full bg-blue-100 px-3 py-1 text-xs font-bold text-blue-700">
      STAGE-1 READ ONLY
    </span>
  );
}

function StatusUnavailable() {
  return (
    <span className="rounded-full bg-slate-100 px-3 py-1 text-xs font-bold text-slate-600">
      DATA UNAVAILABLE
    </span>
  );
}