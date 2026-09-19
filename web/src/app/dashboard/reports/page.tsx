"use client";

import { useMemo, useState } from "react";
import { useRouter } from "next/navigation";

type StageDefinition = {
  number: number;
  id: string;
  name: string;
  shortName: string;
  description: string;
  route: string | null;
  operational: boolean;
};

const stages: StageDefinition[] = [
  {
    number: 1,
    id: "pre-installation",
    name: "Pre-Installation Inspection",
    shortName: "Pre-Installation",
    description:
      "Inspection and verification of the Ganesh Mandap before installation.",
    route: "/pre-installation",
    operational: true,
  },
  {
    number: 2,
    id: "installation",
    name: "Installation Inspection",
    shortName: "Installation",
    description:
      "Inspection and verification after installation of the idol and Mandap setup.",
    route: "/installation",
    operational: true,
  },
  {
    number: 3,
    id: "during-festivity",
    name: "During Festivity Inspection",
    shortName: "During Festivity",
    description:
      "Formal Stage-3 inspection / verification during the festival period. Daily Visitings are maintained separately.",
    route: "/festivity",
    operational: true,
  },
  {
    number: 4,
    id: "immersion",
    name: "Immersion Inspection",
    shortName: "Immersion",
    description:
      "Inspection and verification related to procession, movement and immersion.",
    route: null,
    operational: false,
  },
  {
    number: 5,
    id: "post-immersion",
    name: "Post-Immersion Inspection",
    shortName: "Post-Immersion",
    description:
      "Final inspection and verification after completion of immersion activities.",
    route: null,
    operational: false,
  },
];

