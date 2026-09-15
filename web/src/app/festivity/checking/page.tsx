"use client";

import { useState, type ReactNode } from "react";
import { useRouter } from "next/navigation";

import FestivityGpidSelector, {
  type GpidRecord,
} from "@/components/FestivityGpidSelector";

type SelectionMode = "hierarchy" | "map";

type DisplayValueProps = {
  label: string;
  value?: string | null;
};

type ModuleCardProps = {
  number: string;
  title: string;
  description: string;
  children: ReactNode;
  disabled: boolean;
};

export default function FestivityCheckingPage() {
  const router = useRouter();

  const [selectionMode, setSelectionMode] =
    useState<SelectionMode>("hierarchy");

  const [selectedGpid, setSelectedGpid] =
    useState<GpidRecord | null>(null);

  const hasSelectedGpid = Boolean(selectedGpid);

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
              GPID Checking — Monitoring & Supervisory View
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
        {/* GPID SELECTION */}

        <section className="mb-6 rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
          <div className="mb-5">
            <p className="text-xs font-bold uppercase tracking-wider text-slate-400">
              GPID Selection
            </p>

            <h2 className="mt-1 text-xl font-bold text-slate-800">
              Select Ganesh Point
            </h2>

            <p className="mt-1 text-sm leading-6 text-slate-500">
              Select the GPID before viewing Stage-3 checking
              information.
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
                Zone → Division → Police Station → GPID
              </p>

              <p className="mt-1 text-xs text-amber-700">
                Range will be displayed only when authoritative
                Range data is available.
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
                Select a Ganesh point through authoritative
                coordinates.
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
                Map Selection Not Available
              </p>

              <p className="mt-2 text-sm text-amber-800">
                The current 2026 GPID feed does not provide
                authoritative coordinates for these records.
                Coordinates will not be fabricated.
              </p>
            </div>
          )}
        </section>

        {/* SELECTED GPID */}

        <section className="mb-6 rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
          <div className="flex flex-wrap items-start justify-between gap-4">
            <div>
              <p className="text-xs font-bold uppercase tracking-wider text-slate-400">
                Selected Ganesh Point
              </p>

              <h2 className="mt-1 text-xl font-bold text-[#17365D]">
                {selectedGpid
                  ? `GPID — ${selectedGpid.gpid}`
                  : "Select a GPID to continue"}
              </h2>
            </div>

            {selectedGpid && (
              <span className="rounded-full bg-emerald-100 px-4 py-2 text-xs font-bold text-emerald-800">
                GPID SELECTED
              </span>
            )}
          </div>

          {selectedGpid && (
            <>
              <div className="mt-5 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
                <DisplayValue
                  label="Range"
                  value={selectedGpid.range}
                />

                <DisplayValue
                  label="Zone"
                  value={selectedGpid.zone}
                />

                <DisplayValue
                  label="Division"
                  value={selectedGpid.division}
                />

                <DisplayValue
                  label="Police Station"
                  value={selectedGpid.policeStation}
                />
              </div>

              <div className="mt-4 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
                <DisplayValue
                  label="Applicant / Organizer"
                  value={selectedGpid.name}
                />

                <DisplayValue
                  label="Association"
                  value={selectedGpid.association}
                />

                <DisplayValue
                  label="Mobile"
                  value={selectedGpid.mobile}
                />

                <DisplayValue
                  label="Application Status"
                  value={selectedGpid.status}
                />
              </div>

              <div className="mt-4 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
                <DisplayValue
                  label="Idol Type"
                  value={selectedGpid.idolType}
                />

                <DisplayValue
                  label="Idol Height"
                  value={selectedGpid.idolHeight}
                />

                <DisplayValue
                  label="Pandal Height"
                  value={selectedGpid.pandalHeight}
                />

                <DisplayValue
                  label="Area Type"
                  value={selectedGpid.areaType}
                />
              </div>

              <div className="mt-4 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
                <DisplayValue
                  label="Installation From"
                  value={selectedGpid.installFromDate}
                />

                <DisplayValue
                  label="Installation To"
                  value={selectedGpid.installToDate}
                />

                <DisplayValue
                  label="Immersion Date"
                  value={selectedGpid.immersionDate}
                />

                <DisplayValue
                  label="Immersion Place"
                  value={selectedGpid.immersionPlace}
                />
              </div>

              <div className="mt-4">
                <DisplayValue
                  label="Address"
                  value={selectedGpid.address}
                />
              </div>
            </>
          )}
        </section>

        {/* CHECKING MODULES */}

        <section className="mb-6">
          <div className="mb-5">
            <p className="text-xs font-bold uppercase tracking-wider text-blue-600">
              Stage-3 Checking Areas
            </p>

            <h2 className="mt-1 text-2xl font-bold text-slate-800">
              Festivity Period Checking
            </h2>

            <p className="mt-2 max-w-4xl text-sm leading-6 text-slate-600">
              Every visit must remain an independent,
              auditable checking record. A later visit must
              never overwrite an earlier visit.
            </p>
          </div>

          <div className="space-y-5">
            <ModuleCard
              number="01"
              title="Anti-Desecration Drill"
              description="Physical checking of the idol, Mandap, Laddu, Hundi, jewellery/valuables and the surrounding area."
              disabled={!hasSelectedGpid}
            >
              <div className="space-y-4">
                <YesNoCheck label="Check Idol" />
                <YesNoCheck label="Check Mandap" />
                <YesNoCheck label="Check Laddu" />
                <YesNoCheck label="Check Hundi" />
                <YesNoCheck label="Check Jewellery / Valuables" />
                <YesNoCheck label="Check Inside the Mandap" />
                <YesNoCheck label="Check Around the Mandap" />

                <div>
                  <label className="mb-2 block text-sm font-semibold text-slate-700">
                    Anti-Desecration Drill Remarks
                  </label>
                  <textarea
                    rows={4}
                    placeholder="Enter remarks..."
                    className="w-full rounded-lg border border-slate-300 bg-white px-4 py-3 text-sm text-slate-800 outline-none focus:border-[#17365D] focus:ring-1 focus:ring-[#17365D]"
                  />
                </div>
              </div>
            </ModuleCard>

            <ModuleCard
              number="02"
              title="Volunteers"
              description="Availability, strength and identity of volunteers at the selected GPID."
              disabled={!hasSelectedGpid}
            >
              <VolunteerCheck />
            </ModuleCard>

            <ModuleCard
              number="03"
              title="Lighting"
              description="Lighting arrangements inside and around the Mandap during the applicable checking period."
              disabled={!hasSelectedGpid}
            >
              <div className="space-y-4">
                <YesNoCheck label="Lighting Inside Mandap Available" />
                <YesNoCheck label="Lighting Around Mandap Available" />
                <RemarksBox
                  label="Lighting Remarks / Action Taken"
                  placeholder="Enter deficiency noticed and action taken..."
                />
              </div>
            </ModuleCard>

            <ModuleCard
              number="04"
              title="Sanitation"
              description="Sanitation and cleanliness conditions at the Ganesh point."
              disabled={!hasSelectedGpid}
            >
              <div className="space-y-4">
                <YesNoCheck label="Sanitation Inside Mandap Satisfactory" />
                <YesNoCheck label="Sanitation Around Mandap Satisfactory" />
                <YesNoCheck label="Waste / Garbage Properly Cleared" />
                <RemarksBox
                  label="Sanitation Remarks / Action Taken"
                  placeholder="Enter sanitation deficiency and action taken..."
                />
              </div>
            </ModuleCard>

            <ModuleCard
              number="05"
              title="Pooja & Night Safety"
              description="Continuing safety of pooja arrangements and important objects during the festivity period."
              disabled={!hasSelectedGpid}
            >
              <div className="space-y-4">
                <YesNoCheck label="Laddu Safety Arrangements Satisfactory" />
                <YesNoCheck label="Hundi Safety Arrangements Satisfactory" />
                <YesNoCheck label="Deepam / Flame Safety Satisfactory" />
                <YesNoCheck label="Jewellery / Valuable Articles Secured" />
                <YesNoCheck label="Night Safety Arrangement Available" />
                <RemarksBox
                  label="Pooja & Night Safety Remarks / Action Taken"
                  placeholder="Enter remarks / action taken..."
                />
              </div>
            </ModuleCard>

            <ModuleCard
              number="06"
              title="Sound / Time Compliance"
              description="Monitoring of sound-system use and compliance with permitted timings."
              disabled={!hasSelectedGpid}
            >
              <div className="space-y-4">
                <YesNoCheck label="Sound System Within Permitted Limits" />
                <YesNoCheck label="Permitted Time Compliance" />
                <YesNoCheck label="No Sound / Time Violation Noticed" />
                <RemarksBox
                  label="Action Taken"
                  placeholder="Enter action taken for any violation..."
                />
                <RemarksBox
                  label="Sound / Time Compliance Remarks"
                  placeholder="Enter remarks..."
                />
              </div>
            </ModuleCard>

            <ModuleCard
              number="07"
              title="Fire & Safety Follow-up"
              description="Follow-up of fire and general safety arrangements identified in earlier verification stages."
              disabled={!hasSelectedGpid}
            >
              <div className="space-y-4">
                <YesNoCheck label="Fire Safety Arrangement Satisfactory" />
                <YesNoCheck label="Electrical Safety Satisfactory" />
                <YesNoCheck label="Entry / Exit Accessibility Clear" />
                <YesNoCheck label="Emergency Access Available" />
                <YesNoCheck label="Previous Deficiencies Complied With" />
                <RemarksBox
                  label="Fire & Safety Follow-up Remarks / Action Taken"
                  placeholder="Enter pending deficiency, follow-up and action taken..."
                />
              </div>
            </ModuleCard>

            <ModuleCard
              number="08"
              title="Follow-up & Action Required"
              description="Adverse findings, instructions issued, compliance and pending corrective action."
              disabled={!hasSelectedGpid}
            >
              <div className="space-y-4">
                <YesNoCheck label="Adverse Finding Noticed" />
                <RemarksBox
                  label="Adverse Finding Details"
                  placeholder="Describe the adverse finding, if any..."
                />
                <RemarksBox
                  label="Instruction Issued"
                  placeholder="Enter instructions issued..."
                />
                <RemarksBox
                  label="Action Taken"
                  placeholder="Enter action taken..."
                />
                <YesNoCheck label="Further Follow-up Required" />
                <div>
                  <label className="mb-2 block text-sm font-semibold text-slate-700">
                    Compliance Status
                  </label>
                  <select
                    defaultValue=""
                    className="w-full rounded-lg border border-slate-300 bg-white px-4 py-3 text-sm text-slate-800 outline-none focus:border-[#17365D] focus:ring-1 focus:ring-[#17365D]"
                  >
                    <option value="" disabled>Select compliance status</option>
                    <option value="COMPLIED">COMPLIED</option>
                    <option value="PARTIALLY_COMPLIED">PARTIALLY COMPLIED</option>
                    <option value="PENDING">PENDING</option>
                    <option value="NOT_COMPLIED">NOT COMPLIED</option>
                  </select>
                </div>
                <RemarksBox
                  label="Officer Remarks"
                  placeholder="Enter officer remarks..."
                />
              </div>
            </ModuleCard>
          </div>
        </section>

        {/* SB + SENIOR OFFICER */}

        <section className="mb-6 rounded-xl border border-purple-200 bg-purple-50 p-6">
          <p className="text-xs font-bold uppercase tracking-wider text-purple-700">
            Cross Verification & Supervision
          </p>

          <h2 className="mt-1 text-xl font-bold text-slate-800">
            SB Cross Verification & Senior Officer Remarks
          </h2>

          <div className="mt-5 grid gap-5 lg:grid-cols-2">
            <div className="rounded-xl border border-purple-200 bg-white p-5">
              <h3 className="font-bold text-slate-800">
                SB Cross Verification
              </h3>

              <p className="mt-2 text-sm leading-6 text-slate-600">
                SB assessment must remain separately
                attributable and must not alter the original
                officer checking record.
              </p>

              <div className="mt-5">
                <p className="mb-3 text-sm font-semibold text-slate-700">
                  SB Assessment
                </p>

                <div className="flex flex-wrap gap-3">
                  <label className="flex cursor-pointer items-center gap-2 rounded-lg border border-emerald-300 bg-emerald-50 px-4 py-3">
                    <input type="radio" name="sbAssessment" value="AGREED" className="h-4 w-4" />
                    <span className="font-semibold text-emerald-800">AGREED</span>
                  </label>

                  <label className="flex cursor-pointer items-center gap-2 rounded-lg border border-red-300 bg-red-50 px-4 py-3">
                    <input type="radio" name="sbAssessment" value="DISAGREED" className="h-4 w-4" />
                    <span className="font-semibold text-red-800">DISAGREED</span>
                  </label>
                </div>

                <div className="mt-4">
                  <label className="mb-2 block text-sm font-semibold text-slate-700">
                    SB Remarks
                  </label>
                  <textarea
                    rows={5}
                    placeholder="Enter SB remarks. Remarks are mandatory when DISAGREED..."
                    className="w-full rounded-lg border border-slate-300 px-4 py-3 text-sm outline-none focus:border-purple-600 focus:ring-1 focus:ring-purple-600"
                  />
                </div>
              </div>
            </div>

            <div className="rounded-xl border border-purple-200 bg-white p-5">
              <h3 className="font-bold text-slate-800">
                Senior Officer Remarks
              </h3>

              <p className="mt-2 text-sm leading-6 text-slate-600">
                Senior officer remarks may be recorded
                directly through the application or through
                captured Physical Point Book evidence.
              </p>

              <div className="mt-5">
                <label className="mb-2 block text-sm font-semibold text-slate-700">
                  Senior Officer Remarks
                </label>
                <textarea
                  rows={6}
                  placeholder="Enter Senior Officer remarks..."
                  className="w-full rounded-lg border border-slate-300 px-4 py-3 text-sm outline-none focus:border-purple-600 focus:ring-1 focus:ring-purple-600"
                />

                <div className="mt-4 rounded-lg border border-dashed border-slate-300 bg-slate-50 p-4">
                  <p className="text-sm font-semibold text-slate-700">
                    Physical Point Book Evidence
                  </p>
                  <p className="mt-1 text-xs text-slate-500">
                    Point Book image/evidence upload will be connected with the evidence-storage API.
                  </p>
                </div>
              </div>
            </div>
          </div>
        </section>

        {/* AUDIT / HISTORY */}

        <section className="rounded-xl border border-slate-300 bg-white p-6 shadow-sm">
          <p className="text-xs font-bold uppercase tracking-wider text-slate-500">
            Immutable History
          </p>

          <h2 className="mt-1 text-xl font-bold text-[#17365D]">
            GPID Checking History
          </h2>

          {!selectedGpid ? (
            <p className="mt-4 text-sm text-slate-500">
              Select a GPID to view its Stage-3 checking
              history.
            </p>
          ) : (
            <div className="mt-4 rounded-xl border border-slate-200 bg-slate-50 p-5">
              <p className="font-semibold text-slate-800">
                GPID: {selectedGpid.gpid}
              </p>

              <p className="mt-2 text-sm leading-6 text-slate-600">
                Saved Stage-3 checking visits will appear here
                after the Stage-3 checking persistence API is
                connected.
              </p>

              <p className="mt-2 text-sm text-slate-500">
                Each record will preserve festival day/date,
                checking time, officer identity, rank/unit,
                GPS, findings, evidence, remarks, action taken,
                SB assessment, Senior Officer remarks and
                submission timestamp.
              </p>
            </div>
          )}
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
    <div className="rounded-lg border border-slate-200 bg-slate-50 p-4">
      <p className="text-xs font-semibold uppercase tracking-wide text-slate-500">
        {label}
      </p>

      <p className="mt-1 break-words font-semibold text-slate-800">
        {value || "Data unavailable"}
      </p>
    </div>
  );
}

