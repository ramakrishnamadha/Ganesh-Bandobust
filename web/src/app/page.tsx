"use client";

import { useState } from "react";

type LoginUser = {
  id: string;
  employeeId: string;
  username: string;
  officerName: string;
  rank: string;
  role: string;
  accessLevel: number;
  phoneNumber?: string | null;
  team?: string | null;
  jurisdiction?: {
    commissionerateCode?: string | null;
    commissionerateName?: string | null;
    rangeCode?: string | null;
    rangeName?: string | null;
    zoneCode?: string | null;
    zoneName?: string | null;
    divisionCode?: string | null;
    divisionName?: string | null;
    policeStationCode?: string | null;
    policeStationName?: string | null;
    sectorCode?: string | null;
    sectorName?: string | null;
    allPoliceStations?: boolean;
    allDivisions?: boolean;
    allZones?: boolean;
    allRanges?: boolean;
  };
  canViewLiveTracking: boolean;
  mustChangePassword: boolean;
};

type LoginResponse = {
  success: boolean;
  user?: LoginUser;
  requiresPasswordChange?: boolean;
  error?: string;
};

export default function Home() {
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [isLoggingIn, setIsLoggingIn] = useState(false);

  const handleLogin = async () => {
    if (isLoggingIn) {
      return;
    }

    setError("");

    const trimmedUsername = username.trim();

    if (!trimmedUsername || !password) {
      setError("Enter Employee ID and password.");
      return;
    }

    setIsLoggingIn(true);

    try {
      const response = await fetch("/api/auth/login", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        credentials: "include",
        body: JSON.stringify({
          username: trimmedUsername,
          password,
        }),
      });

      const data = (await response.json()) as LoginResponse;

      if (!response.ok || !data.success || !data.user) {
        setError(data.error ?? "Invalid Employee ID or password.");
        return;
      }

      /*
       * This copy is only for displaying the logged-in officer
       * in the existing UI.
       *
       * Authentication and authorization continue to rely on
       * the signed HttpOnly session cookie created by the server.
       */
      localStorage.setItem(
        "ganesh_user",
        JSON.stringify(data.user),
      );

      /*
       * First-login users must change the default password
       * before continuing to the main application.
       */
      if (
        data.requiresPasswordChange ||
        data.user.mustChangePassword
      ) {
        window.location.href = "/change-password";
        return;
      }

      window.location.href = "/dashboard";
    } catch (loginError) {
      console.error("Web login error:", loginError);

      setError(
        "Unable to connect to the login service. Please try again.",
      );
    } finally {
      setIsLoggingIn(false);
    }
  };

  return (
    <main className="min-h-screen bg-slate-100 flex items-center justify-center px-4">
      <div className="w-full max-w-md bg-white rounded-2xl shadow-xl overflow-hidden">
        <div className="bg-[#17365D] text-white text-center px-8 py-8">
          <div className="text-sm font-semibold tracking-widest mb-3">
            OFFICIAL USE
          </div>

          <h1 className="text-2xl font-bold leading-tight">
            GANESH FESTIVAL
          </h1>

          <h2 className="text-xl font-semibold mt-1">
            BANDOBUST MANAGEMENT SYSTEM
          </h2>

          <p className="text-sm text-blue-100 mt-3">
            Web Application
          </p>
        </div>

        <div className="p-8">
          <h3 className="text-xl font-bold text-slate-800 text-center">
            Official Login
          </h3>

          <p className="text-sm text-slate-500 text-center mt-1 mb-7">
            Authorized officers only
          </p>

          <label className="block text-sm font-semibold text-slate-700 mb-2">
            Employee ID
          </label>

          <input
            type="text"
            value={username}
            onChange={(e) => setUsername(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === "Enter") {
                void handleLogin();
              }
            }}
            placeholder="Enter Employee ID"
            autoComplete="username"
            disabled={isLoggingIn}
            className="w-full border border-slate-300 rounded-lg px-4 py-3 mb-5 outline-none focus:ring-2 focus:ring-blue-500 disabled:bg-slate-100"
          />

          <label className="block text-sm font-semibold text-slate-700 mb-2">
            Password
          </label>

          <input
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === "Enter") {
                void handleLogin();
              }
            }}
            placeholder="Enter password"
            autoComplete="current-password"
            disabled={isLoggingIn}
            className="w-full border border-slate-300 rounded-lg px-4 py-3 mb-4 outline-none focus:ring-2 focus:ring-blue-500 disabled:bg-slate-100"
          />

          {error && (
            <div className="bg-red-100 text-red-700 text-sm px-4 py-3 rounded-lg mb-4">
              {error}
            </div>
          )}

          <button
            type="button"
            onClick={() => {
              void handleLogin();
            }}
            disabled={isLoggingIn}
            className="w-full bg-[#17365D] hover:bg-[#244d7e] disabled:bg-slate-400 disabled:cursor-not-allowed text-white font-semibold py-3 rounded-lg transition"
          >
            {isLoggingIn ? "LOGGING IN..." : "LOGIN"}
          </button>

          <div className="text-xs text-slate-400 text-center mt-5">
            <p>Username: Employee ID</p>
            <p>First-time users must change the default password.</p>
          </div>
        </div>
      </div>
    </main>
  );
}