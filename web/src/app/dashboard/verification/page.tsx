"use client";

import { useState } from "react";

export default function VerificationStagesPage() {
  // Temporary mock data for UI visualization
  const [stages] = useState([
    { id: "pre-installation", name: "Pre-installation", status: "completed" },
    { id: "installation", name: "Installation", status: "in-progress" },
    { id: "during-festivity", name: "During Festivity", status: "pending" },
    { id: "immersion", name: "Immersion", status: "pending" },
    { id: "post-immersion", name: "Post Immersion", status: "pending" },
  ]);

  const getStatusColor = (status: string) => {
    switch (status) {
      case "completed":
        return "bg-green-500 text-white border-green-600";
      case "in-progress":
        return "bg-yellow-400 text-gray-900 border-yellow-500";
      case "pending":
      default:
        return "bg-gray-100 text-gray-500 border-gray-200";
    }
  };

  return (
    <div className="bg-white rounded-lg shadow p-6">
      <h1 className="text-2xl font-semibold mb-6">Verification Stages</h1>
      <p className="text-gray-600 mb-8">
        Track the progress of the 5 verification stages for Ganesh Bandobust.
      </p>

      <div className="space-y-4">
        {stages.map((stage, index) => (
          <div
            key={stage.id}
            className="flex items-center p-4 border rounded-md shadow-sm"
          >
            <div
              className={`flex-shrink-0 h-10 w-10 flex items-center justify-center rounded-full border-2 ${getStatusColor(
                stage.status
              )}`}
            >
              <span className="font-bold">{index + 1}</span>
            </div>
            <div className="ml-4 flex-1">
              <h3 className="text-lg font-medium text-gray-900">{stage.name}</h3>
              <p className="text-sm text-gray-500 capitalize">
                Status: {stage.status.replace("-", " ")}
              </p>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
