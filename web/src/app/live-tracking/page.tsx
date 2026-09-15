"use client";

import dynamic from "next/dynamic";
import { useCallback, useEffect, useState } from "react";
import { useRouter } from "next/navigation";

const LiveTrackingMap = dynamic(
  () => import("@/components/LiveTrackingMap"),
  {
    ssr: false,
    loading: () => (
      <div className="h-[620px] w-full flex items-center justify-center bg-white border border-slate-200 rounded-xl shadow-sm">
        <p className="text-slate-500">
          Loading GIS map...
        </p>
      </div>
    ),
  },
);

type LiveStatus =
  | "ACTIVE"
  | "STALE"
  | "OFFLINE";

type Officer = {
  userId: string;
  userName: string;
  rank: string | null;
  role: string | null;

  commissionerateCode: string | null;
  rangeCode: string | null;
  zoneCode: string | null;
  divisionCode: string | null;
  policeStationCode: string | null;
  sectorCode: string | null;

  deviceSessionId: string;
  deviceType: string | null;
  deviceName: string | null;
  manufacturer: string | null;
  model: string | null;
  platform: string | null;
  osVersion: string | null;

  trackingEnabled: boolean;
  trackingStatus: string | null;

  liveStatus: LiveStatus;

  latitude: number;
  longitude: number;
  accuracy: number | null;
  speed: number | null;
  heading: number | null;
  batteryLevel: number | null;

  locationSource: string | null;
  activityStatus: string | null;
  activeGpid: string | null;

  capturedAt: string;
  locationUpdatedAt: string;
  lastSeenAt: string;
  loginAt: string;
};

type LiveTrackingResponse = {
  success: boolean;

  viewer?: {
    username: string;
    role: string;
    canViewLiveTracking: boolean;
  };

  generatedAt?: string;

  summary?: {
    total: number;
    active: number;
    stale: number;
    offline: number;
    verifying: number;
  };

  officers?: Officer[];

  error?: string;
};

