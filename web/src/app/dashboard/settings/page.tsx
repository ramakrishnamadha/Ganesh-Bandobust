"use client";

import {
  useEffect,
  useMemo,
  useState,
} from "react";

type PoliceStationAccess = {
  id?: string;

  policeStationCode:
    | string
    | null;

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

  phoneNumber:
    | string
    | null;

  team:
    | string
    | null;

  role: string;
  accessLevel: number;

  commissionerateCode:
    | string
    | null;

  commissionerateName:
    | string
    | null;

  rangeCode:
    | string
    | null;

  rangeName:
    | string
    | null;

  zoneCode:
    | string
    | null;

  zoneName:
    | string
    | null;

  divisionCode:
    | string
    | null;

  divisionName:
    | string
    | null;

  policeStationCode:
    | string
    | null;

  policeStationName:
    | string
    | null;

  sectorCode:
    | string
    | null;

  sectorName:
    | string
    | null;

  allPoliceStations: boolean;
  allDivisions: boolean;
  allZones: boolean;
  allRanges: boolean;

  status: string;

  mustChangePassword: boolean;

  policeStationAccesses:
    PoliceStationAccess[];
};

type GaneshRecord = {
  unique_id?: string;
  zone_name?: string;
  division_name?: string;
  ps_name?: string;
};

type UserDraft = {
  role: string;
  accessLevel: string;

  rangeName: string;
  zoneName: string;
  divisionName: string;
  policeStationName: string;
  sectorName: string;

  allRanges: boolean;
  allZones: boolean;
  allDivisions: boolean;
  allPoliceStations: boolean;

  status: string;

  policeStationAccesses:
    PoliceStationAccess[];
};

function text(
  value: unknown,
): string {
  if (
    value === null ||
    value === undefined
  ) {
    return "";
  }

  return String(value).trim();
}

function normalize(
  value: unknown,
): string {
  return text(value)
    .toLowerCase()
    .replace(/\s+/g, " ");
}

function getErrorMessage(
  value: unknown,
): string {
  if (
    typeof value !== "object" ||
    value === null
  ) {
    return "";
  }

  if (
    !("error" in value)
  ) {
    return "";
  }

  return text(
    (
      value as {
        error?: unknown;
      }
    ).error,
  );
}

function draftFromUser(
  user: AdminUser,
): UserDraft {
  return {
    role:
      text(user.role),

    accessLevel:
      String(
        user.accessLevel ?? 0,
      ),

    rangeName:
      text(user.rangeName),

    zoneName:
      text(user.zoneName),

    divisionName:
      text(
        user.divisionName,
      ),

    policeStationName:
      text(
        user.policeStationName,
      ),

    sectorName:
      text(user.sectorName),

    allRanges:
      user.allRanges === true,

    allZones:
      user.allZones === true,

    allDivisions:
      user.allDivisions === true,

    allPoliceStations:
      user.allPoliceStations ===
      true,

    status:
      text(user.status) ||
      "ACTIVE",

    policeStationAccesses:
      (
        user.policeStationAccesses ??
        []
      ).map(
        (access) => ({
          ...access,
        }),
      ),
  };
}

