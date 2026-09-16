"use client";

import { useRouter } from "next/navigation";

export default function ApplicationsPage() {
  const router = useRouter();

  return (
    <main className="min-h-screen bg-slate-100">
      <div className="mx-auto max-w-7xl px-4 py-6 sm:px-6 lg:px-8">
        <div className="mb-6 flex items-center justify-between">
          <div>
            <p className="text-xs font-semibold uppercase tracking-wide text-slate-500">
              Ganesh Bandobust 2026
            </p>

            <h1 className="mt-1 text-2xl font-bold text-slate-800">
              Applications
            </h1>

            <p className="mt-1 text-sm text-slate-500">
              Monitor Ganesh applications, GPIDs, applicant details,
              jurisdiction and application status.
            </p>
          </div>

          <button
            type="button"
            onClick={() => router.push("/dashboard")}
            className="rounded-lg border border-slate-300 bg-white px-4 py-2 text-sm font-semibold text-slate-700 hover:bg-slate-50"
          >
            Back to Dashboard
          </button>
        </div>

        <section className="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
          <h2 className="text-lg font-bold text-slate-800">
            Application Monitoring
          </h2>

          <p className="mt-2 text-sm leading-6 text-slate-600">
            The detailed application and GPID monitoring interface will be
            linked here from the existing live GPID data and hierarchy.
          </p>
        </section>
      </div>
    </main>
  );
}