export default function LiveTrackingPage() {
  const router = useRouter();

  const [data, setData] =
    useState<LiveTrackingResponse | null>(null);

  const [loading, setLoading] =
    useState(true);

  const [refreshing, setRefreshing] =
    useState(false);

  const [error, setError] =
    useState("");

  const [accessDenied, setAccessDenied] =
    useState(false);

  const loadLiveTracking =
    useCallback(
      async (initialLoad = false) => {
        if (initialLoad) {
          setLoading(true);
        } else {
          setRefreshing(true);
        }

        setError("");

        try {
          const response =
            await fetch(
              "/api/tracking/live",
              {
                method: "GET",
                credentials: "include",
                cache: "no-store",
              },
            );

          const result =
            (await response.json()) as LiveTrackingResponse;

          if (response.status === 401) {
            localStorage.removeItem(
              "ganesh_user",
            );

            router.replace("/");
            return;
          }

          if (response.status === 403) {
            setAccessDenied(true);
            setData(null);
            return;
          }

          if (
            !response.ok ||
            !result.success
          ) {
            setError(
              result.error ??
                "Unable to load live tracking data.",
            );
            return;
          }

          setAccessDenied(false);
          setData(result);
        } catch (loadError) {
          console.error(
            "Live tracking load error:",
            loadError,
          );

          setError(
            "Unable to connect to the live tracking service.",
          );
        } finally {
          setLoading(false);
          setRefreshing(false);
        }
      },
      [router],
    );

  useEffect(() => {
    void loadLiveTracking(true);

    const intervalId =
      window.setInterval(() => {
        void loadLiveTracking(false);
      }, 30000);

    return () => {
      window.clearInterval(
        intervalId,
      );
    };
  }, [loadLiveTracking]);

  if (loading) {
    return (
      <main className="min-h-screen bg-slate-100 flex items-center justify-center">
        <div className="bg-white border border-slate-200 rounded-xl shadow-sm px-8 py-6">
          <p className="font-semibold text-slate-700">
            Loading live tracking...
          </p>
        </div>
      </main>
    );
  }

  if (accessDenied) {
    return (
      <main className="min-h-screen bg-slate-100 flex items-center justify-center px-4">
        <div className="max-w-lg w-full bg-white border border-red-200 rounded-xl shadow-sm p-8 text-center">
          <h1 className="text-2xl font-bold text-red-700">
            Access Denied
          </h1>

          <p className="text-slate-600 mt-3">
            You are not authorized to view
            live officer tracking.
          </p>

          <button
            type="button"
            onClick={() =>
              router.push("/dashboard")
            }
            className="mt-6 bg-[#17365D] text-white px-5 py-3 rounded-lg font-semibold hover:bg-[#244d7e]"
          >
            Back to Dashboard
          </button>
        </div>
      </main>
    );
  }

  const summary =
    data?.summary ?? {
      total: 0,
      active: 0,
      stale: 0,
      offline: 0,
      verifying: 0,
    };

  const officers =
    data?.officers ?? [];

  return (
    <main className="min-h-screen bg-slate-100">
      <header className="bg-[#17365D] text-white">
        <div className="max-w-[1600px] mx-auto px-6 py-5 flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
          <div>
            <p className="text-xs tracking-widest text-blue-200">
              OFFICIAL USE · ADMIN GIS
            </p>

            <h1 className="text-xl md:text-2xl font-bold">
              Live Officer Tracking
            </h1>

            <p className="text-sm text-blue-100 mt-1">
              Ganesh Festival Bandobust
              Management System
            </p>
          </div>

          <div className="flex items-center gap-3">
            <button
              type="button"
              onClick={() =>
                router.push("/dashboard")
              }
              className="border border-white/30 px-4 py-2 rounded-lg hover:bg-white/10"
            >
              ← Dashboard
            </button>

            <button
              type="button"
              onClick={() =>
                void loadLiveTracking(false)
              }
              disabled={refreshing}
              className="bg-white text-[#17365D] px-4 py-2 rounded-lg font-semibold hover:bg-blue-50 disabled:opacity-60"
            >
              {refreshing
                ? "Refreshing..."
                : "Refresh"}
            </button>
          </div>
        </div>
      </header>

      <div className="max-w-[1600px] mx-auto px-6 py-6">
        <section className="mb-5 flex flex-col gap-2 md:flex-row md:items-center md:justify-between">
          <div>
            <h2 className="text-2xl font-bold text-slate-800">
              Live GIS
            </h2>

            <p className="text-sm text-slate-500 mt-1">
              Showing the latest known
              position of each officer.
            </p>
          </div>

          <div className="text-sm text-slate-500">
            {data?.generatedAt
              ? `Updated: ${new Date(
                  data.generatedAt,
                ).toLocaleString()}`
              : ""}
          </div>
        </section>

        {error && (
          <div className="mb-5 bg-red-50 border border-red-200 text-red-700 rounded-lg px-4 py-3">
            {error}
          </div>
        )}

        <section className="grid grid-cols-2 lg:grid-cols-5 gap-4 mb-6">
          <div className="bg-white rounded-xl border border-slate-200 shadow-sm p-4">
            <div className="text-3xl font-bold text-[#17365D]">
              {summary.total}
            </div>

            <p className="text-sm text-slate-500 mt-1">
              Officers
            </p>
          </div>

          <div className="bg-white rounded-xl border border-slate-200 shadow-sm p-4">
            <div className="text-3xl font-bold text-green-700">
              {summary.active}
            </div>

            <p className="text-sm text-slate-500 mt-1">
              Active
            </p>
          </div>

          <div className="bg-white rounded-xl border border-slate-200 shadow-sm p-4">
            <div className="text-3xl font-bold text-amber-600">
              {summary.stale}
            </div>

            <p className="text-sm text-slate-500 mt-1">
              Stale
            </p>
          </div>

          <div className="bg-white rounded-xl border border-slate-200 shadow-sm p-4">
            <div className="text-3xl font-bold text-slate-600">
              {summary.offline}
            </div>

            <p className="text-sm text-slate-500 mt-1">
              Offline
            </p>
          </div>

          <div className="bg-white rounded-xl border border-slate-200 shadow-sm p-4">
            <div className="text-3xl font-bold text-blue-700">
              {summary.verifying}
            </div>

            <p className="text-sm text-slate-500 mt-1">
              Verifying
            </p>
          </div>
        </section>

        {officers.length === 0 ? (
          <section className="bg-white border border-slate-200 rounded-xl shadow-sm p-10 text-center">
            <h3 className="text-lg font-bold text-slate-700">
              No officer locations available
            </h3>

            <p className="text-sm text-slate-500 mt-2">
              Live officer positions will
              appear here when tracking data
              is available.
            </p>
          </section>
        ) : (
          <LiveTrackingMap
            officers={officers}
          />
        )}

        <section className="mt-6 bg-white rounded-xl border border-slate-200 shadow-sm overflow-hidden">
          <div className="px-5 py-4 border-b border-slate-200">
            <h3 className="font-bold text-slate-800">
              Officers
            </h3>
          </div>

          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead className="bg-slate-50 text-slate-600">
                <tr>
                  <th className="text-left px-5 py-3">
                    Officer
                  </th>

                  <th className="text-left px-5 py-3">
                    PS / Sector
                  </th>

                  <th className="text-left px-5 py-3">
                    Activity
                  </th>

                  <th className="text-left px-5 py-3">
                    GPID
                  </th>

                  <th className="text-left px-5 py-3">
                    GPS
                  </th>

                  <th className="text-left px-5 py-3">
                    Battery
                  </th>

                  <th className="text-left px-5 py-3">
                    Live Status
                  </th>

                  <th className="text-left px-5 py-3">
                    Last Seen
                  </th>
                </tr>
              </thead>

              <tbody>
                {officers.map(
                  (officer) => (
                    <tr
                      key={
                        officer.userId
                      }
                      className="border-t border-slate-100"
                    >
                      <td className="px-5 py-4">
                        <div className="font-semibold text-slate-800">
                          {officer.userName}
                        </div>

                        <div className="text-xs text-slate-500">
                          {officer.rank ??
                            "-"}{" "}
                          ·{" "}
                          {officer.role ??
                            "-"}
                        </div>
                      </td>

                      <td className="px-5 py-4">
                        <div>
                          {officer.policeStationCode ??
                            "-"}
                        </div>

                        <div className="text-xs text-slate-500">
                          Sector{" "}
                          {officer.sectorCode ??
                            "-"}
                        </div>
                      </td>

                      <td className="px-5 py-4">
                        {officer.activityStatus ??
                          "-"}
                      </td>

                      <td className="px-5 py-4 font-mono text-xs">
                        {officer.activeGpid ??
                          "-"}
                      </td>

                      <td className="px-5 py-4">
                        {officer.accuracy !==
                        null
                          ? `${officer.accuracy.toFixed(
                              1,
                            )} m`
                          : "-"}
                      </td>

                      <td className="px-5 py-4">
                        {officer.batteryLevel !==
                        null
                          ? `${officer.batteryLevel}%`
                          : "-"}
                      </td>

                      <td className="px-5 py-4">
                        <span
                          className={`inline-flex rounded-full px-3 py-1 text-xs font-bold ${
                            officer.liveStatus ===
                            "ACTIVE"
                              ? "bg-green-100 text-green-700"
                              : officer.liveStatus ===
                                  "STALE"
                                ? "bg-amber-100 text-amber-700"
                                : "bg-slate-200 text-slate-600"
                          }`}
                        >
                          {
                            officer.liveStatus
                          }
                        </span>
                      </td>

                      <td className="px-5 py-4 whitespace-nowrap">
                        {new Date(
                          officer.lastSeenAt,
                        ).toLocaleString()}
                      </td>
                    </tr>
                  ),
                )}
              </tbody>
            </table>
          </div>
        </section>
      </div>
    </main>
  );
}