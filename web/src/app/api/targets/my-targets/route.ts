import { NextRequest, NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import {
  verifySessionToken,
  SESSION_COOKIE_NAME,
} from "@/lib/server/auth";
import {
  loadGpidMaster,
  findGpidRecord,
  isRecordPermittedForUser,
  text,
} from "@/lib/server/gpidMaster";
import {
  calculateOfficerDailyProgress,
  recordMandapDailyVisit,
  getTargetRuleForRole,
  MandapDailyStatus,
} from "@/lib/server/visitTargetEngine";

export const dynamic = "force-dynamic";
export const runtime = "nodejs";

const INDIA_TIME_ZONE = "Asia/Kolkata";

/**
 * Returns today's date formatted as YYYY-MM-DD in India Standard Time (IST).
 */
function getIndiaTodayDateString(): string {
  const parts = new Intl.DateTimeFormat("en-CA", {
    timeZone: INDIA_TIME_ZONE,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).formatToParts(new Date());

  const year = parts.find((p) => p.type === "year")?.value ?? "2026";
  const month = parts.find((p) => p.type === "month")?.value ?? "09";
  const day = parts.find((p) => p.type === "day")?.value ?? "18";

  return `${year}-${month}-${day}`;
}

/**
 * Derives festival day (1 to 11) for Ganesh Bandobust 2026.
 * Day 1 = 2026-09-14, Day 11 = 2026-09-24.
 */
function getFestivalDayForDate(dateStr: string): number {
  const [yearStr, monthStr, dayStr] = dateStr.split("-");
  const y = parseInt(yearStr, 10);
  const m = parseInt(monthStr, 10);
  const d = parseInt(dayStr, 10);

  if (isNaN(y) || isNaN(m) || isNaN(d)) {
    return 1;
  }

  // Day 1 starts at 2026-09-14
  const startUtc = Date.UTC(2026, 8, 14); // month is 0-indexed: 8 = September
  const targetUtc = Date.UTC(y, m - 1, d);
  const diffDays = Math.round((targetUtc - startUtc) / (1000 * 60 * 60 * 24)) + 1;

  if (diffDays < 1) return 1;
  if (diffDays > 11) return 11;
  return diffDays;
}

/**
 * Extracts session token from cookies or Authorization header.
 */
function extractSessionToken(request: NextRequest): string | undefined {
  const cookieToken = request.cookies.get(SESSION_COOKIE_NAME)?.value;
  if (cookieToken && cookieToken.trim().length > 0) {
    return cookieToken.trim();
  }

  const authHeader = request.headers.get("authorization");
  if (authHeader && authHeader.startsWith("Bearer ")) {
    return authHeader.slice(7).trim();
  }

  const xSessionToken = request.headers.get("x-session-token");
  if (xSessionToken && xSessionToken.trim().length > 0) {
    return xSessionToken.trim();
  }

  // Fallback to manual Cookie header parsing
  const rawCookie = request.headers.get("cookie");
  if (rawCookie) {
    const match = rawCookie.match(new RegExp(`${SESSION_COOKIE_NAME}=([^;]+)`));
    if (match && match[1]) {
      return decodeURIComponent(match[1].trim());
    }
  }

  return undefined;
}

/**
 * Standardized no-cache headers.
 */
function responseHeaders() {
  return {
    "Cache-Control": "no-store, no-cache, must-revalidate",
    Pragma: "no-cache",
  };
}

/**
 * GET /api/targets/my-targets
 *
 * Retrieves the daily visiting targets, compliance progress,
 * pending mandaps, and completed mandaps for the authenticated officer.
 */
export async function GET(request: NextRequest) {
  try {
    // 1. Authenticate officer session
    const sessionToken = extractSessionToken(request);

    if (!sessionToken) {
      return NextResponse.json(
        {
          success: false,
          error: "Authentication required.",
        },
        {
          status: 401,
          headers: responseHeaders(),
        },
      );
    }

    const session = verifySessionToken(sessionToken);

    if (!session) {
      return NextResponse.json(
        {
          success: false,
          error: "Invalid or expired session.",
        },
        {
          status: 401,
          headers: responseHeaders(),
        },
      );
    }

    // 2. Fetch authenticated officer profile & jurisdiction
    const user = await prisma.user.findUnique({
      where: {
        id: session.userId,
      },
      include: {
        policeStationAccesses: {
          where: {
            canView: true,
          },
          select: {
            policeStationName: true,
            canView: true,
            canEdit: true,
          },
        },
      },
    });

    if (!user) {
      return NextResponse.json(
        {
          success: false,
          error: "User account not found.",
        },
        {
          status: 401,
          headers: responseHeaders(),
        },
      );
    }

    if (user.status !== "ACTIVE") {
      return NextResponse.json(
        {
          success: false,
          error: "This user account is inactive. Please contact your administrator.",
        },
        {
          status: 403,
          headers: responseHeaders(),
        },
      );
    }

    // 3. Parse query parameters
    const { searchParams } = request.nextUrl;
    const rawDate = searchParams.get("date")?.trim();
    const targetDate =
      rawDate && /^\d{4}-\d{2}-\d{2}$/.test(rawDate)
        ? rawDate
        : getIndiaTodayDateString();

    const rawDay = searchParams.get("festivalDay")?.trim();
    const parsedDay = rawDay ? parseInt(rawDay, 10) : NaN;
    const targetFestivalDay =
      !isNaN(parsedDay) && parsedDay >= 1 && parsedDay <= 11
        ? parsedDay
        : getFestivalDayForDate(targetDate);

    const filter = (searchParams.get("filter") || "all").toLowerCase(); // "all" | "pending" | "completed"
    const search = (searchParams.get("search") || "").trim().toLowerCase();

    // 4. Calculate officer daily progress and targets
    const progress = await calculateOfficerDailyProgress({
      userId: user.id,
      officerEmployeeId: user.employeeId,
      officerName: user.name,
      officerRank: user.rank,
      officerRole: user.role,
      policeStationName: user.policeStationName,
      divisionName: user.divisionName,
      zoneName: user.zoneName,
      sectorName: user.sectorName,
      allPoliceStations: user.allPoliceStations,
      allZones: user.allZones,
      date: targetDate,
      festivalDay: targetFestivalDay,
    });

    // 5. Fetch effective target rule configuration
    const targetRule = await getTargetRuleForRole(user.role);

    // 6. Query recent physical visits logged today by this officer
    let recentVisits: Array<{
      id: string;
      gpid: string;
      pandalName: string | null;
      visitSequenceForDay: number;
      visitType: string;
      checkedAt: Date;
      isWithinGeofence: boolean;
      hasDeficiency: boolean;
      remarks: string | null;
    }> = [];

    try {
      recentVisits = await prisma.mandapDailyVisit.findMany({
        where: {
          userId: user.id,
          date: targetDate,
        },
        orderBy: { checkedAt: "desc" },
        take: 10,
        select: {
          id: true,
          gpid: true,
          pandalName: true,
          visitSequenceForDay: true,
          visitType: true,
          checkedAt: true,
          isWithinGeofence: true,
          hasDeficiency: true,
          remarks: true,
        },
      });
    } catch {
      // Table may not be migrated yet on local or staging DB; graceful fallback
    }

    // 7. Apply search and filtering to pending and completed mandaps
    const filterFn = (item: MandapDailyStatus) => {
      if (!search) return true;
      return (
        item.gpid.toLowerCase().includes(search) ||
        item.pandalName.toLowerCase().includes(search) ||
        item.sectorName.toLowerCase().includes(search) ||
        item.clusterName.toLowerCase().includes(search) ||
        item.policeStationName.toLowerCase().includes(search)
      );
    };

    const filteredPending =
      filter === "completed" ? [] : progress.pendingMandaps.filter(filterFn);
    const filteredCompleted =
      filter === "pending" ? [] : progress.completedMandaps.filter(filterFn);

    return NextResponse.json(
      {
        success: true,
        date: targetDate,
        festivalDay: targetFestivalDay,
        officer: {
          id: user.id,
          employeeId: user.employeeId,
          name: user.name,
          rank: user.rank,
          role: user.role,
          policeStationName: user.policeStationName,
          divisionName: user.divisionName,
          zoneName: user.zoneName,
          rangeName: user.rangeName,
          sectorName: user.sectorName,
          clusterName: progress.clusterName,
        },
        rule: {
          role: targetRule.role,
          frequencyPerMandap: targetRule.frequencyPerMandap,
          minMandapsPerUnit: targetRule.minMandapsPerUnit,
          scopeLevel: targetRule.scopeLevel,
          requiresSensitiveMandap: targetRule.requiresSensitiveMandap,
          shiftType: targetRule.shiftType,
        },
        summary: {
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
        },
        counts: {
          totalScopedMandaps:
            progress.pendingMandaps.length + progress.completedMandaps.length,
          pendingCount: progress.pendingMandaps.length,
          completedCount: progress.completedMandaps.length,
          recentVisitsCount: recentVisits.length,
        },
        pendingMandaps: filteredPending,
        completedMandaps: filteredCompleted,
        recentVisits,
      },
      {
        status: 200,
        headers: responseHeaders(),
      },
    );
  } catch (error) {
    console.error("Targets API GET error:", error);
    return NextResponse.json(
      {
        success: false,
        error: "An internal server error occurred while retrieving visiting targets.",
      },
      {
        status: 500,
        headers: responseHeaders(),
      },
    );
  }
}

/**
 * POST /api/targets/my-targets
 *
 * Records a new physical mandap visit event from mobile or web,
 * updates the officer's daily target summary, and returns the updated progress.
 */
export async function POST(request: NextRequest) {
  try {
    // 1. Authenticate officer session
    const sessionToken = extractSessionToken(request);

    if (!sessionToken) {
      return NextResponse.json(
        {
          success: false,
          error: "Authentication required.",
        },
        {
          status: 401,
          headers: responseHeaders(),
        },
      );
    }

    const session = verifySessionToken(sessionToken);

    if (!session) {
      return NextResponse.json(
        {
          success: false,
          error: "Invalid or expired session.",
        },
        {
          status: 401,
          headers: responseHeaders(),
        },
      );
    }

    // 2. Fetch authenticated officer profile
    const user = await prisma.user.findUnique({
      where: {
        id: session.userId,
      },
      include: {
        policeStationAccesses: {
          where: {
            canView: true,
          },
          select: {
            policeStationName: true,
            canView: true,
            canEdit: true,
          },
        },
      },
    });

    if (!user) {
      return NextResponse.json(
        {
          success: false,
          error: "User account not found.",
        },
        {
          status: 401,
          headers: responseHeaders(),
        },
      );
    }

    if (user.status !== "ACTIVE") {
      return NextResponse.json(
        {
          success: false,
          error: "This user account is inactive. Please contact your administrator.",
        },
        {
          status: 403,
          headers: responseHeaders(),
        },
      );
    }

    // 3. Parse and validate JSON request body
    let body: Record<string, unknown>;
    try {
      body = await request.json();
    } catch {
      return NextResponse.json(
        {
          success: false,
          error: "Invalid JSON payload.",
        },
        {
          status: 400,
          headers: responseHeaders(),
        },
      );
    }

    const gpid = typeof body.gpid === "string" ? body.gpid.trim() : "";
    if (!gpid) {
      return NextResponse.json(
        {
          success: false,
          error: "The 'gpid' field is required.",
        },
        {
          status: 400,
          headers: responseHeaders(),
        },
      );
    }

    const latitude = typeof body.latitude === "number" ? body.latitude : NaN;
    const longitude = typeof body.longitude === "number" ? body.longitude : NaN;

    if (isNaN(latitude) || isNaN(longitude)) {
      return NextResponse.json(
        {
          success: false,
          error: "Valid GPS 'latitude' and 'longitude' coordinates are required.",
        },
        {
          status: 400,
          headers: responseHeaders(),
        },
      );
    }

    // 4. Validate GPID against master dataset & check jurisdictional permission
    const { records } = await loadGpidMaster();
    const matchedRecord = findGpidRecord(records, gpid);

    if (!matchedRecord) {
      return NextResponse.json(
        {
          success: false,
          error: `GPID '${gpid}' not found in master records.`,
        },
        {
          status: 404,
          headers: responseHeaders(),
        },
      );
    }

    // Enforce jurisdictional permission
    const isPermitted = isRecordPermittedForUser(matchedRecord, user);
    if (!isPermitted) {
      return NextResponse.json(
        {
          success: false,
          error: `Access Denied: GPID '${gpid}' in '${text(matchedRecord.ps_name)}' PS is outside your authorized jurisdiction.`,
        },
        {
          status: 403,
          headers: responseHeaders(),
        },
      );
    }

    // 5. Determine operational dates & parameters
    const targetDate =
      typeof body.date === "string" && /^\d{4}-\d{2}-\d{2}$/.test(body.date)
        ? body.date
        : getIndiaTodayDateString();

    const targetFestivalDay =
      typeof body.festivalDay === "number" &&
      body.festivalDay >= 1 &&
      body.festivalDay <= 11
        ? body.festivalDay
        : getFestivalDayForDate(targetDate);

    // 6. Record visit event
    const pandalName =
      (typeof body.pandalName === "string" && body.pandalName.trim()) ||
      text(matchedRecord.name) ||
      text(matchedRecord.association) ||
      "Ganesh Mandap";

    const accuracy = typeof body.accuracy === "number" ? body.accuracy : undefined;
    const distanceFromMandapMeters =
      typeof body.distanceFromMandapMeters === "number"
        ? body.distanceFromMandapMeters
        : undefined;

    const isWithinGeofence =
      typeof body.isWithinGeofence === "boolean"
        ? body.isWithinGeofence
        : distanceFromMandapMeters !== undefined
        ? distanceFromMandapMeters <= 100 // 100m geofence default
        : true;

    const visitType =
      typeof body.visitType === "string" ? body.visitType : "ROUTINE";
    const stage =
      typeof body.stage === "string" ? body.stage : "STAGE_3_FESTIVITY";
    const remarks =
      typeof body.remarks === "string" ? body.remarks.trim() : undefined;
    const actionTaken =
      typeof body.actionTaken === "string" ? body.actionTaken.trim() : undefined;

    const evidenceUrls = Array.isArray(body.evidenceUrls)
      ? body.evidenceUrls.filter((url): url is string => typeof url === "string")
      : undefined;

    const hasDeficiency =
      typeof body.hasDeficiency === "boolean" ? body.hasDeficiency : false;

    const deficiencyCategories = Array.isArray(body.deficiencyCategories)
      ? body.deficiencyCategories.filter((c): c is string => typeof c === "string")
      : undefined;

    const requiresFollowUp =
      typeof body.requiresFollowUp === "boolean" ? body.requiresFollowUp : false;

    const verificationSource =
      typeof body.verificationSource === "string"
        ? body.verificationSource
        : "QR_SCAN";

    const newVisit = await recordMandapDailyVisit({
      userId: user.id,
      officerEmployeeId: user.employeeId,
      officerName: user.name,
      officerRank: user.rank,
      officerRole: user.role,
      gpid: text(matchedRecord.unique_id) || gpid,
      pandalName,
      commissionerateName: text(matchedRecord.dist_name) || "Hyderabad",
      rangeName: text(matchedRecord.range_name) || "South Range",
      zoneName: text(matchedRecord.zone_name) || user.zoneName || "Charminar",
      divisionName:
        text(matchedRecord.division_name) || user.divisionName || "Charminar",
      policeStationName:
        text(matchedRecord.ps_name) || user.policeStationName || "Charminar",
      sectorName: text(matchedRecord.sector_name) || user.sectorName || undefined,
      clusterName: text(matchedRecord.cluster_name) || undefined,
      sensitivity: text(matchedRecord.sensitivity) || "NORMAL",
      date: targetDate,
      festivalDay: targetFestivalDay,
      latitude,
      longitude,
      accuracy,
      distanceFromMandapMeters,
      isWithinGeofence,
      visitType,
      stage,
      remarks,
      actionTaken,
      evidenceUrls,
      hasDeficiency,
      deficiencyCategories,
      requiresFollowUp,
      verificationSource,
    });

    // 7. Recalculate officer progress after logging the visit
    const updatedProgress = await calculateOfficerDailyProgress({
      userId: user.id,
      officerEmployeeId: user.employeeId,
      officerName: user.name,
      officerRank: user.rank,
      officerRole: user.role,
      policeStationName: user.policeStationName,
      divisionName: user.divisionName,
      zoneName: user.zoneName,
      sectorName: user.sectorName,
      allPoliceStations: user.allPoliceStations,
      allZones: user.allZones,
      date: targetDate,
      festivalDay: targetFestivalDay,
    });

    return NextResponse.json(
      {
        success: true,
        message: "Mandap visit recorded successfully.",
        visit: {
          id: newVisit.id,
          gpid: newVisit.gpid,
          pandalName: newVisit.pandalName,
          visitSequenceForDay: newVisit.visitSequenceForDay,
          visitType: newVisit.visitType,
          checkedAt: newVisit.checkedAt,
          isWithinGeofence: newVisit.isWithinGeofence,
          hasDeficiency: newVisit.hasDeficiency,
          requiresFollowUp: newVisit.requiresFollowUp,
        },
        summary: {
          targetMandapCount: updatedProgress.targetMandapCount,
          targetTotalVisits: updatedProgress.targetTotalVisits,
          completedUniqueMandaps: updatedProgress.completedUniqueMandaps,
          completedTotalVisits: updatedProgress.completedTotalVisits,
          compliancePercentage: updatedProgress.compliancePercentage,
          status: updatedProgress.status,
        },
      },
      {
        status: 201,
        headers: responseHeaders(),
      },
    );
  } catch (error) {
    console.error("Targets API POST error:", error);
    return NextResponse.json(
      {
        success: false,
        error: "An internal server error occurred while recording mandap visit.",
      },
      {
        status: 500,
        headers: responseHeaders(),
      },
    );
  }
}
