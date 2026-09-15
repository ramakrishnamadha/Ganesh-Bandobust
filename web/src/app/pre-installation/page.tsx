"use client";

import { useEffect, useMemo, useState } from "react";
import { useRouter } from "next/navigation";

type JsonObject = Record<string, unknown>;

type VerificationRecord = {
  id: number;
  gpid: string;
  applicationId?: string | null;

  locationResult?: JsonObject | null;
  mandapResult?: JsonObject | null;
  idolResult?: JsonObject | null;
  routeResult?: JsonObject | null;
  securityResult?: JsonObject | null;
  organizerResult?: JsonObject | null;
  interDepartmentalResult?: JsonObject | null;
  permissionShoReviewResult?: JsonObject | null;

  verificationStatus?: string | null;
  submittedAt?: string | null;
  updatedAt?: string | null;
};

type ModuleDefinition = {
  key:
    | "locationResult"
    | "mandapResult"
    | "idolResult"
    | "routeResult"
    | "securityResult"
    | "organizerResult"
    | "interDepartmentalResult"
    | "permissionShoReviewResult";
  number: number;
  title: string;
  shortTitle: string;
};

const modules: ModuleDefinition[] = [
  {
    key: "locationResult",
    number: 1,
    title: "Location-Based Verification",
    shortTitle: "Location",
  },
  {
    key: "mandapResult",
    number: 2,
    title: "Mandap-Based Verification",
    shortTitle: "Mandap",
  },
  {
    key: "idolResult",
    number: 3,
    title: "Idol-Based Verification",
    shortTitle: "Idol",
  },
  {
    key: "routeResult",
    number: 4,
    title: "Route-Based Verification",
    shortTitle: "Route",
  },
  {
    key: "securityResult",
    number: 5,
    title: "Security-Based Verification",
    shortTitle: "Security",
  },
  {
    key: "organizerResult",
    number: 6,
    title: "Organizer-Based Verification",
    shortTitle: "Organizer",
  },
  {
    key: "interDepartmentalResult",
    number: 7,
    title: "Inter-Departmental Coordination / NOCs",
    shortTitle: "Inter-Dept.",
  },
  {
    key: "permissionShoReviewResult",
    number: 8,
    title: "Permission / SHO Review",
    shortTitle: "SHO Review",
  },
];

function asObject(value: unknown): JsonObject | null {
  if (
    value &&
    typeof value === "object" &&
    !Array.isArray(value)
  ) {
    return value as JsonObject;
  }

  return null;
}

function asArray(value: unknown): unknown[] {
  return Array.isArray(value) ? value : [];
}

function asText(value: unknown): string {
  if (value === null || value === undefined) {
    return "";
  }

  return String(value).trim();
}

function isYes(value: unknown): boolean {
  return value === true || asText(value).toUpperCase() === "YES";
}

function isNo(value: unknown): boolean {
  return value === false || asText(value).toUpperCase() === "NO";
}

function getCompletedModuleCount(record: VerificationRecord): number {
  return modules.filter((module) => record[module.key] != null).length;
}

function getShoDecision(record: VerificationRecord): string {
  const review = asObject(record.permissionShoReviewResult);

  if (!review) {
    return "Pending";
  }

  return asText(review.permissionRecommendation) || "Review Completed";
}

function getUnresolvedNocCount(record: VerificationRecord): number {
  const result = asObject(record.interDepartmentalResult);

  if (!result) {
    return 0;
  }

  let count = 0;

  for (const value of asArray(result.autoIdentifiedRequirements)) {
    const item = asObject(value);

    if (!item) {
      continue;
    }

    if (!isYes(item.coordinationRequired)) {
      continue;
    }

    const status = asText(item.status);

    if (
      status !== "NOC / Clearance Received" &&
      status !== "Not Applicable"
    ) {
      count += 1;
    }

    if (
      status === "Conditional Clearance" &&
      isNo(item.conditionsComplied)
    ) {
      count += 1;
    }
  }

  if (isYes(result.unresolvedInterDepartmentalIssue)) {
    count += 1;
  }

  return count;
}

