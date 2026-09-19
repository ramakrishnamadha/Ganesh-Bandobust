"use client";

import { useEffect, useMemo, useState, useRef } from "react";
import Link from "next/link";
import {
  getRanges,
  getZones,
  getDivisions,
  getPoliceStations,
  getHierarchyForPoliceStation,
  getHierarchyForDivision,
  getHierarchyForZone,
  getHierarchyForRange,
  GANESH_HIERARCHY,
} from "@/lib/hierarchy/ganeshHierarchy";
import { normalizeOfficerRank } from "@/lib/server/userManagementHelper";

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
};

type RowActionConfig = {
  assignmentAction: "RETAIN" | "REASSIGN";
  reassignLevel: number; // 1 to 7
  targetPs: string;
  targetDivision: string;
  targetZone: string;
  targetRange: string;
  targetSector: string;
};

const ROLE_OPTIONS = [
  { level: 1, role: "FIELD_OFFICER", label: "Level 1 — Field Officer" },
  { level: 2, role: "SECTOR_INCHARGE", label: "Level 2 — Sector In-charge" },
  { level: 3, role: "PS_SUPERVISOR", label: "Level 3 — PS Supervisor / SHO" },
  { level: 4, role: "DIVISIONAL_SUPERVISOR", label: "Level 4 — Divisional Supervisor" },
  { level: 5, role: "ZONAL_SUPERVISOR", label: "Level 5 — Zonal Supervisor" },
  { level: 6, role: "RANGE_SUPERVISOR", label: "Level 6 — Range Supervisor" },
  { level: 7, role: "ADMIN", label: "Level 7 — Admin" },
];

