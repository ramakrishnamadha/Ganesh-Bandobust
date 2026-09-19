"use client";

import Link from "next/link";
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
  getHierarchyForZone,
} from "@/lib/hierarchy/ganeshHierarchy";

type PoliceStationAccess = {
  id?: string;
  policeStationCode: string | null;
  policeStationName: string;
  canView: boolean;
  canEdit: boolean;
};

type AdminUser = {
  id: string;
  employeeId: string;
  username: string;
  name: string;
  rank: string;
  phoneNumber: string | null;
  team: string | null;
  role: string;
  accessLevel: number;
  commissionerateCode: string | null;
  commissionerateName: string | null;
  rangeCode: string | null;
  rangeName: string | null;
  zoneCode: string | null;
  zoneName: string | null;
  divisionCode: string | null;
  divisionName: string | null;
  policeStationCode: string | null;
  policeStationName: string | null;
  sectorCode: string | null;
  sectorName: string | null;
  allPoliceStations: boolean;
  allDivisions: boolean;
  allZones: boolean;
  allRanges: boolean;
  status: string;
  mustChangePassword: boolean;
  policeStationAccesses: PoliceStationAccess[];
};

type SummaryCards = {
  totalUsers: number;
  activeUsers: number;
  inactiveUsers: number;
  fieldOfficers: number;
  sectorIncharges: number;
  psSupervisors: number;
  divisionalSupervisors: number;
  zonalSupervisors: number;
  rangeSupervisors: number;
  admins: number;
};

type UserDraft = {
  role: string;
  accessLevel: number;
  rangeName: string;
  zoneName: string;
  divisionName: string;
  policeStationName: string;
  sectorName: string;
  status: string;
};

function text(value: unknown): string {
  if (
    value === null ||
    value === undefined
  ) {
    return "";
  }
  return String(value).trim();
}

function getErrorMessage(
  value: unknown,
): string {
  if (
    typeof value !== "object" ||
    value === null ||
    !("error" in value)
  ) {
    return "";
  }
  return text(
    (value as { error?: unknown })
      .error,
  );
}

const ROLE_OPTIONS = [
  {
    value: "FIELD_OFFICER",
    label: "Field Officer",
    level: 1,
    desc: "Field officer access within assigned PS/Sector",
  },
  {
    value: "SECTOR_INCHARGE",
    label: "Sector In-charge",
    level: 2,
    desc: "Assigned sector and all GPIDs in sector",
  },
  {
    value: "PS_SUPERVISOR",
    label: "PS Supervisor",
    level: 3,
    desc: "Assigned Police Station and all sectors under PS",
  },
  {
    value: "SHO",
    label: "SHO",
    level: 3,
    desc: "Station House Officer - Full PS jurisdiction",
  },
  {
    value: "DIVISIONAL_SUPERVISOR",
    label: "Divisional Supervisor",
    level: 4,
    desc: "Assigned Division and all PSs under Division",
  },
  {
    value: "ZONAL_SUPERVISOR",
    label: "Zonal Supervisor",
    level: 5,
    desc: "Assigned Zone and all Divisions/PSs under Zone",
  },
  {
    value: "RANGE_SUPERVISOR",
    label: "Range Supervisor",
    level: 6,
    desc: "Assigned Range and all Zones/Divisions/PSs under Range",
  },
  {
    value: "ADMIN",
    label: "Administrator",
    level: 7,
    desc: "Commissionerate-wide full administration access",
  },
];

