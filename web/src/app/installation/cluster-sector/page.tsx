"use client";

import { useRouter } from "next/navigation";

type DisplayValueProps = {
  label: string;
  value?: string | null;
};

export default function ClusterSectorInstallationPage() {
  const router = useRouter();

  /*
   * Stage-2 API / authoritative deployment master integration
   * is intentionally pending.
   *
   * IMPORTANT:
   * Sector and Cluster information must come only from genuine
   * authoritative master / deployment data.
   *
   * Never fabricate Sector, Cluster, officer or mobile details.
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
              Cluster & Sector Based Information
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
        {/* DATA STATUS */}

        <section className="mb-6 rounded-xl border border-amber-200 bg-amber-50 p-5">
          <div className="flex flex-wrap items-start justify-between gap-3">
            <div>
              <h2 className="font-bold text-amber-900">
                Authoritative Deployment Data Awaiting Integration
              </h2>

              <p className="mt-2 max-w-4xl text-sm leading-6 text-amber-800">
                Sector and Cluster information must be populated only from
                genuine authoritative deployment or hierarchy master data.
                Where such information is not available, this Web interface
                will clearly display Data unavailable.
              </p>
            </div>

            <span className="rounded-full bg-amber-200 px-3 py-1 text-xs font-bold text-amber-900">
              DATA INTEGRATION PENDING
            </span>
          </div>
        </section>

        {/* GPID */}

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

            <span className="rounded-full bg-slate-100 px-3 py-1 text-xs font-bold text-slate-600">
              DEPLOYMENT DATA UNAVAILABLE
            </span>
          </div>
        </section>

        {/* HIERARCHY */}

        <section className="mb-6 rounded-xl border border-slate-200 bg-white p-6">
          <div className="mb-5">
            <p className="text-xs font-bold uppercase tracking-wider text-slate-400">
              Organisational Hierarchy
            </p>

            <h2 className="mt-1 text-lg font-bold text-slate-800">
              GPID Jurisdiction
            </h2>

            <p className="mt-1 text-sm leading-6 text-slate-500">
              Hierarchy information is displayed from the authoritative
              organisational/location master and remains read-only.
            </p>
          </div>

          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
            <DisplayValue label="Commissionerate" />
            <DisplayValue label="Range" />
            <DisplayValue label="Zone" />
            <DisplayValue label="Division" />
            <DisplayValue label="Police Station" />
            <DisplayValue label="Sector" />
            <DisplayValue label="Cluster" />
          </div>
        </section>

        {/* SECTOR */}

        <section className="mb-6 rounded-xl border border-blue-200 bg-white p-6">
          <div className="mb-5 flex flex-wrap items-start justify-between gap-3">
            <div>
              <p className="text-xs font-bold uppercase tracking-wider text-blue-600">
                Deployment Level
              </p>

              <h2 className="mt-1 text-lg font-bold text-slate-800">
                Sector Information
              </h2>

              <p className="mt-1 text-sm text-slate-500">
                Read-only authoritative deployment information
              </p>
            </div>

            <ReadOnlyBadge />
          </div>

          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            <DisplayValue label="Sector Number / Name" />
            <DisplayValue label="Police Station" />
            <DisplayValue label="Sector Deployment Status" />
          </div>

          <div className="mt-5 border-t border-slate-200 pt-5">
            <h3 className="font-bold text-slate-800">
              Sector In-Charge Officer
            </h3>

            <div className="mt-4 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
              <DisplayValue label="Officer Name" />
              <DisplayValue label="Rank" />
              <DisplayValue label="Unit" />
              <DisplayValue label="Mobile Number" />
            </div>
          </div>
        </section>

        {/* CLUSTER */}

        <section className="mb-6 rounded-xl border border-indigo-200 bg-white p-6">
          <div className="mb-5 flex flex-wrap items-start justify-between gap-3">
            <div>
              <p className="text-xs font-bold uppercase tracking-wider text-indigo-600">
                Deployment Level
              </p>

              <h2 className="mt-1 text-lg font-bold text-slate-800">
                Cluster Information
              </h2>

              <p className="mt-1 text-sm text-slate-500">
                Displayed only where genuine Cluster master data exists
              </p>
            </div>

            <ReadOnlyBadge />
          </div>

          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            <DisplayValue label="Cluster Number / Name" />
            <DisplayValue label="Sector" />
            <DisplayValue label="Cluster Deployment Status" />
          </div>

          <div className="mt-5 border-t border-slate-200 pt-5">
            <h3 className="font-bold text-slate-800">
              Cluster In-Charge Officer
            </h3>

            <div className="mt-4 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
              <DisplayValue label="Officer Name" />
              <DisplayValue label="Rank" />
              <DisplayValue label="Unit" />
              <DisplayValue label="Mobile Number" />
            </div>
          </div>
        </section>

        {/* HIERARCHY FLOW */}

        <section className="mb-6 rounded-xl border border-blue-200 bg-blue-50 p-6">
          <p className="text-xs font-bold uppercase tracking-wider text-blue-700">
            Hierarchy Relationship
          </p>

          <h2 className="mt-1 text-lg font-bold text-slate-800">
            Organisational / Location Mapping
          </h2>

          <div className="mt-5 rounded-xl border border-blue-200 bg-white p-5">
            <p className="text-center text-sm font-bold leading-7 text-[#17365D]">
              Commissionerate → Range → Zone → Division → Police Station
              → Sector → Cluster
            </p>
          </div>

          <p className="mt-4 text-sm leading-6 text-slate-600">
            Sector and Cluster are extensions below Police Station only where
            genuine authoritative data exists. Their absence must not be
            replaced with assumed or automatically generated values.
          </p>
        </section>

        {/* SUPERVISORY INFORMATION */}

        <section className="mb-6 rounded-xl border border-slate-200 bg-white p-6">
          <div className="mb-5">
            <p className="text-xs font-bold uppercase tracking-wider text-slate-400">
              Supervisory Context
            </p>

            <h2 className="mt-1 text-lg font-bold text-slate-800">
              Deployment Visibility
            </h2>
          </div>

          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
            <DisplayValue label="GPID Installation Status" />
            <DisplayValue label="Sector Assigned" />
            <DisplayValue label="Cluster Assigned" />
            <DisplayValue label="Last Updated" />
          </div>
        </section>

        {/* IMPORTANT NOTE */}

        <section className="rounded-xl border border-slate-300 bg-slate-50 p-5">
          <h2 className="font-bold text-slate-800">
            Master Data Rule
          </h2>

          <p className="mt-2 text-sm leading-6 text-slate-600">
            This page must not provide ordinary Web data-entry controls for
            creating Sector or Cluster assignments. It is a monitoring view of
            authoritative deployment information. Any future integration must
            preserve the official hierarchy and role-based jurisdiction.
          </p>
        </section>
      </div>
    </main>
  );
}

function DisplayValue({ label, value }: DisplayValueProps) {
  return (
    <div className="rounded-lg border border-slate-200 bg-slate-50 p-4">
      <p className="text-xs font-semibold text-slate-500">{label}</p>

      <p className="mt-1 font-semibold text-slate-700">
        {value || "Data unavailable"}
      </p>
    </div>
  );
}

function ReadOnlyBadge() {
  return (
    <span className="rounded-full bg-blue-100 px-3 py-1 text-xs font-bold text-blue-700">
      READ ONLY
    </span>
  );
}