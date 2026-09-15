"use client";

import { useEffect, useMemo, useState } from "react";
import { useRouter } from "next/navigation";

type User = {
  username: string;
  officerName: string;
  role: string;
  policeStation: string;
  sector: string;
};

type GaneshRecord = {
  unique_id?: string;
  ref_no?: string;
  name?: string;
  association?: string;
  mobile_no?: string;
  ps_name?: string;
  division_name?: string;
  zone_name?: string;
  dist_name?: string;
  status?: string;
  idol_area_type?: string;
  idol_type?: string;
  idol_height?: string | number;
  instal_from_date?: string;
  instal_to_date?: string;
  immr_date?: string;
  riv_name?: string;
};

type RangeName =
  | "South Range"
  | "North Range";

type RangeSummary = {
  rangeName: RangeName;
  gpidCount: number;
  zoneCount: number;
  divisionCount: number;
  policeStationCount: number;
};

type ZoneSummary = {
  zoneName: string;
  gpidCount: number;
  divisionCount: number;
  policeStationCount: number;
};

type DivisionSummary = {
  divisionName: string;
  gpidCount: number;
  policeStationCount: number;
};

type PoliceStationSummary = {
  policeStationName: string;
  gpidCount: number;
};

function normalizeHierarchyName(
  value?: string,
): string {
  return String(value ?? "")
    .trim()
    .toLowerCase()
    .replace(/\s+/g, " ");
}

function getRangeForZone(
  zoneName?: string,
): RangeName | null {
  const zone =
    normalizeHierarchyName(zoneName);

  const zoneKey =
    zone.replace(/[^a-z0-9]/g, "");

  const southRangeZones =
    new Set([
      "charminar",
      "golconda",
      "golkonda",
      "shamshabad",
      "samshabad",
      "rajendranagar",
      "rajendanagar",
    ]);

  const northRangeZones =
    new Set([
      "jubileehills",
      "khairatabad",
      "secunderabad",
    ]);

  if (southRangeZones.has(zoneKey)) {
    return "South Range";
  }

  if (northRangeZones.has(zoneKey)) {
    return "North Range";
  }

  return null;
}