export default function VerificationStagesPage() {
  const router = useRouter();

  const [gpid, setGpid] =
    useState("");

  const [
    selectedStageId,
    setSelectedStageId,
  ] = useState(
    "pre-installation",
  );

  const selectedStage =
    useMemo(
      () =>
        stages.find(
          (stage) =>
            stage.id ===
            selectedStageId,
        ) ?? stages[0],
      [selectedStageId],
    );

  const normalizedGpid =
    gpid.trim().toUpperCase();

  const openStage = (
    stage: StageDefinition,
  ) => {
    setSelectedStageId(
      stage.id,
    );

    if (!stage.operational) {
      return;
    }

    if (
      stage.id ===
        "pre-installation" &&
      normalizedGpid
    ) {
      router.push(
        `/pre-installation/${encodeURIComponent(
          normalizedGpid,
        )}`,
      );

      return;
    }

    if (stage.route) {
      router.push(
        stage.route,
      );
    }
  };

  return (
    <main className="min-h-screen bg-slate-100">
      <div className="mx-auto max-w-7xl px-4 py-6 sm:px-6 lg:px-8">
        <div className="mb-6">
          <p className="text-xs font-bold uppercase tracking-wider text-slate-400">
            Ganesh Bandobust 2026
          </p>

          <h1 className="mt-1 text-2xl font-bold text-slate-800">
            5-Stage Inspection /
            Verification
          </h1>

          <p className="mt-2 max-w-4xl text-sm leading-6 text-slate-600">
            The five formal festival
            stages are maintained as
            Inspection / Verification.
            They are separate from
            Daily Visitings.
          </p>
        </div>

        <section className="mb-7 rounded-xl border border-blue-200 bg-blue-50 p-5">
          <h2 className="text-base font-bold text-blue-900">
            Direct GPID Inspection
          </h2>

          <p className="mt-2 text-sm leading-6 text-blue-800">
            An authenticated officer
            may directly identify a
            GPID and perform the
            applicable stage
            inspection using his or
            her own login credentials.
            Selection through Range →
            Zone → Division → Police
            Station is not compulsory
            before conducting an
            inspection.
          </p>

          <p className="mt-2 text-xs leading-5 text-blue-700">
            Jurisdiction hierarchy is
            retained separately for
            administrative monitoring,
            supervision and reporting.
          </p>
        </section>

        <section className="mb-7 rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
          <div className="mb-4">
            <p className="text-xs font-bold uppercase tracking-wider text-slate-400">
              GPID
            </p>

            <h2 className="mt-1 text-lg font-bold text-slate-800">
              Search / Enter GPID
            </h2>

            <p className="mt-1 text-sm text-slate-500">
              Enter the GPID before
              opening the required
              inspection stage.
            </p>
          </div>

          <div className="flex max-w-2xl flex-col gap-3 sm:flex-row">
            <input
              type="text"
              value={gpid}
              onChange={(event) =>
                setGpid(
                  event.target.value.toUpperCase(),
                )
              }
              placeholder="Enter GPID"
              className="flex-1 rounded-lg border border-slate-300 bg-white px-4 py-3 text-sm font-semibold uppercase text-slate-800 outline-none focus:border-blue-500"
            />

            <button
              type="button"
              onClick={() => {
                if (
                  normalizedGpid
                ) {
                  router.push(
                    `/pre-installation/${encodeURIComponent(
                      normalizedGpid,
                    )}`,
                  );
                }
              }}
              disabled={
                !normalizedGpid
              }
              className="rounded-lg bg-[#17365D] px-5 py-3 text-sm font-semibold text-white hover:bg-[#234d7d] disabled:cursor-not-allowed disabled:bg-slate-300"
            >
              Open GPID
            </button>
          </div>
        </section>

        <section className="mb-7">
          <div className="mb-4">
            <p className="text-xs font-bold uppercase tracking-wider text-slate-400">
              Inspection Stages
            </p>

            <h2 className="mt-1 text-lg font-bold text-slate-800">
              Select Inspection Stage
            </h2>
          </div>

          <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-5">
            {stages.map(
              (stage) => {
                const selected =
                  selectedStageId ===
                  stage.id;

                return (
                  <button
                    key={stage.id}
                    type="button"
                    onClick={() =>
                      openStage(
                        stage,
                      )
                    }
                    className={`rounded-xl border p-5 text-left shadow-sm transition ${
                      selected
                        ? "border-blue-500 bg-blue-50 ring-1 ring-blue-500"
                        : "border-slate-200 bg-white hover:border-blue-300 hover:bg-slate-50"
                    }`}
                  >
                    <div className="mb-4 flex h-10 w-10 items-center justify-center rounded-full bg-[#17365D] text-sm font-bold text-white">
                      {
                        stage.number
                      }
                    </div>

                    <h3 className="text-base font-bold text-slate-800">
                      {
                        stage.shortName
                      }
                    </h3>

                    <p className="mt-2 text-sm leading-5 text-slate-500">
                      {
                        stage.description
                      }
                    </p>

                    <div className="mt-4">
                      <span
                        className={`inline-flex rounded-full px-2.5 py-1 text-xs font-bold ${
                          stage.operational
                            ? "bg-emerald-100 text-emerald-700"
                            : "bg-amber-100 text-amber-700"
                        }`}
                      >
                        {stage.operational
                          ? "AVAILABLE"
                          : "PENDING CONFIGURATION"}
                      </span>
                    </div>
                  </button>
                );
              },
            )}
          </div>
        </section>

        <section className="rounded-xl border border-slate-200 bg-white shadow-sm">
          <div className="border-b border-slate-200 p-5">
            <p className="text-xs font-bold uppercase tracking-wider text-slate-400">
              Selected Stage
            </p>

            <h2 className="mt-1 text-xl font-bold text-slate-800">
              {
                selectedStage.name
              }
            </h2>

            <p className="mt-2 text-sm leading-6 text-slate-600">
              {
                selectedStage.description
              }
            </p>
          </div>

          <div className="p-5">
            {selectedStage.operational ? (
              <>
                <div className="mb-5 rounded-lg border border-emerald-200 bg-emerald-50 p-4">
                  <p className="text-sm font-semibold text-emerald-900">
                    Inspection module
                    available
                  </p>

                  <p className="mt-1 text-sm leading-6 text-emerald-800">
                    The inspection
                    will be performed
                    under the
                    authenticated
                    officer&apos;s own
                    credentials.
                  </p>
                </div>

                <button
                  type="button"
                  onClick={() =>
                    openStage(
                      selectedStage,
                    )
                  }
                  className="rounded-lg bg-[#17365D] px-5 py-2.5 text-sm font-semibold text-white hover:bg-[#234d7d]"
                >
                  Open{" "}
                  {
                    selectedStage.shortName
                  }{" "}
                  Inspection
                </button>
              </>
            ) : (
              <div className="rounded-lg border border-amber-200 bg-amber-50 p-4">
                <p className="text-sm font-semibold text-amber-900">
                  Module pending
                  configuration
                </p>

                <p className="mt-1 text-sm leading-6 text-amber-800">
                  This stage remains
                  visible as part of
                  the five-stage
                  inspection
                  workflow, but its
                  operational data
                  entry module has
                  not yet been
                  configured.
                </p>
              </div>
            )}
          </div>
        </section>

        <section className="mt-7 grid gap-4 md:grid-cols-2">
          <div className="rounded-xl border border-indigo-200 bg-indigo-50 p-5">
            <h3 className="font-bold text-indigo-900">
              Inspection /
              Verification
            </h3>

            <p className="mt-2 text-sm leading-6 text-indigo-800">
              Five formal stages.
              Each inspection is
              associated with a GPID
              and the authenticated
              inspecting officer.
            </p>
          </div>

          <div className="rounded-xl border border-emerald-200 bg-emerald-50 p-5">
            <h3 className="font-bold text-emerald-900">
              Daily Visitings
            </h3>

            <p className="mt-2 text-sm leading-6 text-emerald-800">
              Repeated daily field
              visits are maintained
              separately by date,
              festival day, GPID,
              officer and
              jurisdiction.
            </p>

            <button
              type="button"
              onClick={() =>
                router.push(
                  "/dashboard/visitings",
                )
              }
              className="mt-4 rounded-lg border border-emerald-300 bg-white px-4 py-2 text-sm font-semibold text-emerald-800 hover:bg-emerald-100"
            >
              Open Visitings
            </button>
          </div>
        </section>
      </div>
    </main>
  );
}