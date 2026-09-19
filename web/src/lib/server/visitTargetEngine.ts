import { prisma } from "@/lib/prisma";
import {
  GaneshRecord,
  loadGpidMaster,
  text,
  sameAccessName,
  normalizeAccessName,
} from "./gpidMaster";

export type OfficerTargetRule = {
  role: string;
  frequencyPerMandap: number;
  minMandapsPerUnit: number;
  scopeLevel: "CLUSTER" | "SECTOR" | "PS" | "DIVISION" | "ZONE" | "COMMISSIONERATE";
  requiresSensitiveMandap: boolean;
  shiftType: "DAY" | "NIGHT";
  activeFromDay: number;
  activeToDay: number;
};

export type MandapDailyStatus = {
  gpid: string;
  pandalName: string;
  policeStationName: string;
  sectorName: string;
  clusterName: string;
  sensitivity: string;
  requiredVisitsToday: number;
  actualVisitsToday: number;
  isFullyVisited: boolean;
  lastVisitedAt: Date | null;
  lastVisitedByOfficer: string | null;
  hasDeficiency: boolean;
};

export type OfficerDailyProgress = {
  officerId: string;
  officerEmployeeId: string;
  officerName: string;
  officerRank: string;
  officerRole: string;
  policeStationName: string;
  sectorName: string | null;
  clusterName: string | null;
  date: string;
  festivalDay: number;

  targetMandapCount: number;
  targetTotalVisits: number;
  completedUniqueMandaps: number;
  completedTotalVisits: number;
  sensitiveTargetCount: number;
  sensitiveCompletedCount: number;
  deficienciesReported: number;

  compliancePercentage: number;
  status: "COMPLETED" | "ON_TRACK" | "DEFICIT" | "NOT_STARTED";
  lastVisitedAt: Date | null;

  pendingMandaps: MandapDailyStatus[];
  completedMandaps: MandapDailyStatus[];
};

export type CreateDailyVisitInput = {
  userId: string;
  officerEmployeeId: string;
  officerName: string;
  officerRank: string;
  officerRole: string;
  gpid: string;
  pandalName?: string;
  commissionerateName?: string;
  rangeName?: string;
  zoneName?: string;
  divisionName?: string;
  policeStationName?: string;
  sectorName?: string;
  clusterName?: string;
  sensitivity?: string;
  date: string; // YYYY-MM-DD
  festivalDay: number;
  latitude: number;
  longitude: number;
  accuracy?: number;
  distanceFromMandapMeters?: number;
  isWithinGeofence?: boolean;
  visitType?: string;
  stage?: string;
  remarks?: string;
  actionTaken?: string;
  evidenceUrls?: string[];
  hasDeficiency?: boolean;
  deficiencyCategories?: string[];
  requiresFollowUp?: boolean;
  verificationSource?: string;
};

/**
 * Returns canonical default target configuration rules by police role / rank.
 */
