"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";

export default function ReportsPage() {
  const router = useRouter();
  const [userRole, setUserRole] = useState<string>("");

  useEffect(() => {
    // Read user role from local storage to simulate hierarchy checking
    const savedUser = localStorage.getItem("ganesh_user");
    if (savedUser) {
      try {
        const parsedUser = JSON.parse(savedUser);
        setUserRole(parsedUser.role || "OFFICER");
      } catch (error) {
        console.error("Failed to parse user", error);
      }
    } else {
      router.push("/");
    }
  }, [router]);

  return (
    <div className="bg-white rounded-lg shadow p-6">
      <h1 className="text-2xl font-semibold mb-6">Daily Reports</h1>
      
      <div className="bg-blue-50 border border-blue-200 text-blue-800 p-4 rounded-md mb-8">
        <p>
          <span className="font-semibold">Current Role:</span> {userRole}
        </p>
        <p className="text-sm mt-1">
          {userRole === "ADMIN" || userRole === "COMMISSIONER" 
            ? "You have high-level access and can view all hierarchy reports." 
            : "You are viewing reports specific to your hierarchy level."}
        </p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
        <div className="bg-gray-50 p-4 rounded-lg border border-gray-200 shadow-sm">
          <h3 className="text-sm font-medium text-gray-500">Total GPIDs Checked</h3>
          <p className="text-3xl font-bold mt-2">1,245</p>
        </div>
        <div className="bg-gray-50 p-4 rounded-lg border border-gray-200 shadow-sm">
          <h3 className="text-sm font-medium text-gray-500">Pending Verifications</h3>
          <p className="text-3xl font-bold mt-2 text-yellow-600">342</p>
        </div>
        <div className="bg-gray-50 p-4 rounded-lg border border-gray-200 shadow-sm">
          <h3 className="text-sm font-medium text-gray-500">Completed</h3>
          <p className="text-3xl font-bold mt-2 text-green-600">903</p>
        </div>
      </div>

      <div className="border-t pt-6">
        <h2 className="text-lg font-medium mb-4">Detailed Report Data</h2>
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Date</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Officer</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              <tr>
                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">Today</td>
                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">John Doe</td>
                <td className="px-6 py-4 whitespace-nowrap text-sm">
                  <span className="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-green-100 text-green-800">Generated</span>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
