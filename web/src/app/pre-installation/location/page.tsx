"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";

export default function LocationVerificationPage() {
  const router = useRouter();

  const [locationVerified, setLocationVerified] = useState("");
  const [locationChanged, setLocationChanged] = useState("");
  const [samePoliceStation, setSamePoliceStation] = useState("");

  const [sector, setSector] = useState("");

  const [commissionerate, setCommissionerate] = useState("");
  const [policeStation, setPoliceStation] = useState("");

  const [sensitivityCompleted, setSensitivityCompleted] = useState("");
  const [sensitivity, setSensitivity] = useState("");

  const [remarks, setRemarks] = useState("");

  const [latitude, setLatitude] = useState<number | null>(null);
  const [longitude, setLongitude] = useState<number | null>(null);
  const [gpsMessage, setGpsMessage] = useState("");

  const [message, setMessage] = useState("");
  const [error, setError] = useState("");

  const captureLocation = () => {
    setGpsMessage("");

    if (!navigator.geolocation) {
      setGpsMessage("GPS / Geolocation is not supported by this browser.");
      return;
    }

    setGpsMessage("Capturing current location...");

    navigator.geolocation.getCurrentPosition(
      (position) => {
        setLatitude(position.coords.latitude);
        setLongitude(position.coords.longitude);

        setGpsMessage("Current location captured successfully.");
      },
      () => {
        setGpsMessage(
          "Unable to capture location. Please allow location permission."
        );
      }
    );
  };

  const saveVerification = () => {
    setError("");
    setMessage("");

    if (locationVerified === "") {
      setError("Please answer: Location Verified?");
      return;
    }

    if (locationVerified === "NO") {
      if (remarks.trim() === "") {
        setError(
          "Reason / Remarks are mandatory when Location Verified is NO."
        );
        return;
      }

      const exception = {
        applicationId: "GAN-2026-001245",
        module: "Location-Based Verification",
        finding: "Location Not Verified",
        type: "LOGICAL_NO",
        remarks: remarks,
        status: "OPEN",
        createdAt: new Date().toISOString(),
      };

      localStorage.setItem(
        "ganesh_location_exception",
        JSON.stringify(exception)
      );

      const verificationData = {
        applicationId: "GAN-2026-001245",
        locationVerified: "NO",
        remarks: remarks,
      };

      localStorage.setItem(
        "ganesh_location_verification",
        JSON.stringify(verificationData)
      );

      setMessage(
        "Location verification saved. This case has been added to NO / Pending monitoring."
      );

      return;
    }

    if (locationChanged === "") {
      setError("Please answer: Location Changed?");
      return;
    }

    if (locationChanged === "NO") {
      if (sector === "") {
        setError("Please select the concerned Sector Number.");
        return;
      }
    }

    if (locationChanged === "YES") {
      if (samePoliceStation === "") {
        setError(
          "Please answer: New location falls under this Police Station?"
        );
        return;
      }

      if (samePoliceStation === "YES") {
        if (sector === "") {
          setError("Please select the concerned Sector Number.");
          return;
        }

        if (latitude === null || longitude === null) {
          setError(
            "New geo-mapping is mandatory when the location has changed within this Police Station."
          );
          return;
        }
      }

      if (samePoliceStation === "NO") {
        if (commissionerate === "") {
          setError("Please select Commissionerate.");
          return;
        }

        if (policeStation === "") {
          setError("Please select Police Station.");
          return;
        }
      }
    }

    if (sensitivityCompleted === "") {
      setError(
        "Please answer: Assessment of Sensitivity of the Location Completed?"
      );
      return;
    }

    if (sensitivityCompleted === "YES" && sensitivity === "") {
      setError("Please select the Sensitivity Category.");
      return;
    }

    if (sensitivityCompleted === "NO" && remarks.trim() === "") {
      setError(
        "Reason / Remarks are mandatory when Sensitivity Assessment is not completed."
      );
      return;
    }

    const verificationData = {
      applicationId: "GAN-2026-001245",

      locationVerified: locationVerified,

      locationChanged: locationChanged,

      samePoliceStation:
        locationChanged === "YES" ? samePoliceStation : null,

      sector: sector || null,

      commissionerate:
        samePoliceStation === "NO" ? commissionerate : null,

      policeStation:
        samePoliceStation === "NO" ? policeStation : null,

      latitude: latitude,
      longitude: longitude,

      sensitivityCompleted: sensitivityCompleted,

      sensitivity:
        sensitivityCompleted === "YES" ? sensitivity : null,

      remarks: remarks,

      savedAt: new Date().toISOString(),
    };

    localStorage.setItem(
      "ganesh_location_verification",
      JSON.stringify(verificationData)
    );

    if (sensitivity === "CRITICAL") {
      const criticalFinding = {
        applicationId: "GAN-2026-001245",
        module: "Location-Based Verification",
        finding: "Critical Location",
        type: "CRITICAL_FINDING",
        status: "OPEN",
        createdAt: new Date().toISOString(),
      };

      localStorage.setItem(
        "ganesh_critical_location",
        JSON.stringify(criticalFinding)
      );
    }

    setMessage("Location-Based Verification saved successfully.");
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
              Location-Based Verification
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
            Point 1 — Location Verified?
          </h2>

          <div className="flex gap-4">

            <button
              onClick={() => setLocationVerified("YES")}
              className={`px-8 py-3 rounded-lg font-semibold border ${
                locationVerified === "YES"
                  ? "bg-green-600 text-white border-green-600"
                  : "bg-white border-slate-300"
              }`}
            >
              YES
            </button>

            <button
              onClick={() => setLocationVerified("NO")}
              className={`px-8 py-3 rounded-lg font-semibold border ${
                locationVerified === "NO"
                  ? "bg-red-600 text-white border-red-600"
                  : "bg-white border-slate-300"
              }`}
            >
              NO
            </button>

          </div>

        </section>


        {locationVerified === "NO" && (

          <section className="bg-red-50 border border-red-200 rounded-xl p-6 mb-5">

            <h3 className="font-bold text-red-800">
              NO-type Reason / Remarks *
            </h3>

            <p className="text-sm text-red-600 mt-1 mb-3">
              This case will be included in supervisory NO / Pending analytics.
            </p>

            <textarea
              value={remarks}
              onChange={(e) => setRemarks(e.target.value)}
              className="w-full border border-red-300 rounded-lg px-4 py-3 min-h-28"
              placeholder="Enter reason why location could not be verified"
            />

          </section>

        )}


        {locationVerified === "YES" && (

          <>
            <section className="bg-white rounded-xl border border-slate-200 p-6 mb-5">

              <h2 className="text-lg font-bold text-slate-800 mb-4">
                Point 2 — Location Changed?
              </h2>

              <div className="flex gap-4">

                <button
                  onClick={() => setLocationChanged("YES")}
                  className={`px-8 py-3 rounded-lg font-semibold border ${
                    locationChanged === "YES"
                      ? "bg-[#17365D] text-white"
                      : "bg-white border-slate-300"
                  }`}
                >
                  YES
                </button>

                <button
                  onClick={() => setLocationChanged("NO")}
                  className={`px-8 py-3 rounded-lg font-semibold border ${
                    locationChanged === "NO"
                      ? "bg-[#17365D] text-white"
                      : "bg-white border-slate-300"
                  }`}
                >
                  NO
                </button>

              </div>

            </section>


            {locationChanged === "NO" && (

              <section className="bg-white rounded-xl border border-slate-200 p-6 mb-5">

                <label className="block font-bold text-slate-700 mb-2">
                  Sector Number *
                </label>

                <select
                  value={sector}
                  onChange={(e) => setSector(e.target.value)}
                  className="w-full border border-slate-300 rounded-lg px-4 py-3"
                >
                  <option value="">
                    Select Sector
                  </option>

                  <option value="01">
                    Sector 01
                  </option>

                  <option value="02">
                    Sector 02
                  </option>

                  <option value="03">
                    Sector 03
                  </option>

                  <option value="04">
                    Sector 04
                  </option>

                  <option value="05">
                    Sector 05
                  </option>

                </select>

                <p className="text-sm text-slate-500 mt-2">
                  Location Changed = NO is a normal workflow response and will
                  not create an exception.
                </p>

              </section>

            )}


            {locationChanged === "YES" && (

              <section className="bg-white rounded-xl border border-slate-200 p-6 mb-5">

                <h3 className="font-bold text-slate-800 mb-4">
                  New location falls under this Police Station?
                </h3>

                <div className="flex gap-4 mb-5">

                  <button
                    onClick={() => setSamePoliceStation("YES")}
                    className={`px-8 py-3 rounded-lg font-semibold border ${
                      samePoliceStation === "YES"
                        ? "bg-[#17365D] text-white"
                        : "bg-white border-slate-300"
                    }`}
                  >
                    YES
                  </button>

                  <button
                    onClick={() => setSamePoliceStation("NO")}
                    className={`px-8 py-3 rounded-lg font-semibold border ${
                      samePoliceStation === "NO"
                        ? "bg-[#17365D] text-white"
                        : "bg-white border-slate-300"
                    }`}
                  >
                    NO
                  </button>

                </div>


                {samePoliceStation === "YES" && (

                  <div className="space-y-5">

                    <div>

                      <label className="block font-bold text-slate-700 mb-2">
                        Sector Number *
                      </label>

                      <select
                        value={sector}
                        onChange={(e) => setSector(e.target.value)}
                        className="w-full border border-slate-300 rounded-lg px-4 py-3"
                      >
                        <option value="">
                          Select Sector
                        </option>

                        <option value="01">
                          Sector 01
                        </option>

                        <option value="02">
                          Sector 02
                        </option>

                        <option value="03">
                          Sector 03
                        </option>

                        <option value="04">
                          Sector 04
                        </option>

                        <option value="05">
                          Sector 05
                        </option>

                      </select>

                    </div>


                    <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">

                      <h4 className="font-bold text-blue-900">
                        New Geo-Mapping Required
                      </h4>

                      <p className="text-sm text-blue-700 mt-1 mb-4">
                        Current location must be captured before verification
                        can be saved.
                      </p>

                      <button
                        onClick={captureLocation}
                        className="bg-blue-700 text-white rounded-lg px-5 py-3 font-semibold"
                      >
                        Capture Current Location
                      </button>

                      {gpsMessage && (

                        <p className="text-sm mt-3">
                          {gpsMessage}
                        </p>

                      )}


                      {latitude !== null && longitude !== null && (

                        <div className="mt-3 text-sm text-slate-700">

                          <p>
                            Latitude: {latitude}
                          </p>

                          <p>
                            Longitude: {longitude}
                          </p>

                        </div>

                      )}

                    </div>

                  </div>

                )}


                {samePoliceStation === "NO" && (

                  <div className="grid md:grid-cols-2 gap-4">

                    <div>

                      <label className="block font-bold text-slate-700 mb-2">
                        Commissionerate Name *
                      </label>

                      <select
                        value={commissionerate}
                        onChange={(e) => setCommissionerate(e.target.value)}
                        className="w-full border border-slate-300 rounded-lg px-4 py-3"
                      >
                        <option value="">
                          Select Commissionerate
                        </option>

                        <option value="Hyderabad">
                          Hyderabad
                        </option>

                        <option value="Cyberabad">
                          Cyberabad
                        </option>

                        <option value="Rachakonda">
                          Rachakonda
                        </option>

                      </select>

                    </div>


                    <div>

                      <label className="block font-bold text-slate-700 mb-2">
                        Police Station Name *
                      </label>

                      <select
                        value={policeStation}
                        onChange={(e) => setPoliceStation(e.target.value)}
                        className="w-full border border-slate-300 rounded-lg px-4 py-3"
                      >
                        <option value="">
                          Select Police Station
                        </option>

                        <option value="Demo PS 1">
                          Demo PS 1
                        </option>

                        <option value="Demo PS 2">
                          Demo PS 2
                        </option>

                        <option value="Demo PS 3">
                          Demo PS 3
                        </option>

                      </select>

                    </div>

                  </div>

                )}

              </section>

            )}


            <section className="bg-white rounded-xl border border-slate-200 p-6 mb-5">

              <h2 className="text-lg font-bold text-slate-800 mb-4">
                Point 3 — Assessment of Sensitivity of the Location Completed?
              </h2>

              <div className="flex gap-4">

                <button
                  onClick={() => setSensitivityCompleted("YES")}
                  className={`px-8 py-3 rounded-lg font-semibold border ${
                    sensitivityCompleted === "YES"
                      ? "bg-[#17365D] text-white"
                      : "bg-white border-slate-300"
                  }`}
                >
                  YES
                </button>

                <button
                  onClick={() => setSensitivityCompleted("NO")}
                  className={`px-8 py-3 rounded-lg font-semibold border ${
                    sensitivityCompleted === "NO"
                      ? "bg-[#17365D] text-white"
                      : "bg-white border-slate-300"
                  }`}
                >
                  NO
                </button>

              </div>


              {sensitivityCompleted === "YES" && (

                <div className="mt-5">

                  <label className="block font-bold text-slate-700 mb-2">
                    Sensitivity Category *
                  </label>

                  <select
                    value={sensitivity}
                    onChange={(e) => setSensitivity(e.target.value)}
                    className="w-full border border-slate-300 rounded-lg px-4 py-3"
                  >
                    <option value="">
                      Select Sensitivity
                    </option>

                    <option value="NORMAL">
                      Normal
                    </option>

                    <option value="SENSITIVE">
                      Sensitive
                    </option>

                    <option value="HYPER_SENSITIVE">
                      Hyper Sensitive
                    </option>

                    <option value="CRITICAL">
                      Critical
                    </option>

                  </select>

                </div>

              )}


              {sensitivityCompleted === "NO" && (

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
            Save Location Verification
          </button>

        </div>

      </div>
    </main>
  );
}