export function getDefaultTargetRule(role: string): OfficerTargetRule {
  const normalized = role.trim().toUpperCase().replace(/\s+/g, "_");

  switch (normalized) {
    case "CLUSTER_INCHARGE":
    case "CLUSTER_IN_CHARGE":
    case "CLUSTER_OFFICER":
      return {
        role: "CLUSTER_INCHARGE",
        frequencyPerMandap: 2, // Min 2 visits per day per mandap in cluster
        minMandapsPerUnit: 0,
        scopeLevel: "CLUSTER",
        requiresSensitiveMandap: false,
        shiftType: "DAY",
        activeFromDay: 1,
        activeToDay: 11,
      };

    case "SECTOR_INCHARGE":
    case "SECTOR_IN_CHARGE":
    case "SECTOR_OFFICER":
    case "SI":
    case "SUB_INSPECTOR":
      return {
        role: "SECTOR_INCHARGE",
        frequencyPerMandap: 1, // Min 1 visit per day per mandap in sector
        minMandapsPerUnit: 0,
        scopeLevel: "SECTOR",
        requiresSensitiveMandap: false,
        shiftType: "DAY",
        activeFromDay: 1,
        activeToDay: 11,
      };

    case "DI":
    case "DETECTIVE_INSPECTOR":
      return {
        role: "DI",
        frequencyPerMandap: 1,
        minMandapsPerUnit: 5, // Min 5 mandaps per sector
        scopeLevel: "PS",
        requiresSensitiveMandap: false,
        shiftType: "DAY",
        activeFromDay: 1,
        activeToDay: 11,
      };

    case "SHO":
    case "INSPECTOR":
    case "CI":
      return {
        role: "SHO",
        frequencyPerMandap: 1,
        minMandapsPerUnit: 10, // Supervisory sample across PS including hypersensitive
        scopeLevel: "PS",
        requiresSensitiveMandap: true,
        shiftType: "DAY",
        activeFromDay: 1,
        activeToDay: 11,
      };

    case "ACP":
    case "DSP":
    case "SUB_DIVISIONAL_OFFICER":
      return {
        role: "ACP",
        frequencyPerMandap: 1,
        minMandapsPerUnit: 2, // Min 2 mandaps per PS, at least 1 sensitive
        scopeLevel: "DIVISION",
        requiresSensitiveMandap: true,
        shiftType: "DAY",
        activeFromDay: 1,
        activeToDay: 11,
      };

    case "ADDL_DCP":
    case "ADDITIONAL_DCP":
      return {
        role: "ADDL_DCP",
        frequencyPerMandap: 1,
        minMandapsPerUnit: 2, // Min 2 mandaps per division, 1 sensitive
        scopeLevel: "ZONE",
        requiresSensitiveMandap: true,
        shiftType: "DAY",
        activeFromDay: 1,
        activeToDay: 11,
      };

    case "DCP":
      return {
        role: "DCP",
        frequencyPerMandap: 1,
        minMandapsPerUnit: 5, // Zone level strategic visits
        scopeLevel: "ZONE",
        requiresSensitiveMandap: true,
        shiftType: "DAY",
        activeFromDay: 1,
        activeToDay: 11,
      };

    case "SB_PS":
    case "SB":
    case "SPECIAL_BRANCH":
      return {
        role: "SB_PS",
        frequencyPerMandap: 1,
        minMandapsPerUnit: 15, // Min 15 mandaps per PS including sensitive
        scopeLevel: "PS",
        requiresSensitiveMandap: true,
        shiftType: "DAY",
        activeFromDay: 1,
        activeToDay: 11,
      };

    case "SB_DIVISION":
      return {
        role: "SB_DIVISION",
        frequencyPerMandap: 1,
        minMandapsPerUnit: 20,
        scopeLevel: "DIVISION",
        requiresSensitiveMandap: true,
        shiftType: "DAY",
        activeFromDay: 1,
        activeToDay: 11,
      };

    case "SB_NIGHT_CITY":
    case "NIGHT_SB":
      return {
        role: "SB_NIGHT_CITY",
        frequencyPerMandap: 1,
        minMandapsPerUnit: 10,
        scopeLevel: "COMMISSIONERATE",
        requiresSensitiveMandap: true,
        shiftType: "NIGHT",
        activeFromDay: 1,
        activeToDay: 11,
      };

    default:
      return {
        role: normalized,
        frequencyPerMandap: 1,
        minMandapsPerUnit: 5,
        scopeLevel: "PS",
        requiresSensitiveMandap: false,
        shiftType: "DAY",
        activeFromDay: 1,
        activeToDay: 11,
      };
  }
}

/**
 * Retrieves the effective target rule for a given role (database override or default).
 */
export async function getTargetRuleForRole(role: string): Promise<OfficerTargetRule> {
  const normalized = role.trim().toUpperCase().replace(/\s+/g, "_");
  try {
    const dbRule = await prisma.dailyVisitTargetRule.findUnique({
      where: { role: normalized },
    });

    if (dbRule && dbRule.active) {
      return {
        role: dbRule.role,
        frequencyPerMandap: dbRule.frequencyPerMandap,
        minMandapsPerUnit: dbRule.minMandapsPerUnit,
        scopeLevel: dbRule.scopeLevel as OfficerTargetRule["scopeLevel"],
        requiresSensitiveMandap: dbRule.requiresSensitiveMandap,
        shiftType: dbRule.shiftType as "DAY" | "NIGHT",
        activeFromDay: dbRule.activeFromDay,
        activeToDay: dbRule.activeToDay,
      };
    }
  } catch {
    // Database table not created yet or unreachable, use canonical defaults
  }

  return getDefaultTargetRule(normalized);
}