function ModuleCard({
  number,
  title,
  description,
  children,
  disabled,
}: ModuleCardProps) {
  return (
    <section
      className={`rounded-xl border bg-white p-6 shadow-sm ${
        disabled
          ? "border-slate-200 opacity-60"
          : "border-blue-200"
      }`}
    >
      <div className="flex gap-4">
        <div className="flex h-12 w-12 shrink-0 items-center justify-center rounded-lg bg-[#17365D] font-bold text-white">
          {number}
        </div>

        <div className="min-w-0 flex-1">
          <div className="flex flex-wrap items-center justify-between gap-3">
            <h3 className="text-xl font-bold text-slate-800">
              {title}
            </h3>

            <span
              className={`rounded-full px-3 py-1 text-xs font-bold ${
                disabled
                  ? "bg-slate-100 text-slate-500"
                  : "bg-blue-100 text-blue-700"
              }`}
            >
              {disabled
                ? "SELECT GPID"
                : "GPID CONNECTED"}
            </span>
          </div>

          <p className="mt-2 text-sm leading-6 text-slate-600">
            {description}
          </p>

          {!disabled && (
            <div className="mt-5">
              {children}
            </div>
          )}
        </div>
      </div>
    </section>
  );
}



function RemarksBox({
  label,
  placeholder,
}: {
  label: string;
  placeholder: string;
}) {
  return (
    <div>
      <label className="mb-2 block text-sm font-semibold text-slate-700">
        {label}
      </label>

      <textarea
        rows={4}
        placeholder={placeholder}
        className="w-full rounded-lg border border-slate-300 bg-white px-4 py-3 text-sm text-slate-800 outline-none focus:border-[#17365D] focus:ring-1 focus:ring-[#17365D]"
      />
    </div>
  );
}

