"use client";

import { useEffect, useMemo, useState } from "react";
import { useRouter } from "next/navigation";

type FestivityCheckVisit = {
  id?: string;
  gpid?: string;
  applicationId?: string | null;

  festivalDay?: number;
  festivalDate?: string | null;

  officerEmployeeId?: string | null;
  officerName?: string | null;
  officerRank?: string | null;
  officerRole?: string | null;

  rangeName?: string | null;
  zoneName?: string | null;
  divisionName?: string | null;
  policeStationName?: string | null;
  sectorName?: string | null;

  antiDigressionResult?: unknown;
  volunteerResult?: unknown;
  lightingResult?: unknown;
  sanitationResult?: unknown;
  poojaResult?: unknown;
  soundSystemResult?: unknown;
  fireSafetyResult?: unknown;

  remarks?: string | null;
  actionTaken?: string | null;

  status?: string | null;
  hasDeficiency?: boolean;
  requiresFollowUp?: boolean;

  poojaPending?: boolean;
  soundPending?: boolean;
  fireSafetyPending?: boolean;

  latitude?: number | null;
  longitude?: number | null;
  accuracy?: number | null;

  checkSource?: string | null;

  checkStartedAt?: string | null;
  checkedAt?: string | null;
};

function text(value: unknown): string {
  if (value === null || value === undefined) {
    return "";
  }

  return String(value).trim();
}

function formatDateTime(value?: string | null): string {
  if (!value) {
    return "-";
  }

  const date = new Date(value);

  if (Number.isNaN(date.getTime())) {
    return value;
  }

  return new Intl.DateTimeFormat("en-IN", {
    timeZone: "Asia/Kolkata",
    day: "2-digit",
    month: "2-digit",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
    hour12: true,
  }).format(date);
}