/**
 * Resolves the operational list of mandaps assigned to or in scope of an officer.
 */
export async function getOfficerScopedMandaps(
  officer: {
    userId: string;
    role: string;
    policeStationName: string | null;
    divisionName: string | null;
    zoneName: string | null;
    sectorName: string | null;
    allPoliceStations: boolean;
    allZones: boolean;
  },
  date: string,
): Promise<{
  mandaps: GaneshRecord[];
  scopeType: "EXPLICIT_ASSIGNMENT" | "CLUSTER" | "SECTOR" | "PS" | "DIVISION" | "ZONE" | "ALL";
  clusterName?: string;
  sectorName?: string;
}> {
  const { records: allMasterRecords } = await loadGpidMaster();

  // 1. Check for active temporary festival duty assignment
  try {
    const assignment = await prisma.ganeshDutyAssignment.findFirst({
      where: {
        userId: officer.userId,
        status: "ACTIVE",
      },
    });

    if (assignment) {
      // If specific GPIDs assigned
      if (Array.isArray(assignment.assignedGpids) && assignment.assignedGpids.length > 0) {
        const assignedGpidSet = new Set(
          assignment.assignedGpids.map((g) => text(g).toUpperCase()),
        );
        const filtered = allMasterRecords.filter((rec) =>
          assignedGpidSet.has(text(rec.unique_id).toUpperCase()),
        );
        return {
          mandaps: filtered,
          scopeType: "EXPLICIT_ASSIGNMENT",
          clusterName: assignment.clusterName ?? undefined,
          sectorName: assignment.sectorName ?? undefined,
        };
      }

      // If cluster assigned
      if (assignment.clusterName && text(assignment.clusterName).length > 0) {
        const filtered = allMasterRecords.filter(
          (rec) =>
            sameAccessName(rec.ps_name, assignment.policeStationName) &&
            text(rec.cluster_name).toLowerCase() === assignment.clusterName?.toLowerCase(),
        );
        return {
          mandaps: filtered,
          scopeType: "CLUSTER",
          clusterName: assignment.clusterName,
          sectorName: assignment.sectorName ?? undefined,
        };
      }

      // If sector assigned
      if (assignment.sectorName && text(assignment.sectorName).length > 0) {
        const filtered = allMasterRecords.filter(
          (rec) =>
            sameAccessName(rec.ps_name, assignment.policeStationName) &&
            text(rec.sector_name).toLowerCase() === assignment.sectorName?.toLowerCase(),
        );
        return {
          mandaps: filtered,
          scopeType: "SECTOR",
          sectorName: assignment.sectorName,
        };
      }
    }
  } catch {
    // Database check failed, continue to fallback
  }

  // 2. Default territorial fallback based on officer's profile
  if (officer.sectorName && text(officer.sectorName).length > 0) {
    const filtered = allMasterRecords.filter(
      (rec) =>
        sameAccessName(rec.ps_name, officer.policeStationName) &&
        text(rec.sector_name).toLowerCase() === officer.sectorName?.toLowerCase(),
    );
    return {
      mandaps: filtered,
      scopeType: "SECTOR",
      sectorName: officer.sectorName,
    };
  }

  if (officer.policeStationName && text(officer.policeStationName).length > 0) {
    const filtered = allMasterRecords.filter((rec) =>
      sameAccessName(rec.ps_name, officer.policeStationName),
    );
    return {
      mandaps: filtered,
      scopeType: "PS",
    };
  }

  if (officer.divisionName && text(officer.divisionName).length > 0) {
    const filtered = allMasterRecords.filter((rec) =>
      sameAccessName(rec.division_name, officer.divisionName),
    );
    return {
      mandaps: filtered,
      scopeType: "DIVISION",
    };
  }

  if (officer.zoneName && text(officer.zoneName).length > 0) {
    const filtered = allMasterRecords.filter((rec) =>
      sameAccessName(rec.zone_name, officer.zoneName),
    );
    return {
      mandaps: filtered,
      scopeType: "ZONE",
    };
  }

  if (officer.allZones || officer.allPoliceStations) {
    return {
      mandaps: allMasterRecords,
      scopeType: "ALL",
    };
  }

  return {
    mandaps: [],
    scopeType: "PS",
  };
}

/**
 * Calculates the real-time target and achievement for an officer for a given day.
 */