function VolunteerCheck() {
  const [available, setAvailable] =
    useState<"YES" | "NO" | null>(null);
  const [count, setCount] = useState(1);

  return (
    <div className="space-y-4">
      <div className="rounded-xl border border-slate-200 bg-slate-50 p-4">
        <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
          <p className="font-semibold text-slate-800">
            Volunteers Available
          </p>

          <div className="flex gap-3">
            <button
              type="button"
              onClick={() => setAvailable("YES")}
              className={`rounded-lg border px-5 py-2 text-sm font-bold ${
                available === "YES"
                  ? "border-emerald-600 bg-emerald-600 text-white"
                  : "border-emerald-300 bg-white text-emerald-700"
              }`}
            >
              YES
            </button>

            <button
              type="button"
              onClick={() => setAvailable("NO")}
              className={`rounded-lg border px-5 py-2 text-sm font-bold ${
                available === "NO"
                  ? "border-red-600 bg-red-600 text-white"
                  : "border-red-300 bg-white text-red-700"
              }`}
            >
              NO
            </button>
          </div>
        </div>
      </div>

      {available === "YES" && (
        <>
          <div>
            <label className="mb-2 block text-sm font-semibold text-slate-700">
              Number of Volunteers
            </label>

            <select
              value={count}
              onChange={(event) =>
                setCount(Number(event.target.value))
              }
              className="w-full rounded-lg border border-slate-300 bg-white px-4 py-3 text-sm text-slate-800 outline-none focus:border-[#17365D] focus:ring-1 focus:ring-[#17365D]"
            >
              {Array.from({ length: 8 }, (_, index) => index + 1).map(
                (number) => (
                  <option key={number} value={number}>
                    {number}
                  </option>
                ),
              )}
            </select>
          </div>

          <div className="grid gap-3 md:grid-cols-2">
            {Array.from({ length: count }, (_, index) => (
              <div key={index}>
                <label className="mb-2 block text-sm font-semibold text-slate-700">
                  Volunteer {index + 1} Name
                </label>

                <input
                  type="text"
                  placeholder={`Enter Volunteer ${index + 1} name`}
                  className="w-full rounded-lg border border-slate-300 bg-white px-4 py-3 text-sm text-slate-800 outline-none focus:border-[#17365D] focus:ring-1 focus:ring-[#17365D]"
                />
              </div>
            ))}
          </div>

          <RemarksBox
            label="Volunteer Remarks"
            placeholder="Enter any additional volunteer remarks..."
          />
        </>
      )}

      {available === "NO" && (
        <RemarksBox
          label="Action Taken"
          placeholder="Enter action taken when volunteers were unavailable..."
        />
      )}
    </div>
  );
}