export default function CheckingPage() {
  const router = useRouter();

  const [records, setRecords] =
    useState<FestivityCheckVisit[]>([]);

  const [loading, setLoading] =
    useState(true);

  const [error, setError] =
    useState("");

  const [searchText, setSearchText] =
    useState("");

  useEffect(() => {
    let active = true;

    const loadCheckingRecords = async () => {
      try {
        const response = await fetch(
          "/api/festivity-checks?limit=500",
          {
            method: "GET",
            cache: "no-store",
            credentials: "include",
          },
        );

        if (!response.ok) {
          throw new Error(
            "Unable to load checking records.",
          );
        }

        const data: unknown =
          await response.json();

        if (!Array.isArray(data)) {
          throw new Error(
            "Unexpected checking response.",
          );
        }

        if (!active) {
          return;
        }

        setRecords(
          data as FestivityCheckVisit[],
        );

        setError("");
      } catch (loadError) {
        console.error(
          "Checking dashboard error:",
          loadError,
        );

        if (!active) {
          return;
        }

        setError(
          "Unable to load Stage-3 checking data.",
        );
      } finally {
        if (active) {
          setLoading(false);
        }
      }
    };

    void loadCheckingRecords();

    const refreshTimer =
      window.setInterval(() => {
        void loadCheckingRecords();
      }, 30000);

    return () => {
      active = false;
      window.clearInterval(refreshTimer);
    };
  }, []);

  const summary =
    useMemo(() => {
      const uniqueGpids =
        new Set<string>();

      const gpidVisitCounts =
        new Map<string, number>();

      const officers =
        new Set<string>();

      let deficiencies = 0;
      let followUps = 0;
      let actionsTaken = 0;
      let poojaPending = 0;
      let soundPending = 0;
      let fireSafetyPending = 0;

      for (const record of records) {
        const gpid =
          text(record.gpid);

        if (gpid) {
          uniqueGpids.add(gpid);

          gpidVisitCounts.set(
            gpid,
            (gpidVisitCounts.get(gpid) ?? 0) + 1,
          );
        }

        const officerKey =
          text(record.officerEmployeeId) ||
          text(record.officerName);

        if (officerKey) {
          officers.add(officerKey);
        }

        if (record.hasDeficiency === true) {
          deficiencies += 1;
        }

        if (record.requiresFollowUp === true) {
          followUps += 1;
        }

        if (
          text(record.actionTaken).length > 0
        ) {
          actionsTaken += 1;
        }

        if (record.poojaPending === true) {
          poojaPending += 1;
        }

        if (record.soundPending === true) {
          soundPending += 1;
        }

        if (
          record.fireSafetyPending === true
        ) {
          fireSafetyPending += 1;
        }
      }

      const repeatedGpids =
        Array.from(
          gpidVisitCounts.values(),
        ).filter(
          (count) => count > 1,
        ).length;

      return {
        totalVisits: records.length,
        uniqueGpids: uniqueGpids.size,
        repeatedGpids,
        deficiencies,
        followUps,
        actionsTaken,
        officers: officers.size,
        poojaPending,
        soundPending,
        fireSafetyPending,
      };
    }, [records]);

  const filteredRecords =
    useMemo(() => {
      const query =
        searchText
          .trim()
          .toLowerCase();

      if (!query) {
        return records;
      }

      return records.filter(
        (record) => {
          const haystack = [
            record.gpid,
            record.officerName,
            record.officerEmployeeId,
            record.officerRank,
            record.zoneName,
            record.divisionName,
            record.policeStationName,
            record.sectorName,
            record.status,
            record.actionTaken,
          ]
            .map((value) =>
              text(value).toLowerCase(),
            )
            .join(" ");

          return haystack.includes(query);
        },
      );
    }, [
      records,
      searchText,
    ]);

  const cards = [
    {
      title: "Total Checking Visits",
      value: summary.totalVisits,
    },
    {
      title: "GPIDs Checked",
      value: summary.uniqueGpids,
    },
    {
      title: "Re-Checked GPIDs",
      value: summary.repeatedGpids,
    },
    {
      title: "Officers Involved",
      value: summary.officers,
    },
    {
      title: "Deficiencies Found",
      value: summary.deficiencies,
    },
    {
      title: "Follow-Up Required",
      value: summary.followUps,
    },
    {
      title: "Actions Taken",
      value: summary.actionsTaken,
    },
    {
      title: "Checks Without Deficiency",
      value: Math.max(
        summary.totalVisits -
          summary.deficiencies,
        0,
      ),
    },
  ];

  return (
    <main className="min-h-screen bg-slate-100">
      <div className="mx-auto max-w-7xl px-4 py-6 sm:px-6 lg:px-8">
        <div className="mb-6 flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
          <div>
            <p className="text-xs font-bold uppercase tracking-wider text-slate-400">
              Stage 3
            </p>

            <h1 className="mt-1 text-2xl font-bold text-slate-800">
              Checking Dashboard
            </h1>

            <p className="mt-1 text-sm text-slate-500">
              Live monitoring of During Festivity field checking visits.
            </p>
          </div>

          <div className="flex gap-2">
            <button
              type="button"
              onClick={() =>
                router.push("/festivity/checking")
              }
              className="rounded-lg bg-[#17365D] px-4 py-2 text-sm font-semibold text-white hover:bg-[#234d7d]"
            >
              Open Detailed Checking
            </button>

            <button
              type="button"
              onClick={() =>
                router.push("/dashboard")
              }
              className="rounded-lg border border-slate-300 bg-white px-4 py-2 text-sm font-semibold text-slate-700 hover:bg-slate-50"
            >
              Dashboard
            </button>
          </div>
        </div>

        {error && (
          <div className="mb-5 rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
            {error}
          </div>
        )}

        <section className="mb-8 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
          {cards.map((card) => (
            <div
              key={card.title}
              className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm"
            >
              <div className="text-3xl font-bold text-[#17365D]">
                {loading
                  ? "..."
                  : card.value.toLocaleString(
                      "en-IN",
                    )}
              </div>

              <p className="mt-2 text-sm text-slate-600">
                {card.title}
              </p>
            </div>
          ))}
        </section>

        <section className="mb-8">
          <div className="mb-4">
            <h2 className="text-xl font-bold text-slate-800">
              Pending Safety / Compliance Items
            </h2>

            <p className="mt-1 text-sm text-slate-500">
              Pending conditions recorded during Stage-3 visits.
            </p>
          </div>

          <div className="grid gap-4 sm:grid-cols-3">
            <div className="rounded-xl border border-amber-200 bg-white p-5 shadow-sm">
              <div className="text-3xl font-bold text-amber-700">
                {loading
                  ? "..."
                  : summary.poojaPending.toLocaleString(
                      "en-IN",
                    )}
              </div>

              <p className="mt-2 text-sm text-slate-600">
                Pooja Related Pending
              </p>
            </div>

            <div className="rounded-xl border border-amber-200 bg-white p-5 shadow-sm">
              <div className="text-3xl font-bold text-amber-700">
                {loading
                  ? "..."
                  : summary.soundPending.toLocaleString(
                      "en-IN",
                    )}
              </div>

              <p className="mt-2 text-sm text-slate-600">
                Sound System Pending
              </p>
            </div>

            <div className="rounded-xl border border-amber-200 bg-white p-5 shadow-sm">
              <div className="text-3xl font-bold text-amber-700">
                {loading
                  ? "..."
                  : summary.fireSafetyPending.toLocaleString(
                      "en-IN",
                    )}
              </div>

              <p className="mt-2 text-sm text-slate-600">
                Fire Safety Pending
              </p>
            </div>
          </div>
        </section>

        <section className="rounded-xl border border-slate-200 bg-white shadow-sm">
          <div className="border-b border-slate-200 p-5">
            <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
              <div>
                <h2 className="text-xl font-bold text-slate-800">
                  Recent Checking Activity
                </h2>

                <p className="mt-1 text-sm text-slate-500">
                  Most recent Stage-3 checking visits within your authorized jurisdiction.
                </p>
              </div>

              <input
                type="text"
                value={searchText}
                onChange={(event) =>
                  setSearchText(
                    event.target.value,
                  )
                }
                placeholder="Search GPID, officer, PS..."
                className="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm outline-none focus:border-blue-500 md:w-80"
              />
            </div>
          </div>

          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-slate-200">
              <thead className="bg-slate-50">
                <tr>
                  <th className="px-4 py-3 text-left text-xs font-bold uppercase tracking-wide text-slate-500">
                    Checked At
                  </th>

                  <th className="px-4 py-3 text-left text-xs font-bold uppercase tracking-wide text-slate-500">
                    GPID
                  </th>

                  <th className="px-4 py-3 text-left text-xs font-bold uppercase tracking-wide text-slate-500">
                    Day
                  </th>

                  <th className="px-4 py-3 text-left text-xs font-bold uppercase tracking-wide text-slate-500">
                    Officer
                  </th>

                  <th className="px-4 py-3 text-left text-xs font-bold uppercase tracking-wide text-slate-500">
                    Police Station
                  </th>

                  <th className="px-4 py-3 text-left text-xs font-bold uppercase tracking-wide text-slate-500">
                    Deficiency
                  </th>

                  <th className="px-4 py-3 text-left text-xs font-bold uppercase tracking-wide text-slate-500">
                    Follow-Up
                  </th>

                  <th className="px-4 py-3 text-left text-xs font-bold uppercase tracking-wide text-slate-500">
                    Action Taken
                  </th>
                </tr>
              </thead>

              <tbody className="divide-y divide-slate-100">
                {!loading &&
                  filteredRecords
                    .slice(0, 100)
                    .map(
                      (
                        record,
                        index,
                      ) => (
                        <tr
                          key={
                            record.id ??
                            `${record.gpid}-${record.checkedAt}-${index}`
                          }
                          className="hover:bg-slate-50"
                        >
                          <td className="whitespace-nowrap px-4 py-3 text-sm text-slate-600">
                            {formatDateTime(
                              record.checkedAt,
                            )}
                          </td>

                          <td className="whitespace-nowrap px-4 py-3 text-sm font-bold text-slate-800">
                            {text(
                              record.gpid,
                            ) || "-"}
                          </td>

                          <td className="whitespace-nowrap px-4 py-3 text-sm text-slate-600">
                            {record.festivalDay ??
                              "-"}
                          </td>

                          <td className="px-4 py-3 text-sm text-slate-700">
                            <div className="font-semibold">
                              {text(
                                record.officerName,
                              ) || "-"}
                            </div>

                            <div className="text-xs text-slate-500">
                              {[
                                text(
                                  record.officerRank,
                                ),
                                text(
                                  record.officerEmployeeId,
                                ),
                              ]
                                .filter(
                                  Boolean,
                                )
                                .join(
                                  " · ",
                                )}
                            </div>
                          </td>

                          <td className="px-4 py-3 text-sm text-slate-600">
                            {text(
                              record.policeStationName,
                            ) || "-"}
                          </td>

                          <td className="whitespace-nowrap px-4 py-3">
                            <span
                              className={`inline-flex rounded-full px-2.5 py-1 text-xs font-bold ${
                                record.hasDeficiency
                                  ? "bg-red-100 text-red-700"
                                  : "bg-emerald-100 text-emerald-700"
                              }`}
                            >
                              {record.hasDeficiency
                                ? "YES"
                                : "NO"}
                            </span>
                          </td>

                          <td className="whitespace-nowrap px-4 py-3">
                            <span
                              className={`inline-flex rounded-full px-2.5 py-1 text-xs font-bold ${
                                record.requiresFollowUp
                                  ? "bg-amber-100 text-amber-700"
                                  : "bg-slate-100 text-slate-600"
                              }`}
                            >
                              {record.requiresFollowUp
                                ? "REQUIRED"
                                : "NO"}
                            </span>
                          </td>

                          <td className="max-w-xs px-4 py-3 text-sm text-slate-600">
                            {text(
                              record.actionTaken,
                            ) || "-"}
                          </td>
                        </tr>
                      ),
                    )}

                {!loading &&
                  filteredRecords.length ===
                    0 && (
                    <tr>
                      <td
                        colSpan={8}
                        className="px-4 py-10 text-center text-sm text-slate-500"
                      >
                        No checking records found.
                      </td>
                    </tr>
                  )}

                {loading && (
                  <tr>
                    <td
                      colSpan={8}
                      className="px-4 py-10 text-center text-sm text-slate-500"
                    >
                      Loading checking records...
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>

          <div className="border-t border-slate-200 px-5 py-3 text-xs text-slate-500">
            Showing up to 100 recent records. Data refreshes automatically every 30 seconds.
          </div>
        </section>
      </div>
    </main>
  );
}