export async function calculateOfficerDailyProgress(params: {
  userId: string;
  officerEmployeeId: string;
  officerName: string;
  officerRank: string;
  officerRole: string;
  policeStationName: string | null;
  divisionName: string | null;
  zoneName: string | null;
  sectorName: string | null;
  allPoliceStations?: boolean;
  allZones?: boolean;
  date: string; // YYYY-MM-DD
  festivalDay: number;
}): Promise<OfficerDailyProgress> {
  const {
    userId,
    officerEmployeeId,
    officerName,
    officerRank,
    officerRole,
    policeStationName,
    divisionName,
    zoneName,
    sectorName,
    allPoliceStations = false,
    allZones = false,
    date,
    festivalDay,
  } = params;

  // 1. Fetch effective target rule
  const rule = await getTargetRuleForRole(officerRole);

  // 2. Resolve scoped mandaps
  const scopedResult = await getOfficerScopedMandaps(
    {
      userId,
      role: officerRole,
      policeStationName,
      divisionName,
      zoneName,
      sectorName,
      allPoliceStations,
      allZones,
    },
    date,
  );

  const mandaps = scopedResult.mandaps;

  // 3. Query actual visits logged by this officer on this day
  let visits: Array<{ gpid: string; checkedAt: Date; hasDeficiency: boolean }> = [];
  try {
    visits = await prisma.mandapDailyVisit.findMany({
      where: {
        userId,
        date,
      },
      orderBy: { checkedAt: "asc" },
      select: {
        gpid: true,
        checkedAt: true,
        hasDeficiency: true,
      },
    });
  } catch {
    // Table not created yet or DB unreachable
  }

  // Also query legacy FestivityCheckVisit for backwards-compatibility fallback
  let legacyVisits: Array<{ gpid: string; checkedAt: Date; hasDeficiency: boolean }> = [];
  try {
    legacyVisits = await prisma.festivityCheckVisit.findMany({
      where: {
        userId,
        festivalDay,
      },
      select: {
        gpid: true,
        checkedAt: true,
        hasDeficiency: true,
      },
    });
  } catch {
    // Table not created yet or DB unreachable
  }

  // Build map of visits per GPID
  const gpidVisitCounts = new Map<string, number>();
  const gpidLastVisited = new Map<string, Date>();
  const gpidDeficiency = new Map<string, boolean>();

  // Count visits from MandapDailyVisit
  for (const v of visits) {
    const key = v.gpid.toUpperCase();
    gpidVisitCounts.set(key, (gpidVisitCounts.get(key) ?? 0) + 1);
    gpidLastVisited.set(key, v.checkedAt);
    if (v.hasDeficiency) gpidDeficiency.set(key, true);
  }

  // Fill in legacy visits if not already counted
  for (const lv of legacyVisits) {
    const key = lv.gpid.toUpperCase();
    if (!gpidVisitCounts.has(key)) {
      gpidVisitCounts.set(key, 1);
      gpidLastVisited.set(key, lv.checkedAt);
      if (lv.hasDeficiency) gpidDeficiency.set(key, true);
    }
  }

  // 4. Compute targets
  let targetMandapCount = 0;
  let targetTotalVisits = 0;
  let sensitiveTargetCount = 0;

  if (rule.scopeLevel === "CLUSTER") {
    targetMandapCount = mandaps.length;
    targetTotalVisits = mandaps.length * rule.frequencyPerMandap;
  } else if (rule.scopeLevel === "SECTOR") {
    targetMandapCount = mandaps.length;
    targetTotalVisits = mandaps.length * rule.frequencyPerMandap;
  } else if (rule.minMandapsPerUnit > 0) {
    targetMandapCount = Math.min(mandaps.length, rule.minMandapsPerUnit);
    targetTotalVisits = targetMandapCount * rule.frequencyPerMandap;
  } else {
    targetMandapCount = mandaps.length;
    targetTotalVisits = mandaps.length * rule.frequencyPerMandap;
  }

  const sensitiveMandapsInScope = mandaps.filter((m) => {
    const sens = text(m.sensitivity).toUpperCase();
    return sens === "SENSITIVE" || sens === "HYPERSENSITIVE";
  });

  if (rule.requiresSensitiveMandap) {
    sensitiveTargetCount = Math.min(sensitiveMandapsInScope.length, 1);
  }

  // 5. Partition mandaps into Pending and Completed
  const pendingMandaps: MandapDailyStatus[] = [];
  const completedMandaps: MandapDailyStatus[] = [];

  let completedUniqueMandaps = 0;
  let completedTotalVisits = 0;
  let sensitiveCompletedCount = 0;
  let deficienciesReported = 0;
  let mostRecentVisit: Date | null = null;

  for (const m of mandaps) {
    const gpidKey = text(m.unique_id).toUpperCase();
    const visitsToday = gpidVisitCounts.get(gpidKey) ?? 0;
    const requiredForMandap = rule.frequencyPerMandap;
    const isFullyVisited = visitsToday >= requiredForMandap;
    const lastVisitDate = gpidLastVisited.get(gpidKey) ?? null;
    const hasDef = gpidDeficiency.get(gpidKey) ?? false;
    const isSensitive =
      text(m.sensitivity).toUpperCase() === "SENSITIVE" ||
      text(m.sensitivity).toUpperCase() === "HYPERSENSITIVE";

    if (visitsToday > 0) {
      completedUniqueMandaps++;
      completedTotalVisits += visitsToday;
      if (isSensitive) sensitiveCompletedCount++;
      if (hasDef) deficienciesReported++;

      if (lastVisitDate && (!mostRecentVisit || lastVisitDate > mostRecentVisit)) {
        mostRecentVisit = lastVisitDate;
      }
    }

    const item: MandapDailyStatus = {
      gpid: gpidKey,
      pandalName: text(m.pandal_name) || text(m.name) || "Ganesh Mandap",
      policeStationName: text(m.ps_name),
      sectorName: text(m.sector_name) || "Sector 1",
      clusterName: text(m.cluster_name) || "Cluster 1",
      sensitivity: text(m.sensitivity) || "NORMAL",
      requiredVisitsToday: requiredForMandap,
      actualVisitsToday: visitsToday,
      isFullyVisited,
      lastVisitedAt: lastVisitDate,
      lastVisitedByOfficer: visitsToday > 0 ? officerName : null,
      hasDeficiency: hasDef,
    };

    if (isFullyVisited) {
      completedMandaps.push(item);
    } else {
      pendingMandaps.push(item);
    }
  }

  // 6. Calculate compliance percentage & status
  let compliancePercentage = 0.0;
  if (targetTotalVisits > 0) {
    compliancePercentage = Math.min(
      100.0,
      Math.round((completedTotalVisits / targetTotalVisits) * 1000) / 10,
    );
  } else {
    compliancePercentage = 100.0;
  }

  let status: OfficerDailyProgress["status"] = "NOT_STARTED";
  if (completedTotalVisits === 0) {
    status = "NOT_STARTED";
  } else if (
    completedTotalVisits >= targetTotalVisits &&
    (!rule.requiresSensitiveMandap || sensitiveCompletedCount >= sensitiveTargetCount)
  ) {
    status = "COMPLETED";
  } else if (compliancePercentage >= 50.0) {
    status = "ON_TRACK";
  } else {
    status = "DEFICIT";
  }

  const result: OfficerDailyProgress = {
    officerId: userId,
    officerEmployeeId,
    officerName,
    officerRank,
    officerRole,
    policeStationName: policeStationName ?? "Unassigned",
    sectorName,
    clusterName: scopedResult.clusterName ?? null,
    date,
    festivalDay,
    targetMandapCount,
    targetTotalVisits,
    completedUniqueMandaps,
    completedTotalVisits,
    sensitiveTargetCount,
    sensitiveCompletedCount,
    deficienciesReported,
    compliancePercentage,
    status,
    lastVisitedAt: mostRecentVisit,
    pendingMandaps,
    completedMandaps,
  };

  // 7. Update DailyOfficerTargetSummary cache asynchronously
  updateDailyOfficerTargetSummaryCache(result).catch((err) => {
    console.warn("Failed to update DailyOfficerTargetSummary cache:", err);
  });

  return result;
}