export default function SettingsPage() {
  const [activeTab, setActiveTab] =
    useState<
      "directory" | "assignment"
    >("directory");

  const [users, setUsers] = useState<
    AdminUser[]
  >([]);
  const [
    summaryCards,
    setSummaryCards,
  ] = useState<SummaryCards | null>(
    null,
  );
  const [
    loadingUsers,
    setLoadingUsers,
  ] = useState(true);
  const [saving, setSaving] =
    useState(false);

  const [error, setError] =
    useState("");
  const [success, setSuccess] =
    useState("");

  // Filters
  const [
    selectedWing,
    setSelectedWing,
  ] = useState("L & O");
  const [
    selectedRangeFilter,
    setSelectedRangeFilter,
  ] = useState("");
  const [
    selectedZoneFilter,
    setSelectedZoneFilter,
  ] = useState("");
  const [
    selectedDivisionFilter,
    setSelectedDivisionFilter,
  ] = useState("");
  const [
    selectedPsFilter,
    setSelectedPsFilter,
  ] = useState("");
  const [
    selectedRankFilter,
    setSelectedRankFilter,
  ] = useState("");
  const [
    selectedRoleFilter,
    setSelectedRoleFilter,
  ] = useState("");
  const [
    selectedStatusFilter,
    setSelectedStatusFilter,
  ] = useState("");
  const [searchText, setSearchText] =
    useState("");

  // Pagination
  const [currentPage, setCurrentPage] =
    useState(1);
  const [pageSize, setPageSize] =
    useState(50);

  // Selection for bulk assignment
  const [
    selectedUserIds,
    setSelectedUserIds,
  ] = useState<Set<string>>(new Set());

  // Role Configurator Draft (For single user editing or bulk assignment)
  const [
    singleUserId,
    setSingleUserId,
  ] = useState<string | null>(null);
  const [draft, setDraft] =
    useState<UserDraft>({
      role: "FIELD_OFFICER",
      accessLevel: 1,
      rangeName: "",
      zoneName: "",
      divisionName: "",
      policeStationName: "",
      sectorName: "",
      status: "ACTIVE",
    });

  // Modal State for confirmation
  const [
    showConfirmModal,
    setShowConfirmModal,
  ] = useState(false);

  const loadUsers = async () => {
    setLoadingUsers(true);
    setError("");

    try {
      const response = await fetch(
        "/api/admin/users",
        {
          method: "GET",
          cache: "no-store",
          credentials: "include",
        },
      );

      const body: unknown =
        await response
          .json()
          .catch(() => null);

      if (!response.ok) {
        throw new Error(
          getErrorMessage(body) ||
            "Unable to load users.",
        );
      }

      if (
        typeof body !== "object" ||
        body === null ||
        !("users" in body) ||
        !Array.isArray(
          (
            body as {
              users?: unknown;
            }
          ).users,
        )
      ) {
        throw new Error(
          "Unexpected users response.",
        );
      }

      const loadedUsers = (
        body as {
          users: AdminUser[];
          summaryCards?: SummaryCards;
        }
      ).users;
      const cards =
        (
          body as {
            summaryCards?: SummaryCards;
          }
        ).summaryCards || null;

      setUsers(loadedUsers);
      setSummaryCards(cards);
    } catch (loadError) {
      console.error(
        "Settings user load error:",
        loadError,
      );
      setError(
        loadError instanceof Error
          ? loadError.message
          : "Unable to load users.",
      );
    } finally {
      setLoadingUsers(false);
    }
  };

  useEffect(() => {
    void loadUsers();
  }, []);

  // Cascading options using authoritative GANESH_HIERARCHY
  const rangeOptions = useMemo(
    () => getRanges(),
    [],
  );
  const zoneOptions = useMemo(
    () =>
      getZones(
        selectedRangeFilter ||
          undefined,
      ),
    [selectedRangeFilter],
  );
  const divisionOptions = useMemo(
    () =>
      getDivisions(
        selectedRangeFilter ||
          undefined,
        selectedZoneFilter || undefined,
      ),
    [
      selectedRangeFilter,
      selectedZoneFilter,
    ],
  );
  const policeStationOptions = useMemo(
    () =>
      getPoliceStations(
        selectedRangeFilter ||
          undefined,
        selectedZoneFilter || undefined,
        selectedDivisionFilter ||
          undefined,
      ),
    [
      selectedRangeFilter,
      selectedZoneFilter,
      selectedDivisionFilter,
    ],
  );

  const rankOptions = useMemo(() => {
    return Array.from(
      new Set(
        users
          .map((u) => text(u.rank))
          .filter(Boolean),
      ),
    ).sort();
  }, [users]);

  // Filtering
  const filteredUsers = useMemo(() => {
    return users.filter((u) => {
      if (
        selectedRangeFilter &&
        text(u.rangeName) !==
          selectedRangeFilter
      )
        return false;
      if (
        selectedZoneFilter &&
        text(u.zoneName) !==
          selectedZoneFilter
      )
        return false;
      if (
        selectedDivisionFilter &&
        text(u.divisionName) !==
          selectedDivisionFilter
      )
        return false;
      if (
        selectedPsFilter &&
        text(u.policeStationName) !==
          selectedPsFilter
      )
        return false;
      if (
        selectedRankFilter &&
        text(u.rank) !==
          selectedRankFilter
      )
        return false;
      if (
        selectedRoleFilter &&
        text(u.role) !==
          selectedRoleFilter
      )
        return false;
      if (
        selectedStatusFilter &&
        text(u.status) !==
          selectedStatusFilter
      )
        return false;

      if (searchText.trim()) {
        const query = searchText
          .trim()
          .toLowerCase();
        const haystack = [
          u.name,
          u.rank,
          u.employeeId,
          u.username,
          u.phoneNumber,
          u.role,
          u.rangeName,
          u.zoneName,
          u.divisionName,
          u.policeStationName,
          u.sectorName,
        ]
          .map((v) =>
            text(v).toLowerCase(),
          )
          .join(" ");

        if (!haystack.includes(query))
          return false;
      }

      return true;
    });
  }, [
    users,
    selectedRangeFilter,
    selectedZoneFilter,
    selectedDivisionFilter,
    selectedPsFilter,
    selectedRankFilter,
    selectedRoleFilter,
    selectedStatusFilter,
    searchText,
  ]);

  // Reset page when filter changes
  useEffect(() => {
    setCurrentPage(1);
  }, [
    selectedRangeFilter,
    selectedZoneFilter,
    selectedDivisionFilter,
    selectedPsFilter,
    selectedRankFilter,
    selectedRoleFilter,
    selectedStatusFilter,
    searchText,
  ]);

  // Pagination slice
  const totalPages =
    Math.ceil(
      filteredUsers.length / pageSize,
    ) || 1;
  const paginatedUsers = useMemo(() => {
    const start =
      (currentPage - 1) * pageSize;
    return filteredUsers.slice(
      start,
      start + pageSize,
    );
  }, [
    filteredUsers,
    currentPage,
    pageSize,
  ]);

  // Selection handlers
  const toggleSelectUser = (
    id: string,
  ) => {
    setSelectedUserIds((prev) => {
      const next = new Set(prev);
      if (next.has(id)) {
        next.delete(id);
      } else {
        next.add(id);
      }
      return next;
    });
  };

  const selectAllFiltered = () => {
    const allFilteredIds =
      filteredUsers.map((u) => u.id);
    setSelectedUserIds(
      new Set(allFilteredIds),
    );
  };

  const clearSelection = () => {
    setSelectedUserIds(new Set());
  };

  // Automated parent hierarchy preview helper for Draft
  const resolvedHierarchyPreview =
    useMemo(() => {
      const ps = text(
        draft.policeStationName,
      );
      const div = text(
        draft.divisionName,
      );
      const z = text(draft.zoneName);
      const r = text(draft.rangeName);

      let resRange = r;
      let resZone = z;
      let resDiv = div;
      let resPs = ps;

      if (ps) {
        const match =
          getHierarchyForPoliceStation(
            ps,
          );
        if (match) {
          resRange = match.range;
          resZone = match.zone;
          resDiv = match.division;
        }
      } else if (div) {
        // Find matching division in ganesh hierarchy
        const divMatch =
          getPoliceStations(
            undefined,
            undefined,
            div,
          );
        if (divMatch.length > 0) {
          const match =
            getHierarchyForPoliceStation(
              divMatch[0],
            );
          if (match) {
            resRange = match.range;
            resZone = match.zone;
          }
        }
      } else if (z) {
        const match =
          getHierarchyForZone(z);
        if (match) {
          resRange = match.range;
        }
      }

      const parts = [
        resRange
          ? `${resRange}`
          : "Range: Not Selected",
        resZone
          ? `${resZone}`
          : "Zone: Not Selected",
        resDiv
          ? `${resDiv}`
          : "Division: Not Selected",
        resPs
          ? `${resPs}`
          : "PS: Not Selected",
      ];

      return parts.join(" → ");
    }, [
      draft.rangeName,
      draft.zoneName,
      draft.divisionName,
      draft.policeStationName,
    ]);

  // Role change handler in draft
  const handleRoleChange = (
    newRole: string,
  ) => {
    const found = ROLE_OPTIONS.find(
      (r) => r.value === newRole,
    );
    setDraft((prev) => ({
      ...prev,
      role: newRole,
      accessLevel: found
        ? found.level
        : 1,
    }));
  };

  // Open assignment editor for single user
  const openSingleUserEdit = (
    user: AdminUser,
  ) => {
    setSingleUserId(user.id);
    setDraft({
      role:
        text(user.role) ||
        "FIELD_OFFICER",
      accessLevel:
        user.accessLevel ?? 1,
      rangeName: text(user.rangeName),
      zoneName: text(user.zoneName),
      divisionName: text(
        user.divisionName,
      ),
      policeStationName: text(
        user.policeStationName,
      ),
      sectorName: text(user.sectorName),
      status:
        text(user.status) || "ACTIVE",
    });
    setActiveTab("assignment");
  };

  // Open assignment editor for bulk selection
  const openBulkAssignment = () => {
    if (selectedUserIds.size === 0) {
      setError(
        "Please select at least one officer from the table.",
      );
      return;
    }
    setSingleUserId(null); // Bulk mode
    setActiveTab("assignment");
  };

  // Submit save single or bulk
  const executeSave = async () => {
    setShowConfirmModal(false);
    setSaving(true);
    setError("");
    setSuccess("");

    try {
      if (singleUserId) {
        // Single user patch
        const response = await fetch(
          "/api/admin/users",
          {
            method: "PATCH",
            headers: {
              "Content-Type":
                "application/json",
            },
            body: JSON.stringify({
              userId: singleUserId,
              role: draft.role,
              accessLevel:
                draft.accessLevel,
              rangeName:
                draft.rangeName || null,
              zoneName:
                draft.zoneName || null,
              divisionName:
                draft.divisionName ||
                null,
              policeStationName:
                draft.policeStationName ||
                null,
              sectorName:
                draft.sectorName ||
                null,
              status: draft.status,
            }),
          },
        );

        const resBody =
          await response.json();
        if (!response.ok) {
          throw new Error(
            getErrorMessage(resBody) ||
              "Failed to update user role.",
          );
        }

        setSuccess(
          "User role and scope updated successfully!",
        );
      } else {
        // Bulk assignment
        const response = await fetch(
          "/api/admin/users/bulk-assign",
          {
            method: "POST",
            headers: {
              "Content-Type":
                "application/json",
            },
            body: JSON.stringify({
              userIds: Array.from(
                selectedUserIds,
              ),
              role: draft.role,
              rangeName:
                draft.rangeName || null,
              zoneName:
                draft.zoneName || null,
              divisionName:
                draft.divisionName ||
                null,
              policeStationName:
                draft.policeStationName ||
                null,
              sectorName:
                draft.sectorName ||
                null,
            }),
          },
        );

        const resBody =
          await response.json();
        if (!response.ok) {
          throw new Error(
            getErrorMessage(resBody) ||
              "Failed to execute bulk assignment.",
          );
        }

        setSuccess(
          `Successfully updated ${resBody.updatedCount} officers to ${draft.role}!`,
        );
        clearSelection();
      }

      await loadUsers();
      setActiveTab("directory");
    } catch (saveError) {
      console.error(
        "Save role error:",
        saveError,
      );
      setError(
        saveError instanceof Error
          ? saveError.message
          : "Unable to save role assignment.",
      );
    } finally {
      setSaving(false);
    }
  };

  return (
    <main className="min-h-screen bg-slate-100 p-4 sm:p-6 lg:p-8">
      <div className="mx-auto max-w-7xl">
        {/* HEADER */}
        <div className="mb-6 flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
          <div>
            <p className="text-xs font-bold uppercase tracking-wider text-slate-400">
              Settings & Administration
            </p>
            <h1 className="mt-1 text-2xl font-black tracking-tight text-slate-800">
              User Management & Role
              Assignment
            </h1>
            <p className="mt-1 text-sm text-slate-500">
              Authoritative user
              directory, supervisory
              jurisdiction mapping, and
              transactional role
              assignment.
            </p>
          </div>

          {/* PRINCIPAL ADMIN NAVIGATION CARDS */}
          <div className="flex flex-wrap items-center gap-3">
            <Link
              href="/dashboard/settings/wings"
              className="inline-flex items-center gap-2 rounded-xl bg-gradient-to-r from-slate-800 to-slate-900 border border-slate-700 px-5 py-3 text-xs md:text-sm font-extrabold text-white shadow-md hover:border-blue-500 transition ring-1 ring-slate-700 hover:ring-blue-400"
            >
              <span>🏛️</span> 1. ADD WINGS & HIERARCHY →
            </Link>

            <Link
              href="/dashboard/settings/role-allotment"
              className="inline-flex items-center gap-2 rounded-xl bg-gradient-to-r from-blue-700 to-indigo-700 px-5 py-3 text-xs md:text-sm font-extrabold text-white shadow-lg shadow-blue-900/30 hover:from-blue-600 hover:to-indigo-600 transition ring-2 ring-blue-400"
            >
              <span>👮</span> 2. ROLE ALLOTMENT →
            </Link>

            <button
              type="button"
              onClick={() =>
                setActiveTab(
                  "directory",
                )
              }
              className={`rounded-xl px-5 py-2.5 text-sm font-bold transition ${
                activeTab ===
                "directory"
                  ? "bg-[#17365D] text-white shadow-md shadow-blue-900/20"
                  : "border border-slate-300 bg-white text-slate-700 hover:bg-slate-50"
              }`}
            >
              User Directory
            </button>
            <button
              type="button"
              onClick={() =>
                setActiveTab(
                  "assignment",
                )
              }
              className={`rounded-xl px-5 py-2.5 text-sm font-bold transition ${
                activeTab ===
                "assignment"
                  ? "bg-[#17365D] text-white shadow-md shadow-blue-900/20"
                  : "border border-slate-300 bg-white text-slate-700 hover:bg-slate-50"
              }`}
            >
              Role & Scope Configurator
              {selectedUserIds.size >
                0 && (
                <span className="ml-2 rounded-full bg-cyan-500 px-2 py-0.5 text-xs text-white">
                  {selectedUserIds.size}
                </span>
              )}
            </button>
          </div>
        </div>

        {/* FEEDBACK BANNERS */}
        {error && (
          <div className="mb-6 rounded-xl border border-red-200 bg-red-50 p-4 text-sm font-semibold text-red-700 shadow-sm">
            {error}
          </div>
        )}
        {success && (
          <div className="mb-6 rounded-xl border border-emerald-200 bg-emerald-50 p-4 text-sm font-semibold text-emerald-800 shadow-sm">
            {success}
          </div>
        )}

        {/* DYNAMIC SUMMARY CARDS */}
        {summaryCards && (
          <section className="mb-8 grid gap-3 sm:grid-cols-2 lg:grid-cols-5">
            <div className="rounded-2xl border border-slate-200 bg-white p-4 shadow-sm">
              <p className="text-xs font-bold uppercase tracking-wider text-slate-400">
                Total Users
              </p>
              <p className="mt-2 text-2xl font-black text-[#17365D]">
                {summaryCards.totalUsers.toLocaleString(
                  "en-IN",
                )}
              </p>
            </div>
            <div className="rounded-2xl border border-emerald-200 bg-emerald-50/50 p-4 shadow-sm">
              <p className="text-xs font-bold uppercase tracking-wider text-emerald-600">
                Active Users
              </p>
              <p className="mt-2 text-2xl font-black text-emerald-800">
                {summaryCards.activeUsers.toLocaleString(
                  "en-IN",
                )}
              </p>
            </div>
            <div className="rounded-2xl border border-slate-200 bg-white p-4 shadow-sm">
              <p className="text-xs font-bold uppercase tracking-wider text-slate-400">
                Field Officers
              </p>
              <p className="mt-2 text-2xl font-black text-slate-700">
                {summaryCards.fieldOfficers.toLocaleString(
                  "en-IN",
                )}
              </p>
            </div>
            <div className="rounded-2xl border border-blue-200 bg-blue-50/50 p-4 shadow-sm">
              <p className="text-xs font-bold uppercase tracking-wider text-blue-600">
                PS Supervisors / SHO
              </p>
              <p className="mt-2 text-2xl font-black text-blue-800">
                {summaryCards.psSupervisors.toLocaleString(
                  "en-IN",
                )}
              </p>
            </div>
            <div className="rounded-2xl border border-purple-200 bg-purple-50/50 p-4 shadow-sm">
              <p className="text-xs font-bold uppercase tracking-wider text-purple-600">
                Divisional / Zonal /
                Admins
              </p>
              <p className="mt-2 text-2xl font-black text-purple-800">
                {(
                  summaryCards.divisionalSupervisors +
                  summaryCards.zonalSupervisors +
                  summaryCards.rangeSupervisors +
                  summaryCards.admins
                ).toLocaleString(
                  "en-IN",
                )}
              </p>
            </div>
          </section>
        )}

        {/* TAB 1: USER DIRECTORY & FILTERING */}
        {activeTab === "directory" && (
          <section className="space-y-6">
            {/* CASCADING HIERARCHICAL FILTERS */}
            <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
              <div className="mb-4 flex items-center justify-between border-b border-slate-100 pb-3">
                <h2 className="text-base font-bold text-slate-800">
                  Hierarchical Officers
                  Filter
                </h2>
                <button
                  type="button"
                  onClick={() => {
                    setSelectedRangeFilter(
                      "",
                    );
                    setSelectedZoneFilter(
                      "",
                    );
                    setSelectedDivisionFilter(
                      "",
                    );
                    setSelectedPsFilter(
                      "",
                    );
                    setSelectedRankFilter(
                      "",
                    );
                    setSelectedRoleFilter(
                      "",
                    );
                    setSelectedStatusFilter(
                      "",
                    );
                    setSearchText("");
                  }}
                  className="text-xs font-bold text-blue-600 hover:text-blue-800"
                >
                  Reset All Filters
                </button>
              </div>

              <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
                {/* WING */}
                <div>
                  <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 mb-1.5">
                    Wing
                  </label>
                  <select
                    value={selectedWing}
                    onChange={(e) =>
                      setSelectedWing(
                        e.target.value,
                      )
                    }
                    className="w-full rounded-xl border border-slate-300 bg-slate-50 px-3 py-2.5 text-sm font-semibold text-slate-700 outline-none focus:border-blue-500"
                  >
                    <option value="L & O">
                      L & O (Law &
                      Order)
                    </option>
                  </select>
                </div>

                {/* RANGE */}
                <div>
                  <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 mb-1.5">
                    Range
                  </label>
                  <select
                    value={
                      selectedRangeFilter
                    }
                    onChange={(e) => {
                      setSelectedRangeFilter(
                        e.target.value,
                      );
                      setSelectedZoneFilter(
                        "",
                      );
                      setSelectedDivisionFilter(
                        "",
                      );
                      setSelectedPsFilter(
                        "",
                      );
                    }}
                    className="w-full rounded-xl border border-slate-300 bg-white px-3 py-2.5 text-sm font-semibold text-slate-700 outline-none focus:border-blue-500"
                  >
                    <option value="">
                      All Ranges
                    </option>
                    {rangeOptions.map(
                      (r) => (
                        <option
                          key={r}
                          value={r}
                        >
                          {r}
                        </option>
                      ),
                    )}
                  </select>
                </div>

                {/* ZONE */}
                <div>
                  <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 mb-1.5">
                    Zone
                  </label>
                  <select
                    value={
                      selectedZoneFilter
                    }
                    onChange={(e) => {
                      setSelectedZoneFilter(
                        e.target.value,
                      );
                      setSelectedDivisionFilter(
                        "",
                      );
                      setSelectedPsFilter(
                        "",
                      );
                    }}
                    disabled={
                      !selectedRangeFilter &&
                      zoneOptions.length ===
                        0
                    }
                    className="w-full rounded-xl border border-slate-300 bg-white px-3 py-2.5 text-sm font-semibold text-slate-700 outline-none focus:border-blue-500 disabled:bg-slate-100 disabled:text-slate-400"
                  >
                    <option value="">
                      All Zones
                    </option>
                    {zoneOptions.map(
                      (z) => (
                        <option
                          key={z}
                          value={z}
                        >
                          {z}
                        </option>
                      ),
                    )}
                  </select>
                </div>

                {/* DIVISION */}
                <div>
                  <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 mb-1.5">
                    Division
                  </label>
                  <select
                    value={
                      selectedDivisionFilter
                    }
                    onChange={(e) => {
                      setSelectedDivisionFilter(
                        e.target.value,
                      );
                      setSelectedPsFilter(
                        "",
                      );
                    }}
                    disabled={
                      !selectedZoneFilter &&
                      divisionOptions.length ===
                        0
                    }
                    className="w-full rounded-xl border border-slate-300 bg-white px-3 py-2.5 text-sm font-semibold text-slate-700 outline-none focus:border-blue-500 disabled:bg-slate-100 disabled:text-slate-400"
                  >
                    <option value="">
                      All Divisions
                    </option>
                    {divisionOptions.map(
                      (d) => (
                        <option
                          key={d}
                          value={d}
                        >
                          {d}
                        </option>
                      ),
                    )}
                  </select>
                </div>

                {/* POLICE STATION */}
                <div>
                  <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 mb-1.5">
                    Police Station
                  </label>
                  <select
                    value={
                      selectedPsFilter
                    }
                    onChange={(e) =>
                      setSelectedPsFilter(
                        e.target.value,
                      )
                    }
                    disabled={
                      !selectedDivisionFilter &&
                      policeStationOptions.length ===
                        0
                    }
                    className="w-full rounded-xl border border-slate-300 bg-white px-3 py-2.5 text-sm font-semibold text-slate-700 outline-none focus:border-blue-500 disabled:bg-slate-100 disabled:text-slate-400"
                  >
                    <option value="">
                      All Police
                      Stations
                    </option>
                    {policeStationOptions.map(
                      (ps) => (
                        <option
                          key={ps}
                          value={ps}
                        >
                          {ps}
                        </option>
                      ),
                    )}
                  </select>
                </div>

                {/* RANK */}
                <div>
                  <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 mb-1.5">
                    Police Rank
                  </label>
                  <select
                    value={
                      selectedRankFilter
                    }
                    onChange={(e) =>
                      setSelectedRankFilter(
                        e.target.value,
                      )
                    }
                    className="w-full rounded-xl border border-slate-300 bg-white px-3 py-2.5 text-sm font-semibold text-slate-700 outline-none focus:border-blue-500"
                  >
                    <option value="">
                      All Ranks
                    </option>
                    {rankOptions.map(
                      (rk) => (
                        <option
                          key={rk}
                          value={rk}
                        >
                          {rk}
                        </option>
                      ),
                    )}
                  </select>
                </div>

                {/* APPLICATION ROLE */}
                <div>
                  <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 mb-1.5">
                    Application Role
                  </label>
                  <select
                    value={
                      selectedRoleFilter
                    }
                    onChange={(e) =>
                      setSelectedRoleFilter(
                        e.target.value,
                      )
                    }
                    className="w-full rounded-xl border border-slate-300 bg-white px-3 py-2.5 text-sm font-semibold text-slate-700 outline-none focus:border-blue-500"
                  >
                    <option value="">
                      All Roles
                    </option>
                    {ROLE_OPTIONS.map(
                      (r) => (
                        <option
                          key={r.value}
                          value={
                            r.value
                          }
                        >
                          {r.label}
                        </option>
                      ),
                    )}
                  </select>
                </div>

                {/* SEARCH INPUT */}
                <div>
                  <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 mb-1.5">
                    Search Name / Emp ID
                    / Phone
                  </label>
                  <input
                    type="text"
                    value={searchText}
                    onChange={(e) =>
                      setSearchText(
                        e.target.value,
                      )
                    }
                    placeholder="Search by name, employee ID..."
                    className="w-full rounded-xl border border-slate-300 px-3 py-2.5 text-sm font-medium outline-none focus:border-blue-500"
                  />
                </div>
              </div>
            </div>

            {/* SELECTION ACTION BAR */}
            <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between rounded-2xl border border-slate-200 bg-white p-4 shadow-sm">
              <div className="flex items-center gap-3">
                <span className="text-sm font-bold text-slate-700">
                  {selectedUserIds.size}{" "}
                  Officers Selected
                </span>
                {selectedUserIds.size >
                  0 && (
                  <button
                    type="button"
                    onClick={
                      clearSelection
                    }
                    className="text-xs font-bold text-slate-500 hover:text-slate-800 underline"
                  >
                    Clear Selection
                  </button>
                )}
              </div>

              <div className="flex items-center gap-2">
                <button
                  type="button"
                  onClick={
                    selectAllFiltered
                  }
                  className="rounded-xl border border-slate-300 bg-white px-4 py-2 text-xs font-bold text-slate-700 hover:bg-slate-50"
                >
                  Select All Filtered (
                  {filteredUsers.length}
                  )
                </button>

                <button
                  type="button"
                  disabled={
                    selectedUserIds.size ===
                    0
                  }
                  onClick={
                    openBulkAssignment
                  }
                  className="rounded-xl bg-cyan-600 px-4 py-2 text-xs font-bold text-white shadow-sm hover:bg-cyan-700 disabled:bg-slate-300 disabled:cursor-not-allowed"
                >
                  Assign Role to
                  Selected (
                  {selectedUserIds.size}
                  )
                </button>
              </div>
            </div>

            {/* OFFICERS TABLE */}
            <div className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm">
              <div className="overflow-x-auto">
                <table className="min-w-full divide-y divide-slate-200 text-left text-sm">
                  <thead className="bg-slate-50">
                    <tr>
                      <th className="px-4 py-3.5 text-xs font-bold uppercase tracking-wider text-slate-500 w-10">
                        <input
                          type="checkbox"
                          checked={
                            paginatedUsers.length >
                              0 &&
                            paginatedUsers.every(
                              (u) =>
                                selectedUserIds.has(
                                  u.id,
                                ),
                            )
                          }
                          onChange={(
                            e,
                          ) => {
                            if (
                              e.target
                                .checked
                            ) {
                              const next =
                                new Set(
                                  selectedUserIds,
                                );
                              paginatedUsers.forEach(
                                (u) =>
                                  next.add(
                                    u.id,
                                  ),
                              );
                              setSelectedUserIds(
                                next,
                              );
                            } else {
                              const next =
                                new Set(
                                  selectedUserIds,
                                );
                              paginatedUsers.forEach(
                                (u) =>
                                  next.delete(
                                    u.id,
                                  ),
                              );
                              setSelectedUserIds(
                                next,
                              );
                            }
                          }}
                          className="h-4 w-4 rounded border-slate-300 text-blue-600"
                        />
                      </th>
                      <th className="px-4 py-3.5 text-xs font-bold uppercase tracking-wider text-slate-500">
                        Emp ID /
                        Username
                      </th>
                      <th className="px-4 py-3.5 text-xs font-bold uppercase tracking-wider text-slate-500">
                        Officer Name &
                        Rank
                      </th>
                      <th className="px-4 py-3.5 text-xs font-bold uppercase tracking-wider text-slate-500">
                        Wing / Range /
                        Zone / Division
                        / PS
                      </th>
                      <th className="px-4 py-3.5 text-xs font-bold uppercase tracking-wider text-slate-500">
                        Application Role
                      </th>
                      <th className="px-4 py-3.5 text-xs font-bold uppercase tracking-wider text-slate-500">
                        Status
                      </th>
                      <th className="px-4 py-3.5 text-right text-xs font-bold uppercase tracking-wider text-slate-500">
                        Action
                      </th>
                    </tr>
                  </thead>

                  <tbody className="divide-y divide-slate-100">
                    {loadingUsers && (
                      <tr>
                        <td
                          colSpan={7}
                          className="px-4 py-12 text-center text-sm font-semibold text-slate-500"
                        >
                          Loading user
                          directory...
                        </td>
                      </tr>
                    )}

                    {!loadingUsers &&
                      paginatedUsers.length ===
                        0 && (
                        <tr>
                          <td
                            colSpan={7}
                            className="px-4 py-12 text-center text-sm font-semibold text-slate-500"
                          >
                            No officers
                            match the
                            selected
                            hierarchy or
                            filters.
                          </td>
                        </tr>
                      )}

                    {!loadingUsers &&
                      paginatedUsers.map(
                        (u) => {
                          const isSelected =
                            selectedUserIds.has(
                              u.id,
                            );

                          return (
                            <tr
                              key={u.id}
                              className={`transition ${isSelected ? "bg-cyan-50/60" : "hover:bg-slate-50"}`}
                            >
                              <td className="px-4 py-3.5">
                                <input
                                  type="checkbox"
                                  checked={
                                    isSelected
                                  }
                                  onChange={() =>
                                    toggleSelectUser(
                                      u.id,
                                    )
                                  }
                                  className="h-4 w-4 rounded border-slate-300 text-blue-600"
                                />
                              </td>
                              <td className="px-4 py-3.5 font-bold text-slate-800 whitespace-nowrap">
                                <div>
                                  {
                                    u.employeeId
                                  }
                                </div>
                                <div className="text-xs font-normal text-slate-400">
                                  {
                                    u.username
                                  }
                                </div>
                              </td>
                              <td className="px-4 py-3.5">
                                <div className="font-bold text-slate-800">
                                  {
                                    u.name
                                  }
                                </div>
                                <div className="text-xs font-semibold text-blue-600">
                                  {u.rank ||
                                    "Rank N/A"}
                                </div>
                              </td>
                              <td className="px-4 py-3.5 text-xs text-slate-600">
                                <div className="font-semibold text-slate-700">
                                  L & O
                                </div>
                                <div>
                                  {[
                                    u.rangeName,
                                    u.zoneName,
                                    u.divisionName,
                                    u.policeStationName,
                                  ]
                                    .filter(
                                      Boolean,
                                    )
                                    .join(
                                      " → ",
                                    ) ||
                                    "Scope Unassigned"}
                                </div>
                              </td>
                              <td className="px-4 py-3.5 whitespace-nowrap">
                                <span className="inline-flex rounded-full bg-slate-100 px-3 py-1 text-xs font-extrabold text-slate-800">
                                  {
                                    u.role
                                  }
                                </span>
                              </td>
                              <td className="px-4 py-3.5 whitespace-nowrap">
                                <span
                                  className={`inline-flex rounded-full px-2.5 py-1 text-xs font-bold ${
                                    u.status ===
                                    "ACTIVE"
                                      ? "bg-emerald-100 text-emerald-800"
                                      : "bg-red-100 text-red-800"
                                  }`}
                                >
                                  {
                                    u.status
                                  }
                                </span>
                              </td>
                              <td className="px-4 py-3.5 text-right whitespace-nowrap">
                                <button
                                  type="button"
                                  onClick={() =>
                                    openSingleUserEdit(
                                      u,
                                    )
                                  }
                                  className="rounded-lg border border-slate-300 px-3 py-1.5 text-xs font-bold text-slate-700 hover:bg-slate-100"
                                >
                                  Assign
                                  Role →
                                </button>
                              </td>
                            </tr>
                          );
                        },
                      )}
                  </tbody>
                </table>
              </div>

              {/* PAGINATION CONTROLS */}
              <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between border-t border-slate-200 bg-slate-50 px-5 py-3.5 text-xs text-slate-600">
                <div>
                  Showing{" "}
                  {Math.min(
                    (currentPage - 1) *
                      pageSize +
                      1,
                    filteredUsers.length,
                  )}{" "}
                  to{" "}
                  {Math.min(
                    currentPage *
                      pageSize,
                    filteredUsers.length,
                  )}{" "}
                  of{" "}
                  {filteredUsers.length}{" "}
                  officers
                </div>

                <div className="flex items-center gap-4">
                  <div className="flex items-center gap-2">
                    <span>
                      Per page:
                    </span>
                    <select
                      value={pageSize}
                      onChange={(e) => {
                        setPageSize(
                          Number(
                            e.target
                              .value,
                          ),
                        );
                        setCurrentPage(
                          1,
                        );
                      }}
                      className="rounded-lg border border-slate-300 bg-white px-2 py-1 font-semibold text-slate-700"
                    >
                      <option
                        value={25}
                      >
                        25
                      </option>
                      <option
                        value={50}
                      >
                        50
                      </option>
                      <option
                        value={100}
                      >
                        100
                      </option>
                    </select>
                  </div>

                  <div className="flex items-center gap-1.5">
                    <button
                      type="button"
                      disabled={
                        currentPage ===
                        1
                      }
                      onClick={() =>
                        setCurrentPage(
                          (p) =>
                            Math.max(
                              p - 1,
                              1,
                            ),
                        )
                      }
                      className="rounded-lg border border-slate-300 bg-white px-3 py-1 font-bold text-slate-700 disabled:opacity-40"
                    >
                      Previous
                    </button>
                    <span className="font-bold text-slate-800">
                      {currentPage} /{" "}
                      {totalPages}
                    </span>
                    <button
                      type="button"
                      disabled={
                        currentPage >=
                        totalPages
                      }
                      onClick={() =>
                        setCurrentPage(
                          (p) =>
                            Math.min(
                              p + 1,
                              totalPages,
                            ),
                        )
                      }
                      className="rounded-lg border border-slate-300 bg-white px-3 py-1 font-bold text-slate-700 disabled:opacity-40"
                    >
                      Next
                    </button>
                  </div>
                </div>
              </div>
            </div>
          </section>
        )}

        {/* TAB 2: ROLE ASSIGNMENT & SCOPE CONFIGURATOR */}
        {activeTab === "assignment" && (
          <section className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
            <div className="mb-6 border-b border-slate-100 pb-4">
              <h2 className="text-lg font-bold text-slate-800">
                {singleUserId
                  ? "Individual Role & Scope Configurator"
                  : `Group Role Assignment (${selectedUserIds.size} Selected Officers)`}
              </h2>
              <p className="mt-1 text-xs text-slate-500">
                Configure application
                supervisory role and
                complete parent
                hierarchy scope. Rank is
                NOT modified.
              </p>
            </div>

            <div className="space-y-6">
              {/* ROLE SELECTOR */}
              <div>
                <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 mb-2">
                  Select Application
                  Role
                </label>
                <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
                  {ROLE_OPTIONS.map(
                    (opt) => {
                      const isSelected =
                        draft.role ===
                        opt.value;
                      return (
                        <div
                          key={
                            opt.value
                          }
                          onClick={() =>
                            handleRoleChange(
                              opt.value,
                            )
                          }
                          className={`cursor-pointer rounded-2xl border p-4 transition ${
                            isSelected
                              ? "border-blue-600 bg-blue-50/60 ring-2 ring-blue-500"
                              : "border-slate-200 hover:border-slate-300 hover:bg-slate-50"
                          }`}
                        >
                          <div className="flex items-center justify-between">
                            <span className="text-sm font-extrabold text-slate-800">
                              {
                                opt.label
                              }
                            </span>
                            <span className="rounded-full bg-slate-200 px-2 py-0.5 text-[10px] font-black text-slate-700">
                              Lvl{" "}
                              {
                                opt.level
                              }
                            </span>
                          </div>
                          <p className="mt-2 text-xs text-slate-500">
                            {opt.desc}
                          </p>
                        </div>
                      );
                    },
                  )}
                </div>
              </div>

              {/* JURISDICTION & SCOPE ASSIGNMENT */}
              <div className="rounded-2xl border border-slate-200 bg-slate-50/50 p-5 space-y-4">
                <h3 className="text-xs font-bold uppercase tracking-wider text-slate-600">
                  Assign Supervisory
                  Scope & Jurisdiction
                </h3>

                <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
                  <div>
                    <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 mb-1">
                      Range
                    </label>
                    <select
                      value={
                        draft.rangeName
                      }
                      onChange={(e) =>
                        setDraft({
                          ...draft,
                          rangeName:
                            e.target
                              .value,
                        })
                      }
                      className="w-full rounded-xl border border-slate-300 bg-white px-3 py-2.5 text-sm font-semibold text-slate-700"
                    >
                      <option value="">
                        Select Range
                      </option>
                      {rangeOptions.map(
                        (r) => (
                          <option
                            key={r}
                            value={r}
                          >
                            {r}
                          </option>
                        ),
                      )}
                    </select>
                  </div>

                  <div>
                    <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 mb-1">
                      Zone
                    </label>
                    <select
                      value={
                        draft.zoneName
                      }
                      onChange={(e) =>
                        setDraft({
                          ...draft,
                          zoneName:
                            e.target
                              .value,
                        })
                      }
                      className="w-full rounded-xl border border-slate-300 bg-white px-3 py-2.5 text-sm font-semibold text-slate-700"
                    >
                      <option value="">
                        Select Zone
                      </option>
                      {getZones(
                        draft.rangeName ||
                          undefined,
                      ).map((z) => (
                        <option
                          key={z}
                          value={z}
                        >
                          {z}
                        </option>
                      ))}
                    </select>
                  </div>

                  <div>
                    <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 mb-1">
                      Division
                    </label>
                    <select
                      value={
                        draft.divisionName
                      }
                      onChange={(e) =>
                        setDraft({
                          ...draft,
                          divisionName:
                            e.target
                              .value,
                        })
                      }
                      className="w-full rounded-xl border border-slate-300 bg-white px-3 py-2.5 text-sm font-semibold text-slate-700"
                    >
                      <option value="">
                        Select Division
                      </option>
                      {getDivisions(
                        draft.rangeName ||
                          undefined,
                        draft.zoneName ||
                          undefined,
                      ).map((d) => (
                        <option
                          key={d}
                          value={d}
                        >
                          {d}
                        </option>
                      ))}
                    </select>
                  </div>

                  <div>
                    <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 mb-1">
                      Police Station
                    </label>
                    <select
                      value={
                        draft.policeStationName
                      }
                      onChange={(e) =>
                        setDraft({
                          ...draft,
                          policeStationName:
                            e.target
                              .value,
                        })
                      }
                      className="w-full rounded-xl border border-slate-300 bg-white px-3 py-2.5 text-sm font-semibold text-slate-700"
                    >
                      <option value="">
                        Select Police
                        Station
                      </option>
                      {getPoliceStations(
                        draft.rangeName ||
                          undefined,
                        draft.zoneName ||
                          undefined,
                        draft.divisionName ||
                          undefined,
                      ).map((ps) => (
                        <option
                          key={ps}
                          value={ps}
                        >
                          {ps}
                        </option>
                      ))}
                    </select>
                  </div>
                </div>

                {/* AUTOMATED PARENT HIERARCHY PREVIEW */}
                <div className="rounded-xl border border-blue-200 bg-blue-50/60 p-4">
                  <p className="text-xs font-bold uppercase tracking-wider text-blue-700">
                    Resolved Complete
                    Parent Hierarchy:
                  </p>
                  <p className="mt-1 text-sm font-extrabold text-slate-800">
                    {
                      resolvedHierarchyPreview
                    }
                  </p>
                </div>
              </div>

              {/* SAVE / CONFIRM ACTIONS */}
              <div className="flex items-center justify-end gap-3 pt-4 border-t border-slate-100">
                <button
                  type="button"
                  onClick={() =>
                    setActiveTab(
                      "directory",
                    )
                  }
                  className="rounded-xl border border-slate-300 bg-white px-5 py-2.5 text-sm font-bold text-slate-700 hover:bg-slate-50"
                >
                  Cancel
                </button>

                <button
                  type="button"
                  onClick={() =>
                    setShowConfirmModal(
                      true,
                    )
                  }
                  className="rounded-xl bg-[#17365D] px-6 py-2.5 text-sm font-bold text-white shadow-md hover:bg-[#234d7d]"
                >
                  {singleUserId
                    ? "Save Role Assignment"
                    : `Apply Role to ${selectedUserIds.size} Officers`}
                </button>
              </div>
            </div>
          </section>
        )}

        {/* CONFIRMATION MODAL */}
        {showConfirmModal && (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-950/70 p-4 backdrop-blur-sm">
            <div className="w-full max-w-lg rounded-2xl bg-white p-6 shadow-2xl space-y-4">
              <h3 className="text-lg font-bold text-slate-800">
                Confirm Role &
                Jurisdiction Update
              </h3>

              <div className="rounded-xl bg-amber-50 border border-amber-200 p-4 text-xs font-semibold text-amber-800">
                You are about to update{" "}
                {singleUserId
                  ? "1 officer"
                  : `${selectedUserIds.size} officers`}
                .
              </div>

              <div className="space-y-2 text-sm text-slate-700">
                <div className="flex justify-between border-b pb-2">
                  <span className="font-semibold text-slate-500">
                    New Role:
                  </span>
                  <span className="font-extrabold text-blue-700">
                    {draft.role}
                  </span>
                </div>

                <div className="flex justify-between border-b pb-2">
                  <span className="font-semibold text-slate-500">
                    Access Level:
                  </span>
                  <span className="font-extrabold text-slate-800">
                    Level{" "}
                    {draft.accessLevel}
                  </span>
                </div>

                <div className="flex justify-between border-b pb-2">
                  <span className="font-semibold text-slate-500">
                    Complete Scope:
                  </span>
                  <span className="font-bold text-slate-800 text-right">
                    {
                      resolvedHierarchyPreview
                    }
                  </span>
                </div>
              </div>

              <div className="flex justify-end gap-3 pt-4">
                <button
                  type="button"
                  onClick={() =>
                    setShowConfirmModal(
                      false,
                    )
                  }
                  className="rounded-xl border border-slate-300 px-4 py-2 text-sm font-bold text-slate-700 hover:bg-slate-50"
                >
                  Cancel
                </button>

                <button
                  type="button"
                  disabled={saving}
                  onClick={executeSave}
                  className="rounded-xl bg-emerald-600 px-5 py-2 text-sm font-bold text-white shadow-sm hover:bg-emerald-700 disabled:opacity-50"
                >
                  {saving
                    ? "Saving..."
                    : "Confirm & Apply"}
                </button>
              </div>
            </div>
          </div>
        )}
      </div>
    </main>
  );
}