export default function RoleAllotmentPage() {
  // Top Hierarchy & Wing State
  const [selectedWing, setSelectedWing] = useState("L_AND_O");
  const [selectedRange, setSelectedRange] = useState("");
  const [selectedZone, setSelectedZone] = useState("");
  const [selectedDivision, setSelectedDivision] = useState("");
  const [selectedPs, setSelectedPs] = useState("");

  // Officer Source Mode: "STATION" vs "ALL"
  const [officerSource, setOfficerSource] = useState<"STATION" | "ALL">("STATION");
  const [allUsersSearchQuery, setAllUsersSearchQuery] = useState("");

  // Officer Roster State & Totals
  const [rosterUsers, setRosterUsers] = useState<AdminUser[]>([]);
  const [loadingUsers, setLoadingUsers] = useState(false);
  const [fetchError, setFetchError] = useState("");
  const [totalRosterCount, setTotalRosterCount] = useState(0);
  const [totalApplicationUsers, setTotalApplicationUsers] = useState(0);

  // Request Race Protection Controller Ref
  const fetchControllerRef = useRef<AbortController | null>(null);

  // Interlinked Roster Filters
  const [filterName, setFilterName] = useState("");
  const [filterEmpId, setFilterEmpId] = useState("");
  const [filterRank, setFilterRank] = useState("");
  const [filterStatus, setFilterStatus] = useState("ALL");

  // Multi-Selection State
  const [selectedUserIds, setSelectedUserIds] = useState<string[]>([]);

  // Per-Row Action State
  const [rowActionMap, setRowActionMap] = useState<Record<string, RowActionConfig>>({});

  // Bulk Action Panel State
  const [bulkLevel, setBulkLevel] = useState<number>(1);
  const [bulkTargetPs, setBulkTargetPs] = useState("");
  const [bulkTargetDivision, setBulkTargetDivision] = useState("");
  const [bulkTargetZone, setBulkTargetZone] = useState("");
  const [bulkTargetRange, setBulkTargetRange] = useState("");
  const [bulkTargetSector, setBulkTargetSector] = useState("");

  // Modal & Saving State
  const [showConfirmModal, setShowConfirmModal] = useState(false);
  const [modalMode, setModalMode] = useState<"SINGLE" | "BULK">("SINGLE");
  const [singleTargetUser, setSingleTargetUser] = useState<AdminUser | null>(null);
  const [singleTargetLevel, setSingleTargetLevel] = useState<number>(1);
  const [saving, setSaving] = useState(false);
  const [feedback, setFeedback] = useState<{ type: "success" | "error"; message: string } | null>(null);

  // Master Data Lists
  const allRanges = useMemo(() => getRanges(), []);
  const allZones = useMemo(() => getZones(selectedRange || undefined), [selectedRange]);
  const allDivisions = useMemo(() => getDivisions(selectedRange || undefined, selectedZone || undefined), [selectedRange, selectedZone]);
  const allPoliceStations = useMemo(
    () => getPoliceStations(selectedRange || undefined, selectedZone || undefined, selectedDivision || undefined),
    [selectedRange, selectedZone, selectedDivision],
  );

  // All Master Stations for dynamic target selectors
  const globalAllStations = useMemo(() => getPoliceStations(), []);
  const globalAllDivisions = useMemo(() => getDivisions(), []);
  const globalAllZones = useMemo(() => getZones(), []);

  // Helper to clear selections, per-row drafts, and bulk state
  const resetSelectionsAndDrafts = () => {
    setSelectedUserIds([]);
    setRowActionMap({});
    setBulkTargetPs("");
    setBulkTargetDivision("");
    setBulkTargetZone("");
    setBulkTargetRange("");
    setBulkTargetSector("");
  };

  // Fetch initial total application users count on mount
  useEffect(() => {
    const fetchAppTotal = async () => {
      try {
        const res = await fetch("/api/admin/role-allotment?source=station");
        const data = await res.json();
        if (res.ok && typeof data.totalApplicationUsers === "number") {
          setTotalApplicationUsers(data.totalApplicationUsers);
        }
      } catch {
        // Silent catch on initial mount count fetch
      }
    };
    fetchAppTotal();
  }, []);

  // Cascade Handlers with immediate clearing
  const handleRangeChange = (val: string) => {
    if (fetchControllerRef.current) fetchControllerRef.current.abort();
    setSelectedRange(val);
    setSelectedZone("");
    setSelectedDivision("");
    setSelectedPs("");
    setRosterUsers([]);
    setTotalRosterCount(0);
    resetSelectionsAndDrafts();
  };

  const handleZoneChange = (val: string) => {
    if (fetchControllerRef.current) fetchControllerRef.current.abort();
    setSelectedZone(val);
    setSelectedDivision("");
    setSelectedPs("");
    setRosterUsers([]);
    setTotalRosterCount(0);
    resetSelectionsAndDrafts();
  };

  const handleDivisionChange = (val: string) => {
    if (fetchControllerRef.current) fetchControllerRef.current.abort();
    setSelectedDivision(val);
    setSelectedPs("");
    setRosterUsers([]);
    setTotalRosterCount(0);
    resetSelectionsAndDrafts();
  };

  const handlePsChange = (val: string) => {
    if (fetchControllerRef.current) fetchControllerRef.current.abort();
    setSelectedPs(val);
    setRosterUsers([]);
    setTotalRosterCount(0);
    resetSelectionsAndDrafts();
    if (val && officerSource === "STATION") {
      fetchRosterUsers("station", val, "");
    }
  };

  const handleOfficerSourceChange = (mode: "STATION" | "ALL") => {
    if (fetchControllerRef.current) fetchControllerRef.current.abort();
    setOfficerSource(mode);
    setRosterUsers([]);
    setTotalRosterCount(0);
    setFetchError("");
    resetSelectionsAndDrafts();
    setFilterName("");
    setFilterEmpId("");
    setFilterRank("");
    setFilterStatus("ALL");

    if (mode === "STATION" && selectedPs) {
      fetchRosterUsers("station", selectedPs, "");
    } else if (mode === "ALL" && allUsersSearchQuery.trim()) {
      fetchRosterUsers("all", "", allUsersSearchQuery.trim());
    }
  };

  const handleSearchAllUsers = () => {
    if (officerSource === "ALL") {
      resetSelectionsAndDrafts();
      fetchRosterUsers("all", "", allUsersSearchQuery.trim());
    }
  };

  // Fetch Users Function with AbortController Race Protection & Total Count Handling
  const fetchRosterUsers = async (mode: "station" | "all", psName: string, queryStr: string) => {
    if (fetchControllerRef.current) {
      fetchControllerRef.current.abort();
    }
    const controller = new AbortController();
    fetchControllerRef.current = controller;

    setLoadingUsers(true);
    setFetchError("");
    resetSelectionsAndDrafts();

    try {
      let url = `/api/admin/role-allotment?source=${mode}`;
      if (mode === "station" && psName) {
        url += `&policeStationName=${encodeURIComponent(psName)}`;
      } else if (mode === "all" && queryStr) {
        url += `&search=${encodeURIComponent(queryStr)}`;
      }

      const res = await fetch(url, { signal: controller.signal });
      const data = await res.json();

      if (!res.ok) {
        throw new Error(data.error || "Failed to load officer roster.");
      }

      const users: AdminUser[] = data.users || [];
      setRosterUsers(users);
      setTotalRosterCount(typeof data.total === "number" ? data.total : users.length);
      if (typeof data.totalApplicationUsers === "number") {
        setTotalApplicationUsers(data.totalApplicationUsers);
      }

      // Initialize rowActionMap for loaded users
      const initialMap: Record<string, RowActionConfig> = {};
      users.forEach((u) => {
        initialMap[u.id] = {
          assignmentAction: "RETAIN",
          reassignLevel: u.accessLevel && u.accessLevel >= 1 && u.accessLevel <= 7 ? u.accessLevel : 1,
          targetPs: u.policeStationName || psName || globalAllStations[0] || "",
          targetDivision: u.divisionName || globalAllDivisions[0] || "",
          targetZone: u.zoneName || globalAllZones[0] || "",
          targetRange: u.rangeName || allRanges[0] || "",
          targetSector: u.sectorName || "",
        };
      });
      setRowActionMap(initialMap);
    } catch (err) {
      if (err instanceof Error && err.name === "AbortError") {
        return;
      }
      setFetchError(err instanceof Error ? err.message : "Error fetching roster.");
      setRosterUsers([]);
      setTotalRosterCount(0);
    } finally {
      if (fetchControllerRef.current === controller) {
        setLoadingUsers(false);
      }
    }
  };

  // Interlinked Filter handlers
  const handleFilterNameChange = (val: string) => {
    setFilterName(val);
    if (val) {
      const found = rosterUsers.find((u) => u.name === val);
      if (found) {
        setFilterEmpId(found.employeeId);
        setFilterRank(normalizeOfficerRank(found.rank));
      }
    } else {
      setFilterEmpId("");
      setFilterRank("");
    }
  };

  const handleFilterEmpIdChange = (val: string) => {
    setFilterEmpId(val);
    if (val) {
      const found = rosterUsers.find((u) => u.employeeId === val);
      if (found) {
        setFilterName(found.name);
        setFilterRank(normalizeOfficerRank(found.rank));
      }
    } else {
      setFilterName("");
      setFilterRank("");
    }
  };

  // Filtered Roster Officers
  const filteredRoster = useMemo(() => {
    return rosterUsers.filter((user) => {
      if (filterName && user.name !== filterName) return false;
      if (filterEmpId && user.employeeId !== filterEmpId) return false;
      if (filterRank && normalizeOfficerRank(user.rank) !== filterRank) return false;
      if (filterStatus === "ASSIGNED") {
        const isAssigned = Boolean(user.role && user.accessLevel >= 1 && user.accessLevel <= 7);
        if (!isAssigned) return false;
      } else if (filterStatus === "NOT_ASSIGNED") {
        const isAssigned = Boolean(user.role && user.accessLevel >= 1 && user.accessLevel <= 7);
        if (isAssigned) return false;
      }
      return true;
    });
  }, [rosterUsers, filterName, filterEmpId, filterRank, filterStatus]);

  // Protected Admin exclusion (Employee ID 1837323 & acting admin)
  const selectableFilteredRoster = useMemo(() => {
    return filteredRoster.filter((u) => u.employeeId !== "1837323" && u.role !== "ADMIN");
  }, [filteredRoster]);

  // Select All Displayed checkbox state
  const isAllDisplayedSelected =
    selectableFilteredRoster.length > 0 &&
    selectableFilteredRoster.every((u) => selectedUserIds.includes(u.id));

  const toggleSelectAllDisplayed = () => {
    if (isAllDisplayedSelected) {
      const selectableIds = new Set(selectableFilteredRoster.map((u) => u.id));
      setSelectedUserIds((prev) => prev.filter((id) => !selectableIds.has(id)));
    } else {
      const newIds = new Set([...selectedUserIds, ...selectableFilteredRoster.map((u) => u.id)]);
      setSelectedUserIds(Array.from(newIds));
    }
  };

  const toggleUserSelection = (userId: string, isProtected: boolean) => {
    if (isProtected) return;
    setSelectedUserIds((prev) => (prev.includes(userId) ? prev.filter((id) => id !== userId) : [...prev, userId]));
  };

  // Row Action Config Updater
  const updateRowAction = (userId: string, key: keyof RowActionConfig, value: unknown) => {
    setRowActionMap((prev) => ({
      ...prev,
      [userId]: {
        ...(prev[userId] || {
          assignmentAction: "RETAIN",
          reassignLevel: 1,
          targetPs: selectedPs || globalAllStations[0] || "",
          targetDivision: globalAllDivisions[0] || "",
          targetZone: globalAllZones[0] || "",
          targetRange: allRanges[0] || "",
          targetSector: "",
        }),
        [key]: value,
      },
    }));
  };

  // Single Row Action Trigger
  const triggerSingleRowAction = (user: AdminUser) => {
    const config = rowActionMap[user.id];
    if (!config || config.assignmentAction === "RETAIN") return;
    setSingleTargetUser(user);
    setSingleTargetLevel(config.reassignLevel);
    setModalMode("SINGLE");
    setShowConfirmModal(true);
  };

  // Bulk Action Trigger
  const triggerBulkAction = () => {
    if (selectedUserIds.length === 0) return;
    setModalMode("BULK");
    setShowConfirmModal(true);
  };

  // Target Role Config for Modal Display
  const currentTargetRoleOption = useMemo(() => {
    const level = modalMode === "SINGLE" ? singleTargetLevel : bulkLevel;
    return ROLE_OPTIONS.find((r) => r.level === level) || ROLE_OPTIONS[0];
  }, [modalMode, singleTargetLevel, bulkLevel]);

  // Selected Target Objects for Modal
  const modalTargetUsers = useMemo(() => {
    if (modalMode === "SINGLE" && singleTargetUser) {
      return [singleTargetUser];
    }
    return rosterUsers.filter((u) => selectedUserIds.includes(u.id));
  }, [modalMode, singleTargetUser, rosterUsers, selectedUserIds]);

  // Execute Role Allotment POST API
  const executeRoleAllotment = async () => {
    const targetIds = modalTargetUsers.map((u) => u.id);
    if (targetIds.length === 0) return;

    setSaving(true);
    setFeedback(null);

    try {
      const level = modalMode === "SINGLE" ? singleTargetLevel : bulkLevel;
      const roleOption = ROLE_OPTIONS.find((r) => r.level === level) || ROLE_OPTIONS[0];

      let targetPs: string | null = null;
      let targetDivision: string | null = null;
      let targetZone: string | null = null;
      let targetRange: string | null = null;
      let targetSector: string | null = null;

      if (modalMode === "SINGLE" && singleTargetUser) {
        const config = rowActionMap[singleTargetUser.id];
        targetPs = config?.targetPs || null;
        targetDivision = config?.targetDivision || null;
        targetZone = config?.targetZone || null;
        targetRange = config?.targetRange || null;
        targetSector = config?.targetSector || null;
      } else {
        targetPs = bulkTargetPs || selectedPs || null;
        targetDivision = bulkTargetDivision || null;
        targetZone = bulkTargetZone || null;
        targetRange = bulkTargetRange || null;
        targetSector = bulkTargetSector || null;
      }

      const res = await fetch("/api/admin/role-allotment", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          targetUserIds: targetIds,
          role: roleOption.role,
          policeStationName: targetPs,
          divisionName: targetDivision,
          zoneName: targetZone,
          rangeName: targetRange,
          sectorName: targetSector,
        }),
      });

      const data = await res.json();
      if (!res.ok) {
        throw new Error(data.error || "Role allotment failed.");
      }

      setFeedback({ type: "success", message: data.message || "Role allotment updated successfully." });
      setShowConfirmModal(false);
      setSelectedUserIds([]);

      // Refresh roster
      if (officerSource === "STATION" && selectedPs) {
        fetchRosterUsers("station", selectedPs, "");
      } else if (officerSource === "ALL") {
        fetchRosterUsers("all", "", allUsersSearchQuery);
      }
    } catch (err) {
      setFeedback({ type: "error", message: err instanceof Error ? err.message : "Error saving allotment." });
      setShowConfirmModal(false);
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="min-h-screen bg-[#060B18] text-slate-100 p-6 md:p-8 space-y-8">
      {/* HEADER BAR */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 border-b border-slate-800/80 pb-6">
        <div>
          <div className="flex items-center gap-3">
            <Link
              href="/dashboard/settings"
              className="text-xs font-bold text-slate-400 hover:text-white transition bg-slate-900 border border-slate-800 px-3 py-1.5 rounded-lg"
            >
              ← Back to Settings Hub
            </Link>
            <span className="text-xs text-blue-400 font-semibold uppercase tracking-wider bg-blue-950/60 border border-blue-800/50 px-2.5 py-1 rounded-md">
              Settings → Role Allotment
            </span>
          </div>
          <h1 className="mt-3 text-2xl md:text-3xl font-black tracking-tight text-white uppercase">
            ROLE ALLOTMENT
          </h1>
          <p className="mt-1 text-xs md:text-sm text-slate-400">
            Assign application users to operational roles and authorized jurisdiction.
          </p>
        </div>
      </div>

      {/* FEEDBACK BANNER */}
      {feedback && (
        <div
          className={`rounded-2xl border p-4 text-xs md:text-sm flex items-center justify-between shadow-lg ${
            feedback.type === "success"
              ? "border-emerald-500/40 bg-emerald-950/40 text-emerald-200"
              : "border-rose-500/40 bg-rose-950/40 text-rose-200"
          }`}
        >
          <div className="flex items-center gap-3">
            <span className="text-xl">{feedback.type === "success" ? "✅" : "⚠️"}</span>
            <p className="font-semibold">{feedback.message}</p>
          </div>
          <button
            type="button"
            onClick={() => setFeedback(null)}
            className="text-slate-300 hover:text-white font-bold text-xs bg-slate-900/60 px-2.5 py-1 rounded-lg"
          >
            Dismiss
          </button>
        </div>
      )}

      {/* TOP HIERARCHY CASCADE & WING SELECTOR */}
      <div className="rounded-2xl border border-slate-800 bg-slate-900/80 p-6 shadow-xl space-y-6">
        <div className="flex items-center justify-between border-b border-slate-800 pb-4">
          <div>
            <h2 className="text-sm font-black uppercase tracking-wider text-blue-400">
              1. Top Hierarchy & Operational Wing Cascade
            </h2>
            <p className="text-xs text-slate-400">Select Wing and cascade down from Range to Police Station.</p>
          </div>
          <span className="text-xs font-bold text-slate-300 bg-slate-950 px-3 py-1 rounded-full border border-slate-800">
            Master Data: GANESH_HIERARCHY
          </span>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-5 gap-4">
          {/* WING SELECTOR */}
          <div>
            <label className="block text-xs font-bold text-slate-300 uppercase tracking-wider mb-1.5">
              Wing
            </label>
            <select
              value={selectedWing}
              onChange={(e) => setSelectedWing(e.target.value)}
              className="w-full rounded-xl border border-blue-500/50 bg-slate-950 px-3.5 py-2.5 text-xs text-white font-bold focus:border-blue-400 focus:outline-none"
            >
              <option value="L_AND_O">L & O (Law & Order)</option>
            </select>
          </div>

          {/* RANGE CASCADE */}
          <div>
            <label className="block text-xs font-bold text-slate-300 uppercase tracking-wider mb-1.5">
              Range
            </label>
            <select
              value={selectedRange}
              onChange={(e) => handleRangeChange(e.target.value)}
              className="w-full rounded-xl border border-slate-700 bg-slate-950 px-3.5 py-2.5 text-xs text-white focus:border-blue-500 focus:outline-none"
            >
              <option value="">-- Select Range --</option>
              {allRanges.map((r) => (
                <option key={r} value={r}>
                  {r}
                </option>
              ))}
            </select>
          </div>

          {/* ZONE CASCADE */}
          <div>
            <label className="block text-xs font-bold text-slate-300 uppercase tracking-wider mb-1.5">
              Zone
            </label>
            <select
              value={selectedZone}
              onChange={(e) => handleZoneChange(e.target.value)}
              disabled={!selectedRange}
              className="w-full rounded-xl border border-slate-700 bg-slate-950 px-3.5 py-2.5 text-xs text-white disabled:opacity-40 focus:border-blue-500 focus:outline-none"
            >
              <option value="">-- Select Zone --</option>
              {allZones.map((z) => (
                <option key={z} value={z}>
                  {z}
                </option>
              ))}
            </select>
          </div>

          {/* DIVISION CASCADE */}
          <div>
            <label className="block text-xs font-bold text-slate-300 uppercase tracking-wider mb-1.5">
              Division
            </label>
            <select
              value={selectedDivision}
              onChange={(e) => handleDivisionChange(e.target.value)}
              disabled={!selectedZone}
              className="w-full rounded-xl border border-slate-700 bg-slate-950 px-3.5 py-2.5 text-xs text-white disabled:opacity-40 focus:border-blue-500 focus:outline-none"
            >
              <option value="">-- Select Division --</option>
              {allDivisions.map((d) => (
                <option key={d} value={d}>
                  {d}
                </option>
              ))}
            </select>
          </div>

          {/* POLICE STATION CASCADE */}
          <div>
            <label className="block text-xs font-bold text-slate-300 uppercase tracking-wider mb-1.5">
              Police Station
            </label>
            <select
              value={selectedPs}
              onChange={(e) => handlePsChange(e.target.value)}
              disabled={!selectedDivision}
              className="w-full rounded-xl border border-blue-500/80 bg-slate-950 px-3.5 py-2.5 text-xs text-white font-bold disabled:opacity-40 focus:border-blue-400 focus:outline-none"
            >
              <option value="">-- Select Station --</option>
              {allPoliceStations.map((ps) => (
                <option key={ps} value={ps}>
                  {ps}
                </option>
              ))}
            </select>
          </div>
        </div>
      </div>

      {/* OFFICER SOURCE & ROSTER SECTION */}
      <div className="rounded-2xl border border-slate-800 bg-slate-900/80 p-6 shadow-xl space-y-6">
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 border-b border-slate-800 pb-4">
          <div>
            <h2 className="text-sm font-black uppercase tracking-wider text-blue-400">
              2. Officer Roster Source & Interlinked Filters
            </h2>
            <p className="text-xs text-slate-400">Select source mode and apply interlinked officer filters.</p>
          </div>

          {/* OFFICER SOURCE CONTROL */}
          <div className="flex items-center gap-3 bg-slate-950 p-1.5 rounded-xl border border-slate-800">
            <span className="text-xs font-extrabold uppercase text-slate-400 pl-2">Officer Source:</span>
            <button
              type="button"
              onClick={() => handleOfficerSourceChange("STATION")}
              className={`px-3 py-1.5 rounded-lg text-xs font-bold transition ${
                officerSource === "STATION"
                  ? "bg-blue-600 text-white shadow-md"
                  : "text-slate-400 hover:text-white"
              }`}
            >
              Selected Police Station
            </button>
            <button
              type="button"
              onClick={() => handleOfficerSourceChange("ALL")}
              className={`px-3 py-1.5 rounded-lg text-xs font-bold transition ${
                officerSource === "ALL"
                  ? "bg-indigo-600 text-white shadow-md"
                  : "text-slate-400 hover:text-white"
              }`}
            >
              All Users Search
            </button>
          </div>
        </div>

        {/* ALL USERS SEARCH INPUT */}
        {officerSource === "ALL" && (
          <div className="flex items-center gap-3 bg-indigo-950/40 p-4 rounded-xl border border-indigo-800/60">
            <input
              type="text"
              value={allUsersSearchQuery}
              onChange={(e) => setAllUsersSearchQuery(e.target.value)}
              onKeyDown={(e) => e.key === "Enter" && handleSearchAllUsers()}
              placeholder="Search by Officer Name or Employee ID across all application users..."
              className="flex-1 rounded-xl border border-indigo-700/60 bg-slate-950 px-4 py-2.5 text-xs text-white placeholder-slate-500 focus:border-indigo-400 focus:outline-none"
            />
            <button
              type="button"
              onClick={handleSearchAllUsers}
              className="rounded-xl bg-indigo-600 hover:bg-indigo-500 px-5 py-2.5 text-xs font-extrabold text-white transition shadow-md"
            >
              Search Users
            </button>
          </div>
        )}

        {/* INTERLINKED FILTERS BAR */}
        <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-4 gap-4 bg-slate-950/60 p-4 rounded-xl border border-slate-800">
          <div>
            <label className="block text-[11px] font-bold text-slate-400 uppercase mb-1">Name</label>
            <select
              value={filterName}
              onChange={(e) => handleFilterNameChange(e.target.value)}
              className="w-full rounded-lg border border-slate-700 bg-slate-900 px-3 py-2 text-xs text-white focus:border-blue-500 focus:outline-none"
            >
              <option value="">All Names</option>
              {Array.from(new Set(rosterUsers.map((u) => u.name))).map((n) => (
                <option key={n} value={n}>
                  {n}
                </option>
              ))}
            </select>
          </div>

          <div>
            <label className="block text-[11px] font-bold text-slate-400 uppercase mb-1">Employee ID</label>
            <select
              value={filterEmpId}
              onChange={(e) => handleFilterEmpIdChange(e.target.value)}
              className="w-full rounded-lg border border-slate-700 bg-slate-900 px-3 py-2 text-xs text-white focus:border-blue-500 focus:outline-none"
            >
              <option value="">All Employee IDs</option>
              {Array.from(new Set(rosterUsers.map((u) => u.employeeId))).map((emp) => (
                <option key={emp} value={emp}>
                  {emp}
                </option>
              ))}
            </select>
          </div>

          <div>
            <label className="block text-[11px] font-bold text-slate-400 uppercase mb-1">Normalized Rank</label>
            <select
              value={filterRank}
              onChange={(e) => setFilterRank(e.target.value)}
              className="w-full rounded-lg border border-slate-700 bg-slate-900 px-3 py-2 text-xs text-white focus:border-blue-500 focus:outline-none"
            >
              <option value="">All Ranks</option>
              <option value="Inspector">Inspector</option>
              <option value="SI">SI</option>
              <option value="ASI">ASI</option>
              <option value="HC">HC</option>
              <option value="PC">PC</option>
              <option value="HG">HG</option>
              <option value="Other">Other</option>
            </select>
          </div>

          <div>
            <label className="block text-[11px] font-bold text-slate-400 uppercase mb-1">Assignment Status</label>
            <select
              value={filterStatus}
              onChange={(e) => setFilterStatus(e.target.value)}
              className="w-full rounded-lg border border-slate-700 bg-slate-900 px-3 py-2 text-xs text-white focus:border-blue-500 focus:outline-none"
            >
              <option value="ALL">All Statuses</option>
              <option value="ASSIGNED">Assigned</option>
              <option value="NOT_ASSIGNED">Not Assigned</option>
            </select>
          </div>
        </div>

        {/* UI COUNTERS SUMMARY BAR */}
        <div className="flex flex-wrap items-center justify-between gap-4 bg-slate-950 p-4 rounded-xl border border-slate-800 text-xs">
          {officerSource === "STATION" ? (
            <div className="flex flex-wrap items-center gap-4">
              <span className="font-bold text-slate-300">
                Current System PS: <span className="text-blue-400 font-extrabold">{selectedPs || "None Selected"}</span>
              </span>
              <span className="text-slate-700">|</span>
              <span className="font-bold text-slate-300">
                Officers in Current System PS: <span className="text-emerald-400 font-extrabold">{totalRosterCount}</span>
              </span>
              <span className="text-slate-700">|</span>
              <span className="font-bold text-slate-300">
                Displayed: <span className="text-indigo-400 font-extrabold">{filteredRoster.length}</span>
              </span>
            </div>
          ) : (
            <div className="flex flex-wrap items-center gap-4">
              <span className="font-bold text-slate-300">
                Total Application Users:{" "}
                <span className="text-amber-400 font-extrabold">
                  {totalApplicationUsers ? totalApplicationUsers.toLocaleString() : "1,444"}
                </span>
              </span>
              <span className="text-slate-700">|</span>
              <span className="font-bold text-slate-300">
                Search Results: <span className="text-emerald-400 font-extrabold">{totalRosterCount}</span>
              </span>
              <span className="text-slate-700">|</span>
              <span className="font-bold text-slate-300">
                Displayed: <span className="text-indigo-400 font-extrabold">{filteredRoster.length}</span>
              </span>
            </div>
          )}
          <span className="text-[11px] font-semibold text-slate-500 uppercase tracking-wider">
            {officerSource === "STATION" ? "Scope: Selected Police Station Only" : "Scope: Complete Application Directory"}
          </span>
        </div>

        {/* BULK ACTION PANEL (Shown when 1+ officers are checked) */}
        {selectedUserIds.length > 0 && (
          <div className="p-4 rounded-xl border border-indigo-500/50 bg-indigo-950/40 space-y-4 shadow-xl">
            <div className="flex flex-col md:flex-row md:items-center justify-between gap-3 border-b border-indigo-800/60 pb-3">
              <div className="flex items-center gap-3">
                <span className="rounded-lg bg-indigo-600 px-3 py-1 text-xs font-black text-white uppercase tracking-wider shadow">
                  SELECTED OFFICERS: {selectedUserIds.length}
                </span>
                <span className="text-xs text-indigo-200 font-medium">
                  Bulk Assignment Panel (Overrides per-row dropdowns)
                </span>
              </div>

              <button
                type="button"
                onClick={triggerBulkAction}
                className="inline-flex items-center gap-2 rounded-xl bg-gradient-to-r from-emerald-600 to-teal-600 px-5 py-2 text-xs font-extrabold text-white shadow-md hover:from-emerald-500 hover:to-teal-500 transition ring-2 ring-emerald-400/40"
              >
                <span>⚡</span> APPLY TO {selectedUserIds.length} SELECTED OFFICERS →
              </button>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div>
                <label className="block text-xs font-bold text-indigo-200 uppercase mb-1">
                  Bulk Assign / Reassign As
                </label>
                <select
                  value={bulkLevel}
                  onChange={(e) => setBulkLevel(Number(e.target.value))}
                  className="w-full rounded-lg border border-indigo-700 bg-slate-950 px-3 py-2 text-xs text-white font-bold focus:border-emerald-400 focus:outline-none"
                >
                  {ROLE_OPTIONS.map((opt) => (
                    <option key={opt.level} value={opt.level}>
                      {opt.label}
                    </option>
                  ))}
                </select>
              </div>

              {/* Dynamic Target Jurisdiction for Bulk */}
              {bulkLevel <= 3 && (
                <div>
                  <label className="block text-xs font-bold text-indigo-200 uppercase mb-1">Target Police Station</label>
                  <select
                    value={bulkTargetPs || selectedPs}
                    onChange={(e) => setBulkTargetPs(e.target.value)}
                    className="w-full rounded-lg border border-indigo-700 bg-slate-950 px-3 py-2 text-xs text-white focus:border-emerald-400 focus:outline-none"
                  >
                    {globalAllStations.map((ps) => (
                      <option key={ps} value={ps}>
                        {ps}
                      </option>
                    ))}
                  </select>
                </div>
              )}

              {bulkLevel === 4 && (
                <div>
                  <label className="block text-xs font-bold text-indigo-200 uppercase mb-1">Target Division</label>
                  <select
                    value={bulkTargetDivision}
                    onChange={(e) => setBulkTargetDivision(e.target.value)}
                    className="w-full rounded-lg border border-indigo-700 bg-slate-950 px-3 py-2 text-xs text-white focus:border-emerald-400 focus:outline-none"
                  >
                    <option value="">-- Select Division --</option>
                    {globalAllDivisions.map((d) => (
                      <option key={d} value={d}>
                        {d}
                      </option>
                    ))}
                  </select>
                </div>
              )}

              {bulkLevel === 5 && (
                <div>
                  <label className="block text-xs font-bold text-indigo-200 uppercase mb-1">Target Zone</label>
                  <select
                    value={bulkTargetZone}
                    onChange={(e) => setBulkTargetZone(e.target.value)}
                    className="w-full rounded-lg border border-indigo-700 bg-slate-950 px-3 py-2 text-xs text-white focus:border-emerald-400 focus:outline-none"
                  >
                    <option value="">-- Select Zone --</option>
                    {globalAllZones.map((z) => (
                      <option key={z} value={z}>
                        {z}
                      </option>
                    ))}
                  </select>
                </div>
              )}

              {bulkLevel === 6 && (
                <div>
                  <label className="block text-xs font-bold text-indigo-200 uppercase mb-1">Target Range</label>
                  <select
                    value={bulkTargetRange}
                    onChange={(e) => setBulkTargetRange(e.target.value)}
                    className="w-full rounded-lg border border-indigo-700 bg-slate-950 px-3 py-2 text-xs text-white focus:border-emerald-400 focus:outline-none"
                  >
                    <option value="">-- Select Range --</option>
                    {allRanges.map((r) => (
                      <option key={r} value={r}>
                        {r}
                      </option>
                    ))}
                  </select>
                </div>
              )}

              {bulkLevel === 7 && (
                <div>
                  <label className="block text-xs font-bold text-rose-300 uppercase mb-1">Commissionerate Access</label>
                  <span className="block text-xs font-black text-amber-400 bg-amber-950/60 p-2 rounded-lg border border-amber-800">
                    ⚠️ Granting Commissionerate Admin Access
                  </span>
                </div>
              )}
            </div>
          </div>
        )}

        {/* OFFICER ROSTER TABLE */}
        {loadingUsers ? (
          <div className="p-8 text-center text-xs text-slate-400 font-semibold animate-pulse">
            Loading roster officers...
          </div>
        ) : fetchError ? (
          <div className="p-4 rounded-xl border border-rose-800 bg-rose-950/40 text-xs text-rose-300 font-semibold">
            {fetchError}
          </div>
        ) : rosterUsers.length === 0 ? (
          <div className="p-8 text-center text-xs text-slate-400 font-semibold border border-dashed border-slate-800 rounded-xl">
            {officerSource === "STATION"
              ? selectedPs
                ? `No officers found for ${selectedPs} Police Station.`
                : "Select Range → Zone → Division → Police Station above to display roster officers."
              : allUsersSearchQuery.trim()
              ? "No officers found matching search query."
              : "Enter Officer Name or Employee ID to search all users."}
          </div>
        ) : (
          <div className="overflow-x-auto rounded-xl border border-slate-800">
            <table className="w-full text-left text-xs text-slate-300">
              <thead className="bg-slate-950 text-slate-400 font-bold uppercase tracking-wider text-[11px] sticky top-0">
                <tr>
                  <th className="p-3 w-10 text-center sticky left-0 z-20 bg-slate-950">
                    <input
                      type="checkbox"
                      checked={isAllDisplayedSelected}
                      onChange={toggleSelectAllDisplayed}
                      className="rounded border-slate-700 bg-slate-900 text-blue-600 focus:ring-blue-500 cursor-pointer"
                      title="Select All Displayed Officers"
                    />
                  </th>
                  <th className="p-3 sticky left-10 z-20 bg-slate-950 shadow-md">Officer Name</th>
                  <th className="p-3">Employee ID</th>
                  <th className="p-3">Rank</th>
                  <th className="p-3">Status</th>
                  <th className="p-3">Current Application Role</th>
                  <th className="p-3">Current System PS</th>
                  <th className="p-3">Current Div / Zone / Range</th>
                  <th className="p-3">Assignment Action</th>
                  <th className="p-3">Reassign As</th>
                  <th className="p-3">Target Jurisdiction</th>
                  <th className="p-3 text-center">Action</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-800/60 bg-slate-900/40 font-medium">
                {filteredRoster.map((user) => {
                  const isProtected = user.employeeId === "1837323" || user.role === "ADMIN";
                  const isChecked = selectedUserIds.includes(user.id);
                  const normalizedRank = normalizeOfficerRank(user.rank);

                  const isAssigned = user.role && user.accessLevel >= 1 && user.accessLevel <= 7;
                  const rowConfig = rowActionMap[user.id] || {
                    assignmentAction: "RETAIN",
                    reassignLevel: user.accessLevel || 1,
                    targetPs: selectedPs || globalAllStations[0] || "",
                    targetDivision: globalAllDivisions[0] || "",
                    targetZone: globalAllZones[0] || "",
                    targetRange: allRanges[0] || "",
                    targetSector: "",
                  };

                  return (
                    <tr
                      key={user.id}
                      className={`hover:bg-slate-800/40 transition ${isChecked ? "bg-blue-950/30" : ""}`}
                    >
                      {/* SELECT CHECKBOX */}
                      <td className="p-3 text-center sticky left-0 z-10 bg-slate-900/90">
                        <input
                          type="checkbox"
                          checked={isChecked}
                          disabled={isProtected}
                          onChange={() => toggleUserSelection(user.id, isProtected)}
                          className="rounded border-slate-700 bg-slate-900 text-blue-600 focus:ring-blue-500 disabled:opacity-30 cursor-pointer"
                        />
                      </td>

                      {/* NAME */}
                      <td className="p-3 font-bold text-white flex items-center gap-2 sticky left-10 z-10 bg-slate-900/90 shadow-md">
                        {user.name}
                        {isProtected && (
                          <span className="rounded bg-amber-950 border border-amber-800 px-1.5 py-0.5 text-[9px] font-black uppercase text-amber-400">
                            Protected Admin
                          </span>
                        )}
                      </td>

                      {/* EMPLOYEE ID */}
                      <td className="p-3 font-mono text-slate-300">{user.employeeId}</td>

                      {/* RANK (RAW / NORMALIZED) */}
                      <td className="p-3">
                        <span className="text-slate-200 font-semibold">{user.rank}</span>
                        <span className="text-[10px] text-slate-500 block">({normalizedRank})</span>
                      </td>

                      {/* ASSIGNMENT STATUS */}
                      <td className="p-3">
                        <span
                          className={`rounded-md border px-2 py-0.5 text-[10px] font-black uppercase tracking-wider ${
                            isAssigned
                              ? "bg-emerald-950/80 border-emerald-800 text-emerald-400"
                              : "bg-amber-950/80 border-amber-800 text-amber-400"
                          }`}
                        >
                          {isAssigned ? "ASSIGNED" : "NOT ASSIGNED"}
                        </span>
                      </td>

                      {/* CURRENT APPLICATION ROLE */}
                      <td className="p-3 font-semibold text-blue-300">
                        {isAssigned ? `Level ${user.accessLevel} — ${user.role}` : "Not Assigned"}
                      </td>

                      {/* CURRENT SYSTEM POLICE STATION */}
                      <td className="p-3 font-bold text-slate-200">
                        {user.policeStationName || "—"}
                      </td>

                      {/* CURRENT DIVISION / ZONE / RANGE */}
                      <td className="p-3 text-slate-300 text-[11px]">
                        {(() => {
                          // Level 1, 2, 3 with Police Station
                          if (user.policeStationName) {
                            const resolved = getHierarchyForPoliceStation(user.policeStationName);
                            if (resolved) {
                              const isMismatch =
                                (user.divisionName && user.divisionName.toLowerCase() !== resolved.division.toLowerCase()) ||
                                (user.zoneName && user.zoneName.toLowerCase() !== resolved.zone.toLowerCase()) ||
                                (user.rangeName && user.rangeName.toLowerCase() !== resolved.range.toLowerCase());
                              return (
                                <div>
                                  <span className="font-semibold text-slate-200">
                                    {resolved.division} / {resolved.zone} / {resolved.range}
                                  </span>
                                  {isMismatch && (
                                    <span className="text-[9px] font-bold text-amber-400 bg-amber-950/80 border border-amber-800/80 px-1.5 py-0.5 rounded block w-max mt-0.5">
                                      Stored jurisdiction differs
                                    </span>
                                  )}
                                </div>
                              );
                            }
                          }

                          // Level 4 (DIVISIONAL_SUPERVISOR) - Primary scope: divisionName
                          if (user.accessLevel === 4 || user.role === "DIVISIONAL_SUPERVISOR") {
                            const divName = user.divisionName;
                            if (divName) {
                              const resolved = getHierarchyForDivision(divName);
                              if (resolved) {
                                return (
                                  <span className="font-semibold text-slate-200">
                                    {resolved.division} Division → {resolved.zone} / {resolved.range}
                                  </span>
                                );
                              }
                              return <span className="font-semibold text-slate-200">{divName} Division</span>;
                            }
                            return <span className="text-slate-500">Unassigned Division</span>;
                          }

                          // Level 5 (ZONAL_SUPERVISOR) - Primary scope: zoneName
                          if (user.accessLevel === 5 || user.role === "ZONAL_SUPERVISOR") {
                            const zName = user.zoneName;
                            if (zName) {
                              const resolved = getHierarchyForZone(zName);
                              if (resolved) {
                                return (
                                  <span className="font-semibold text-slate-200">
                                    {resolved.zone} Zone → {resolved.range}
                                  </span>
                                );
                              }
                              return <span className="font-semibold text-slate-200">{zName} Zone</span>;
                            }
                            return <span className="text-slate-500">Unassigned Zone</span>;
                          }

                          // Level 6 (RANGE_SUPERVISOR) - Primary scope: rangeName
                          if (user.accessLevel === 6 || user.role === "RANGE_SUPERVISOR") {
                            const rName = user.rangeName;
                            if (rName) {
                              return <span className="font-semibold text-slate-200">{rName}</span>;
                            }
                            return <span className="text-slate-500">Unassigned Range</span>;
                          }

                          // Level 7 (ADMIN)
                          if (user.accessLevel === 7 || user.role === "ADMIN") {
                            return <span className="font-semibold text-amber-400">Hyderabad Commissionerate / Admin</span>;
                          }

                          const parts = [user.divisionName, user.zoneName, user.rangeName].filter(Boolean);
                          return <span>{parts.length > 0 ? parts.join(" / ") : "Commissionerate Wide"}</span>;
                        })()}
                      </td>

                      {/* ASSIGNMENT ACTION DROPDOWN */}
                      <td className="p-3">
                        <select
                          value={rowConfig.assignmentAction}
                          disabled={isProtected}
                          onChange={(e) => updateRowAction(user.id, "assignmentAction", e.target.value)}
                          className="rounded-lg border border-slate-700 bg-slate-950 px-2 py-1 text-xs text-white focus:border-blue-500 focus:outline-none disabled:opacity-30"
                        >
                          <option value="RETAIN">Retain</option>
                          <option value="REASSIGN">Remove / Reassign</option>
                        </select>
                      </td>

                      {/* REASSIGN AS DROPDOWN */}
                      <td className="p-3">
                        <select
                          value={rowConfig.reassignLevel}
                          disabled={isProtected || rowConfig.assignmentAction === "RETAIN"}
                          onChange={(e) => updateRowAction(user.id, "reassignLevel", Number(e.target.value))}
                          className="rounded-lg border border-slate-700 bg-slate-950 px-2 py-1 text-xs text-white disabled:opacity-30 focus:border-blue-500 focus:outline-none"
                        >
                          {ROLE_OPTIONS.map((opt) => (
                            <option key={opt.level} value={opt.level}>
                              {opt.label}
                            </option>
                          ))}
                        </select>
                      </td>

                      {/* DYNAMIC TARGET JURISDICTION */}
                      <td className="p-3">
                        {rowConfig.assignmentAction === "RETAIN" ? (
                          <span className="text-slate-600 text-[11px]">—</span>
                        ) : rowConfig.reassignLevel <= 3 ? (
                          <select
                            value={rowConfig.targetPs || selectedPs}
                            onChange={(e) => updateRowAction(user.id, "targetPs", e.target.value)}
                            className="rounded-lg border border-slate-700 bg-slate-950 px-2 py-1 text-xs text-white focus:border-blue-500 focus:outline-none"
                          >
                            {globalAllStations.map((ps) => (
                              <option key={ps} value={ps}>
                                {ps}
                              </option>
                            ))}
                          </select>
                        ) : rowConfig.reassignLevel === 4 ? (
                          <select
                            value={rowConfig.targetDivision}
                            onChange={(e) => updateRowAction(user.id, "targetDivision", e.target.value)}
                            className="rounded-lg border border-slate-700 bg-slate-950 px-2 py-1 text-xs text-white focus:border-blue-500 focus:outline-none"
                          >
                            {globalAllDivisions.map((d) => (
                              <option key={d} value={d}>
                                {d}
                              </option>
                            ))}
                          </select>
                        ) : rowConfig.reassignLevel === 5 ? (
                          <select
                            value={rowConfig.targetZone}
                            onChange={(e) => updateRowAction(user.id, "targetZone", e.target.value)}
                            className="rounded-lg border border-slate-700 bg-slate-950 px-2 py-1 text-xs text-white focus:border-blue-500 focus:outline-none"
                          >
                            {globalAllZones.map((z) => (
                              <option key={z} value={z}>
                                {z}
                              </option>
                            ))}
                          </select>
                        ) : rowConfig.reassignLevel === 6 ? (
                          <select
                            value={rowConfig.targetRange}
                            onChange={(e) => updateRowAction(user.id, "targetRange", e.target.value)}
                            className="rounded-lg border border-slate-700 bg-slate-950 px-2 py-1 text-xs text-white focus:border-blue-500 focus:outline-none"
                          >
                            {allRanges.map((r) => (
                              <option key={r} value={r}>
                                {r}
                              </option>
                            ))}
                          </select>
                        ) : (
                          <span className="text-amber-400 font-bold text-[11px]">Commissionerate</span>
                        )}
                      </td>

                      {/* ACTION BUTTON */}
                      <td className="p-3 text-center">
                        <button
                          type="button"
                          disabled={isProtected || rowConfig.assignmentAction === "RETAIN"}
                          onClick={() => triggerSingleRowAction(user)}
                          className={`rounded-lg px-3 py-1 text-[11px] font-bold transition ${
                            rowConfig.assignmentAction === "RETAIN" || isProtected
                              ? "bg-slate-800 text-slate-500 cursor-not-allowed opacity-40"
                              : "bg-emerald-600 hover:bg-emerald-500 text-white shadow-md"
                          }`}
                        >
                          REASSIGN
                        </button>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* CONFIRMATION MODAL */}
      {showConfirmModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-950/80 backdrop-blur-sm">
          <div className="relative w-full max-w-xl rounded-2xl border border-slate-700 bg-[#0A1128] p-6 shadow-2xl space-y-6">
            <div className="flex items-center justify-between border-b border-slate-800 pb-4">
              <div>
                <h3 className="text-lg font-black uppercase tracking-wider text-white flex items-center gap-2">
                  <span>🛡️</span> CONFIRM ROLE ALLOTMENT
                </h3>
                <p className="text-xs text-slate-400 mt-0.5">
                  Verify operational target role and jurisdiction before applying changes.
                </p>
              </div>
              <button
                type="button"
                onClick={() => setShowConfirmModal(false)}
                className="text-slate-400 hover:text-white font-bold text-lg"
              >
                ✕
              </button>
            </div>

            <div className="space-y-4 text-xs">
              {(modalMode === "SINGLE" ? singleTargetLevel : bulkLevel) === 7 && (
                <div className="rounded-xl border border-amber-800 bg-amber-950/60 p-3 text-amber-200 font-bold">
                  ⚠️ WARNING: You are granting Commissionerate-wide administrative access (Level 7 Admin).
                </div>
              )}

              <div className="grid grid-cols-2 gap-3 bg-slate-900/80 p-3.5 rounded-xl border border-slate-800">
                <div>
                  <span className="text-[10px] font-bold uppercase text-slate-500 block">Operational Wing</span>
                  <span className="font-extrabold text-white">L & O (Law & Order)</span>
                </div>
                <div>
                  <span className="text-[10px] font-bold uppercase text-slate-500 block">Target Level & Role</span>
                  <span className="font-extrabold text-emerald-400">{currentTargetRoleOption.label}</span>
                </div>
                <div>
                  <span className="text-[10px] font-bold uppercase text-slate-500 block">Mode</span>
                  <span className="font-extrabold text-indigo-300">
                    {modalMode === "SINGLE" ? "Single Officer Reassignment" : "Bulk Officer Reassignment"}
                  </span>
                </div>
                <div>
                  <span className="text-[10px] font-bold uppercase text-slate-500 block">Affected Count</span>
                  <span className="font-extrabold text-emerald-300">{modalTargetUsers.length} Officer(s)</span>
                </div>
              </div>

              {/* CURRENT VS NEW ASSIGNMENT COMPARISON PANEL */}
              {modalMode === "SINGLE" && singleTargetUser && (() => {
                const config = rowActionMap[singleTargetUser.id];
                const currentPs = singleTargetUser.policeStationName || "None";
                const targetLevel = config?.reassignLevel || 1;
                const newPs = targetLevel <= 3 ? (config?.targetPs || selectedPs || "None") : "N/A (Higher Jurisdiction)";
                const isPsChanging = targetLevel <= 3 && currentPs !== newPs;

                return (
                  <div className="space-y-3">
                    <div className="grid grid-cols-2 gap-3 bg-slate-950 p-3.5 rounded-xl border border-slate-800">
                      <div className="space-y-1">
                        <span className="text-[10px] font-black uppercase text-slate-500 block">CURRENT SYSTEM ASSIGNMENT</span>
                        <p className="font-bold text-slate-300">PS: <span className="text-amber-300">{currentPs}</span></p>
                        <p className="text-[11px] text-slate-400">Role: {singleTargetUser.role || "Not Assigned"}</p>
                      </div>
                      <div className="space-y-1">
                        <span className="text-[10px] font-black uppercase text-emerald-400 block">NEW ASSIGNMENT</span>
                        <p className="font-bold text-white">PS: <span className="text-emerald-300">{newPs}</span></p>
                        <p className="text-[11px] text-emerald-400 font-semibold">Role: {currentTargetRoleOption.label}</p>
                      </div>
                    </div>
                    {isPsChanging && (
                      <div className="rounded-xl border border-blue-500/50 bg-blue-950/40 p-2.5 text-center text-xs font-bold text-blue-200">
                        ⚡ Police Station assignment will change after confirmation.
                      </div>
                    )}
                  </div>
                );
              })()}

              {modalMode === "BULK" && (() => {
                const targetPs = bulkLevel <= 3 ? (bulkTargetPs || selectedPs || "None") : "N/A (Higher Jurisdiction)";
                return (
                  <div className="space-y-2 bg-slate-950 p-3 rounded-xl border border-slate-800">
                    <div className="flex justify-between items-center text-xs font-bold">
                      <span className="text-slate-400 uppercase text-[10px]">NEW BULK TARGET PS:</span>
                      <span className="text-emerald-300 font-extrabold">{targetPs}</span>
                    </div>
                    <div className="rounded-lg border border-blue-500/40 bg-blue-950/30 p-2 text-center text-[11px] font-bold text-blue-200">
                      ⚡ Police Station assignment will change after confirmation for officers whose current PS differs from target.
                    </div>
                  </div>
                );
              })()}

              <div>
                <span className="text-[11px] font-extrabold uppercase text-slate-400 block mb-2">
                  Affected Officer Roster ({modalTargetUsers.length})
                </span>
                <div className="max-h-40 overflow-y-auto space-y-1.5 rounded-xl border border-slate-800 bg-slate-950 p-3">
                  {modalTargetUsers.map((u) => (
                    <div key={u.id} className="flex items-center justify-between text-[11px] border-b border-slate-900 pb-1">
                      <div>
                        <span className="font-bold text-white">{u.name}</span>
                        <span className="text-slate-500 ml-2">({u.policeStationName || "No Current PS"})</span>
                      </div>
                      <span className="font-mono text-slate-400">{u.employeeId}</span>
                      <span className="text-slate-300">{u.rank}</span>
                    </div>
                  ))}
                </div>
              </div>
            </div>

            <div className="flex items-center justify-end gap-3 pt-3 border-t border-slate-800">
              <button
                type="button"
                onClick={() => setShowConfirmModal(false)}
                disabled={saving}
                className="rounded-xl border border-slate-700 bg-slate-800 px-5 py-2.5 text-xs font-bold text-slate-300 hover:text-white transition disabled:opacity-50"
              >
                CANCEL
              </button>
              <button
                type="button"
                onClick={executeRoleAllotment}
                disabled={saving}
                className="rounded-xl bg-gradient-to-r from-emerald-600 to-teal-600 px-6 py-2.5 text-xs font-extrabold text-white shadow-lg shadow-emerald-900/30 hover:from-emerald-500 hover:to-teal-500 transition ring-2 ring-emerald-400/40 disabled:opacity-50"
              >
                {saving ? "SAVING ALLOTMENT..." : "CONFIRM ROLE ALLOTMENT"}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
