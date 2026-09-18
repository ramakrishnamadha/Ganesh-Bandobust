"use client";

import {
  useEffect,
  useMemo,
  useState,
} from "react";

import {
  getRanges,
  getZones,
  getDivisions,
  getPoliceStations,
  getHierarchyForPoliceStation,
} from "@/lib/hierarchy/ganeshHierarchy";

type FestivityCheckVisit = {
  id?: string;

  gpid?: string | null;
  applicationId?: string | null;

  festivalDay?:
    | string
    | number
    | null;

  festivalDate?:
    | string
    | null;

  officerId?:
    | string
    | null;

  officerName?:
    | string
    | null;

  officerRank?:
    | string
    | null;

  officerRole?:
    | string
    | null;

  commissionerateCode?:
    | string
    | null;

  commissionerateName?:
    | string
    | null;

  rangeCode?:
    | string
    | null;

  rangeName?:
    | string
    | null;

  zoneCode?:
    | string
    | null;

  zoneName?:
    | string
    | null;

  divisionCode?:
    | string
    | null;

  divisionName?:
    | string
    | null;

  policeStationCode?:
    | string
    | null;

  policeStationName?:
    | string
    | null;

  sectorCode?:
    | string
    | null;

  sectorName?:
    | string
    | null;

  clusterCode?:
    | string
    | null;

  clusterName?:
    | string
    | null;

  remarks?:
    | string
    | null;

  actionTaken?:
    | string
    | null;

  status?:
    | string
    | null;

  hasDeficiency?:
    | boolean
    | null;

  requiresFollowUp?:
    | boolean
    | null;

  poojaPending?:
    | boolean
    | null;

  soundPending?:
    | boolean
    | null;

  fireSafetyPending?:
    | boolean
    | null;

  latitude?:
    | number
    | string
    | null;

  longitude?:
    | number
    | string
    | null;

  checkSource?:
    | string
    | null;

  sessionId?:
    | string
    | null;

  checkStartedAt?:
    | string
    | null;

  checkedAt?:
    | string
    | null;

  createdAt?:
    | string
    | null;

  updatedAt?:
    | string
    | null;
};

type ResolvedJurisdiction = {
  rangeName: string;
  zoneName: string;
  divisionName: string;
  policeStationName: string;
};

type FestivalDayDefinition = {
  day: number;
  dayValue: string;
  dateValue: string;
  displayDate: string;
};

/*
 * GANESH FESTIVAL 2026
 *
 * Day 1 = 14 September 2026
 * Day 11 = 24 September 2026
 *
 * These values are intentionally fixed so that all
 * 11 festival days remain available even where no
 * Visitings have yet been recorded.
 */
const FESTIVAL_DAYS: FestivalDayDefinition[] = [
  {
    day: 1,
    dayValue: "1",
    dateValue: "2026-09-14",
    displayDate: "14-09-2026",
  },
  {
    day: 2,
    dayValue: "2",
    dateValue: "2026-09-15",
    displayDate: "15-09-2026",
  },
  {
    day: 3,
    dayValue: "3",
    dateValue: "2026-09-16",
    displayDate: "16-09-2026",
  },
  {
    day: 4,
    dayValue: "4",
    dateValue: "2026-09-17",
    displayDate: "17-09-2026",
  },
  {
    day: 5,
    dayValue: "5",
    dateValue: "2026-09-18",
    displayDate: "18-09-2026",
  },
  {
    day: 6,
    dayValue: "6",
    dateValue: "2026-09-19",
    displayDate: "19-09-2026",
  },
  {
    day: 7,
    dayValue: "7",
    dateValue: "2026-09-20",
    displayDate: "20-09-2026",
  },
  {
    day: 8,
    dayValue: "8",
    dateValue: "2026-09-21",
    displayDate: "21-09-2026",
  },
  {
    day: 9,
    dayValue: "9",
    dateValue: "2026-09-22",
    displayDate: "22-09-2026",
  },
  {
    day: 10,
    dayValue: "10",
    dateValue: "2026-09-23",
    displayDate: "23-09-2026",
  },
  {
    day: 11,
    dayValue: "11",
    dateValue: "2026-09-24",
    displayDate: "24-09-2026",
  },
];

function text(
  value: unknown,
): string {
  if (
    value === null ||
    value === undefined
  ) {
    return "";
  }

  return String(
    value,
  ).trim();
}

function normalize(
  value: unknown,
): string {
  return text(
    value,
  )
    .toLowerCase()
    .replace(
      /\s+/g,
      " ",
    );
}

function boolValue(
  value: unknown,
): boolean {
  return (
    value === true ||
    value ===
      "true" ||
    value === 1 ||
    value === "1"
  );
}

function normalizeFestivalDay(
  value: unknown,
): string {
  const raw =
    text(value);

  if (!raw) {
    return "";
  }

  /*
   * Allows values such as:
   * 1
   * "1"
   * "Day 1"
   * "DAY 1"
   */
  const match =
    raw.match(
      /\d+/,
    );

  if (!match) {
    return raw;
  }

  return String(
    Number(
      match[0],
    ),
  );
}