export default function Dashboard() {
  const router = useRouter();

  const [user, setUser] =
    useState<User | null>(null);

  const [records, setRecords] =
    useState<GaneshRecord[]>([]);

  const [loadingGpids, setLoadingGpids] =
    useState(true);

  const [gpidError, setGpidError] =
    useState("");

  const [searchText, setSearchText] =
    useState("");

  const [selectedRange, setSelectedRange] =
    useState<RangeName | null>(null);

  const [selectedZone, setSelectedZone] =
    useState<string | null>(null);

  const [
    selectedDivision,
    setSelectedDivision,
  ] = useState<string | null>(null);

  const [
    selectedPoliceStation,
    setSelectedPoliceStation,
  ] = useState<string | null>(null);

  useEffect(() => {
    const savedUser =
      localStorage.getItem("ganesh_user");

    if (!savedUser) {
      router.push("/");
      return;
    }

    const timer =
      window.setTimeout(() => {
        try {
          const parsedUser =
            JSON.parse(savedUser) as User;

          setUser(parsedUser);
        } catch (error) {
          console.error(
            "Invalid saved user:",
            error,
          );

          localStorage.removeItem(
            "ganesh_user",
          );

          router.push("/");
        }
      }, 0);

    return () => {
      window.clearTimeout(timer);
    };
  }, [router]);

  useEffect(() => {
    let active = true;

    const loadGpids =
      async () => {
        try {
          const response =
            await fetch(
              "/api/gpid",
              {
                method: "GET",
                cache: "no-store",
                credentials: "include",
              },
            );

          if (!response.ok) {
            throw new Error(
              "Failed to load GPID records.",
            );
          }

          const data: unknown =
            await response.json();

          if (!Array.isArray(data)) {
            throw new Error(
              "Unexpected GPID response.",
            );
          }

          const validRecords =
            data.filter(
              (
                item,
              ): item is GaneshRecord => {
                if (
                  typeof item !== "object" ||
                  item === null ||
                  !("unique_id" in item)
                ) {
                  return false;
                }

                const gpid =
                  String(
                    (item as GaneshRecord)
                      .unique_id ?? "",
                  ).trim();

                return gpid.length > 0;
              },
            );

          if (!active) {
            return;
          }

          setRecords(validRecords);
          setGpidError("");
        } catch (error) {
          console.error(
            "Dashboard GPID error:",
            error,
          );

          if (!active) {
            return;
          }

          setGpidError(
            "Unable to load live GPID data.",
          );
        } finally {
          if (active) {
            setLoadingGpids(false);
          }
        }
      };

    const initialTimer =
      window.setTimeout(() => {
        void loadGpids();
      }, 0);

    const refreshTimer =
      window.setInterval(() => {
        void loadGpids();
      }, 30000);

    return () => {
      active = false;

      window.clearTimeout(
        initialTimer,
      );

      window.clearInterval(
        refreshTimer,
      );
    };
  }, []);

  const summary =
    useMemo(() => {
      const zones =
        new Set<string>();

      const divisions =
        new Set<string>();

      const policeStations =
        new Set<string>();

      for (const record of records) {
        const zone =
          String(
            record.zone_name ?? "",
          ).trim();

        const division =
          String(
            record.division_name ?? "",
          ).trim();

        const policeStation =
          String(
            record.ps_name ?? "",
          ).trim();

        if (zone) {
          zones.add(zone);
        }

        if (division) {
          divisions.add(division);
        }

        if (policeStation) {
          policeStations.add(
            policeStation,
          );
        }
      }

      return {
        totalGpids:
          records.length,

        totalZones:
          zones.size,

        totalDivisions:
          divisions.size,

        totalPoliceStations:
          policeStations.size,
      };
    }, [records]);

  const rangeSummary =
    useMemo<RangeSummary[]>(() => {
      const rangeMap =
        new Map<
          RangeName,
          {
            gpids: number;
            zones: Set<string>;
            divisions: Set<string>;
            policeStations: Set<string>;
          }
        >();

      rangeMap.set(
        "South Range",
        {
          gpids: 0,
          zones:
            new Set<string>(),
          divisions:
            new Set<string>(),
          policeStations:
            new Set<string>(),
        },
      );

      rangeMap.set(
        "North Range",
        {
          gpids: 0,
          zones:
            new Set<string>(),
          divisions:
            new Set<string>(),
          policeStations:
            new Set<string>(),
        },
      );

      for (const record of records) {
        const zoneName =
          String(
            record.zone_name ?? "",
          ).trim();

        const rangeName =
          getRangeForZone(
            zoneName,
          );

        if (!rangeName) {
          continue;
        }

        const divisionName =
          String(
            record.division_name ?? "",
          ).trim();

        const policeStationName =
          String(
            record.ps_name ?? "",
          ).trim();

        const current =
          rangeMap.get(
            rangeName,
          );

        if (!current) {
          continue;
        }

        current.gpids += 1;

        if (zoneName) {
          current.zones.add(
            zoneName,
          );
        }

        if (divisionName) {
          current.divisions.add(
            divisionName,
          );
        }

        if (policeStationName) {
          current.policeStations.add(
            policeStationName,
          );
        }
      }

      return (
        [
          "South Range",
          "North Range",
        ] as RangeName[]
      ).map(
        (rangeName) => {
          const value =
            rangeMap.get(
              rangeName,
            )!;

          return {
            rangeName,
            gpidCount:
              value.gpids,
            zoneCount:
              value.zones.size,
            divisionCount:
              value.divisions.size,
            policeStationCount:
              value.policeStations
                .size,
          };
        },
      );
    }, [records]);

  const selectedRangeSummary =
    useMemo(() => {
      if (!selectedRange) {
        return null;
      }

      return (
        rangeSummary.find(
          (range) =>
            range.rangeName ===
            selectedRange,
        ) ?? null
      );
    }, [
      rangeSummary,
      selectedRange,
    ]);

  const searchResults =
    useMemo(() => {
      const query =
        searchText
          .trim()
          .toLowerCase();

      if (!query) {
        return [];
      }

      return records
        .filter(
          (record) => {
            const fields = [
              record.unique_id,
              record.ref_no,
              record.mobile_no,
              record.name,
              record.association,
              record.ps_name,
              record.division_name,
              record.zone_name,
            ];

            return fields.some(
              (value) =>
                String(
                  value ?? "",
                )
                  .toLowerCase()
                  .includes(query),
            );
          },
        )
        .slice(0, 100);
    }, [
      records,
      searchText,
    ]);

  const zoneSummary =
    useMemo<ZoneSummary[]>(() => {
      if (!selectedRange) {
        return [];
      }

      const zoneMap =
        new Map<
          string,
          {
            gpids: number;
            divisions: Set<string>;
            policeStations: Set<string>;
          }
        >();

      for (const record of records) {
        const zoneName =
          String(
            record.zone_name ?? "",
          ).trim() ||
          "Unmapped";

        if (
          getRangeForZone(
            zoneName,
          ) !== selectedRange
        ) {
          continue;
        }

        const divisionName =
          String(
            record.division_name ?? "",
          ).trim();

        const policeStationName =
          String(
            record.ps_name ?? "",
          ).trim();

        if (
          !zoneMap.has(
            zoneName,
          )
        ) {
          zoneMap.set(
            zoneName,
            {
              gpids: 0,
              divisions:
                new Set<string>(),
              policeStations:
                new Set<string>(),
            },
          );
        }

        const current =
          zoneMap.get(
            zoneName,
          );

        if (!current) {
          continue;
        }

        current.gpids += 1;

        if (divisionName) {
          current.divisions.add(
            divisionName,
          );
        }

        if (policeStationName) {
          current.policeStations.add(
            policeStationName,
          );
        }
      }

      return Array.from(
        zoneMap.entries(),
      )
        .map(
          ([
            zoneName,
            value,
          ]) => ({
            zoneName,
            gpidCount:
              value.gpids,
            divisionCount:
              value.divisions.size,
            policeStationCount:
              value.policeStations
                .size,
          }),
        )
        .sort(
          (a, b) =>
            a.zoneName.localeCompare(
              b.zoneName,
            ),
        );
    }, [
      records,
      selectedRange,
    ]);

  const divisionSummary =
    useMemo<
      DivisionSummary[]
    >(() => {
      if (!selectedZone) {
        return [];
      }

      const divisionMap =
        new Map<
          string,
          {
            gpids: number;
            policeStations: Set<string>;
          }
        >();

      for (const record of records) {
        const zoneName =
          String(
            record.zone_name ?? "",
          ).trim();

        if (
          zoneName !==
          selectedZone
        ) {
          continue;
        }

        const divisionName =
          String(
            record.division_name ?? "",
          ).trim() ||
          "Unmapped";

        const policeStationName =
          String(
            record.ps_name ?? "",
          ).trim();

        if (
          !divisionMap.has(
            divisionName,
          )
        ) {
          divisionMap.set(
            divisionName,
            {
              gpids: 0,
              policeStations:
                new Set<string>(),
            },
          );
        }

        const current =
          divisionMap.get(
            divisionName,
          );

        if (!current) {
          continue;
        }

        current.gpids += 1;

        if (policeStationName) {
          current.policeStations.add(
            policeStationName,
          );
        }
      }

      return Array.from(
        divisionMap.entries(),
      )
        .map(
          ([
            divisionName,
            value,
          ]) => ({
            divisionName,
            gpidCount:
              value.gpids,
            policeStationCount:
              value.policeStations
                .size,
          }),
        )
        .sort(
          (a, b) =>
            a.divisionName.localeCompare(
              b.divisionName,
            ),
        );
    }, [
      records,
      selectedZone,
    ]);

  const policeStationSummary =
    useMemo<
      PoliceStationSummary[]
    >(() => {
      if (
        !selectedZone ||
        !selectedDivision
      ) {
        return [];
      }

      const policeStationMap =
        new Map<
          string,
          number
        >();

      for (const record of records) {
        const zoneName =
          String(
            record.zone_name ?? "",
          ).trim();

        const divisionName =
          String(
            record.division_name ?? "",
          ).trim();

        if (
          zoneName !==
            selectedZone ||
          divisionName !==
            selectedDivision
        ) {
          continue;
        }

        const policeStationName =
          String(
            record.ps_name ?? "",
          ).trim() ||
          "Unmapped";

        policeStationMap.set(
          policeStationName,
          (
            policeStationMap.get(
              policeStationName,
            ) ?? 0
          ) + 1,
        );
      }

      return Array.from(
        policeStationMap.entries(),
      )
        .map(
          ([
            policeStationName,
            gpidCount,
          ]) => ({
            policeStationName,
            gpidCount,
          }),
        )
        .sort(
          (a, b) =>
            a.policeStationName.localeCompare(
              b.policeStationName,
            ),
        );
    }, [
      records,
      selectedZone,
      selectedDivision,
    ]);

  const selectedPoliceStationRecords =
    useMemo<
      GaneshRecord[]
    >(() => {
      if (
        !selectedZone ||
        !selectedDivision ||
        !selectedPoliceStation
      ) {
        return [];
      }

      return records
        .filter(
          (record) => {
            const zoneName =
              String(
                record.zone_name ??
                  "",
              ).trim();

            const divisionName =
              String(
                record.division_name ??
                  "",
              ).trim();

            const policeStationName =
              String(
                record.ps_name ??
                  "",
              ).trim();

            return (
              zoneName ===
                selectedZone &&
              divisionName ===
                selectedDivision &&
              policeStationName ===
                selectedPoliceStation
            );
          },
        )
        .sort(
          (a, b) =>
            String(
              a.unique_id ??
                "",
            ).localeCompare(
              String(
                b.unique_id ??
                  "",
              ),
            ),
        );
    }, [
      records,
      selectedZone,
      selectedDivision,
      selectedPoliceStation,
    ]);

  const selectedZonePoliceStationCount =
    useMemo(() => {
      if (!selectedZone) {
        return 0;
      }

      return new Set(
        records
          .filter(
            (record) =>
              String(
                record.zone_name ??
                  "",
              ).trim() ===
              selectedZone,
          )
          .map(
            (record) =>
              String(
                record.ps_name ??
                  "",
              ).trim(),
          )
          .filter(Boolean),
      ).size;
    }, [
      records,
      selectedZone,
    ]);

  const selectedZoneGpidCount =
    useMemo(() => {
      if (!selectedZone) {
        return 0;
      }

      return records.filter(
        (record) =>
          String(
            record.zone_name ??
              "",
          ).trim() ===
          selectedZone,
      ).length;
    }, [
      records,
      selectedZone,
    ]);

  const selectedDivisionGpidCount =
    useMemo(() => {
      if (
        !selectedZone ||
        !selectedDivision
      ) {
        return 0;
      }

      return records.filter(
        (record) =>
          String(
            record.zone_name ??
              "",
          ).trim() ===
            selectedZone &&
          String(
            record.division_name ??
              "",
          ).trim() ===
            selectedDivision,
      ).length;
    }, [
      records,
      selectedZone,
      selectedDivision,
    ]);

  const getStatusClassName =
    (status?: string) => {
      const normalizedStatus =
        String(status ?? "")
          .trim()
          .toUpperCase();

      if (
        normalizedStatus ===
        "APPROVED"
      ) {
        return "bg-green-50 border-green-200 text-green-700";
      }

      if (
        normalizedStatus ===
        "REJECTED"
      ) {
        return "bg-red-50 border-red-200 text-red-700";
      }

      if (
        normalizedStatus ===
        "PENDING"
      ) {
        return "bg-amber-50 border-amber-200 text-amber-700";
      }

      return "bg-slate-50 border-slate-200 text-slate-700";
    };

  const openGpid =
    (gpid?: string) => {
      const cleanGpid =
        String(
          gpid ?? "",
        ).trim();

      if (!cleanGpid) {
        return;
      }

      router.push(
        `/pre-installation/${encodeURIComponent(
          cleanGpid,
        )}`,
      );
    };

  const logout =
    async () => {
      try {
        await fetch(
          "/api/auth/logout",
          {
            method: "POST",
            credentials: "include",
          },
        );
      } catch (error) {
        console.error(
          "Logout API error:",
          error,
        );
      } finally {
        localStorage.removeItem(
          "ganesh_user",
        );

        router.push("/");
      }
    };

  if (!user) {
    return (
      <main className="min-h-screen flex items-center justify-center bg-slate-100">
        <div className="text-slate-600">
          Loading...
        </div>
      </main>
    );
  }

  const dashboardCards = [
    {
      title: "Total GPIDs",
      value: loadingGpids
        ? "..."
        : summary.totalGpids.toLocaleString(
            "en-IN",
          ),
    },
    {
      title: "Zones",
      value: loadingGpids
        ? "..."
        : summary.totalZones.toString(),
    },
    {
      title: "Divisions",
      value: loadingGpids
        ? "..."
        : summary.totalDivisions.toString(),
    },
    {
      title: "Police Stations",
      value: loadingGpids
        ? "..."
        : summary.totalPoliceStations.toString(),
    },
  ];

  const stages = [
    {
      number: 1,
      name: "Pre-Installation",
      status: "ACTIVE",
      active: true,
    },
    {
      number: 2,
      name: "Installation",
      status: "Pending Configuration",
      active: false,
    },
    {
      number: 3,
      name: "During Festivity",
      status: "Pending Configuration",
      active: false,
    },
    {
      number: 4,
      name: "Immersion",
      status: "Pending Configuration",
      active: false,
    },
    {
      number: 5,
      name: "Post-Immersion",
      status: "Pending Configuration",
      active: false,
    },
  ];

  return (
    <main className="min-h-screen bg-slate-100">
      <header className="bg-[#17365D] text-white">
        <div className="max-w-7xl mx-auto px-6 py-5 flex items-center justify-between">
          <div>
            <p className="text-xs tracking-widest text-blue-200">
              OFFICIAL USE
            </p>

            <h1 className="text-xl md:text-2xl font-bold">
              Ganesh Festival Bandobust Management System
            </h1>
          </div>

          <button
            onClick={() => {
              void logout();
            }}
            className="border border-white/30 px-4 py-2 rounded-lg hover:bg-white/10"
          >
            Logout
          </button>
        </div>
      </header>

      <div className="max-w-7xl mx-auto px-6 py-8">
        <section className="bg-white rounded-xl shadow-sm p-5 mb-7">
          <div className="grid md:grid-cols-4 gap-5">
            <div>
              <p className="text-xs text-slate-500">
                Officer
              </p>

              <p className="font-bold text-slate-800">
                {user.officerName}
              </p>
            </div>

            <div>
              <p className="text-xs text-slate-500">
                Role
              </p>

              <p className="font-bold text-slate-800">
                {user.role}
              </p>
            </div>

            <div>
              <p className="text-xs text-slate-500">
                Police Station
              </p>

              <p className="font-bold text-slate-800">
                {user.policeStation || "-"}
              </p>
            </div>

            <div>
              <p className="text-xs text-slate-500">
                Sector
              </p>

              <p className="font-bold text-slate-800">
                {user.sector || "-"}
              </p>
            </div>
          </div>
        </section>

        <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-3 mb-4">
          <div>
            <h2 className="text-2xl font-bold text-slate-800">
              Ganesh Integrated Dashboard
            </h2>

            <p className="text-sm text-slate-500 mt-1">
              Live GPID monitoring across Hyderabad Commissionerate
            </p>
          </div>

          <div className="text-xs text-slate-500">
            Auto refresh: 30 seconds
          </div>
        </div>

        {gpidError && (
          <div className="mb-4 rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
            {gpidError}
          </div>
        )}

        <section className="grid sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
          {dashboardCards.map(
            (card) => (
              <div
                key={card.title}
                className="bg-white rounded-xl shadow-sm border border-slate-200 p-5"
              >
                <div className="text-3xl font-bold text-[#17365D]">
                  {card.value}
                </div>

                <p className="text-sm text-slate-600 mt-2">
                  {card.title}
                </p>
              </div>
            ),
          )}
        </section>

        <section className="bg-white rounded-xl border border-slate-200 shadow-sm mb-8 p-5">
          <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4 mb-4">
            <div>
              <h2 className="text-xl font-bold text-slate-800">
                Search Ganesh Application
              </h2>

              <p className="text-sm text-slate-500 mt-1">
                Search by GPID, Reference ID, Mobile Number, Applicant or Association
              </p>
            </div>

            {searchText && (
              <button
                onClick={() =>
                  setSearchText("")
                }
                className="px-4 py-2 rounded-lg border border-slate-300 text-sm font-semibold text-slate-600 hover:bg-slate-50"
              >
                Clear
              </button>
            )}
          </div>

          <input
            type="text"
            value={searchText}
            onChange={(event) =>
              setSearchText(
                event.target.value,
              )
            }
            placeholder="Enter GPID / Reference ID / Mobile / Applicant / Association"
            className="w-full rounded-xl border border-slate-300 px-4 py-3 text-sm outline-none focus:border-blue-500 focus:ring-2 focus:ring-blue-100"
          />

          {searchText.trim() && (
            <div className="mt-5 overflow-x-auto border border-slate-200 rounded-xl">
              <table className="w-full min-w-[1100px] text-sm">
                <thead className="bg-slate-50 text-slate-600">
                  <tr>
                    <th className="text-left px-4 py-3">
                      GPID
                    </th>

                    <th className="text-left px-4 py-3">
                      Reference ID
                    </th>

                    <th className="text-left px-4 py-3">
                      Applicant
                    </th>

                    <th className="text-left px-4 py-3">
                      Mobile
                    </th>

                    <th className="text-left px-4 py-3">
                      Association / Mandal
                    </th>

                    <th className="text-left px-4 py-3">
                      Police Station
                    </th>

                    <th className="text-left px-4 py-3">
                      Status
                    </th>
                  </tr>
                </thead>

                <tbody>
                  {searchResults.map(
                    (record) => (
                      <tr
                        key={String(
                          record.unique_id ?? "",
                        )}
                        className="border-t border-slate-100 hover:bg-slate-50"
                      >
                        <td className="px-4 py-4 whitespace-nowrap">
                          {record.unique_id ? (
                            <button
                              onClick={() =>
                                openGpid(
                                  record.unique_id,
                                )
                              }
                              className="font-bold text-[#17365D] hover:text-blue-700 hover:underline"
                            >
                              {record.unique_id}
                            </button>
                          ) : (
                            "-"
                          )}
                        </td>

                        <td className="px-4 py-4 whitespace-nowrap">
                          {record.ref_no || "-"}
                        </td>

                        <td className="px-4 py-4">
                          {record.name || "-"}
                        </td>

                        <td className="px-4 py-4 whitespace-nowrap">
                          {record.mobile_no || "-"}
                        </td>

                        <td className="px-4 py-4">
                          {record.association || "-"}
                        </td>

                        <td className="px-4 py-4 whitespace-nowrap">
                          {record.ps_name || "-"}
                        </td>

                        <td className="px-4 py-4">
                          <span
                            className={`inline-flex rounded-full border px-3 py-1 text-xs font-semibold ${getStatusClassName(
                              record.status,
                            )}`}
                          >
                            {record.status || "-"}
                          </span>
                        </td>
                      </tr>
                    ),
                  )}

                  {searchResults.length ===
                    0 && (
                    <tr>
                      <td
                        colSpan={7}
                        className="px-5 py-8 text-center text-slate-500"
                      >
                        No matching Ganesh application found.
                      </td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>
          )}

          {searchResults.length ===
            100 && (
            <p className="text-xs text-amber-700 mt-3">
              Showing first 100 matches. Refine the search for more precise results.
            </p>
          )}
        </section>

        <section className="bg-white rounded-xl border border-slate-200 shadow-sm mb-8 overflow-hidden">
          <div className="px-5 py-4 border-b border-slate-200">
            <h2 className="text-xl font-bold text-slate-800">
              Hyderabad Commissionerate
            </h2>

            <p className="text-sm text-slate-500 mt-1">
              Click a Range to view its Zones
            </p>
          </div>

          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead className="bg-slate-50 text-slate-600">
                <tr>
                  <th className="text-left px-5 py-3">
                    Range
                  </th>

                  <th className="text-right px-5 py-3">
                    Zones
                  </th>

                  <th className="text-right px-5 py-3">
                    Divisions
                  </th>

                  <th className="text-right px-5 py-3">
                    Police Stations
                  </th>

                  <th className="text-right px-5 py-3">
                    GPIDs
                  </th>
                </tr>
              </thead>

              <tbody>
                {rangeSummary.map(
                  (range) => (
                    <tr
                      key={range.rangeName}
                      onClick={() => {
                        setSelectedRange(
                          range.rangeName,
                        );

                        setSelectedZone(null);
                        setSelectedDivision(null);
                        setSelectedPoliceStation(
                          null,
                        );
                      }}
                      className={`border-t border-slate-100 cursor-pointer transition ${
                        selectedRange ===
                        range.rangeName
                          ? "bg-indigo-50"
                          : "hover:bg-slate-50"
                      }`}
                    >
                      <td className="px-5 py-4 font-semibold text-[#17365D]">
                        {range.rangeName}
                      </td>

                      <td className="px-5 py-4 text-right">
                        {range.zoneCount}
                      </td>

                      <td className="px-5 py-4 text-right">
                        {range.divisionCount}
                      </td>

                      <td className="px-5 py-4 text-right">
                        {range.policeStationCount}
                      </td>

                      <td className="px-5 py-4 text-right font-bold text-[#17365D]">
                        {range.gpidCount.toLocaleString(
                          "en-IN",
                        )}
                      </td>
                    </tr>
                  ),
                )}

                {loadingGpids && (
                  <tr>
                    <td
                      colSpan={5}
                      className="px-5 py-8 text-center text-slate-500"
                    >
                      Loading live GPID data...
                    </td>
                  </tr>
                )}
              </tbody>

              {!loadingGpids && (
                <tfoot className="bg-[#17365D] text-white">
                  <tr>
                    <td className="px-5 py-4 font-bold">
                      TOTAL
                    </td>

                    <td className="px-5 py-4 text-right font-bold">
                      {summary.totalZones}
                    </td>

                    <td className="px-5 py-4 text-right font-bold">
                      {summary.totalDivisions}
                    </td>

                    <td className="px-5 py-4 text-right font-bold">
                      {summary.totalPoliceStations}
                    </td>

                    <td className="px-5 py-4 text-right text-lg font-bold">
                      {summary.totalGpids.toLocaleString(
                        "en-IN",
                      )}
                    </td>
                  </tr>
                </tfoot>
              )}
            </table>
          </div>
        </section>

        {selectedRange && (
          <section className="bg-white rounded-xl border border-indigo-200 shadow-sm mb-8 overflow-hidden">
            <div className="px-5 py-4 bg-indigo-50 border-b border-indigo-200 flex items-center justify-between">
              <div>
                <p className="text-xs font-semibold text-indigo-700 uppercase tracking-wide">
                  Selected Range
                </p>

                <h2 className="text-xl font-bold text-[#17365D]">
                  {selectedRange}
                </h2>

                <p className="text-sm text-slate-500 mt-1">
                  Click a Zone to view its Divisions
                </p>
              </div>

              <button
                onClick={() => {
                  setSelectedRange(null);
                  setSelectedZone(null);
                  setSelectedDivision(null);
                  setSelectedPoliceStation(
                    null,
                  );
                }}
                className="px-4 py-2 rounded-lg border border-slate-300 bg-white text-sm font-semibold text-slate-600 hover:bg-slate-50"
              >
                Close
              </button>
            </div>

            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead className="bg-slate-50 text-slate-600">
                  <tr>
                    <th className="text-left px-5 py-3">
                      Zone
                    </th>

                    <th className="text-right px-5 py-3">
                      Divisions
                    </th>

                    <th className="text-right px-5 py-3">
                      Police Stations
                    </th>

                    <th className="text-right px-5 py-3">
                      GPIDs
                    </th>
                  </tr>
                </thead>

                <tbody>
                  {zoneSummary.map(
                    (zone) => (
                      <tr
                        key={zone.zoneName}
                        onClick={() => {
                          setSelectedZone(
                            zone.zoneName,
                          );

                          setSelectedDivision(
                            null,
                          );

                          setSelectedPoliceStation(
                            null,
                          );
                        }}
                        className={`border-t border-slate-100 cursor-pointer transition ${
                          selectedZone ===
                          zone.zoneName
                            ? "bg-blue-50"
                            : "hover:bg-slate-50"
                        }`}
                      >
                        <td className="px-5 py-4 font-semibold text-[#17365D]">
                          {zone.zoneName}
                        </td>

                        <td className="px-5 py-4 text-right">
                          {zone.divisionCount}
                        </td>

                        <td className="px-5 py-4 text-right">
                          {zone.policeStationCount}
                        </td>

                        <td className="px-5 py-4 text-right font-bold text-[#17365D]">
                          {zone.gpidCount.toLocaleString(
                            "en-IN",
                          )}
                        </td>
                      </tr>
                    ),
                  )}
                </tbody>

                <tfoot className="bg-slate-100">
                  <tr>
                    <td className="px-5 py-4 font-bold text-slate-800">
                      TOTAL
                    </td>

                    <td className="px-5 py-4 text-right font-bold">
                      {selectedRangeSummary
                        ?.divisionCount ?? 0}
                    </td>

                    <td className="px-5 py-4 text-right font-bold">
                      {selectedRangeSummary
                        ?.policeStationCount ??
                        0}
                    </td>

                    <td className="px-5 py-4 text-right font-bold text-[#17365D]">
                      {(
                        selectedRangeSummary
                          ?.gpidCount ?? 0
                      ).toLocaleString(
                        "en-IN",
                      )}
                    </td>
                  </tr>
                </tfoot>
              </table>
            </div>
          </section>
        )}

        {selectedZone && (
          <section className="bg-white rounded-xl border border-blue-200 shadow-sm mb-8 overflow-hidden">
            <div className="px-5 py-4 bg-blue-50 border-b border-blue-200 flex items-center justify-between">
              <div>
                <p className="text-xs font-semibold text-blue-600 uppercase tracking-wide">
                  Selected Zone
                </p>

                <h2 className="text-xl font-bold text-[#17365D]">
                  {selectedZone} Zone
                </h2>

                <p className="text-sm text-slate-500 mt-1">
                  Click a Division to view its Police Stations
                </p>
              </div>

              <button
                onClick={() => {
                  setSelectedZone(null);
                  setSelectedDivision(null);
                  setSelectedPoliceStation(
                    null,
                  );
                }}
                className="px-4 py-2 rounded-lg border border-slate-300 bg-white text-sm font-semibold text-slate-600 hover:bg-slate-50"
              >
                Close
              </button>
            </div>

            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead className="bg-slate-50 text-slate-600">
                  <tr>
                    <th className="text-left px-5 py-3">
                      Division
                    </th>

                    <th className="text-right px-5 py-3">
                      Police Stations
                    </th>

                    <th className="text-right px-5 py-3">
                      GPIDs
                    </th>
                  </tr>
                </thead>

                <tbody>
                  {divisionSummary.map(
                    (division) => (
                      <tr
                        key={
                          division.divisionName
                        }
                        onClick={() => {
                          setSelectedDivision(
                            division.divisionName,
                          );

                          setSelectedPoliceStation(
                            null,
                          );
                        }}
                        className={`border-t border-slate-100 cursor-pointer transition ${
                          selectedDivision ===
                          division.divisionName
                            ? "bg-emerald-50"
                            : "hover:bg-slate-50"
                        }`}
                      >
                        <td className="px-5 py-4 font-semibold text-[#17365D]">
                          {division.divisionName}
                        </td>

                        <td className="px-5 py-4 text-right">
                          {division.policeStationCount}
                        </td>

                        <td className="px-5 py-4 text-right font-bold text-[#17365D]">
                          {division.gpidCount.toLocaleString(
                            "en-IN",
                          )}
                        </td>
                      </tr>
                    ),
                  )}
                </tbody>

                <tfoot className="bg-slate-100">
                  <tr>
                    <td className="px-5 py-4 font-bold text-slate-800">
                      TOTAL
                    </td>

                    <td className="px-5 py-4 text-right font-bold">
                      {selectedZonePoliceStationCount}
                    </td>

                    <td className="px-5 py-4 text-right font-bold text-[#17365D]">
                      {selectedZoneGpidCount.toLocaleString(
                        "en-IN",
                      )}
                    </td>
                  </tr>
                </tfoot>
              </table>
            </div>
          </section>
        )}

        {selectedZone &&
          selectedDivision && (
            <section className="bg-white rounded-xl border border-emerald-200 shadow-sm mb-8 overflow-hidden">
              <div className="px-5 py-4 bg-emerald-50 border-b border-emerald-200 flex items-center justify-between">
                <div>
                  <p className="text-xs font-semibold text-emerald-700 uppercase tracking-wide">
                    Selected Division
                  </p>

                  <h2 className="text-xl font-bold text-slate-800">
                    {selectedDivision} Division
                  </h2>

                  <p className="text-sm text-slate-500 mt-1">
                    Click a Police Station to view its GPIDs
                  </p>
                </div>

                <button
                  onClick={() => {
                    setSelectedDivision(
                      null,
                    );

                    setSelectedPoliceStation(
                      null,
                    );
                  }}
                  className="px-4 py-2 rounded-lg border border-slate-300 bg-white text-sm font-semibold text-slate-600 hover:bg-slate-50"
                >
                  Close
                </button>
              </div>

              <div className="overflow-x-auto">
                <table className="w-full text-sm">
                  <thead className="bg-slate-50 text-slate-600">
                    <tr>
                      <th className="text-left px-5 py-3">
                        Police Station
                      </th>

                      <th className="text-right px-5 py-3">
                        GPIDs
                      </th>
                    </tr>
                  </thead>

                  <tbody>
                    {policeStationSummary.map(
                      (
                        policeStation,
                      ) => (
                        <tr
                          key={
                            policeStation.policeStationName
                          }
                          onClick={() =>
                            setSelectedPoliceStation(
                              policeStation.policeStationName,
                            )
                          }
                          className={`border-t border-slate-100 cursor-pointer transition ${
                            selectedPoliceStation ===
                            policeStation.policeStationName
                              ? "bg-amber-50"
                              : "hover:bg-slate-50"
                          }`}
                        >
                          <td className="px-5 py-4 font-semibold text-[#17365D]">
                            {policeStation.policeStationName}
                          </td>

                          <td className="px-5 py-4 text-right font-bold text-[#17365D]">
                            {policeStation.gpidCount.toLocaleString(
                              "en-IN",
                            )}
                          </td>
                        </tr>
                      ),
                    )}
                  </tbody>

                  <tfoot className="bg-slate-100">
                    <tr>
                      <td className="px-5 py-4 font-bold text-slate-800">
                        TOTAL
                      </td>

                      <td className="px-5 py-4 text-right font-bold text-[#17365D]">
                        {selectedDivisionGpidCount.toLocaleString(
                          "en-IN",
                        )}
                      </td>
                    </tr>
                  </tfoot>
                </table>
              </div>
            </section>
          )}

        {selectedZone &&
          selectedDivision &&
          selectedPoliceStation && (
            <section className="bg-white rounded-xl border border-amber-200 shadow-sm mb-10 overflow-hidden">
              <div className="px-5 py-4 bg-amber-50 border-b border-amber-200 flex items-center justify-between">
                <div>
                  <p className="text-xs font-semibold text-amber-700 uppercase tracking-wide">
                    Selected Police Station
                  </p>

                  <h2 className="text-xl font-bold text-slate-800">
                    {selectedPoliceStation} Police Station
                  </h2>

                  <p className="text-sm text-slate-500 mt-1">
                    {
                      selectedPoliceStationRecords.length
                    }{" "}
                    GPIDs
                  </p>
                </div>

                <button
                  onClick={() =>
                    setSelectedPoliceStation(
                      null,
                    )
                  }
                  className="px-4 py-2 rounded-lg border border-slate-300 bg-white text-sm font-semibold text-slate-600 hover:bg-slate-50"
                >
                  Close
                </button>
              </div>

              <div className="overflow-x-auto">
                <table className="w-full text-sm min-w-[1200px]">
                  <thead className="bg-slate-50 text-slate-600">
                    <tr>
                      <th className="text-left px-4 py-3">
                        GPID
                      </th>

                      <th className="text-left px-4 py-3">
                        Association / Mandal
                      </th>

                      <th className="text-left px-4 py-3">
                        Applicant
                      </th>

                      <th className="text-left px-4 py-3">
                        Idol Type
                      </th>

                      <th className="text-right px-4 py-3">
                        Idol Height
                      </th>

                      <th className="text-left px-4 py-3">
                        Area Category
                      </th>

                      <th className="text-left px-4 py-3">
                        Installation Date
                      </th>

                      <th className="text-left px-4 py-3">
                        Immersion Date
                      </th>

                      <th className="text-left px-4 py-3">
                        Status
                      </th>
                    </tr>
                  </thead>

                  <tbody>
                    {selectedPoliceStationRecords.map(
                      (record) => (
                        <tr
                          key={String(
                            record.unique_id ?? "",
                          )}
                          className="border-t border-slate-100 hover:bg-slate-50"
                        >
                          <td className="px-4 py-4 whitespace-nowrap">
                            {record.unique_id ? (
                              <button
                                onClick={() =>
                                  openGpid(
                                    record.unique_id,
                                  )
                                }
                                className="font-bold text-[#17365D] hover:text-blue-700 hover:underline"
                              >
                                {record.unique_id}
                              </button>
                            ) : (
                              "-"
                            )}
                          </td>

                          <td className="px-4 py-4">
                            {record.association ||
                              "-"}
                          </td>

                          <td className="px-4 py-4">
                            {record.name || "-"}
                          </td>

                          <td className="px-4 py-4">
                            {record.idol_type ||
                              "-"}
                          </td>

                          <td className="px-4 py-4 text-right whitespace-nowrap">
                            {record.idol_height
                              ? `${record.idol_height} ft`
                              : "-"}
                          </td>

                          <td className="px-4 py-4 whitespace-nowrap">
                            {record.idol_area_type ||
                              "-"}
                          </td>

                          <td className="px-4 py-4 whitespace-nowrap">
                            {record.instal_from_date ||
                              "-"}
                          </td>

                          <td className="px-4 py-4 whitespace-nowrap">
                            {record.immr_date ||
                              record.instal_to_date ||
                              "-"}
                          </td>

                          <td className="px-4 py-4">
                            <span
                              className={`inline-flex rounded-full border px-3 py-1 text-xs font-semibold ${getStatusClassName(
                                record.status,
                              )}`}
                            >
                              {record.status ||
                                "-"}
                            </span>
                          </td>
                        </tr>
                      ),
                    )}

                    {selectedPoliceStationRecords.length ===
                      0 && (
                      <tr>
                        <td
                          colSpan={9}
                          className="px-5 py-8 text-center text-slate-500"
                        >
                          No GPIDs found for this Police Station.
                        </td>
                      </tr>
                    )}
                  </tbody>

                  <tfoot className="bg-slate-100">
                    <tr>
                      <td
                        colSpan={8}
                        className="px-4 py-4 font-bold text-slate-800"
                      >
                        TOTAL GPIDs
                      </td>

                      <td className="px-4 py-4 font-bold text-right text-[#17365D]">
                        {
                          selectedPoliceStationRecords.length
                        }
                      </td>
                    </tr>
                  </tfoot>
                </table>
              </div>
            </section>
          )}

        <div className="flex items-center justify-between mb-4">
          <h2 className="text-2xl font-bold text-slate-800">
            Festival Stages
          </h2>
        </div>

        <section className="space-y-3">
          {stages.map(
            (stage) => (
              <button
                key={stage.number}
                onClick={() => {
                  if (
                    stage.number === 1
                  ) {
                    router.push(
                      "/pre-installation",
                    );
                  }
                }}
                className={`w-full text-left bg-white border rounded-xl px-5 py-5 flex items-center justify-between transition ${
                  stage.active
                    ? "border-blue-300 hover:border-blue-500 cursor-pointer"
                    : "border-slate-200 cursor-default"
                }`}
              >
                <div className="flex items-center gap-4">
                  <div
                    className={`w-10 h-10 rounded-full flex items-center justify-center font-bold ${
                      stage.active
                        ? "bg-[#17365D] text-white"
                        : "bg-slate-200 text-slate-500"
                    }`}
                  >
                    {stage.number}
                  </div>

                  <div>
                    <p className="font-bold text-slate-800">
                      {stage.name}
                    </p>

                    <p
                      className={`text-sm ${
                        stage.active
                          ? "text-green-600"
                          : "text-slate-400"
                      }`}
                    >
                      {stage.status}
                    </p>
                  </div>
                </div>

                {stage.active && (
                  <span className="text-[#17365D] font-semibold">
                    Open →
                  </span>
                )}
              </button>
            ),
          )}
        </section>
      </div>
    </main>
  );
}