function YesNoCheck({
  label,
}: {
  label: string;
}) {
  const [value, setValue] =
    useState<"YES" | "NO" | null>(null);

  return (
    <div className="rounded-xl border border-slate-200 bg-slate-50 p-4">
      <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
        <p className="font-semibold text-slate-800">{label}</p>

        <div className="flex gap-3">
          <button
            type="button"
            onClick={() => setValue("YES")}
            className={`rounded-lg border px-5 py-2 text-sm font-bold ${
              value === "YES"
                ? "border-emerald-600 bg-emerald-600 text-white"
                : "border-emerald-300 bg-white text-emerald-700"
            }`}
          >
            YES
          </button>

          <button
            type="button"
            onClick={() => setValue("NO")}
            className={`rounded-lg border px-5 py-2 text-sm font-bold ${
              value === "NO"
                ? "border-red-600 bg-red-600 text-white"
                : "border-red-300 bg-white text-red-700"
            }`}
          >
            NO
          </button>
        </div>
      </div>

      {value === "NO" && (
        <div className="mt-4">
          <label className="mb-2 block text-xs font-semibold uppercase tracking-wide text-red-700">
            Remarks / Action Taken
          </label>
          <textarea
            rows={3}
            placeholder={`Enter remarks / action taken for ${label}...`}
            className="w-full rounded-lg border border-red-200 bg-white px-4 py-3 text-sm outline-none focus:border-red-500"
          />
        </div>
      )}
    </div>
  );
}