function festivalDateForDay(
  dayValue: string,
): string {
  if (!dayValue) {
    return "";
  }

  return (
    FESTIVAL_DAYS.find(
      (item) =>
        item.dayValue ===
        dayValue,
    )?.dateValue ?? ""
  );
}

function festivalDayForDate(
  dateValue: string,
): string {
  if (!dateValue) {
    return "";
  }

  return (
    FESTIVAL_DAYS.find(
      (item) =>
        item.dateValue ===
        dateValue,
    )?.dayValue ?? ""
  );
}

function formatDateTime(
  value: unknown,
): string {
  const raw =
    text(value);

  if (!raw) {
    return "-";
  }

  const date =
    new Date(raw);

  if (
    Number.isNaN(
      date.getTime(),
    )
  ) {
    return raw;
  }

  return new Intl.DateTimeFormat(
    "en-IN",
    {
      timeZone:
        "Asia/Kolkata",

      day: "2-digit",
      month: "2-digit",
      year: "numeric",

      hour: "2-digit",
      minute: "2-digit",

      hour12: true,
    },
  ).format(date);
}

function formatDate(
  value: unknown,
): string {
  const raw =
    text(value);

  if (!raw) {
    return "-";
  }

  /*
   * Avoid date shifting when API already supplies
   * a YYYY-MM-DD festival date.
   */
  const directMatch =
    raw.match(
      /^(\d{4})-(\d{2})-(\d{2})/,
    );

  if (directMatch) {
    return `${directMatch[3]}-${directMatch[2]}-${directMatch[1]}`;
  }

  const date =
    new Date(raw);

  if (
    Number.isNaN(
      date.getTime(),
    )
  ) {
    return raw;
  }

  return new Intl.DateTimeFormat(
    "en-IN",
    {
      timeZone:
        "Asia/Kolkata",

      day: "2-digit",
      month: "2-digit",
      year: "numeric",
    },
  ).format(date);
}

function dateKeyInIndia(
  value: unknown,
): string {
  const raw =
    text(value);

  if (!raw) {
    return "";
  }

  /*
   * If value is already stored as YYYY-MM-DD,
   * preserve that exact calendar date.
   */
  const directMatch =
    raw.match(
      /^(\d{4})-(\d{2})-(\d{2})/,
    );

  if (
    directMatch &&
    !raw.includes("T")
  ) {
    return `${directMatch[1]}-${directMatch[2]}-${directMatch[3]}`;
  }

  const date =
    new Date(raw);

  if (
    Number.isNaN(
      date.getTime(),
    )
  ) {
    return raw.slice(
      0,
      10,
    );
  }

  const parts =
    new Intl.DateTimeFormat(
      "en-CA",
      {
        timeZone:
          "Asia/Kolkata",

        year:
          "numeric",

        month:
          "2-digit",

        day:
          "2-digit",
      },
    ).formatToParts(
      date,
    );

  const year =
    parts.find(
      (part) =>
        part.type ===
        "year",
    )?.value;

  const month =
    parts.find(
      (part) =>
        part.type ===
        "month",
    )?.value;

  const day =
    parts.find(
      (part) =>
        part.type ===
        "day",
    )?.value;

  if (
    !year ||
    !month ||
    !day
  ) {
    return "";
  }

  return `${year}-${month}-${day}`;
}

/*
 * Daily Visit Date:
 *
 * Preference:
 * 1. actual checkedAt
 * 2. createdAt
 * 3. saved festivalDate
 */
function visitDateKey(
  record:
    FestivityCheckVisit,
): string {
  const raw =
    text(
      record.checkedAt,
    ) ||
    text(
      record.createdAt,
    ) ||
    text(
      record.festivalDate,
    );

  return dateKeyInIndia(
    raw,
  );
}

function resolveJurisdiction(
  record:
    FestivityCheckVisit,
): ResolvedJurisdiction {
  const savedPoliceStation =
    text(
      record.policeStationName,
    );

  const master =
    savedPoliceStation
      ? getHierarchyForPoliceStation(
          savedPoliceStation,
        )
      : null;

  if (master) {
    return {
      rangeName:
        text(
          master.range,
        ),

      zoneName:
        text(
          master.zone,
        ),

      divisionName:
        text(
          master.division,
        ),

      policeStationName:
        text(
          master.policeStation,
        ),
    };
  }

  return {
    rangeName:
      text(
        record.rangeName,
      ),

    zoneName:
      text(
        record.zoneName,
      ),

    divisionName:
      text(
        record.divisionName,
      ),

    policeStationName:
      savedPoliceStation,
  };
}

