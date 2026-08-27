"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";

export default function Home() {
  const router = useRouter();

  const [username, setUsername] = useState("field1");
  const [password, setPassword] = useState("field123");
  const [error, setError] = useState("");

  const handleLogin = () => {
    setError("");

    if (username === "field1" && password === "field123") {
      localStorage.setItem(
        "ganesh_user",
        JSON.stringify({
          username: "field1",
          officerName: "Field Officer Demo",
          role: "FIELD_OFFICER",
          policeStation: "Demo Police Station",
          sector: "03",
        })
      );

      router.push("/dashboard");
      return;
    }

    if (username === "sho1" && password === "sho123") {
      localStorage.setItem(
        "ganesh_user",
        JSON.stringify({
          username: "sho1",
          officerName: "SHO Demo",
          role: "SHO",
          policeStation: "Demo Police Station",
          sector: "",
        })
      );

      router.push("/dashboard");
      return;
    }

    setError("Invalid username or password");
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
            Username
          </label>

          <input
            type="text"
            value={username}
            onChange={(e) => setUsername(e.target.value)}
            placeholder="Enter username"
            className="w-full border border-slate-300 rounded-lg px-4 py-3 mb-5 outline-none focus:ring-2 focus:ring-blue-500"
          />

          <label className="block text-sm font-semibold text-slate-700 mb-2">
            Password
          </label>

          <input
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            placeholder="Enter password"
            className="w-full border border-slate-300 rounded-lg px-4 py-3 mb-4 outline-none focus:ring-2 focus:ring-blue-500"
          />

          {error && (
            <div className="bg-red-100 text-red-700 text-sm px-4 py-3 rounded-lg mb-4">
              {error}
            </div>
          )}

          <button
            type="button"
            onClick={handleLogin}
            className="w-full bg-[#17365D] hover:bg-[#244d7e] text-white font-semibold py-3 rounded-lg transition"
          >
            LOGIN
          </button>

          <div className="text-xs text-slate-400 text-center mt-5">
            <p>Field Officer Demo: field1 / field123</p>
            <p>SHO Demo: sho1 / sho123</p>
          </div>
        </div>
      </div>
    </main>
  );
}