export default function SettingsPage() {
  const [
    users,
    setUsers,
  ] = useState<
    AdminUser[]
  >([]);

  const [
    gpidRecords,
    setGpidRecords,
  ] = useState<
    GaneshRecord[]
  >([]);

  const [
    selectedUserId,
    setSelectedUserId,
  ] = useState("");

  const [
    draft,
    setDraft,
  ] =
    useState<UserDraft | null>(
      null,
    );

  const [
    searchText,
    setSearchText,
  ] = useState("");

  const [
    additionalPs,
    setAdditionalPs,
  ] = useState("");

  const [
    loadingUsers,
    setLoadingUsers,
  ] = useState(true);

  const [
    loadingHierarchy,
    setLoadingHierarchy,
  ] = useState(false);

  const [
    saving,
    setSaving,
  ] = useState(false);

  const [
    error,
    setError,
  ] = useState("");

  const [
    success,
    setSuccess,
  ] = useState("");

  const loadUsers =
    async () => {
      setLoadingUsers(true);
      setError("");

      try {
        const response =
          await fetch(
            "/api/admin/users",
            {
              method: "GET",
              cache: "no-store",
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

        if (!response.ok) {
          throw new Error(
            getErrorMessage(
              body,
            ) ||
              "Unable to load users.",
          );
        }

        if (
          typeof body !==
            "object" ||
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

        const loadedUsers =
          (
            body as {
              users:
                AdminUser[];
            }
          ).users;

        setUsers(
          loadedUsers,
        );

        setSelectedUserId(
          (current) => {
            if (
              current &&
              loadedUsers.some(
                (user) =>
                  user.id ===
                  current,
              )
            ) {
              return current;
            }

            return (
              loadedUsers[0]
                ?.id ?? ""
            );
          },
        );
      } catch (
        loadError
      ) {
        console.error(
          "Settings user load error:",
          loadError,
        );

        setError(
          loadError instanceof
            Error
            ? loadError.message
            : "Unable to load users.",
        );
      } finally {
        setLoadingUsers(
          false,
        );
      }
    };

  const loadHierarchy =
    async () => {
      setLoadingHierarchy(
        true,
      );

      try {
        const response =
          await fetch(
            "/api/gpid",
            {
              method: "GET",
              cache: "no-store",
              credentials:
                "include",
            },
          );

        if (!response.ok) {
          console.error(
            "Unable to load jurisdiction hierarchy.",
          );

          return;
        }

        const body:
          unknown =
          await response.json();

        if (
          !Array.isArray(
            body,
          )
        ) {
          return;
        }

        const validRecords =
          (
            body as
              GaneshRecord[]
          ).filter(
            (record) =>
              text(
                record.unique_id,
              ).length > 0,
          );

        setGpidRecords(
          validRecords,
        );
      } catch (
        hierarchyError
      ) {
        console.error(
          "Settings hierarchy load error:",
          hierarchyError,
        );
      } finally {
        setLoadingHierarchy(
          false,
        );
      }
    };

  useEffect(() => {
    void loadUsers();

    /*
     * Do NOT block the Settings page
     * while the large GPID master loads.
     */
    void loadHierarchy();
  }, []);

  const selectedUser =
    useMemo(
      () =>
        users.find(
          (user) =>
            user.id ===
            selectedUserId,
        ) ?? null,
      [
        users,
        selectedUserId,
      ],
    );

  useEffect(() => {
    if (!selectedUser) {
      setDraft(null);
      return;
    }

    setDraft(
      draftFromUser(
        selectedUser,
      ),
    );

    setSuccess("");
    setError("");
  }, [selectedUser]);

  const filteredUsers =
    useMemo(() => {
      const query =
        searchText
          .trim()
          .toLowerCase();

      if (!query) {
        return users;
      }

      return users.filter(
        (user) => {
          const haystack = [
            user.name,
            user.rank,
            user.employeeId,
            user.username,
            user.role,
            user.rangeName,
            user.zoneName,
            user.divisionName,
            user.policeStationName,
            user.sectorName,
          ]
            .map(
              (value) =>
                text(
                  value,
                ).toLowerCase(),
            )
            .join(" ");

          return haystack.includes(
            query,
          );
        },
      );
    }, [
      users,
      searchText,
    ]);

  /*
   * IMPORTANT:
   * We intentionally do NOT guess Range
   * from Zone here.
   *
   * Range must come from the corrected
   * authoritative hierarchy master.
   *
   * Until that master is wired into
   * /api/gpid, existing assigned Range
   * values from users are shown.
   */
  const rangeOptions =
    useMemo(() => {
      return Array.from(
        new Set(
          users
            .map(
              (user) =>
                text(
                  user.rangeName,
                ),
            )
            .filter(Boolean),
        ),
      ).sort(
        (
          left,
          right,
        ) =>
          left.localeCompare(
            right,
          ),
      );
    }, [users]);

  const zoneOptions =
    useMemo(() => {
      return Array.from(
        new Set(
          gpidRecords
            .map(
              (record) =>
                text(
                  record.zone_name,
                ),
            )
            .filter(Boolean),
        ),
      ).sort(
        (
          left,
          right,
        ) =>
          left.localeCompare(
            right,
          ),
      );
    }, [
      gpidRecords,
    ]);

  const divisionOptions =
    useMemo(() => {
      if (!draft) {
        return [];
      }

      return Array.from(
        new Set(
          gpidRecords
            .filter(
              (record) => {
                if (
                  draft.zoneName &&
                  text(
                    record.zone_name,
                  ) !==
                    draft.zoneName
                ) {
                  return false;
                }

                return true;
              },
            )
            .map(
              (record) =>
                text(
                  record.division_name,
                ),
            )
            .filter(Boolean),
        ),
      ).sort(
        (
          left,
          right,
        ) =>
          left.localeCompare(
            right,
          ),
      );
    }, [
      draft,
      gpidRecords,
    ]);

  const policeStationOptions =
    useMemo(() => {
      if (!draft) {
        return [];
      }

      return Array.from(
        new Set(
          gpidRecords
            .filter(
              (record) => {
                if (
                  draft.zoneName &&
                  text(
                    record.zone_name,
                  ) !==
                    draft.zoneName
                ) {
                  return false;
                }

                if (
                  draft.divisionName &&
                  text(
                    record.division_name,
                  ) !==
                    draft.divisionName
                ) {
                  return false;
                }

                return true;
              },
            )
            .map(
              (record) =>
                text(
                  record.ps_name,
                ),
            )
            .filter(Boolean),
        ),
      ).sort(
        (
          left,
          right,
        ) =>
          left.localeCompare(
            right,
          ),
      );
    }, [
      draft,
      gpidRecords,
    ]);

  const allPoliceStations =
    useMemo(() => {
      return Array.from(
        new Set(
          gpidRecords
            .map(
              (record) =>
                text(
                  record.ps_name,
                ),
            )
            .filter(Boolean),
        ),
      ).sort(
        (
          left,
          right,
        ) =>
          left.localeCompare(
            right,
          ),
      );
    }, [
      gpidRecords,
    ]);

  const addAdditionalPs =
    () => {
      if (
        !draft ||
        !additionalPs
      ) {
        return;
      }

      const alreadyExists =
        draft.policeStationAccesses.some(
          (access) =>
            normalize(
              access.policeStationName,
            ) ===
            normalize(
              additionalPs,
            ),
        );

      if (alreadyExists) {
        return;
      }

      setDraft({
        ...draft,

        policeStationAccesses: [
          ...draft.policeStationAccesses,

          {
            policeStationCode:
              null,

            policeStationName:
              additionalPs,

            canView: true,
            canEdit: true,
          },
        ],
      });

      setAdditionalPs("");
    };

  const removeAdditionalPs =
    (
      policeStationName:
        string,
    ) => {
      if (!draft) {
        return;
      }

      setDraft({
        ...draft,

        policeStationAccesses:
          draft.policeStationAccesses.filter(
            (access) =>
              normalize(
                access.policeStationName,
              ) !==
              normalize(
                policeStationName,
              ),
          ),
      });
    };

  const updateAdditionalPs =
    (
      policeStationName:
        string,

      field:
        | "canView"
        | "canEdit",

      value: boolean,
    ) => {
      if (!draft) {
        return;
      }

      setDraft({
        ...draft,

        policeStationAccesses:
          draft.policeStationAccesses.map(
            (access) =>
              normalize(
                access.policeStationName,
              ) ===
              normalize(
                policeStationName,
              )
                ? {
                    ...access,
                    [field]:
                      value,
                  }
                : access,
          ),
      });
    };

  const saveUser =
    async () => {
      if (
        !selectedUser ||
        !draft
      ) {
        return;
      }

      const accessLevel =
        Number(
          draft.accessLevel,
        );

      if (
        !Number.isInteger(
          accessLevel,
        ) ||
        accessLevel < 0
      ) {
        setError(
          "Access Level must be a valid non-negative integer.",
        );

        return;
      }

      setSaving(true);
      setError("");
      setSuccess("");

      try {
        const response =
          await fetch(
            "/api/admin/users",
            {
              method:
                "PATCH",

              credentials:
                "include",

              headers: {
                "Content-Type":
                  "application/json",
              },

              body:
                JSON.stringify({
                  userId:
                    selectedUser.id,

                  role:
                    draft.role,

                  accessLevel,

                  /*
                   * Do not preserve unknown or
                   * incorrect hierarchy codes
                   * when changing names.
                   */
                  rangeCode:
                    null,

                  rangeName:
                    draft.rangeName ||
                    null,

                  zoneCode:
                    null,

                  zoneName:
                    draft.zoneName ||
                    null,

                  divisionCode:
                    null,

                  divisionName:
                    draft.divisionName ||
                    null,

                  policeStationCode:
                    null,

                  policeStationName:
                    draft.policeStationName ||
                    null,

                  sectorCode:
                    null,

                  sectorName:
                    draft.sectorName ||
                    null,

                  allRanges:
                    draft.allRanges,

                  allZones:
                    draft.allZones,

                  allDivisions:
                    draft.allDivisions,

                  allPoliceStations:
                    draft.allPoliceStations,

                  status:
                    draft.status,

                  policeStationAccesses:
                    draft.policeStationAccesses.map(
                      (
                        access,
                      ) => ({
                        policeStationCode:
                          access.policeStationCode,

                        policeStationName:
                          access.policeStationName,

                        canView:
                          access.canView,

                        canEdit:
                          access.canEdit,
                      }),
                    ),
                }),
            },
          );

        const body:
          unknown =
          await response
            .json()
            .catch(
              () => null,
            );

        if (!response.ok) {
          throw new Error(
            getErrorMessage(
              body,
            ) ||
              "Unable to save user settings.",
          );
        }

        if (
          typeof body !==
            "object" ||
          body === null ||
          !("user" in body)
        ) {
          throw new Error(
            "User was updated but the server returned no user record.",
          );
        }

        const updatedUser =
          (
            body as {
              user:
                AdminUser;
            }
          ).user;

        setUsers(
          (
            currentUsers,
          ) =>
            currentUsers.map(
              (user) =>
                user.id ===
                updatedUser.id
                  ? updatedUser
                  : user,
            ),
        );

        setDraft(
          draftFromUser(
            updatedUser,
          ),
        );

        setSuccess(
          "Role, jurisdiction and permissions saved successfully.",
        );
      } catch (
        saveError
      ) {
        console.error(
          "Settings save error:",
          saveError,
        );

        setError(
          saveError instanceof
            Error
            ? saveError.message
            : "Unable to save user settings.",
        );
      } finally {
        setSaving(false);
      }
    };

  if (loadingUsers) {
    return (
      <main className="min-h-screen bg-slate-100 p-6">
        <div className="rounded-xl border border-slate-200 bg-white p-8 text-center text-slate-500 shadow-sm">
          Loading Officers / Users...
        </div>
      </main>
    );
  }

  return (
    <main className="min-h-screen bg-slate-100">
      <div className="mx-auto max-w-7xl px-4 py-6 sm:px-6 lg:px-8">
        <div className="mb-6">
          <p className="text-xs font-bold uppercase tracking-wider text-slate-400">
            Administration
          </p>

          <h1 className="mt-1 text-2xl font-bold text-slate-800">
            Settings — Role & Jurisdiction Allotment
          </h1>

          <p className="mt-2 text-sm leading-6 text-slate-600">
            Configure officer role, access level,
            jurisdiction and additional Police Station
            permissions.
          </p>
        </div>

        {loadingHierarchy && (
          <div className="mb-5 rounded-lg border border-blue-200 bg-blue-50 px-4 py-3 text-sm text-blue-700">
            Officer list loaded. Jurisdiction master is
            loading separately in the background...
          </div>
        )}

        {error && (
          <div className="mb-5 rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
            {error}
          </div>
        )}

        {success && (
          <div className="mb-5 rounded-lg border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm font-semibold text-emerald-700">
            {success}
          </div>
        )}

        <div className="grid gap-6 lg:grid-cols-[340px_minmax(0,1fr)]">
          <section className="rounded-xl border border-slate-200 bg-white shadow-sm">
            <div className="border-b border-slate-200 p-4">
              <h2 className="text-lg font-bold text-slate-800">
                Officers / Users
              </h2>

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
                placeholder="Search officer, ID, role..."
                className="mt-3 w-full rounded-lg border border-slate-300 px-3 py-2.5 text-sm outline-none focus:border-blue-500"
              />
            </div>

            <div className="max-h-[720px] overflow-y-auto">
              {filteredUsers.map(
                (user) => {
                  const selected =
                    user.id ===
                    selectedUserId;

                  return (
                    <button
                      key={
                        user.id
                      }
                      type="button"
                      onClick={() =>
                        setSelectedUserId(
                          user.id,
                        )
                      }
                      className={`block w-full border-b border-slate-100 px-4 py-4 text-left transition ${
                        selected
                          ? "bg-blue-50"
                          : "hover:bg-slate-50"
                      }`}
                    >
                      <div className="font-bold text-slate-800">
                        {
                          user.name
                        }
                      </div>

                      <div className="mt-1 text-xs text-slate-500">
                        {
                          user.rank
                        }{" "}
                        ·{" "}
                        {
                          user.employeeId
                        }
                      </div>

                      <div className="mt-2 flex flex-wrap gap-2">
                        <span className="rounded-full bg-slate-100 px-2 py-1 text-xs font-semibold text-slate-600">
                          {
                            user.role
                          }
                        </span>

                        <span
                          className={`rounded-full px-2 py-1 text-xs font-semibold ${
                            user.status ===
                            "ACTIVE"
                              ? "bg-emerald-100 text-emerald-700"
                              : "bg-red-100 text-red-700"
                          }`}
                        >
                          {
                            user.status
                          }
                        </span>
                      </div>
                    </button>
                  );
                },
              )}

              {filteredUsers.length ===
                0 && (
                <div className="p-6 text-center text-sm text-slate-500">
                  No users found.
                </div>
              )}
            </div>
          </section>

          <section className="rounded-xl border border-slate-200 bg-white shadow-sm">
            {!selectedUser ||
            !draft ? (
              <div className="p-10 text-center text-slate-500">
                Select an officer to configure access.
              </div>
            ) : (
              <>
                <div className="border-b border-slate-200 p-5">
                  <p className="text-xs font-bold uppercase tracking-wider text-slate-400">
                    Selected Officer
                  </p>

                  <h2 className="mt-1 text-xl font-bold text-slate-800">
                    {
                      selectedUser.name
                    }
                  </h2>

                  <p className="mt-1 text-sm text-slate-500">
                    {
                      selectedUser.rank
                    }{" "}
                    · Employee ID:{" "}
                    {
                      selectedUser.employeeId
                    }{" "}
                    · Username:{" "}
                    {
                      selectedUser.username
                    }
                  </p>
                </div>

                <div className="space-y-7 p-5">
                  <section>
                    <h3 className="mb-4 text-base font-bold text-slate-800">
                      Role & Account
                    </h3>

                    <div className="grid gap-4 md:grid-cols-3">
                      <div>
                        <label className="mb-2 block text-sm font-semibold text-slate-700">
                          Role
                        </label>

                        <input
                          list="ganesh-role-options"
                          value={
                            draft.role
                          }
                          onChange={(
                            event,
                          ) =>
                            setDraft({
                              ...draft,

                              role:
                                event.target.value.toUpperCase(),
                            })
                          }
                          className="w-full rounded-lg border border-slate-300 px-3 py-2.5 text-sm"
                        />

                        <datalist id="ganesh-role-options">
                          <option value="ADMIN" />
                          <option value="COMMISSIONER" />
                          <option value="ADDL_CP" />
                          <option value="DCP" />
                          <option value="ADDL_DCP" />
                          <option value="ACP" />
                          <option value="INSPECTOR" />
                          <option value="DI" />
                          <option value="SI" />
                          <option value="ASI" />
                          <option value="HC" />
                          <option value="PC" />
                          <option value="OFFICER" />
                        </datalist>
                      </div>

                      <div>
                        <label className="mb-2 block text-sm font-semibold text-slate-700">
                          Access Level
                        </label>

                        <input
                          type="number"
                          min="0"
                          value={
                            draft.accessLevel
                          }
                          onChange={(
                            event,
                          ) =>
                            setDraft({
                              ...draft,

                              accessLevel:
                                event.target.value,
                            })
                          }
                          className="w-full rounded-lg border border-slate-300 px-3 py-2.5 text-sm"
                        />
                      </div>

                      <div>
                        <label className="mb-2 block text-sm font-semibold text-slate-700">
                          Account Status
                        </label>

                        <select
                          value={
                            draft.status
                          }
                          onChange={(
                            event,
                          ) =>
                            setDraft({
                              ...draft,

                              status:
                                event.target.value,
                            })
                          }
                          className="w-full rounded-lg border border-slate-300 px-3 py-2.5 text-sm"
                        >
                          <option value="ACTIVE">
                            ACTIVE
                          </option>

                          <option value="INACTIVE">
                            INACTIVE
                          </option>
                        </select>
                      </div>
                    </div>
                  </section>

                  <section className="rounded-xl border border-blue-200 bg-blue-50 p-5">
                    <h3 className="font-bold text-blue-900">
                      Hierarchy-wide Access
                    </h3>

                    <div className="mt-4 grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
                      <label className="flex items-center gap-3 rounded-lg border border-blue-200 bg-white px-4 py-3">
                        <input
                          type="checkbox"
                          checked={
                            draft.allRanges
                          }
                          onChange={(
                            event,
                          ) =>
                            setDraft({
                              ...draft,

                              allRanges:
                                event.target.checked,
                            })
                          }
                        />

                        <span className="text-sm font-semibold">
                          All Ranges
                        </span>
                      </label>

                      <label className="flex items-center gap-3 rounded-lg border border-blue-200 bg-white px-4 py-3">
                        <input
                          type="checkbox"
                          checked={
                            draft.allZones
                          }
                          onChange={(
                            event,
                          ) =>
                            setDraft({
                              ...draft,

                              allZones:
                                event.target.checked,
                            })
                          }
                        />

                        <span className="text-sm font-semibold">
                          All Zones
                        </span>
                      </label>

                      <label className="flex items-center gap-3 rounded-lg border border-blue-200 bg-white px-4 py-3">
                        <input
                          type="checkbox"
                          checked={
                            draft.allDivisions
                          }
                          onChange={(
                            event,
                          ) =>
                            setDraft({
                              ...draft,

                              allDivisions:
                                event.target.checked,
                            })
                          }
                        />

                        <span className="text-sm font-semibold">
                          All Divisions
                        </span>
                      </label>

                      <label className="flex items-center gap-3 rounded-lg border border-blue-200 bg-white px-4 py-3">
                        <input
                          type="checkbox"
                          checked={
                            draft.allPoliceStations
                          }
                          onChange={(
                            event,
                          ) =>
                            setDraft({
                              ...draft,

                              allPoliceStations:
                                event.target.checked,
                            })
                          }
                        />

                        <span className="text-sm font-semibold">
                          All Police Stations
                        </span>
                      </label>
                    </div>
                  </section>

                  <section>
                    <h3 className="text-base font-bold text-slate-800">
                      Primary Jurisdiction
                    </h3>

                    <p className="mb-4 mt-1 text-sm text-slate-500">
                      Range → Zone → Division → Police Station →
                      Sector
                    </p>

                    <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
                      <div>
                        <label className="mb-2 block text-sm font-semibold">
                          Range
                        </label>

                        <select
                          value={
                            draft.rangeName
                          }
                          onChange={(
                            event,
                          ) =>
                            setDraft({
                              ...draft,

                              rangeName:
                                event.target.value,
                            })
                          }
                          className="w-full rounded-lg border border-slate-300 px-3 py-2.5 text-sm"
                        >
                          <option value="">
                            Not Assigned
                          </option>

                          {rangeOptions.map(
                            (
                              range,
                            ) => (
                              <option
                                key={
                                  range
                                }
                                value={
                                  range
                                }
                              >
                                {
                                  range
                                }
                              </option>
                            ),
                          )}
                        </select>
                      </div>

                      <div>
                        <label className="mb-2 block text-sm font-semibold">
                          Zone
                        </label>

                        <select
                          value={
                            draft.zoneName
                          }
                          onChange={(
                            event,
                          ) =>
                            setDraft({
                              ...draft,

                              zoneName:
                                event.target.value,

                              divisionName:
                                "",

                              policeStationName:
                                "",
                            })
                          }
                          disabled={
                            loadingHierarchy
                          }
                          className="w-full rounded-lg border border-slate-300 px-3 py-2.5 text-sm disabled:bg-slate-100"
                        >
                          <option value="">
                            Not Assigned
                          </option>

                          {zoneOptions.map(
                            (
                              zone,
                            ) => (
                              <option
                                key={
                                  zone
                                }
                                value={
                                  zone
                                }
                              >
                                {
                                  zone
                                }
                              </option>
                            ),
                          )}
                        </select>
                      </div>

                      <div>
                        <label className="mb-2 block text-sm font-semibold">
                          Division
                        </label>

                        <select
                          value={
                            draft.divisionName
                          }
                          onChange={(
                            event,
                          ) =>
                            setDraft({
                              ...draft,

                              divisionName:
                                event.target.value,

                              policeStationName:
                                "",
                            })
                          }
                          disabled={
                            loadingHierarchy
                          }
                          className="w-full rounded-lg border border-slate-300 px-3 py-2.5 text-sm disabled:bg-slate-100"
                        >
                          <option value="">
                            Not Assigned
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
                        <label className="mb-2 block text-sm font-semibold">
                          Police Station
                        </label>

                        <select
                          value={
                            draft.policeStationName
                          }
                          onChange={(
                            event,
                          ) =>
                            setDraft({
                              ...draft,

                              policeStationName:
                                event.target.value,
                            })
                          }
                          disabled={
                            loadingHierarchy
                          }
                          className="w-full rounded-lg border border-slate-300 px-3 py-2.5 text-sm disabled:bg-slate-100"
                        >
                          <option value="">
                            Not Assigned
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
                        <label className="mb-2 block text-sm font-semibold">
                          Sector
                        </label>

                        <input
                          type="text"
                          value={
                            draft.sectorName
                          }
                          onChange={(
                            event,
                          ) =>
                            setDraft({
                              ...draft,

                              sectorName:
                                event.target.value,
                            })
                          }
                          placeholder="Enter Sector if applicable"
                          className="w-full rounded-lg border border-slate-300 px-3 py-2.5 text-sm"
                        />

                        <p className="mt-1 text-xs text-slate-400">
                          Use only where authoritative Sector
                          mapping exists.
                        </p>
                      </div>
                    </div>
                  </section>

                  <section>
                    <h3 className="text-base font-bold text-slate-800">
                      Additional Police Station Access
                    </h3>

                    <p className="mt-1 text-sm text-slate-500">
                      Assign additional Police Stations with
                      separate View/Edit permissions.
                    </p>

                    <div className="mt-4 flex flex-col gap-3 sm:flex-row">
                      <select
                        value={
                          additionalPs
                        }
                        onChange={(
                          event,
                        ) =>
                          setAdditionalPs(
                            event.target.value,
                          )
                        }
                        disabled={
                          loadingHierarchy
                        }
                        className="flex-1 rounded-lg border border-slate-300 px-3 py-2.5 text-sm disabled:bg-slate-100"
                      >
                        <option value="">
                          Select Police Station
                        </option>

                        {allPoliceStations.map(
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

                      <button
                        type="button"
                        onClick={
                          addAdditionalPs
                        }
                        disabled={
                          !additionalPs
                        }
                        className="rounded-lg bg-slate-800 px-5 py-2.5 text-sm font-semibold text-white disabled:bg-slate-300"
                      >
                        Add Access
                      </button>
                    </div>

                    <div className="mt-4 space-y-3">
                      {draft.policeStationAccesses.map(
                        (
                          access,
                        ) => (
                          <div
                            key={
                              access.policeStationName
                            }
                            className="flex flex-col gap-3 rounded-lg border border-slate-200 bg-slate-50 p-4 md:flex-row md:items-center md:justify-between"
                          >
                            <div className="font-semibold text-slate-800">
                              {
                                access.policeStationName
                              }
                            </div>

                            <div className="flex flex-wrap gap-4">
                              <label className="flex items-center gap-2 text-sm">
                                <input
                                  type="checkbox"
                                  checked={
                                    access.canView
                                  }
                                  onChange={(
                                    event,
                                  ) =>
                                    updateAdditionalPs(
                                      access.policeStationName,

                                      "canView",

                                      event.target.checked,
                                    )
                                  }
                                />

                                View
                              </label>

                              <label className="flex items-center gap-2 text-sm">
                                <input
                                  type="checkbox"
                                  checked={
                                    access.canEdit
                                  }
                                  onChange={(
                                    event,
                                  ) =>
                                    updateAdditionalPs(
                                      access.policeStationName,

                                      "canEdit",

                                      event.target.checked,
                                    )
                                  }
                                />

                                Edit
                              </label>

                              <button
                                type="button"
                                onClick={() =>
                                  removeAdditionalPs(
                                    access.policeStationName,
                                  )
                                }
                                className="rounded-lg border border-red-200 bg-white px-3 py-1 text-xs font-bold text-red-700"
                              >
                                Remove
                              </button>
                            </div>
                          </div>
                        ),
                      )}

                      {draft.policeStationAccesses.length ===
                        0 && (
                        <div className="rounded-lg border border-dashed border-slate-300 p-5 text-center text-sm text-slate-500">
                          No additional Police Station access.
                        </div>
                      )}
                    </div>
                  </section>

                  <section className="grid gap-4 md:grid-cols-2">
                    <div className="rounded-xl border border-indigo-200 bg-indigo-50 p-4">
                      <h4 className="font-bold text-indigo-900">
                        Inspection / Verification
                      </h4>

                      <p className="mt-2 text-sm leading-6 text-indigo-800">
                        Five formal stages. Any authenticated
                        officer may conduct an applicable GPID
                        inspection using his or her credentials.
                      </p>
                    </div>

                    <div className="rounded-xl border border-emerald-200 bg-emerald-50 p-4">
                      <h4 className="font-bold text-emerald-900">
                        Visitings
                      </h4>

                      <p className="mt-2 text-sm leading-6 text-emerald-800">
                        Daily repeated visits are separately
                        reportable by date, festival day, officer,
                        GPID and jurisdiction.
                      </p>
                    </div>
                  </section>
                </div>

                <div className="sticky bottom-0 flex flex-col gap-3 border-t border-slate-200 bg-white p-5 sm:flex-row sm:justify-end">
                  <button
                    type="button"
                    onClick={() =>
                      setDraft(
                        draftFromUser(
                          selectedUser,
                        ),
                      )
                    }
                    disabled={
                      saving
                    }
                    className="rounded-lg border border-slate-300 px-5 py-2.5 text-sm font-semibold text-slate-700"
                  >
                    Reset Changes
                  </button>

                  <button
                    type="button"
                    onClick={() => {
                      void saveUser();
                    }}
                    disabled={
                      saving ||
                      !draft.role
                    }
                    className="rounded-lg bg-[#17365D] px-6 py-2.5 text-sm font-bold text-white disabled:bg-slate-300"
                  >
                    {saving
                      ? "Saving..."
                      : "Save Role & Jurisdiction"}
                  </button>
                </div>
              </>
            )}
          </section>
        </div>
      </div>
    </main>
  );
}