export default function VisitingsPage() {
  const [
    visits,
    setVisits,
  ] = useState<
    FestivityCheckVisit[]
  >([]);

  const [
    loading,
    setLoading,
  ] =
    useState(true);

  const [
    refreshing,
    setRefreshing,
  ] =
    useState(false);

  const [
    error,
    setError,
  ] =
    useState("");

  const [
    lastUpdated,
    setLastUpdated,
  ] = useState<
    Date | null
  >(null);

  const [
    selectedRange,
    setSelectedRange,
  ] =
    useState("");

  const [
    selectedZone,
    setSelectedZone,
  ] =
    useState("");

  const [
    selectedDivision,
    setSelectedDivision,
  ] =
    useState("");

  const [
    selectedPoliceStation,
    setSelectedPoliceStation,
  ] =
    useState("");

  const [
    selectedGpid,
    setSelectedGpid,
  ] =
    useState("");

  const [
    selectedFestivalDay,
    setSelectedFestivalDay,
  ] =
    useState("");

  const [
    selectedVisitDate,
    setSelectedVisitDate,
  ] =
    useState("");

  const [
    searchText,
    setSearchText,
  ] =
    useState("");

  const loadVisits =
    async (
      initial = false,
    ) => {
      if (initial) {
        setLoading(
          true,
        );
      } else {
        setRefreshing(
          true,
        );
      }

      try {
        const response =
          await fetch(
            "/api/festivity-checks?limit=500",
            {
              method:
                "GET",

              cache:
                "no-store",

              credentials:
                "include",
            },
          );

        const body:
          unknown =
          await response
            .json()
            .catch(
              () => null,
            );

        if (
          !response.ok
        ) {
          throw new Error(
            "Unable to load Visitings records.",
          );
        }

        let records:
          FestivityCheckVisit[] =
          [];

        if (
          Array.isArray(
            body,
          )
        ) {
          records =
            body as FestivityCheckVisit[];
        } else if (
          typeof body ===
            "object" &&
          body !== null &&
          "visits" in body &&
          Array.isArray(
            (
              body as {
                visits?: unknown;
              }
            ).visits,
          )
        ) {
          records =
            (
              body as {
                visits:
                  FestivityCheckVisit[];
              }
            ).visits;
        } else if (
          typeof body ===
            "object" &&
          body !== null &&
          "data" in body &&
          Array.isArray(
            (
              body as {
                data?: unknown;
              }
            ).data,
          )
        ) {
          records =
            (
              body as {
                data:
                  FestivityCheckVisit[];
              }
            ).data;
        }

        setVisits(
          records,
        );

        setLastUpdated(
          new Date(),
        );

        setError("");
      } catch (
        loadError
      ) {
        console.error(
          "Visitings load error:",
          loadError,
        );

        setError(
          loadError instanceof
            Error
            ? loadError.message
            : "Unable to load Visitings.",
        );
      } finally {
        setLoading(
          false,
        );

        setRefreshing(
          false,
        );
      }
    };

  useEffect(() => {
    void loadVisits(
      true,
    );

    const timer =
      window.setInterval(
        () => {
          void loadVisits(
            false,
          );
        },
        30000,
      );

    return () => {
      window.clearInterval(
        timer,
      );
    };
  }, []);

  const rangeOptions =
    useMemo(
      () =>
        getRanges(),
      [],
    );

  const zoneOptions =
    useMemo(
      () =>
        selectedRange
          ? getZones(
              selectedRange,
            )
          : [],
      [
        selectedRange,
      ],
    );

  const divisionOptions =
    useMemo(
      () =>
        selectedRange &&
        selectedZone
          ? getDivisions(
              selectedRange,
              selectedZone,
            )
          : [],
      [
        selectedRange,
        selectedZone,
      ],
    );

  const policeStationOptions =
    useMemo(
      () =>
        selectedRange &&
        selectedZone &&
        selectedDivision
          ? getPoliceStations(
              selectedRange,
              selectedZone,
              selectedDivision,
            )
          : [],
      [
        selectedRange,
        selectedZone,
        selectedDivision,
      ],
    );

  const gpidOptions =
    useMemo(() => {
      if (
        !selectedRange ||
        !selectedZone ||
        !selectedDivision ||
        !selectedPoliceStation
      ) {
        return [];
      }

      const values =
        new Set<string>();

      for (
        const visit of
        visits
      ) {
        const jurisdiction =
          resolveJurisdiction(
            visit,
          );

        if (
          jurisdiction.rangeName !==
            selectedRange
        ) {
          continue;
        }

        if (
          jurisdiction.zoneName !==
            selectedZone
        ) {
          continue;
        }

        if (
          jurisdiction.divisionName !==
            selectedDivision
        ) {
          continue;
        }

        if (
          jurisdiction.policeStationName !==
            selectedPoliceStation
        ) {
          continue;
        }

        const gpid =
          text(
            visit.gpid,
          );

        if (gpid) {
          values.add(
            gpid,
          );
        }
      }

      return Array.from(
        values,
      ).sort(
        (
          left,
          right,
        ) =>
          left.localeCompare(
            right,
            undefined,
            {
              numeric:
                true,
            },
          ),
      );
    }, [
      visits,
      selectedRange,
      selectedZone,
      selectedDivision,
      selectedPoliceStation,
    ]);

  /*
   * DAY -> DATE
   *
   * Selecting a Festival Day automatically selects
   * the corresponding calendar date.
   */
  const handleFestivalDayChange =
    (
      dayValue: string,
    ) => {
      setSelectedFestivalDay(
        dayValue,
      );

      if (!dayValue) {
        setSelectedVisitDate(
          "",
        );

        return;
      }

      setSelectedVisitDate(
        festivalDateForDay(
          dayValue,
        ),
      );
    };

  /*
   * DATE -> DAY
   *
   * Selecting a Festival Date automatically selects
   * the matching Festival Day.
   *
   * Dates outside the configured 11-day festival
   * period clear the Festival Day selection.
   */
  const handleVisitDateChange =
    (
      dateValue: string,
    ) => {
      setSelectedVisitDate(
        dateValue,
      );

      if (!dateValue) {
        setSelectedFestivalDay(
          "",
        );

        return;
      }

      setSelectedFestivalDay(
        festivalDayForDate(
          dateValue,
        ),
      );
    };

  const filteredVisits =
    useMemo(() => {
      const query =
        normalize(
          searchText,
        );

      return visits.filter(
        (visit) => {
          const jurisdiction =
            resolveJurisdiction(
              visit,
            );

          if (
            selectedRange &&
            jurisdiction.rangeName !==
              selectedRange
          ) {
            return false;
          }

          if (
            selectedZone &&
            jurisdiction.zoneName !==
              selectedZone
          ) {
            return false;
          }

          if (
            selectedDivision &&
            jurisdiction.divisionName !==
              selectedDivision
          ) {
            return false;
          }

          if (
            selectedPoliceStation &&
            jurisdiction.policeStationName !==
              selectedPoliceStation
          ) {
            return false;
          }

          if (
            selectedGpid &&
            text(
              visit.gpid,
            ) !==
              selectedGpid
          ) {
            return false;
          }

          /*
           * Festival Day filtering.
           *
           * If old/saved records contain festivalDay,
           * use it directly.
           *
           * If festivalDay is missing, derive Day from
           * the actual visit date so date-wise historical
           * records are still filterable.
           */
          if (
            selectedFestivalDay
          ) {
            const savedDay =
              normalizeFestivalDay(
                visit.festivalDay,
              );

            const calculatedDay =
              festivalDayForDate(
                visitDateKey(
                  visit,
                ),
              );

            if (
              savedDay !==
                selectedFestivalDay &&
              calculatedDay !==
                selectedFestivalDay
            ) {
              return false;
            }
          }

          /*
           * Visit Date filtering.
           */
          if (
            selectedVisitDate &&
            visitDateKey(
              visit,
            ) !==
              selectedVisitDate
          ) {
            return false;
          }

          if (!query) {
            return true;
          }

          const haystack =
            [
              visit.gpid,
              visit.applicationId,
              visit.officerName,
              visit.officerRank,
              visit.officerRole,
              jurisdiction.rangeName,
              jurisdiction.zoneName,
              jurisdiction.divisionName,
              jurisdiction.policeStationName,
              visit.sectorName,
              visit.remarks,
              visit.actionTaken,
              visit.status,
              visit.festivalDay,
              visit.festivalDate,
              visit.checkedAt,
            ]
              .map(
                (
                  value,
                ) =>
                  normalize(
                    value,
                  ),
              )
              .join(
                " ",
              );

          return haystack.includes(
            query,
          );
        },
      );
    }, [
      visits,
      selectedRange,
      selectedZone,
      selectedDivision,
      selectedPoliceStation,
      selectedGpid,
      selectedFestivalDay,
      selectedVisitDate,
      searchText,
    ]);

  const summary =
    useMemo(() => {
      const gpids =
        new Set<string>();

      const officers =
        new Set<string>();

      const gpidVisitCount =
        new Map<
          string,
          number
        >();

      let deficiencies =
        0;

      let followUp =
        0;

      let actions =
        0;

      let withoutDeficiency =
        0;

      let safetyPending =
        0;

      for (
        const visit of
        filteredVisits
      ) {
        const gpid =
          text(
            visit.gpid,
          );

        if (gpid) {
          gpids.add(
            gpid,
          );

          gpidVisitCount.set(
            gpid,
            (
              gpidVisitCount.get(
                gpid,
              ) ?? 0
            ) + 1,
          );
        }

        const officerKey =
          text(
            visit.officerId,
          ) ||
          text(
            visit.officerName,
          );

        if (
          officerKey
        ) {
          officers.add(
            officerKey,
          );
        }

        if (
          boolValue(
            visit.hasDeficiency,
          )
        ) {
          deficiencies +=
            1;
        } else {
          withoutDeficiency +=
            1;
        }

        if (
          boolValue(
            visit.requiresFollowUp,
          )
        ) {
          followUp +=
            1;
        }

        if (
          text(
            visit.actionTaken,
          )
        ) {
          actions +=
            1;
        }

        if (
          boolValue(
            visit.poojaPending,
          ) ||
          boolValue(
            visit.soundPending,
          ) ||
          boolValue(
            visit.fireSafetyPending,
          )
        ) {
          safetyPending +=
            1;
        }
      }

      const revisitedGpids =
        Array.from(
          gpidVisitCount.values(),
        ).filter(
          (count) =>
            count > 1,
        ).length;

      return {
        totalVisits:
          filteredVisits.length,

        uniqueGpids:
          gpids.size,

        revisitedGpids,

        officers:
          officers.size,

        deficiencies,

        followUp,

        actions,

        withoutDeficiency,

        safetyPending,
      };
    }, [
      filteredVisits,
    ]);

  const selectedFestival =
    useMemo(() => {
      if (
        selectedFestivalDay
      ) {
        return (
          FESTIVAL_DAYS.find(
            (item) =>
              item.dayValue ===
              selectedFestivalDay,
          ) ?? null
        );
      }

      if (
        selectedVisitDate
      ) {
        return (
          FESTIVAL_DAYS.find(
            (item) =>
              item.dateValue ===
              selectedVisitDate,
          ) ?? null
        );
      }

      return null;
    }, [
      selectedFestivalDay,
      selectedVisitDate,
    ]);

  const resetFilters =
    () => {
      setSelectedRange(
        "",
      );

      setSelectedZone(
        "",
      );

      setSelectedDivision(
        "",
      );

      setSelectedPoliceStation(
        "",
      );

      setSelectedGpid(
        "",
      );

      setSelectedFestivalDay(
        "",
      );

      setSelectedVisitDate(
        "",
      );

      setSearchText(
        "",
      );
    };

  return (
    <div className="min-h-screen bg-slate-100">
      <div className="w-full">
        <div className="mb-6 flex flex-col gap-4 xl:flex-row xl:items-start xl:justify-between">
          <div>
            <p className="text-xs font-bold uppercase tracking-[0.18em] text-slate-400">
              Field Monitoring
            </p>

            <h1 className="mt-1 text-3xl font-bold text-slate-800">
              Visitings Dashboard
            </h1>

            <p className="mt-2 max-w-4xl text-sm leading-6 text-slate-600">
              Daily and repeated field visits are maintained
              separately from the formal five-stage
              Inspection / Verification workflow.
            </p>
          </div>

          <div className="flex flex-wrap gap-3">
            <button
              type="button"
              onClick={() =>
                void loadVisits(
                  false,
                )
              }
              disabled={
                refreshing
              }
              className="rounded-xl border border-slate-300 bg-white px-5 py-3 text-sm font-bold text-slate-700 shadow-sm hover:bg-slate-50 disabled:opacity-60"
            >
              {refreshing
                ? "Refreshing..."
                : "Refresh"}
            </button>

            <a
              href="/festivity/checking"
              className="rounded-xl bg-[#17365D] px-5 py-3 text-sm font-bold text-white shadow-sm hover:bg-[#244d7c]"
            >
              Open Detailed Visitings
            </a>
          </div>
        </div>

        {error && (
          <div className="mb-6 rounded-xl border border-red-200 bg-red-50 px-5 py-4 text-sm font-semibold text-red-700">
            {error}
          </div>
        )}

        <section className="mb-7 rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
          <div className="mb-5 flex flex-col gap-3 lg:flex-row lg:items-start lg:justify-between">
            <div>
              <p className="text-xs font-bold uppercase tracking-wider text-slate-400">
                Jurisdiction Selection
              </p>

              <h2 className="mt-1 text-xl font-bold text-slate-800">
                Range → Zone → Division → Police Station → GPID
              </h2>

              <p className="mt-2 text-sm leading-6 text-slate-500">
                Select the jurisdiction and Festival Day /
                Date to view daily Visitings.
              </p>
            </div>

            <button
              type="button"
              onClick={
                resetFilters
              }
              className="rounded-xl border border-slate-300 bg-white px-5 py-2.5 text-sm font-bold text-slate-700 hover:bg-slate-50"
            >
              Reset Filters
            </button>
          </div>

          <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
            <div>
              <label className="mb-2 block text-sm font-bold text-slate-700">
                Range
              </label>

              <select
                value={
                  selectedRange
                }
                onChange={(
                  event,
                ) => {
                  setSelectedRange(
                    event.target.value,
                  );

                  setSelectedZone(
                    "",
                  );

                  setSelectedDivision(
                    "",
                  );

                  setSelectedPoliceStation(
                    "",
                  );

                  setSelectedGpid(
                    "",
                  );
                }}
                className="w-full rounded-xl border border-slate-300 bg-white px-3 py-3 text-sm font-semibold text-slate-700"
              >
                <option value="">
                  All Ranges
                </option>

                {rangeOptions.map(
                  (range) => (
                    <option
                      key={range}
                      value={range}
                    >
                      {range}
                    </option>
                  ),
                )}
              </select>
            </div>

            <div>
              <label className="mb-2 block text-sm font-bold text-slate-700">
                Zone
              </label>

              <select
                value={
                  selectedZone
                }
                disabled={
                  !selectedRange
                }
                onChange={(
                  event,
                ) => {
                  setSelectedZone(
                    event.target.value,
                  );

                  setSelectedDivision(
                    "",
                  );

                  setSelectedPoliceStation(
                    "",
                  );

                  setSelectedGpid(
                    "",
                  );
                }}
                className="w-full rounded-xl border border-slate-300 bg-white px-3 py-3 text-sm font-semibold text-slate-700 disabled:cursor-not-allowed disabled:bg-slate-100 disabled:text-slate-400"
              >
                <option value="">
                  All Zones
                </option>

                {zoneOptions.map(
                  (zone) => (
                    <option
                      key={zone}
                      value={zone}
                    >
                      {zone}
                    </option>
                  ),
                )}
              </select>
            </div>

            <div>
              <label className="mb-2 block text-sm font-bold text-slate-700">
                Division
              </label>

              <select
                value={
                  selectedDivision
                }
                disabled={
                  !selectedZone
                }
                onChange={(
                  event,
                ) => {
                  setSelectedDivision(
                    event.target.value,
                  );

                  setSelectedPoliceStation(
                    "",
                  );

                  setSelectedGpid(
                    "",
                  );
                }}
                className="w-full rounded-xl border border-slate-300 bg-white px-3 py-3 text-sm font-semibold text-slate-700 disabled:cursor-not-allowed disabled:bg-slate-100 disabled:text-slate-400"
              >
                <option value="">
                  All Divisions
                </option>

                {divisionOptions.map(
                  (
                    division,
                  ) => (
                    <option
                      key={
                        division
                      }
                      value={
                        division
                      }
                    >
                      {
                        division
                      }
                    </option>
                  ),
                )}
              </select>
            </div>

            <div>
              <label className="mb-2 block text-sm font-bold text-slate-700">
                Police Station
              </label>

              <select
                value={
                  selectedPoliceStation
                }
                disabled={
                  !selectedDivision
                }
                onChange={(
                  event,
                ) => {
                  setSelectedPoliceStation(
                    event.target.value,
                  );

                  setSelectedGpid(
                    "",
                  );
                }}
                className="w-full rounded-xl border border-slate-300 bg-white px-3 py-3 text-sm font-semibold text-slate-700 disabled:cursor-not-allowed disabled:bg-slate-100 disabled:text-slate-400"
              >
                <option value="">
                  All Police Stations
                </option>

                {policeStationOptions.map(
                  (
                    policeStation,
                  ) => (
                    <option
                      key={
                        policeStation
                      }
                      value={
                        policeStation
                      }
                    >
                      {
                        policeStation
                      }
                    </option>
                  ),
                )}
              </select>
            </div>

            <div>
              <label className="mb-2 block text-sm font-bold text-slate-700">
                GPID
              </label>

              <select
                value={
                  selectedGpid
                }
                disabled={
                  !selectedPoliceStation
                }
                onChange={(
                  event,
                ) =>
                  setSelectedGpid(
                    event.target.value,
                  )
                }
                className="w-full rounded-xl border border-slate-300 bg-white px-3 py-3 text-sm font-semibold text-slate-700 disabled:cursor-not-allowed disabled:bg-slate-100 disabled:text-slate-400"
              >
                <option value="">
                  All GPIDs
                </option>

                {gpidOptions.map(
                  (
                    gpid,
                  ) => (
                    <option
                      key={
                        gpid
                      }
                      value={
                        gpid
                      }
                    >
                      {
                        gpid
                      }
                    </option>
                  ),
                )}
              </select>
            </div>

            <div>
              <label className="mb-2 block text-sm font-bold text-slate-700">
                Festival Day
              </label>

              <select
                value={
                  selectedFestivalDay
                }
                onChange={(
                  event,
                ) =>
                  handleFestivalDayChange(
                    event.target.value,
                  )
                }
                className="w-full rounded-xl border border-slate-300 bg-white px-3 py-3 text-sm font-semibold text-slate-700"
              >
                <option value="">
                  All Festival Days
                </option>

                {FESTIVAL_DAYS.map(
                  (
                    item,
                  ) => (
                    <option
                      key={
                        item.dayValue
                      }
                      value={
                        item.dayValue
                      }
                    >
                      Day{" "}
                      {
                        item.day
                      }{" "}
                      -{" "}
                      {
                        item.displayDate
                      }
                    </option>
                  ),
                )}
              </select>
            </div>

            <div>
              <label className="mb-2 block text-sm font-bold text-slate-700">
                Festival / Visit Date
              </label>

              <input
                type="date"
                min="2026-09-14"
                max="2026-09-24"
                value={
                  selectedVisitDate
                }
                onChange={(
                  event,
                ) =>
                  handleVisitDateChange(
                    event.target.value,
                  )
                }
                className="w-full rounded-xl border border-slate-300 bg-white px-3 py-3 text-sm font-semibold text-slate-700"
              />
            </div>

            <div>
              <label className="mb-2 block text-sm font-bold text-slate-700">
                Search
              </label>

              <input
                type="text"
                value={
                  searchText
                }
                onChange={(
                  event,
                ) =>
                  setSearchText(
                    event.target.value,
                  )
                }
                placeholder="GPID / Officer / PS / Remarks..."
                className="w-full rounded-xl border border-slate-300 bg-white px-3 py-3 text-sm"
              />
            </div>
          </div>

          {selectedFestival && (
            <div className="mt-5 rounded-xl border border-blue-200 bg-blue-50 px-5 py-4">
              <div className="flex flex-wrap items-center gap-x-8 gap-y-2">
                <div>
                  <span className="text-xs font-bold uppercase tracking-wide text-blue-500">
                    Festival Day
                  </span>

                  <div className="text-lg font-bold text-blue-900">
                    Day{" "}
                    {
                      selectedFestival.day
                    }
                  </div>
                </div>

                <div>
                  <span className="text-xs font-bold uppercase tracking-wide text-blue-500">
                    Corresponding Date
                  </span>

                  <div className="text-lg font-bold text-blue-900">
                    {
                      selectedFestival.displayDate
                    }
                  </div>
                </div>
              </div>
            </div>
          )}
        </section>

        <section className="mb-7 grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
          {[
            {
              title:
                "Total Visitings",

              value:
                summary.totalVisits,
            },
            {
              title:
                "GPIDs Visited",

              value:
                summary.uniqueGpids,
            },
            {
              title:
                "Re-Visited GPIDs",

              value:
                summary.revisitedGpids,
            },
            {
              title:
                "Officers Involved",

              value:
                summary.officers,
            },
            {
              title:
                "Deficiencies Found",

              value:
                summary.deficiencies,
            },
            {
              title:
                "Follow-Up Required",

              value:
                summary.followUp,
            },
            {
              title:
                "Actions Taken",

              value:
                summary.actions,
            },
            {
              title:
                "Visits Without Deficiency",

              value:
                summary.withoutDeficiency,
            },
          ].map(
            (
              card,
            ) => (
              <div
                key={
                  card.title
                }
                className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm"
              >
                <div className="text-3xl font-bold text-[#17365D]">
                  {loading
                    ? "..."
                    : card.value.toLocaleString(
                        "en-IN",
                      )}
                </div>

                <div className="mt-2 text-sm font-semibold text-slate-600">
                  {
                    card.title
                  }
                </div>
              </div>
            ),
          )}
        </section>

        <section className="mb-7 grid gap-4 lg:grid-cols-2">
          <div className="rounded-2xl border border-amber-200 bg-amber-50 p-5">
            <p className="text-xs font-bold uppercase tracking-wider text-amber-700">
              Compliance / Safety
            </p>

            <div className="mt-2 text-3xl font-bold text-amber-900">
              {loading
                ? "..."
                : summary.safetyPending.toLocaleString(
                    "en-IN",
                  )}
            </div>

            <p className="mt-2 text-sm leading-6 text-amber-800">
              Visit records with pending Pooja, Sound or
              Fire-Safety related items.
            </p>
          </div>

          <div className="rounded-2xl border border-blue-200 bg-blue-50 p-5">
            <p className="text-xs font-bold uppercase tracking-wider text-blue-700">
              Current Result
            </p>

            <div className="mt-2 text-3xl font-bold text-blue-900">
              {loading
                ? "..."
                : filteredVisits.length.toLocaleString(
                    "en-IN",
                  )}
            </div>

            <p className="mt-2 text-sm leading-6 text-blue-800">
              Visitings matching the currently selected
              jurisdiction, Festival Day, Date and search
              filters.
            </p>
          </div>
        </section>

        <section className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm">
          <div className="flex flex-col gap-3 border-b border-slate-200 p-5 lg:flex-row lg:items-center lg:justify-between">
            <div>
              <h2 className="text-xl font-bold text-slate-800">
                Daily Visiting Records
              </h2>

              <p className="mt-1 text-sm text-slate-500">
                Every visit is retained independently so
                repeated visits to the same GPID remain
                visible.
              </p>
            </div>

            <div className="text-sm font-semibold text-slate-500">
              {lastUpdated
                ? `Updated ${lastUpdated.toLocaleTimeString(
                    "en-IN",
                    {
                      hour:
                        "2-digit",

                      minute:
                        "2-digit",

                      second:
                        "2-digit",

                      hour12:
                        true,
                    },
                  )}`
                : ""}
            </div>
          </div>

          <div className="overflow-x-auto">
            <table className="min-w-[1500px] w-full divide-y divide-slate-200">
              <thead className="bg-slate-50">
                <tr>
                  {[
                    "Date / Time",
                    "GPID",
                    "Festival Day",
                    "Officer",
                    "Rank",
                    "Range",
                    "Zone",
                    "Division",
                    "Police Station",
                    "Sector",
                    "Deficiency",
                    "Follow-Up",
                    "Action Taken",
                    "Remarks",
                  ].map(
                    (
                      heading,
                    ) => (
                      <th
                        key={
                          heading
                        }
                        className="whitespace-nowrap px-4 py-3 text-left text-xs font-bold uppercase tracking-wide text-slate-500"
                      >
                        {
                          heading
                        }
                      </th>
                    ),
                  )}
                </tr>
              </thead>

              <tbody className="divide-y divide-slate-100">
                {loading && (
                  <tr>
                    <td
                      colSpan={
                        14
                      }
                      className="px-5 py-12 text-center text-sm text-slate-500"
                    >
                      Loading Visitings...
                    </td>
                  </tr>
                )}

                {!loading &&
                  filteredVisits.length ===
                    0 && (
                    <tr>
                      <td
                        colSpan={
                          14
                        }
                        className="px-5 py-12 text-center text-sm text-slate-500"
                      >
                        No Visitings found for the selected
                        filters.
                      </td>
                    </tr>
                  )}

                {!loading &&
                  filteredVisits.map(
                    (
                      visit,
                      index,
                    ) => {
                      const jurisdiction =
                        resolveJurisdiction(
                          visit,
                        );

                      const visitDate =
                        visitDateKey(
                          visit,
                        );

                      const savedDay =
                        normalizeFestivalDay(
                          visit.festivalDay,
                        );

                      const calculatedDay =
                        savedDay ||
                        festivalDayForDate(
                          visitDate,
                        );

                      return (
                        <tr
                          key={
                            text(
                              visit.id,
                            ) ||
                            `${text(
                              visit.gpid,
                            )}-${text(
                              visit.checkedAt,
                            )}-${index}`
                          }
                          className="hover:bg-slate-50"
                        >
                          <td className="whitespace-nowrap px-4 py-3 text-sm text-slate-600">
                            {formatDateTime(
                              visit.checkedAt ||
                                visit.createdAt,
                            )}
                          </td>

                          <td className="whitespace-nowrap px-4 py-3 text-sm font-bold text-[#17365D]">
                            {text(
                              visit.gpid,
                            ) ||
                              "-"}
                          </td>

                          <td className="whitespace-nowrap px-4 py-3 text-sm text-slate-600">
                            {calculatedDay
                              ? `Day ${calculatedDay}`
                              : "-"}
                          </td>

                          <td className="whitespace-nowrap px-4 py-3 text-sm font-semibold text-slate-700">
                            {text(
                              visit.officerName,
                            ) ||
                              "-"}
                          </td>

                          <td className="whitespace-nowrap px-4 py-3 text-sm text-slate-600">
                            {text(
                              visit.officerRank,
                            ) ||
                              "-"}
                          </td>

                          <td className="whitespace-nowrap px-4 py-3 text-sm text-slate-600">
                            {jurisdiction.rangeName ||
                              "-"}
                          </td>

                          <td className="whitespace-nowrap px-4 py-3 text-sm text-slate-600">
                            {jurisdiction.zoneName ||
                              "-"}
                          </td>

                          <td className="whitespace-nowrap px-4 py-3 text-sm text-slate-600">
                            {jurisdiction.divisionName ||
                              "-"}
                          </td>

                          <td className="whitespace-nowrap px-4 py-3 text-sm text-slate-600">
                            {jurisdiction.policeStationName ||
                              "-"}
                          </td>

                          <td className="whitespace-nowrap px-4 py-3 text-sm text-slate-600">
                            {text(
                              visit.sectorName,
                            ) ||
                              "-"}
                          </td>

                          <td className="whitespace-nowrap px-4 py-3">
                            <span
                              className={`rounded-full px-2.5 py-1 text-xs font-bold ${
                                boolValue(
                                  visit.hasDeficiency,
                                )
                                  ? "bg-red-100 text-red-700"
                                  : "bg-emerald-100 text-emerald-700"
                              }`}
                            >
                              {boolValue(
                                visit.hasDeficiency,
                              )
                                ? "YES"
                                : "NO"}
                            </span>
                          </td>

                          <td className="whitespace-nowrap px-4 py-3">
                            <span
                              className={`rounded-full px-2.5 py-1 text-xs font-bold ${
                                boolValue(
                                  visit.requiresFollowUp,
                                )
                                  ? "bg-amber-100 text-amber-700"
                                  : "bg-slate-100 text-slate-600"
                              }`}
                            >
                              {boolValue(
                                visit.requiresFollowUp,
                              )
                                ? "YES"
                                : "NO"}
                            </span>
                          </td>

                          <td className="max-w-[260px] px-4 py-3 text-sm text-slate-600">
                            {text(
                              visit.actionTaken,
                            ) ||
                              "-"}
                          </td>

                          <td className="max-w-[320px] px-4 py-3 text-sm text-slate-600">
                            {text(
                              visit.remarks,
                            ) ||
                              "-"}
                          </td>
                        </tr>
                      );
                    },
                  )}
              </tbody>
            </table>
          </div>

          <div className="border-t border-slate-200 bg-slate-50 px-5 py-3 text-xs text-slate-500">
            Visitings refresh automatically every 30 seconds.
            Festival Day and Festival Date are synchronized
            automatically in both directions.
          </div>
        </section>
      </div>
    </div>
  );
}