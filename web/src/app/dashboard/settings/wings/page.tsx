"use client";

import { useState } from "react";
import Link from "next/link";
import { GANESH_HIERARCHY } from "@/lib/hierarchy/ganeshHierarchy";

export default function WingsManagementPage() {
  const [notice, setNotice] = useState("");

  const totalStations = new Set(GANESH_HIERARCHY.map((h) => h.policeStation)).size;
  const totalDivisions = new Set(GANESH_HIERARCHY.map((h) => h.division)).size;
  const totalZones = new Set(GANESH_HIERARCHY.map((h) => h.zone)).size;
  const totalRanges = new Set(GANESH_HIERARCHY.map((h) => h.range)).size;

  const handleAddNewWingClick = () => {
    setNotice("Dynamic Wing creation will be enabled after hierarchy master configuration is approved.");
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
              Phase 1 Master Configuration
            </span>
          </div>
          <h1 className="mt-3 text-2xl md:text-3xl font-black tracking-tight text-white uppercase">
            ADD WINGS & HIERARCHY
          </h1>
          <p className="mt-1 text-xs md:text-sm text-slate-400">
            Define organizational wings and master hierarchy structures for police operations.
          </p>
        </div>

        <button
          type="button"
          onClick={handleAddNewWingClick}
          className="inline-flex items-center gap-2 rounded-xl bg-gradient-to-r from-blue-600 to-indigo-600 px-5 py-3 text-xs md:text-sm font-extrabold text-white shadow-lg shadow-blue-900/30 hover:from-blue-500 hover:to-indigo-500 transition ring-2 ring-blue-400/40"
        >
          <span>+</span> ADD NEW WING
        </button>
      </div>

      {/* NOTICE BANNER */}
      {notice && (
        <div className="rounded-2xl border border-amber-500/40 bg-amber-950/30 p-4 text-xs md:text-sm text-amber-200 flex items-center justify-between shadow-lg">
          <div className="flex items-center gap-3">
            <span className="text-xl">⚠️</span>
            <p className="font-semibold">{notice}</p>
          </div>
          <button
            type="button"
            onClick={() => setNotice("")}
            className="text-amber-400 hover:text-white font-bold text-xs bg-amber-900/50 px-2.5 py-1 rounded-lg"
          >
            Dismiss
          </button>
        </div>
      )}

      {/* EXISTING WINGS SECTION */}
      <div className="space-y-4">
        <div className="flex items-center justify-between">
          <h2 className="text-base font-extrabold uppercase tracking-wider text-slate-200">
            Configured Operational Wings (1)
          </h2>
          <span className="text-xs font-semibold text-slate-400">
            Source: Authoritative Master Dataset (GANESH_HIERARCHY)
          </span>
        </div>

        {/* L&O WING CARD */}
        <div className="rounded-2xl border border-slate-800 bg-slate-900/80 p-6 shadow-xl space-y-6">
          <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 border-b border-slate-800 pb-5">
            <div className="flex items-center gap-4">
              <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-gradient-to-tr from-blue-600 to-indigo-600 text-white font-black text-lg shadow-md ring-1 ring-white/20">
                L&O
              </div>
              <div>
                <div className="flex items-center gap-2">
                  <h3 className="text-lg font-black text-white">Law & Order Wing</h3>
                  <span className="rounded-md bg-emerald-950/80 border border-emerald-800 px-2 py-0.5 text-[10px] font-black uppercase text-emerald-400 tracking-wider">
                    ACTIVE
                  </span>
                </div>
                <p className="text-xs text-slate-400">
                  Primary operational wing for territorial police station bandobust duties.
                </p>
              </div>
            </div>

            <div className="flex items-center gap-2">
              <span className="text-xs font-bold text-slate-400 bg-slate-950 px-3 py-1.5 rounded-xl border border-slate-800">
                Code: L_AND_O
              </span>
            </div>
          </div>

          {/* HIERARCHY FLOW VISUALIZER */}
          <div className="space-y-3">
            <p className="text-xs font-extrabold uppercase tracking-wider text-slate-400">
              Configured Organizational Hierarchy Cascade
            </p>
            <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-4 gap-3">
              <div className="rounded-xl border border-slate-800 bg-slate-950/90 p-4 space-y-1">
                <span className="text-[10px] font-bold uppercase text-blue-400 tracking-wider">Level 1 • Top Scope</span>
                <p className="text-sm font-extrabold text-white">Range</p>
                <p className="text-xs text-slate-400">{totalRanges} Ranges Configured</p>
              </div>

              <div className="rounded-xl border border-slate-800 bg-slate-950/90 p-4 space-y-1">
                <span className="text-[10px] font-bold uppercase text-blue-400 tracking-wider">Level 2 • Zonal Scope</span>
                <p className="text-sm font-extrabold text-white">Zone</p>
                <p className="text-xs text-slate-400">{totalZones} Zones Configured</p>
              </div>

              <div className="rounded-xl border border-slate-800 bg-slate-950/90 p-4 space-y-1">
                <span className="text-[10px] font-bold uppercase text-blue-400 tracking-wider">Level 3 • Supervisory</span>
                <p className="text-sm font-extrabold text-white">Division</p>
                <p className="text-xs text-slate-400">{totalDivisions} Divisions Configured</p>
              </div>

              <div className="rounded-xl border border-slate-800 bg-slate-950/90 p-4 space-y-1">
                <span className="text-[10px] font-bold uppercase text-blue-400 tracking-wider">Level 4 • Terminal Station</span>
                <p className="text-sm font-extrabold text-white">Police Station</p>
                <p className="text-xs text-slate-400">{totalStations} Stations Configured</p>
              </div>
            </div>
          </div>

          {/* SUMMARY STATS */}
          <div className="pt-2 border-t border-slate-800/60 flex items-center justify-between text-xs text-slate-400">
            <p>
              Derivation Engine: <span className="text-slate-200 font-semibold">GANESH_HIERARCHY Master Data</span>
            </p>
            <p>
              Sector Master Integration: <span className="text-emerald-400 font-semibold">Enabled (Optional Level 1/2)</span>
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}
