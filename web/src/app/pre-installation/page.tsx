"use client";

import { useRouter } from "next/navigation";

export default function PreInstallationPage() {
  const router = useRouter();

  const modules = [
    "Location-Based Verification",
    "Mandap-Based Verification",
    "Idol-Based Verification",
    "Route-Based Verification",
    "Security-Based Verification",
    "Organizer-Based Verification",
    "Inter-Departmental Coordination / NOCs",
    "Permission / SHO Review",
  ];

  return (
    <main className="min-h-screen bg-slate-100">
      <header className="bg-[#17365D] text-white">
        <div className="max-w-6xl mx-auto px-6 py-5 flex items-center justify-between">
          <div>
            <p className="text-xs tracking-widest text-blue-200">
              STAGE 1
            </p>

            <h1 className="text-2xl font-bold">
              Pre-Installation Verification
            </h1>
          </div>

          <button
            onClick={() => router.push("/dashboard")}
            className="border border-white/30 px-4 py-2 rounded-lg"
          >
            ← Dashboard
          </button>
        </div>
      </header>

      <div className="max-w-6xl mx-auto px-6 py-8">

        <div className="bg-white border border-slate-200 rounded-xl p-5 mb-6">
          <h2 className="font-bold text-slate-800">
            Pre-Installation Checklist
          </h2>

          <p className="text-sm text-slate-500 mt-1">
            Complete the following verification modules for the selected
            Ganesh application.
          </p>
        </div>

        <div className="grid md:grid-cols-2 gap-4">

          {modules.map((module, index) => (
            <button
              key={module}
              onClick={() => {
                if (index === 0) {
                  router.push("/pre-installation/location");
                }
                if (index === 1) {
  router.push("/pre-installation/mandap");
}
if (index === 2) {
  router.push("/pre-installation/idol");
}
              }}
              className="bg-white border border-slate-200 hover:border-blue-400 rounded-xl p-5 text-left shadow-sm transition"
            >
              <div className="flex items-start gap-4">

                <div className="w-10 h-10 rounded-full bg-[#17365D] text-white flex items-center justify-center font-bold">
                  {index + 1}
                </div>

                <div>
                  <h3 className="font-bold text-slate-800">
                    {module}
                  </h3>

                  <p className="text-sm text-slate-400 mt-1">
                    {index === 0
                      ? "Ready to configure"
                      : "Pending Development"}
                  </p>
                </div>

              </div>
            </button>
          ))}

        </div>
      </div>
    </main>
  );
}