function getIssueCount(record: VerificationRecord): number {
  let count = 0;

  const location = asObject(record.locationResult);

  if (location) {
    if (isNo(location.locationVerified)) count += 1;
    if (isYes(location.locationChanged)) count += 1;
    if (isYes(location.disputedLand)) count += 1;

    const sensitivity = asText(location.sensitivity).toUpperCase();

    if (sensitivity === "MEDIUM" || sensitivity === "HIGH") {
      count += 1;
    }
  }

  const mandap = asObject(record.mandapResult);

  if (mandap) {
    if (isNo(mandap.mandapInstalled)) count += 1;

    if (isYes(mandap.mandapInstalled)) {
      if (isNo(mandap.structuralStability)) count += 1;
      if (isYes(mandap.roadObstruction)) count += 1;
      if (isNo(mandap.emergencyAccess)) count += 1;

      if (
        isYes(mandap.overheadWires) ||
        isYes(mandap.overheadWiresRisk)
      ) {
        count += 1;
      }

      if (
        isYes(mandap.electricalHazard) ||
        isYes(mandap.electricalHazardRisk)
      ) {
        count += 1;
      }

      if (isNo(mandap.mandapHeightVerified)) {
        count += 1;
      }
    }
  }

  const idol = asObject(record.idolResult);

  if (idol) {
    if (isNo(idol.idolInstalled)) count += 1;
    if (isNo(idol.heightMatches)) count += 1;
    if (isNo(idol.widthMatches)) count += 1;
    if (isNo(idol.basePlatformSafe)) count += 1;
  }

  const route = asObject(record.routeResult);

  if (route) {
    if (isNo(route.installationRouteVerified)) {
      count += 1;
    }

    if (
      isNo(route.constructedAtLocationProcessionRouteVerified)
    ) {
      count += 1;
    }

    for (const stretchValue of asArray(route.routeStretches)) {
      const stretch = asObject(stretchValue);

      if (!stretch) {
        continue;
      }

      for (const issueValue of asArray(stretch.issues)) {
        const issue = asObject(issueValue);

        if (issue && isYes(issue.noticed)) {
          count += 1;
        }
      }
    }
  }

  const security = asObject(record.securityResult);

  if (security) {
    if (isNo(security.securityVerified)) {
      count += 1;
    }

    for (const pointNo of [2, 4, 6, 7, 8, 9, 10, 11]) {
      const point = asObject(security[`point${pointNo}`]);

      if (point && isNo(point.available)) {
        count += 1;
      }
    }

    const cctv = asObject(security.point3);

    if (cctv && isNo(cctv.cctvAvailable)) {
      count += 1;
    }

    const fire = asObject(security.point5);

    if (
      fire &&
      (isNo(fire.fireExtinguisherAvailable) ||
        isNo(fire.waterArrangementAvailable) ||
        isNo(fire.sandArrangementAvailable))
    ) {
      count += 1;
    }
  }

  const organizer = asObject(record.organizerResult);

  if (organizer) {
    if (isNo(organizer.allOrganizersPersonallyVerified)) {
      count += 1;
    }

    for (const personValue of asArray(organizer.organizers)) {
      const person = asObject(personValue);

      if (!person) {
        continue;
      }

      if (isNo(person.contactVerified)) {
        count += 1;
      }

      if (isYes(person.adverseInformation)) {
        count += 1;
      }
    }
  }

  count += getUnresolvedNocCount(record);

  return count;
}

function formatDate(value?: string | null): string {
  if (!value) {
    return "-";
  }

  const date = new Date(value);

  if (Number.isNaN(date.getTime())) {
    return "-";
  }

  return date.toLocaleString("en-IN");
}