/**
 * Upserts a precomputed daily target summary for fast supervisory dashboard queries.
 */
export async function updateDailyOfficerTargetSummaryCache(
  progress: OfficerDailyProgress,
): Promise<void> {
  try {
    await prisma.dailyOfficerTargetSummary.upsert({
      where: {
        date_userId: {
          date: progress.date,
          userId: progress.officerId,
        },
      },
      update: {
        festivalDay: progress.festivalDay,
        officerEmployeeId: progress.officerEmployeeId,
        officerName: progress.officerName,
        officerRank: progress.officerRank,
        officerRole: progress.officerRole,
        policeStationName: progress.policeStationName,
        sectorName: progress.sectorName,
        clusterName: progress.clusterName,
        targetMandapCount: progress.targetMandapCount,
        targetTotalVisits: progress.targetTotalVisits,
        completedUniqueMandaps: progress.completedUniqueMandaps,
        completedTotalVisits: progress.completedTotalVisits,
        sensitiveTargetCount: progress.sensitiveTargetCount,
        sensitiveCompletedCount: progress.sensitiveCompletedCount,
        deficienciesReported: progress.deficienciesReported,
        compliancePercentage: progress.compliancePercentage,
        status: progress.status,
        lastVisitedAt: progress.lastVisitedAt,
        calculatedAt: new Date(),
      },
      create: {
        date: progress.date,
        festivalDay: progress.festivalDay,
        userId: progress.officerId,
        officerEmployeeId: progress.officerEmployeeId,
        officerName: progress.officerName,
        officerRank: progress.officerRank,
        officerRole: progress.officerRole,
        rangeName: "South Range", // Will be inferred from station
        zoneName: "Charminar",
        divisionName: "Charminar",
        policeStationName: progress.policeStationName,
        sectorName: progress.sectorName,
        clusterName: progress.clusterName,
        targetMandapCount: progress.targetMandapCount,
        targetTotalVisits: progress.targetTotalVisits,
        completedUniqueMandaps: progress.completedUniqueMandaps,
        completedTotalVisits: progress.completedTotalVisits,
        sensitiveTargetCount: progress.sensitiveTargetCount,
        sensitiveCompletedCount: progress.sensitiveCompletedCount,
        deficienciesReported: progress.deficienciesReported,
        compliancePercentage: progress.compliancePercentage,
        status: progress.status,
        lastVisitedAt: progress.lastVisitedAt,
        calculatedAt: new Date(),
      },
    });
  } catch {
    // Graceful fallback if summary table is not yet migrated in database
  }
}

