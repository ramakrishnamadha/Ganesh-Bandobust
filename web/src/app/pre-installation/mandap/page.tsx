"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";

export default function MandapVerificationPage() {
  const router = useRouter();

  const [structuralInspected, setStructuralInspected] = useState("");
  const [roadObstruction, setRoadObstruction] = useState("");
  const [obstructionType, setObstructionType] = useState("");
  const [trafficImpact, setTrafficImpact] = useState("");
  const [roadWidth, setRoadWidth] = useState("");
  const [actionRequired, setActionRequired] = useState("");

  const [emergencyVerified, setEmergencyVerified] = useState("");
  const [emergencyAccess, setEmergencyAccess] = useState("");

  const [remarks, setRemarks] = useState("");

  const [error, setError] = useState("");
  const [message, setMessage] = useState("");

  const saveVerification = () => {
    setError("");
    setMessage("");

    if (structuralInspected === "") {
      setError("Please answer: Structural Stability of Mandap Inspected?");
      return;
    }

    if (structuralInspected === "NO") {
      if (remarks.trim() === "") {
        setError(
          "Reason / Remarks are mandatory when Structural Stability Inspection is NO."
        );
        return;
      }

      const exception = {
        applicationId: "GAN-2026-001245",
        module: "Mandap-Based Verification",
        finding: "Structural Stability Not Inspected",
        type: "LOGICAL_NO",
        remarks,
        status: "OPEN",
        createdAt: new Date().toISOString(),
      };

      localStorage.setItem(
        "ganesh_mandap_exception",
        JSON.stringify(exception)
      );

      const data = {
        applicationId: "GAN-2026-001245",
        structuralInspected: "NO",
        remarks,
      };

      localStorage.setItem(
        "ganesh_mandap_verification",
        JSON.stringify(data)
      );

      setMessage(
        "Mandap verification saved. This case has been added to NO / Pending monitoring."
      );

      return;
    }

    if (roadObstruction === "") {
      setError(
        "Please answer: Road Block / Obstruction from Traffic Point of View?"
      );
      return;
    }

    if (roadObstruction === "YES") {
      if (obstructionType === "") {
        setError("Please select Obstruction Type.");
        return;
      }

      if (trafficImpact === "") {
        setError("Please select Impact on Traffic.");
        return;
      }

      if (roadWidth.trim() === "") {
        setError("Please enter Road Width Available.");
        return;
      }

      if (actionRequired === "") {
        setError("Please select Action Required.");
        return;
      }
    }

    if (emergencyVerified === "") {
      setError("Please answer: Access for Emergency Vehicles Verified?");
      return;
    }

    if (emergencyVerified === "NO") {
      if (remarks.trim() === "") {
        setError(
          "Reason / Remarks are mandatory when Emergency Vehicle Access Verification is NO."
        );
        return;
      }

      const emergencyException = {
        applicationId: "GAN-2026-001245",
        module: "Mandap-Based Verification",
        finding: "Emergency Vehicle Access Not Verified",
        type: "LOGICAL_NO",
        remarks,
        status: "OPEN",
        createdAt: new Date().toISOString(),
      };

      localStorage.setItem(
        "ganesh_emergency_exception",
        JSON.stringify(emergencyException)
      );
    }

    if (emergencyVerified === "YES" && emergencyAccess === "") {
      setError("Please select Emergency Vehicle Access.");
      return;
    }

    const data = {
      applicationId: "GAN-2026-001245",
      structuralInspected,
      roadObstruction,
      obstructionType:
        roadObstruction === "YES" ? obstructionType : null,
      trafficImpact:
        roadObstruction === "YES" ? trafficImpact : null,
      roadWidth:
        roadObstruction === "YES" ? roadWidth : null,
      actionRequired:
        roadObstruction === "YES" ? actionRequired : null,
      emergencyVerified,
      emergencyAccess:
        emergencyVerified === "YES" ? emergencyAccess : null,
      remarks,
      savedAt: new Date().toISOString(),
    };

    localStorage.setItem(
      "ganesh_mandap_verification",
      JSON.stringify(data)
    );

    if (
      trafficImpact === "CRITICAL" ||
      actionRequired === "IMMEDIATE_ACTION"
    ) {
      const criticalFinding = {
        applicationId: "GAN-2026-001245",
        module: "Mandap-Based Verification",
        finding:
          trafficImpact === "CRITICAL"
            ? "Critical Traffic Impact"
            : "Immediate Action Required",
        type: "CRITICAL_FINDING",
        status: "OPEN",
        createdAt: new Date().toISOString(),
      };

      localStorage.setItem(
        "ganesh_mandap_critical",
        JSON.stringify(criticalFinding)
      );
    }

    if (emergencyAccess === "INACCESSIBLE") {
      const adverseFinding = {
        applicationId: "GAN-2026-001245",
        module: "Mandap-Based Verification",
        finding: "Emergency Vehicle Access Inaccessible",
        type: "ADVERSE_FINDING",
        status: "OPEN",
        createdAt: new Date().toISOString(),
      };

      localStorage.setItem(
        "ganesh_emergency_inaccessible",
        JSON.stringify(adverseFinding)
      );
    }

    setMessage("Mandap-Based Verification saved successfully.");
  };

  return (
    <main className="min-h-screen bg-slate-100">
      <header className="bg-[#17365D] text-white">
        <div className="max-w-5xl mx-auto px-6 py-5 flex justify-between items-center">
          <div>
            <p className="text-xs tracking-widest text-blue-200">
              PRE-INSTALLATION
            </p>

            <h1 className="text-2xl font-bold">
              Mandap-Based Verification
            </h1>
          </div>

          <button
            onClick={() => router.push("/pre-installation")}
            className="border border-white/30 rounded-lg px-4 py-2"
          >
            ← Back
          </button>
        </div>
      </header>

      <div className="max-w-5xl mx-auto px-6 py-8">

        <section className="bg-white rounded-xl border border-slate-200 p-5 mb-6">
          <p className="text-xs text-slate-500">
            Application ID
          </p>

          <p className="text-xl font-bold text-[#17365D]">
            GAN-2026-001245
          </p>

          <p className="text-sm text-slate-500 mt-2">
            Demo Ganesh Application
          </p>
        </section>

        <section className="bg-white rounded-xl border border-slate-200 p-6 mb-5">
          <h2 className="text-lg font-bold text-slate-800 mb-4">
            Structural Stability of Mandap Inspected?
          </h2>

          <div className="flex gap-4">
            <button
              onClick={() => setStructuralInspected("YES")}
              className={`px-8 py-3 rounded-lg font-semibold border ${
                structuralInspected === "YES"
                  ? "bg-green-600 text-white border-green-600"
                  : "bg-white border-slate-300"
              }`}
            >
              YES
            </button>

            <button
              onClick={() => setStructuralInspected("NO")}
              className={`px-8 py-3 rounded-lg font-semibold border ${
                structuralInspected === "NO"
                  ? "bg-red-600 text-white border-red-600"
                  : "bg-white border-slate-300"
              }`}
            >
              NO
            </button>
          </div>

          {structuralInspected === "NO" && (
            <div className="mt-5">
              <label className="block font-bold text-red-700 mb-2">
                NO-type Reason / Remarks *
              </label>

              <textarea
                value={remarks}
                onChange={(e) => setRemarks(e.target.value)}
                className="w-full border border-red-300 rounded-lg px-4 py-3 min-h-28"
                placeholder="Enter reason"
              />
            </div>
          )}
        </section>

        {structuralInspected === "YES" && (
          <>
            <section className="bg-white rounded-xl border border-slate-200 p-6 mb-5">
              <h2 className="text-lg font-bold text-slate-800 mb-4">
                Road Block / Obstruction from Traffic Point of View?
              </h2>

              <div className="flex gap-4">
                <button
                  onClick={() => setRoadObstruction("YES")}
                  className={`px-8 py-3 rounded-lg font-semibold border ${
                    roadObstruction === "YES"
                      ? "bg-[#17365D] text-white"
                      : "bg-white border-slate-300"
                  }`}
                >
                  YES
                </button>

                <button
                  onClick={() => setRoadObstruction("NO")}
                  className={`px-8 py-3 rounded-lg font-semibold border ${
                    roadObstruction === "NO"
                      ? "bg-[#17365D] text-white"
                      : "bg-white border-slate-300"
                  }`}
                >
                  NO
                </button>
              </div>

              {roadObstruction === "YES" && (
                <div className="grid md:grid-cols-2 gap-4 mt-5">

                  <div>
                    <label className="block font-bold text-slate-700 mb-2">
                      Obstruction Type *
                    </label>

                    <select
                      value={obstructionType}
                      onChange={(e) => setObstructionType(e.target.value)}
                      className="w-full border border-slate-300 rounded-lg px-4 py-3"
                    >
                      <option value="">Select Type</option>
                      <option value="MANDAP">Mandap</option>
                      <option value="PARKING">Parking</option>
                      <option value="BARRICADES">Barricades</option>
                      <option value="OTHER">Other</option>
                    </select>
                  </div>

                  <div>
                    <label className="block font-bold text-slate-700 mb-2">
                      Impact on Traffic *
                    </label>

                    <select
                      value={trafficImpact}
                      onChange={(e) => setTrafficImpact(e.target.value)}
                      className="w-full border border-slate-300 rounded-lg px-4 py-3"
                    >
                      <option value="">Select Impact</option>
                      <option value="LOW">Low</option>
                      <option value="MODERATE">Moderate</option>
                      <option value="HIGH">High</option>
                      <option value="CRITICAL">Critical</option>
                    </select>
                  </div>

                  <div>
                    <label className="block font-bold text-slate-700 mb-2">
                      Road Width Available (ft.) *
                    </label>

                    <input
                      type="number"
                      value={roadWidth}
                      onChange={(e) => setRoadWidth(e.target.value)}
                      className="w-full border border-slate-300 rounded-lg px-4 py-3"
                      placeholder="Example: 20"
                    />
                  </div>

                  <div>
                    <label className="block font-bold text-slate-700 mb-2">
                      Action Required *
                    </label>

                    <select
                      value={actionRequired}
                      onChange={(e) => setActionRequired(e.target.value)}
                      className="w-full border border-slate-300 rounded-lg px-4 py-3"
                    >
                      <option value="">Select Action</option>
                      <option value="NO_ACTION">No Action</option>
                      <option value="RECTIFICATION">Rectification</option>
                      <option value="TRAFFIC_DIVERSION">
                        Traffic Diversion
                      </option>
                      <option value="IMMEDIATE_ACTION">
                        Immediate Action
                      </option>
                    </select>
                  </div>

                </div>
              )}
            </section>

            <section className="bg-white rounded-xl border border-slate-200 p-6 mb-5">
              <h2 className="text-lg font-bold text-slate-800 mb-4">
                Access for Emergency Vehicles Verified?
              </h2>

              <div className="flex gap-4">
                <button
                  onClick={() => setEmergencyVerified("YES")}
                  className={`px-8 py-3 rounded-lg font-semibold border ${
                    emergencyVerified === "YES"
                      ? "bg-[#17365D] text-white"
                      : "bg-white border-slate-300"
                  }`}
                >
                  YES
                </button>

                <button
                  onClick={() => setEmergencyVerified("NO")}
                  className={`px-8 py-3 rounded-lg font-semibold border ${
                    emergencyVerified === "NO"
                      ? "bg-red-600 text-white"
                      : "bg-white border-slate-300"
                  }`}
                >
                  NO
                </button>
              </div>

              {emergencyVerified === "YES" && (
                <div className="mt-5">
                  <label className="block font-bold text-slate-700 mb-2">
                    Emergency Vehicle Access *
                  </label>

                  <select
                    value={emergencyAccess}
                    onChange={(e) => setEmergencyAccess(e.target.value)}
                    className="w-full border border-slate-300 rounded-lg px-4 py-3"
                  >
                    <option value="">Select Access Status</option>
                    <option value="ACCESSIBLE">Accessible</option>
                    <option value="INACCESSIBLE">Inaccessible</option>
                  </select>
                </div>
              )}

              {emergencyVerified === "NO" && (
                <div className="mt-5">
                  <label className="block font-bold text-red-700 mb-2">
                    NO-type Reason / Remarks *
                  </label>

                  <textarea
                    value={remarks}
                    onChange={(e) => setRemarks(e.target.value)}
                    className="w-full border border-red-300 rounded-lg px-4 py-3 min-h-28"
                    placeholder="Enter reason"
                  />
                </div>
              )}

            </section>
          </>
        )}

        {error && (
          <div className="bg-red-100 border border-red-200 text-red-700 rounded-lg px-4 py-3 mb-4">
            {error}
          </div>
        )}

        {message && (
          <div className="bg-green-100 border border-green-200 text-green-700 rounded-lg px-4 py-3 mb-4">
            {message}
          </div>
        )}

        <div className="flex justify-end">
          <button
            onClick={saveVerification}
            className="bg-[#17365D] text-white font-semibold rounded-lg px-8 py-3"
          >
            Save Mandap Verification
          </button>
        </div>

      </div>
    </main>
  );
}