export default function PreInstallationPage() {
  const router = useRouter();

  const [records, setRecords] = useState<VerificationRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [search, setSearch] = useState("");

  async function loadVerifications() {
    setLoading(true);
    setError("");

    try {
      const response = await fetch("/api/verification", {
        method: "GET",
        cache: "no-store",
      });

      if (!response.ok) {
        throw new Error(
          `Unable to load verification records. Status ${response.status}`
        );
      }

      const data = await response.json();

      if (!Array.isArray(data)) {
        throw new Error("Unexpected verification API response.");
      }

      setRecords(data as VerificationRecord[]);
    } catch (err) {
      console.error(err);

      setError(
        "Unable to load Pre-Installation verification data."
      );
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    void loadVerifications();
  }, []);

  const summary = useMemo(() => {
    const total = records.length;

    let completed = 0;
    let inProgress = 0;
    let withIssues = 0;
    let nocPending = 0;
    let shoPending = 0;
    let recommended = 0;
    let conditional = 0;
    let notRecommended = 0;

    for (const record of records) {
      const moduleCount = getCompletedModuleCount(record);

      if (moduleCount === 8) {
        completed += 1;
      } else {
        inProgress += 1;
      }

      if (getIssueCount(record) > 0) {
        withIssues += 1;
      }

      if (getUnresolvedNocCount(record) > 0) {
        nocPending += 1;
      }

      const decision = getShoDecision(record);

      if (decision === "Pending") {
        shoPending += 1;
      } else if (decision === "Recommended for Permission") {
        recommended += 1;
      } else if (decision === "Recommended with Conditions") {
        conditional += 1;
      } else if (decision === "Not Recommended") {
        notRecommended += 1;
      }
    }

    return {
      total,
      completed,
      inProgress,
      withIssues,
      nocPending,
      shoPending,
      recommended,
      conditional,
      notRecommended,
    };
  }, [records]);

  const moduleSummary = useMemo(() => {
    return modules.map((module) => ({
      ...module,
      completed: records.filter(
        (record) => record[module.key] != null
      ).length,
    }));
  }, [records]);

  const filteredRecords = useMemo(() => {
    const query = search.trim().toLowerCase();

    if (!query) {
      return records;
    }

    return records.filter((record) => {
      return (
        record.gpid.toLowerCase().includes(query) ||
        asText(record.applicationId)
          .toLowerCase()
          .includes(query)
      );
    });
  }, [records, search]);

  return (
    <main className="min-h-screen bg-slate-100">
      <header className="bg-[#17365D] text-white">
        <div className="max-w-[1500px] mx-auto px-6 py-5 flex flex-wrap gap-4 items-center justify-between">
          <div>
            <p className="text-xs tracking-widest text-blue-200">
              STAGE 1 · MONITORING & SUPERVISION
            </p>

            <h1 className="text-2xl font-bold">
              Pre-Installation Verification
            </h1>

            <p className="text-sm text-blue-100 mt-1">
              Supervisory monitoring of field verification
              submitted through the Mobile application
            </p>
          </div>

          <div className="flex gap-3">
            <button
              onClick={() => void loadVerifications()}
              className="border border-white/30 px-4 py-2 rounded-lg hover:bg-white/10"
            >
              ↻ Refresh
            </button>

            <button
              onClick={() => router.push("/dashboard")}
              className="border border-white/30 px-4 py-2 rounded-lg hover:bg-white/10"
            >
              ← Dashboard
            </button>
          </div>
        </div>
      </header>

      <div className="max-w-[1500px] mx-auto px-6 py-7">
        {error && (
          <div className="mb-5 bg-red-50 border border-red-200 text-red-700 rounded-xl px-4 py-3">
            {error}
          </div>
        )}

        <section className="grid sm:grid-cols-2 lg:grid-cols-4 xl:grid-cols-5 gap-4 mb-7">
          <SummaryCard
            title="Verification Records"
            value={summary.total}
            description="GPIDs received from Mobile"
          />

          <SummaryCard
            title="In Progress"
            value={summary.inProgress}
            description="One or more modules pending"
          />

          <SummaryCard
            title="All 8 Completed"
            value={summary.completed}
            description="Complete verification package"
          />

          <SummaryCard
            title="Attention Required"
            value={summary.withIssues}
            description="Records having adverse findings"
            warning
          />

          <SummaryCard
            title="NOC / Coordination Pending"
            value={summary.nocPending}
            description="Unresolved departmental issues"
            warning
          />
        </section>

        <section className="bg-white border border-slate-200 rounded-xl p-5 mb-7">
          <div className="flex flex-wrap gap-3 items-center justify-between mb-4">
            <div>
              <h2 className="font-bold text-slate-800 text-lg">
                Module Completion Monitoring
              </h2>

              <p className="text-sm text-slate-500 mt-1">
                Number of GPIDs for which each Mobile
                verification module is available
              </p>
            </div>
          </div>

          <div className="grid sm:grid-cols-2 lg:grid-cols-4 gap-3">
            {moduleSummary.map((module) => {
              const percentage =
                summary.total === 0
                  ? 0
                  : Math.round(
                      (module.completed / summary.total) * 100
                    );

              return (
                <div
                  key={module.key}
                  className="border border-slate-200 rounded-xl p-4"
                >
                  <div className="flex items-start gap-3">
                    <div className="w-9 h-9 rounded-full bg-[#17365D] text-white flex items-center justify-center text-sm font-bold shrink-0">
                      {module.number}
                    </div>

                    <div className="min-w-0 flex-1">
                      <p className="font-semibold text-slate-800">
                        {module.shortTitle}
                      </p>

                      <p className="text-xs text-slate-500 mt-1">
                        {module.completed} / {summary.total} GPIDs
                      </p>
                    </div>

                    <span className="text-sm font-bold text-[#17365D]">
                      {percentage}%
                    </span>
                  </div>

                  <div className="mt-3 h-2 bg-slate-100 rounded-full overflow-hidden">
                    <div
                      className="h-full bg-[#17365D] rounded-full"
                      style={{
                        width: `${percentage}%`,
                      }}
                    />
                  </div>
                </div>
              );
            })}
          </div>
        </section>

        <section className="grid lg:grid-cols-2 gap-5 mb-7">
          <div className="bg-white border border-slate-200 rounded-xl p-5">
            <h2 className="font-bold text-slate-800 text-lg">
              SHO Review Status
            </h2>

            <p className="text-sm text-slate-500 mt-1 mb-5">
              Permission recommendation recorded after
              verification review
            </p>

            <div className="grid grid-cols-2 gap-3">
              <StatusBox
                label="Pending Review"
                value={summary.shoPending}
              />

              <StatusBox
                label="Recommended"
                value={summary.recommended}
              />

              <StatusBox
                label="With Conditions"
                value={summary.conditional}
              />

              <StatusBox
                label="Not Recommended"
                value={summary.notRecommended}
                warning
              />
            </div>
          </div>

          <div className="bg-white border border-slate-200 rounded-xl p-5">
            <h2 className="font-bold text-slate-800 text-lg">
              Supervisory Principle
            </h2>

            <p className="text-sm text-slate-500 mt-1 mb-4">
              This Web application is for monitoring and
              supervision.
            </p>

            <div className="space-y-3 text-sm text-slate-700">
              <div className="bg-slate-50 rounded-lg px-4 py-3">
                Mobile officers perform field verification,
                GPS capture, evidence collection and
                measurements.
              </div>

              <div className="bg-slate-50 rounded-lg px-4 py-3">
                Web officers monitor completion, adverse
                findings, evidence, NOCs, unresolved issues
                and SHO review.
              </div>

              <div className="bg-slate-50 rounded-lg px-4 py-3">
                Web does not duplicate Mobile field-entry
                verification forms.
              </div>
            </div>
          </div>
        </section>

        <section className="bg-white border border-slate-200 rounded-xl overflow-hidden">
          <div className="p-5 border-b border-slate-200 flex flex-wrap gap-4 items-center justify-between">
            <div>
              <h2 className="font-bold text-slate-800 text-lg">
                GPID Verification Monitoring
              </h2>

              <p className="text-sm text-slate-500 mt-1">
                Click any GPID row to open the complete
                supervisory verification details.
              </p>
            </div>

            <input
              type="text"
              value={search}
              onChange={(event) => setSearch(event.target.value)}
              placeholder="Search GPID / Application ID"
              className="w-full sm:w-80 border border-slate-300 rounded-lg px-4 py-2.5 outline-none focus:border-blue-500"
            />
          </div>

          {loading ? (
            <div className="p-10 text-center text-slate-500">
              Loading verification records...
            </div>
          ) : filteredRecords.length === 0 ? (
            <div className="p-10 text-center">
              <p className="font-semibold text-slate-700">
                No verification records found.
              </p>

              <p className="text-sm text-slate-500 mt-2">
                Mobile verification submissions will appear
                here after they are saved to the shared
                database.
              </p>
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full min-w-[1050px] text-sm">
                <thead className="bg-slate-50 text-slate-600">
                  <tr>
                    <th className="text-left px-4 py-3">
                      GPID
                    </th>

                    <th className="text-left px-4 py-3">
                      Progress
                    </th>

                    <th className="text-left px-4 py-3">
                      Issues
                    </th>

                    <th className="text-left px-4 py-3">
                      NOC / Coordination
                    </th>

                    <th className="text-left px-4 py-3">
                      SHO Decision
                    </th>

                    <th className="text-left px-4 py-3">
                      Status
                    </th>

                    <th className="text-left px-4 py-3">
                      Last Updated
                    </th>
                  </tr>
                </thead>

                <tbody>
                  {filteredRecords.map((record) => {
                    const completedModules =
                      getCompletedModuleCount(record);

                    const issueCount =
                      getIssueCount(record);

                    const nocCount =
                      getUnresolvedNocCount(record);

                    const shoDecision =
                      getShoDecision(record);

                    return (
                      <tr
                        key={record.id}
                        onClick={() =>
                          router.push(
                            `/pre-installation/${encodeURIComponent(
                              record.gpid
                            )}`
                          )
                        }
                        className="border-t border-slate-100 hover:bg-blue-50 cursor-pointer transition"
                        title={`Open supervisory details for ${record.gpid}`}
                      >
                        <td className="px-4 py-4">
                          <div className="font-bold text-[#17365D]">
                            {record.gpid}{" "}
                            <span className="text-blue-500">
                              →
                            </span>
                          </div>

                          {record.applicationId &&
                            record.applicationId !== record.gpid && (
                              <div className="text-xs text-slate-400 mt-1">
                                App: {record.applicationId}
                              </div>
                            )}
                        </td>

                        <td className="px-4 py-4">
                          <div className="font-semibold text-slate-700">
                            {completedModules} / 8
                          </div>

                          <div className="w-28 h-1.5 bg-slate-100 rounded-full mt-2 overflow-hidden">
                            <div
                              className="h-full bg-[#17365D]"
                              style={{
                                width: `${
                                  (completedModules / 8) * 100
                                }%`,
                              }}
                            />
                          </div>
                        </td>

                        <td className="px-4 py-4">
                          {issueCount === 0 ? (
                            <span className="inline-flex rounded-full bg-green-50 text-green-700 px-3 py-1 text-xs font-semibold">
                              No issue detected
                            </span>
                          ) : (
                            <span className="inline-flex rounded-full bg-red-50 text-red-700 px-3 py-1 text-xs font-semibold">
                              {issueCount} issue
                              {issueCount !== 1 ? "s" : ""}
                            </span>
                          )}
                        </td>

                        <td className="px-4 py-4">
                          {record.interDepartmentalResult == null ? (
                            <span className="text-slate-400">
                              Pending
                            </span>
                          ) : nocCount > 0 ? (
                            <span className="font-semibold text-amber-700">
                              {nocCount} pending
                            </span>
                          ) : (
                            <span className="font-semibold text-green-700">
                              No unresolved issue
                            </span>
                          )}
                        </td>

                        <td className="px-4 py-4">
                          <span
                            className={
                              shoDecision === "Not Recommended"
                                ? "font-semibold text-red-700"
                                : shoDecision ===
                                    "Recommended with Conditions"
                                  ? "font-semibold text-amber-700"
                                  : shoDecision ===
                                      "Recommended for Permission"
                                    ? "font-semibold text-green-700"
                                    : "text-slate-400"
                            }
                          >
                            {shoDecision}
                          </span>
                        </td>

                        <td className="px-4 py-4">
                          <span className="inline-flex rounded-full bg-slate-100 text-slate-700 px-3 py-1 text-xs font-semibold">
                            {asText(record.verificationStatus) ||
                              "UNKNOWN"}
                          </span>
                        </td>

                        <td className="px-4 py-4 text-slate-500">
                          {formatDate(
                            record.updatedAt || record.submittedAt
                          )}
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          )}
        </section>
      </div>
    </main>
  );
}

function SummaryCard({
  title,
  value,
  description,
  warning = false,
}: {
  title: string;
  value: number;
  description: string;
  warning?: boolean;
}) {
  return (
    <div className="bg-white border border-slate-200 rounded-xl p-5 shadow-sm">
      <p className="text-sm text-slate-500">
        {title}
      </p>

      <p
        className={`text-3xl font-bold mt-2 ${
          warning ? "text-amber-700" : "text-[#17365D]"
        }`}
      >
        {value}
      </p>

      <p className="text-xs text-slate-400 mt-2">
        {description}
      </p>
    </div>
  );
}

function StatusBox({
  label,
  value,
  warning = false,
}: {
  label: string;
  value: number;
  warning?: boolean;
}) {
  return (
    <div className="border border-slate-200 rounded-lg p-4">
      <p className="text-xs text-slate-500">
        {label}
      </p>

      <p
        className={`text-2xl font-bold mt-1 ${
          warning ? "text-red-700" : "text-[#17365D]"
        }`}
      >
        {value}
      </p>
    </div>
  );
}