"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import DigitalMeasurementTool from "@/components/DigitalMeasurementTool";

export default function IdolVerificationPage() {
  const router = useRouter();

  const [idolInstalled, setIdolInstalled] = useState("");
  const [purchaseVerified, setPurchaseVerified] = useState("");
  const [purchaseWithinPS, setPurchaseWithinPS] = useState("");
  const [dimensionsVerified, setDimensionsVerified] = useState("");

  const [height, setHeight] = useState("");
  const [width, setWidth] = useState("");
  const [material, setMaterial] = useState("");

  const [measurementTool, setMeasurementTool] =
    useState<"HEIGHT" | "WIDTH" | null>(null);

  const [heightMeasurementMethod, setHeightMeasurementMethod] =
    useState<"MANUAL" | "DIGITAL" | "">("");

  const [widthMeasurementMethod, setWidthMeasurementMethod] =
    useState<"MANUAL" | "DIGITAL" | "">("");

  const [remarks, setRemarks] = useState("");

  const [error, setError] = useState("");
  const [message, setMessage] = useState("");

  const saveVerification = () => {
    setError("");
    setMessage("");

    // ------------------------------------------------
    // 1. IDOL INSTALLED
    // ------------------------------------------------

    if (idolInstalled === "") {
      setError("Please answer: Idol Installed or Not?");
      return;
    }

    if (idolInstalled === "NO") {
      if (remarks.trim() === "") {
        setError(
          "Reason / Remarks are mandatory when Idol Installed is NO."
        );
        return;
      }

      const exception = {
        applicationId: "GAN-2026-001245",
        module: "Idol-Based Verification",
        finding: "Idol Not Installed",
        type: "LOGICAL_NO",
        remarks,
        status: "OPEN",
        createdAt: new Date().toISOString(),
      };

      localStorage.setItem(
        "ganesh_idol_not_installed",
        JSON.stringify(exception)
      );

      localStorage.setItem(
        "ganesh_idol_verification",
        JSON.stringify({
          applicationId: "GAN-2026-001245",
          idolInstalled: "NO",
          remarks,
          savedAt: new Date().toISOString(),
        })
      );

      setMessage(
        "Saved as Idol Not Installed and added to NO / Pending monitoring."
      );

      return;
    }

    // ------------------------------------------------
    // 2. PLACE OF PURCHASE VERIFIED
    // ------------------------------------------------

    if (purchaseVerified === "") {
      setError("Please answer: Place of Purchase Verified?");
      return;
    }

    if (purchaseVerified === "NO" && remarks.trim() === "") {
      setError(
        "Reason / Remarks are mandatory when Place of Purchase is not verified."
      );
      return;
    }

    // ------------------------------------------------
    // 3. PURCHASE WITHIN PS
    // ------------------------------------------------

    if (purchaseWithinPS === "") {
      setError(
        "Please answer: Place of Purchase Falls Within This PS Limits?"
      );
      return;
    }

    // IMPORTANT:
    // purchaseWithinPS = NO is allowed without mandatory remarks.
    // It does NOT create a logical-NO exception automatically.

    // ------------------------------------------------
    // 4. HEIGHT / WIDTH / MATERIAL VERIFIED
    // ------------------------------------------------

    if (dimensionsVerified === "") {
      setError(
        "Please answer: Idol Height, Width and Material Verified?"
      );
      return;
    }

    if (dimensionsVerified === "NO" && remarks.trim() === "") {
      setError(
        "Reason / Remarks are mandatory when Height, Width and Material are not verified."
      );
      return;
    }

    if (dimensionsVerified === "YES") {
      if (height.trim() === "") {
        setError(
          "Please enter or digitally measure Idol Height."
        );
        return;
      }

      if (width.trim() === "") {
        setError(
          "Please enter or digitally measure Idol Width."
        );
        return;
      }

      if (material === "") {
        setError("Please select Idol Material.");
        return;
      }
    }

    // ------------------------------------------------
    // DETERMINE MEASUREMENT METHOD
    // ------------------------------------------------

    let measurementMethod = null;

    if (dimensionsVerified === "YES") {
      if (
        heightMeasurementMethod === "DIGITAL" &&
        widthMeasurementMethod === "DIGITAL"
      ) {
        measurementMethod = "DIGITAL_PHOTO_CALIBRATION";
      } else if (
        heightMeasurementMethod === "DIGITAL" ||
        widthMeasurementMethod === "DIGITAL"
      ) {
        measurementMethod = "MIXED_MANUAL_AND_DIGITAL";
      } else {
        measurementMethod = "MANUAL_WEB_VERIFICATION";
      }
    }

    // ------------------------------------------------
    // SAVE MAIN IDOL VERIFICATION
    // ------------------------------------------------

    const data = {
      applicationId: "GAN-2026-001245",

      idolInstalled,
      purchaseVerified,
      purchaseWithinPS,
      dimensionsVerified,

      height:
        dimensionsVerified === "YES" ? height : null,

      width:
        dimensionsVerified === "YES" ? width : null,

      material:
        dimensionsVerified === "YES" ? material : null,

      measurementMethod,

      heightMeasurementMethod:
        dimensionsVerified === "YES"
          ? heightMeasurementMethod || "MANUAL"
          : null,

      widthMeasurementMethod:
        dimensionsVerified === "YES"
          ? widthMeasurementMethod || "MANUAL"
          : null,

      measurementUnit:
        dimensionsVerified === "YES"
          ? "FT"
          : null,

      remarks,

      savedAt: new Date().toISOString(),
    };

    localStorage.setItem(
      "ganesh_idol_verification",
      JSON.stringify(data)
    );

    // ------------------------------------------------
    // PURCHASE NOT VERIFIED EXCEPTION
    // ------------------------------------------------

    if (purchaseVerified === "NO") {
      localStorage.setItem(
        "ganesh_purchase_not_verified",
        JSON.stringify({
          applicationId: "GAN-2026-001245",
          module: "Idol-Based Verification",
          finding: "Place of Purchase Not Verified",
          type: "LOGICAL_NO",
          remarks,
          status: "OPEN",
          createdAt: new Date().toISOString(),
        })
      );
    }

    // ------------------------------------------------
    // DIMENSIONS NOT VERIFIED EXCEPTION
    // ------------------------------------------------

    if (dimensionsVerified === "NO") {
      localStorage.setItem(
        "ganesh_dimensions_not_verified",
        JSON.stringify({
          applicationId: "GAN-2026-001245",
          module: "Idol-Based Verification",
          finding: "Idol Height / Width / Material Not Verified",
          type: "LOGICAL_NO",
          remarks,
          status: "OPEN",
          createdAt: new Date().toISOString(),
        })
      );
    }

    setMessage(
      "Idol-Based Verification saved successfully."
    );
  };

  return (
    <main className="min-h-screen bg-slate-100">

      {/* HEADER */}

      <header className="bg-[#17365D] text-white">
        <div className="max-w-5xl mx-auto px-6 py-5 flex justify-between items-center">

          <div>
            <p className="text-xs tracking-widest text-blue-200">
              PRE-INSTALLATION
            </p>

            <h1 className="text-2xl font-bold">
              Idol-Based Verification
            </h1>
          </div>

          <button
            onClick={() =>
              router.push("/pre-installation")
            }
            className="border border-white/30 rounded-lg px-4 py-2"
          >
            ← Back
          </button>

        </div>
      </header>

      <div className="max-w-5xl mx-auto px-6 py-8">

        {/* APPLICATION DETAILS */}

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

        {/* ------------------------------------------------ */}
        {/* POINT 1 — IDOL INSTALLED */}
        {/* ------------------------------------------------ */}

        <section className="bg-white rounded-xl border border-slate-200 p-6 mb-5">

          <h2 className="text-lg font-bold text-slate-800 mb-4">
            Idol Installed or Not?
          </h2>

          <div className="flex gap-4">

            <button
              onClick={() =>
                setIdolInstalled("YES")
              }
              className={`px-8 py-3 rounded-lg font-semibold border ${
                idolInstalled === "YES"
                  ? "bg-green-600 text-white"
                  : "bg-white border-slate-300"
              }`}
            >
              YES
            </button>

            <button
              onClick={() =>
                setIdolInstalled("NO")
              }
              className={`px-8 py-3 rounded-lg font-semibold border ${
                idolInstalled === "NO"
                  ? "bg-red-600 text-white"
                  : "bg-white border-slate-300"
              }`}
            >
              NO
            </button>

          </div>

          {idolInstalled === "NO" && (
            <div className="mt-5">

              <label className="block font-bold text-red-700 mb-2">
                NO-type Reason / Remarks *
              </label>

              <textarea
                value={remarks}
                onChange={(e) =>
                  setRemarks(e.target.value)
                }
                className="w-full border border-red-300 rounded-lg px-4 py-3 min-h-28"
                placeholder="Enter reason why Idol is not installed"
              />

              <p className="text-sm text-red-600 mt-2">
                Status will be recorded as Idol Not Installed.
              </p>

            </div>
          )}

        </section>

        {idolInstalled === "YES" && (
          <>

            {/* ------------------------------------------------ */}
            {/* POINT 2 — PLACE OF PURCHASE VERIFIED */}
            {/* ------------------------------------------------ */}

            <section className="bg-white rounded-xl border border-slate-200 p-6 mb-5">

              <h2 className="text-lg font-bold text-slate-800 mb-4">
                Place of Purchase Verified?
              </h2>

              <div className="flex gap-4">

                <button
                  onClick={() =>
                    setPurchaseVerified("YES")
                  }
                  className={`px-8 py-3 rounded-lg font-semibold border ${
                    purchaseVerified === "YES"
                      ? "bg-[#17365D] text-white"
                      : "bg-white border-slate-300"
                  }`}
                >
                  YES
                </button>

                <button
                  onClick={() =>
                    setPurchaseVerified("NO")
                  }
                  className={`px-8 py-3 rounded-lg font-semibold border ${
                    purchaseVerified === "NO"
                      ? "bg-red-600 text-white"
                      : "bg-white border-slate-300"
                  }`}
                >
                  NO
                </button>

              </div>

              {purchaseVerified === "NO" && (
                <div className="mt-5">

                  <label className="block font-bold text-red-700 mb-2">
                    NO-type Reason / Remarks *
                  </label>

                  <textarea
                    value={remarks}
                    onChange={(e) =>
                      setRemarks(e.target.value)
                    }
                    className="w-full border border-red-300 rounded-lg px-4 py-3 min-h-24"
                    placeholder="Enter reason"
                  />

                </div>
              )}

            </section>

            {/* ------------------------------------------------ */}
            {/* POINT 3 — PURCHASE WITHIN PS */}
            {/* ------------------------------------------------ */}

            <section className="bg-white rounded-xl border border-slate-200 p-6 mb-5">

              <h2 className="text-lg font-bold text-slate-800 mb-4">
                Place of Purchase Falls Within This PS Limits?
              </h2>

              <div className="flex gap-4">

                <button
                  onClick={() =>
                    setPurchaseWithinPS("YES")
                  }
                  className={`px-8 py-3 rounded-lg font-semibold border ${
                    purchaseWithinPS === "YES"
                      ? "bg-[#17365D] text-white"
                      : "bg-white border-slate-300"
                  }`}
                >
                  YES
                </button>

                <button
                  onClick={() =>
                    setPurchaseWithinPS("NO")
                  }
                  className={`px-8 py-3 rounded-lg font-semibold border ${
                    purchaseWithinPS === "NO"
                      ? "bg-[#17365D] text-white"
                      : "bg-white border-slate-300"
                  }`}
                >
                  NO
                </button>

              </div>

              {purchaseWithinPS === "NO" && (
                <div className="bg-blue-50 border border-blue-200 rounded-lg px-4 py-3 mt-4">

                  <p className="text-sm text-blue-800">
                    Purchase location is outside this Police Station limits.
                  </p>

                  <p className="text-xs text-blue-600 mt-1">
                    This NO does not require mandatory NO-type remarks
                    and will not automatically create a logical-NO exception.
                  </p>

                </div>
              )}

            </section>

            {/* ------------------------------------------------ */}
            {/* POINT 4 — HEIGHT / WIDTH / MATERIAL */}
            {/* ------------------------------------------------ */}

            <section className="bg-white rounded-xl border border-slate-200 p-6 mb-5">

              <h2 className="text-lg font-bold text-slate-800 mb-4">
                Idol Height, Width and Material Verified?
              </h2>

              <div className="flex gap-4">

                <button
                  onClick={() =>
                    setDimensionsVerified("YES")
                  }
                  className={`px-8 py-3 rounded-lg font-semibold border ${
                    dimensionsVerified === "YES"
                      ? "bg-[#17365D] text-white"
                      : "bg-white border-slate-300"
                  }`}
                >
                  YES
                </button>

                <button
                  onClick={() =>
                    setDimensionsVerified("NO")
                  }
                  className={`px-8 py-3 rounded-lg font-semibold border ${
                    dimensionsVerified === "NO"
                      ? "bg-red-600 text-white"
                      : "bg-white border-slate-300"
                  }`}
                >
                  NO
                </button>

              </div>

              {/* ================================================= */}
              {/* DIGITAL + MANUAL MEASUREMENT SECTION */}
              {/* ================================================= */}

              {dimensionsVerified === "YES" && (
                <div className="mt-5">

                  {/* DIGITAL MEASUREMENT */}

                  <div className="bg-blue-50 border border-blue-200 rounded-xl p-5 mb-5">

                    <h3 className="font-bold text-blue-900 text-lg">
                      Idol Digital Measurement
                    </h3>

                    <p className="text-sm text-blue-700 mt-2">
                      Use photograph-based digital measurement to calculate
                      idol Height and Width using a known reference object.
                    </p>

                    <div className="mt-4 flex flex-wrap gap-3">

                      <button
                        type="button"
                        onClick={() =>
                          setMeasurementTool("HEIGHT")
                        }
                        className="bg-blue-700 hover:bg-blue-800 text-white px-5 py-3 rounded-lg font-semibold"
                      >
                        📏 Measure Height Digitally
                      </button>

                      <button
                        type="button"
                        onClick={() =>
                          setMeasurementTool("WIDTH")
                        }
                        className="bg-blue-700 hover:bg-blue-800 text-white px-5 py-3 rounded-lg font-semibold"
                      >
                        ↔ Measure Width Digitally
                      </button>

                    </div>

                    <p className="text-xs text-blue-600 mt-3">
                      Digital measurement uses photograph calibration.
                      Mobile AR-based measurement may be added later.
                    </p>

                  </div>

                  {/* CURRENT MEASUREMENT STATUS */}

                  {(height || width) && (
                    <div className="bg-green-50 border border-green-200 rounded-xl p-4 mb-5">

                      <h3 className="font-bold text-green-800 mb-2">
                        Measurement Status
                      </h3>

                      <div className="grid md:grid-cols-2 gap-3 text-sm">

                        <div>
                          <span className="font-semibold">
                            Height:
                          </span>{" "}
                          {height || "-"} ft
                          {heightMeasurementMethod && (
                            <span className="ml-2 text-xs text-green-700">
                              ({heightMeasurementMethod})
                            </span>
                          )}
                        </div>

                        <div>
                          <span className="font-semibold">
                            Width:
                          </span>{" "}
                          {width || "-"} ft
                          {widthMeasurementMethod && (
                            <span className="ml-2 text-xs text-green-700">
                              ({widthMeasurementMethod})
                            </span>
                          )}
                        </div>

                      </div>

                    </div>
                  )}

                  {/* MANUAL ENTRY */}

                  <div className="border border-slate-200 rounded-xl p-5">

                    <h3 className="font-bold text-slate-800 mb-1">
                      Manual / Physically Verified Measurement
                    </h3>

                    <p className="text-sm text-slate-500 mb-5">
                      Measurements may also be entered manually after
                      physical verification.
                    </p>

                    <div className="grid md:grid-cols-3 gap-4">

                      {/* HEIGHT */}

                      <div>

                        <label className="block font-bold text-slate-700 mb-2">
                          Height (ft.) *
                        </label>

                        <input
                          type="number"
                          step="0.1"
                          min="0"
                          value={height}
                          onChange={(e) => {
                            setHeight(e.target.value);

                            setHeightMeasurementMethod(
                              "MANUAL"
                            );
                          }}
                          className="w-full border border-slate-300 rounded-lg px-4 py-3"
                          placeholder="Example: 12.5"
                        />

                        <p className="text-xs text-slate-400 mt-2">
                          Manual verified measurement
                        </p>

                      </div>

                      {/* WIDTH */}

                      <div>

                        <label className="block font-bold text-slate-700 mb-2">
                          Width (ft.) *
                        </label>

                        <input
                          type="number"
                          step="0.1"
                          min="0"
                          value={width}
                          onChange={(e) => {
                            setWidth(e.target.value);

                            setWidthMeasurementMethod(
                              "MANUAL"
                            );
                          }}
                          className="w-full border border-slate-300 rounded-lg px-4 py-3"
                          placeholder="Example: 7.5"
                        />

                        <p className="text-xs text-slate-400 mt-2">
                          Manual verified measurement
                        </p>

                      </div>

                      {/* MATERIAL */}

                      <div>

                        <label className="block font-bold text-slate-700 mb-2">
                          Material *
                        </label>

                        <select
                          value={material}
                          onChange={(e) =>
                            setMaterial(e.target.value)
                          }
                          className="w-full border border-slate-300 rounded-lg px-4 py-3"
                        >
                          <option value="">
                            Select Material
                          </option>

                          <option value="CLAY">
                            Clay
                          </option>

                          <option value="POP">
                            POP
                          </option>

                        </select>

                      </div>

                    </div>

                  </div>

                </div>
              )}

              {/* NO REMARKS */}

              {dimensionsVerified === "NO" && (
                <div className="mt-5">

                  <label className="block font-bold text-red-700 mb-2">
                    NO-type Reason / Remarks *
                  </label>

                  <textarea
                    value={remarks}
                    onChange={(e) =>
                      setRemarks(e.target.value)
                    }
                    className="w-full border border-red-300 rounded-lg px-4 py-3 min-h-24"
                    placeholder="Enter reason"
                  />

                </div>
              )}

            </section>

          </>
        )}

        {/* ERROR */}

        {error && (
          <div className="bg-red-100 border border-red-200 text-red-700 rounded-lg px-4 py-3 mb-4">
            {error}
          </div>
        )}

        {/* SUCCESS */}

        {message && (
          <div className="bg-green-100 border border-green-200 text-green-700 rounded-lg px-4 py-3 mb-4">
            {message}
          </div>
        )}

        {/* SAVE */}

        <div className="flex justify-end">

          <button
            onClick={saveVerification}
            className="bg-[#17365D] text-white font-semibold rounded-lg px-8 py-3 hover:bg-[#244d7e]"
          >
            Save Idol Verification
          </button>

        </div>

      </div>

      {/* ================================================= */}
      {/* DIGITAL MEASUREMENT MODAL */}
      {/* ================================================= */}

      {measurementTool && (
        <DigitalMeasurementTool
          measurementType={measurementTool}

          onClose={() =>
            setMeasurementTool(null)
          }

          onUseMeasurement={(value) => {
            const currentType =
              measurementTool;

            if (currentType === "HEIGHT") {
              setHeight(
                value.toString()
              );

              setHeightMeasurementMethod(
                "DIGITAL"
              );
            }

            if (currentType === "WIDTH") {
              setWidth(
                value.toString()
              );

              setWidthMeasurementMethod(
                "DIGITAL"
              );
            }

            setMeasurementTool(null);

            setMessage(
              `${
                currentType === "HEIGHT"
                  ? "Height"
                  : "Width"
              } digitally measured and added successfully.`
            );
          }}
        />
      )}

    </main>
  );
}