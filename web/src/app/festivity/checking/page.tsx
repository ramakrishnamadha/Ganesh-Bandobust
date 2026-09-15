"use client";

import { useState, type ReactNode } from "react";
import { useRouter } from "next/navigation";

import FestivityGpidSelector, {
  type GpidRecord,
} from "@/components/FestivityGpidSelector";

type DisplayValueProps = {
  label: string;
  value?: string | null;
  alert?: boolean;
};

type SelectionMode = "hierarchy" | "map";

export default function FestivityCheckingPage() {
  const router = useRouter();

  const [selectionMode, setSelectionMode] =
    useState<SelectionMode>("hierarchy");

  const [selectedGpid, setSelectedGpid] =
    useState<GpidRecord | null>(null);

  return (
    <main className="min-h-screen bg-slate-100">
      <header className="bg-[#17365D] text-white">
        <div className="mx-auto flex max-w-7xl items-center justify-between px-6 py-5">
          <div>
            <p className="text-xs tracking-widest text-blue-200">
              STAGE 3 — FESTIVITY PERIOD
            </p>

            <h1 className="mt-1 text-2xl font-bold">
              CHECKING
            </h1>

            <p className="mt-1 text-sm text-blue-100">
              GPID Field Checking — Monitoring & Supervisory View
            </p>
          </div>

          <button
            type="button"
            onClick={() => router.push("/festivity")}
            className="rounded-lg border border-white/30 px-4 py-2 hover:bg-white/10"
          >
            ← Festivity
          </button>
        </div>
      </header>

      <div className="mx-auto max-w-7xl px-6 py-8">
        <section className="mb-6 rounded-xl border border-slate-200 bg-white p-6">
          <div className="mb-5">
            <p className="text-xs font-bold uppercase tracking-wider text-slate-400">
              GPID Selection
            </p>

            <h2 className="mt-1 text-lg font-bold text-slate-800">
              Select Ganesh Point for Checking
            </h2>

            <p className="mt-1 text-sm leading-6 text-slate-500">
              Select the GPID through the organisational hierarchy or
              through map-based selection when authoritative coordinates
              are available.
            </p>
          </div>

          <div className="mb-6 grid gap-4 md:grid-cols-2">
            <button
              type="button"
              onClick={() => setSelectionMode("hierarchy")}
              className={`rounded-xl border p-5 text-left transition ${
                selectionMode === "hierarchy"
                  ? "border-[#17365D] bg-blue-50 ring-1 ring-[#17365D]"
                  : "border-slate-200 bg-white hover:border-slate-300"
              }`}
            >
              <p className="font-bold text-slate-800">
                GPID / Hierarchy Selection
              </p>

              <p className="mt-2 text-sm text-slate-500">
                Range → Zone → Division → Police Station → GPID
              </p>
            </button>

            <button
              type="button"
              onClick={() => setSelectionMode("map")}
              className={`rounded-xl border p-5 text-left transition ${
                selectionMode === "map"
                  ? "border-[#17365D] bg-blue-50 ring-1 ring-[#17365D]"
                  : "border-slate-200 bg-white hover:border-slate-300"
              }`}
            >
              <p className="font-bold text-slate-800">
                Map-Based GPID Selection
              </p>

              <p className="mt-2 text-sm text-slate-500">
                Select the required Ganesh point from the GPID map.
              </p>
            </button>
          </div>

          {selectionMode === "hierarchy" && (
            <FestivityGpidSelector
              onSelect={setSelectedGpid}
            />
          )}

          {selectionMode === "map" && (
            <div className="rounded-xl border border-amber-200 bg-amber-50 p-6">
              <p className="font-bold text-amber-900">
                Map data pending
              </p>

              <p className="mt-2 text-sm text-amber-800">
                Only authoritative GPID coordinates will be used.
              </p>
            </div>
          )}
        </section>

        <section className="rounded-xl border border-slate-200 bg-white p-6">
          <h2 className="text-lg font-bold text-[#17365D]">
            {selectedGpid
              ? `GPID — ${selectedGpid.gpid}`
              : "GPID — Data unavailable"}
          </h2>

          <div className="mt-4 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
            <DisplayValue
              label="Range"
              value={selectedGpid?.range}
            />

            <DisplayValue
              label="Zone"
              value={selectedGpid?.zone}
            />

            <DisplayValue
              label="Division"
              value={selectedGpid?.division}
            />

            <DisplayValue
              label="Police Station"
              value={selectedGpid?.policeStation}
            />
          </div>
        </section>
      </div>
    </main>
  );
}

function DisplayValue({
  label,
  value,
}: DisplayValueProps) {
  return (
    <div className="rounded-lg border border-slate-200 bg-white p-4">
      <p className="text-xs font-semibold text-slate-500">
        {label}
      </p>

      <p className="mt-1 font-semibold text-slate-700">
        {value || "Data unavailable"}
      </p>
    </div>
  );
}