/**
 * Records a new physical visit event into MandapDailyVisit.
 */
export async function recordMandapDailyVisit(input: CreateDailyVisitInput) {
  // Determine visitSequenceForDay
  const priorVisitsCount = await prisma.mandapDailyVisit.count({
    where: {
      gpid: input.gpid,
      date: input.date,
    },
  });

  const visit = await prisma.mandapDailyVisit.create({
    data: {
      userId: input.userId,
      officerEmployeeId: input.officerEmployeeId,
      officerName: input.officerName,
      officerRank: input.officerRank,
      officerRole: input.officerRole,
      gpid: input.gpid,
      pandalName: input.pandalName,
      commissionerateName: input.commissionerateName ?? "Hyderabad",
      rangeName: input.rangeName ?? "South Range",
      zoneName: input.zoneName ?? "Charminar",
      divisionName: input.divisionName ?? "Charminar",
      policeStationName: input.policeStationName ?? "Charminar",
      sectorName: input.sectorName,
      clusterName: input.clusterName,
      sensitivity: input.sensitivity ?? "NORMAL",
      date: input.date,
      festivalDay: input.festivalDay,
      visitSequenceForDay: priorVisitsCount + 1,
      latitude: input.latitude,
      longitude: input.longitude,
      accuracy: input.accuracy,
      distanceFromMandapMeters: input.distanceFromMandapMeters,
      isWithinGeofence: input.isWithinGeofence ?? true,
      visitType: input.visitType ?? "ROUTINE",
      stage: input.stage ?? "STAGE_3_FESTIVITY",
      remarks: input.remarks,
      actionTaken: input.actionTaken,
      evidenceUrls: input.evidenceUrls as never,
      hasDeficiency: input.hasDeficiency ?? false,
      deficiencyCategories: input.deficiencyCategories as never,
      requiresFollowUp: input.requiresFollowUp ?? false,
      completionStatus: "COMPLETED",
      verificationSource: input.verificationSource ?? "QR_SCAN",
    },
  });

  return visit;
}
