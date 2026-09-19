import { NextRequest } from "next/server";

import { prisma } from "@/lib/prisma";
import { getWebSession } from "@/lib/server/auth";
import {
  getRoleScopeConfig,
  resolveCompleteParentHierarchy,
} from "@/lib/server/userManagementHelper";
import { GANESH_HIERARCHY } from "@/lib/hierarchy/ganeshHierarchy";

type JsonObject = Record<string, unknown>;

function text(value: unknown): string {
  if (value === null || value === undefined) {
    return "";
  }
  return String(value).trim();
}

function nullableText(value: unknown): string | null {
  const result = text(value);
  return result.length > 0 ? result : null;
}

function isObject(value: unknown): value is JsonObject {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function responseHeaders(): HeadersInit {
  return {
    "Cache-Control": "no-store, no-cache, must-revalidate",
    Pragma: "no-cache",
  };
}

const ALLOWED_ROLES = [
  "FIELD_OFFICER",
  "SECTOR_INCHARGE",
  "PS_SUPERVISOR",
  "SHO",
  "DIVISIONAL_SUPERVISOR",
  "ZONAL_SUPERVISOR",
  "RANGE_SUPERVISOR",
  "ADMIN",
];

// GET: Fetch users roster by jurisdiction filter or All Users search
export async function GET(request: NextRequest) {
  try {
    const session = getWebSession(request);

    if (!session) {
      return Response.json(
        { error: "Authentication required. Please log in." },
        { status: 401, headers: responseHeaders() },
      );
    }

    if (session.role.toUpperCase() !== "ADMIN" || session.accessLevel < 7) {
      return Response.json(
        { error: "Access denied. Admin authorization required." },
        { status: 403, headers: responseHeaders() },
      );
    }

    const { searchParams } = new URL(request.url);
    const rawSource = searchParams.get("source") || "station";
    const sourceMode = rawSource.toUpperCase() === "ALL" ? "all" : "station";
    const policeStationName = searchParams.get("policeStationName");
    const role = searchParams.get("role");
    const search = searchParams.get("search");
    const page = Math.max(1, parseInt(searchParams.get("page") || "1", 10));
    const pageSize = Math.min(100, Math.max(10, parseInt(searchParams.get("pageSize") || "50", 10)));

    // Always fetch total application users count for unambiguous directory reporting
    const totalApplicationUsers = await prisma.user.count();

    const whereClause: Record<string, unknown> = {};

    if (sourceMode === "all") {
      const queryStr = search ? search.trim() : "";
      if (!queryStr) {
        // All Users mode requires an explicit search term; do not return broad directory dump
        return Response.json(
          {
            success: true,
            users: [],
            total: 0,
            page: 1,
            totalPages: 0,
            pageSize,
            totalApplicationUsers,
          },
          { headers: responseHeaders() },
        );
      }

      whereClause.OR = [
        { name: { contains: queryStr, mode: "insensitive" } },
        { employeeId: { contains: queryStr, mode: "insensitive" } },
      ];
    } else {
      // SELECTED POLICE STATION MODE
      const psName = policeStationName ? policeStationName.trim() : "";
      if (!psName) {
        // Return empty roster until a specific Police Station is selected
        return Response.json(
          {
            success: true,
            users: [],
            total: 0,
            page: 1,
            totalPages: 0,
            pageSize,
            totalApplicationUsers,
          },
          { headers: responseHeaders() },
        );
      }

      // Safe canonical exact PS matching (e.g. Abids vs Abids PS)
      const rawPs = psName.replace(/\s+PS$/i, "").trim();
      const psVariations = Array.from(new Set([psName, `${rawPs} PS`, rawPs]));
      whereClause.OR = psVariations.map((p) => ({
        policeStationName: { equals: p, mode: "insensitive" },
      }));
    }

    if (role) {
      whereClause.role = role.trim().toUpperCase();
    }

    const totalMatching = await prisma.user.count({ where: whereClause });
    const totalPages = Math.ceil(totalMatching / pageSize);

    const users = await prisma.user.findMany({
      where: whereClause,
      take: sourceMode === "all" ? pageSize : undefined,
      skip: sourceMode === "all" ? (page - 1) * pageSize : undefined,
      select: {
        id: true,
        employeeId: true,
        username: true,
        name: true,
        rank: true,
        phoneNumber: true,
        team: true,
        role: true,
        accessLevel: true,
        commissionerateName: true,
        rangeName: true,
        zoneName: true,
        divisionName: true,
        policeStationName: true,
        sectorName: true,
        allRanges: true,
        allZones: true,
        allDivisions: true,
        allPoliceStations: true,
        status: true,
        createdAt: true,
        updatedAt: true,
      },
      orderBy: [{ policeStationName: "asc" }, { name: "asc" }],
    });

    return Response.json(
      {
        success: true,
        users,
        total: totalMatching,
        page,
        totalPages,
        pageSize,
        totalApplicationUsers,
      },
      { headers: responseHeaders() },
    );
  } catch (error) {
    const errorMsg = error instanceof Error ? error.message : "Internal server error";
    return Response.json({ error: errorMsg }, { status: 500, headers: responseHeaders() });
  }
}

// POST: Execute atomic single or bulk role allotment using explicit targetUserIds array
export async function POST(request: NextRequest) {
  try {
    const session = getWebSession(request);

    if (!session) {
      return Response.json(
        { error: "Authentication required. Please log in again." },
        { status: 401, headers: responseHeaders() },
      );
    }

    if (session.role.toUpperCase() !== "ADMIN" || session.accessLevel < 7) {
      return Response.json(
        { error: "Access denied. Admin authorization required." },
        { status: 403, headers: responseHeaders() },
      );
    }

    const adminUser = await prisma.user.findUnique({
      where: { id: session.userId },
      select: { id: true, employeeId: true, name: true, role: true },
    });

    if (!adminUser || adminUser.role.toUpperCase() !== "ADMIN") {
      return Response.json(
        { error: "Access denied. Valid administrator profile required." },
        { status: 403, headers: responseHeaders() },
      );
    }

    let body: JsonObject = {};
    try {
      const parsed = await request.json();
      if (isObject(parsed)) {
        body = parsed;
      }
    } catch {
      return Response.json(
        { error: "Invalid JSON payload." },
        { status: 400, headers: responseHeaders() },
      );
    }

    // Explicit target IDs parsing & validation
    let rawIds: string[] = [];
    if (Array.isArray(body.targetUserIds)) {
      rawIds = body.targetUserIds.map((id) => text(id)).filter((id) => id.length > 0);
    } else if (body.targetUserId || body.userId) {
      const singleId = text(body.targetUserId || body.userId);
      if (singleId) rawIds.push(singleId);
    }

    if (rawIds.length === 0) {
      return Response.json(
        { error: "REJECTED: Explicit targetUserIds array is required. Bulk predicate updates are forbidden." },
        { status: 400, headers: responseHeaders() },
      );
    }

    // Deduplicate target IDs
    const uniqueTargetIds = Array.from(new Set(rawIds));

    // Exclude acting Admin ID (session.userId and employeeId 1837323 protection)
    const filteredTargetIds = uniqueTargetIds.filter((id) => id !== adminUser.id);
    if (filteredTargetIds.length === 0) {
      return Response.json(
        { error: "REJECTED: The active administrator account cannot be targeted in bulk operations." },
        { status: 400, headers: responseHeaders() },
      );
    }

    const requestedRole = text(body.role).toUpperCase();
    if (!requestedRole || !ALLOWED_ROLES.includes(requestedRole)) {
      return Response.json(
        { error: `Invalid role requested. Allowed roles: ${ALLOWED_ROLES.join(", ")}` },
        { status: 400, headers: responseHeaders() },
      );
    }

    // Fetch exact target user records
    const targetUsers = await prisma.user.findMany({
      where: { id: { in: filteredTargetIds } },
    });

    if (targetUsers.length !== filteredTargetIds.length) {
      return Response.json(
        { error: "REJECTED: One or more target officer records were not found." },
        { status: 404, headers: responseHeaders() },
      );
    }

    // Ensure acting admin is not in target list by employeeId 1837323 as additional safety
    const protectedUser = targetUsers.find(u => u.employeeId === "1837323" || u.id === adminUser.id);
    if (protectedUser) {
      return Response.json(
        { error: `REJECTED: Controlling Admin account (${protectedUser.employeeId}) cannot be altered via bulk allotment.` },
        { status: 400, headers: responseHeaders() },
      );
    }

    // 1. Resolve role scope configuration from ROLE_SCOPE_MAP
    const roleConfig = getRoleScopeConfig(requestedRole);

    // 2. Server-side Parent Hierarchy Derivation
    let inputPoliceStation = nullableText(body.policeStationName);
    let inputDivision = nullableText(body.divisionName);
    let inputZone = nullableText(body.zoneName);
    let inputRange = nullableText(body.rangeName);
    const inputSector = nullableText(body.sectorName);

    if (requestedRole === "ADMIN") {
      inputPoliceStation = null;
      inputDivision = null;
      inputZone = null;
      inputRange = null;
    } else if (requestedRole === "RANGE_SUPERVISOR") {
      inputPoliceStation = null;
      inputDivision = null;
      inputZone = null;
    } else if (requestedRole === "ZONAL_SUPERVISOR") {
      inputPoliceStation = null;
      inputDivision = null;
    } else if (requestedRole === "DIVISIONAL_SUPERVISOR") {
      inputPoliceStation = null;
    }

    const derivedHierarchy = resolveCompleteParentHierarchy({
      rangeName: inputRange,
      zoneName: inputZone,
      divisionName: inputDivision,
      policeStationName: inputPoliceStation,
    });

    // Validate terminal selection against master dataset
    if (inputPoliceStation) {
      const psMatch = GANESH_HIERARCHY.find(
        (h) => h.policeStation.toLowerCase() === inputPoliceStation!.toLowerCase(),
      );
      if (!psMatch) {
        return Response.json(
          { error: `Invalid Police Station "${inputPoliceStation}". Station not found in GANESH_HIERARCHY master.` },
          { status: 400, headers: responseHeaders() },
        );
      }
    } else if (inputDivision) {
      const divMatch = GANESH_HIERARCHY.find(
        (h) => h.division.toLowerCase() === inputDivision!.toLowerCase(),
      );
      if (!divMatch) {
        return Response.json(
          { error: `Invalid Division "${inputDivision}". Division not found in GANESH_HIERARCHY master.` },
          { status: 400, headers: responseHeaders() },
        );
      }
    } else if (inputZone) {
      const zoneMatch = GANESH_HIERARCHY.find(
        (h) => h.zone.toLowerCase() === inputZone!.toLowerCase(),
      );
      if (!zoneMatch) {
        return Response.json(
          { error: `Invalid Zone "${inputZone}". Zone not found in GANESH_HIERARCHY master.` },
          { status: 400, headers: responseHeaders() },
        );
      }
    } else if (inputRange) {
      const rangeMatch = GANESH_HIERARCHY.find(
        (h) => h.range.toLowerCase() === inputRange!.toLowerCase(),
      );
      if (!rangeMatch) {
        return Response.json(
          { error: `Invalid Range "${inputRange}". Range not found in GANESH_HIERARCHY master.` },
          { status: 400, headers: responseHeaders() },
        );
      }
    }

    const updateData: Record<string, unknown> = {
      role: roleConfig.role,
      accessLevel: roleConfig.accessLevel,
      allRanges: roleConfig.allRanges,
      allZones: roleConfig.allZones,
      allDivisions: roleConfig.allDivisions,
      allPoliceStations: roleConfig.allPoliceStations,
      commissionerateName: derivedHierarchy.commissionerateName,
      rangeName: roleConfig.allRanges ? null : derivedHierarchy.rangeName,
      zoneName: roleConfig.allZones ? null : derivedHierarchy.zoneName,
      divisionName: roleConfig.allDivisions ? null : derivedHierarchy.divisionName,
      policeStationName: roleConfig.allPoliceStations ? null : derivedHierarchy.policeStationName,
      sectorName: roleConfig.allPoliceStations ? null : inputSector,
    };

    const now = new Date();

    // Execute atomic transaction for all target updates, per-user audit events, and target session termination
    await prisma.$transaction(async (tx) => {
      // Re-verify exact target count inside transaction
      const exactCount = await tx.user.count({ where: { id: { in: filteredTargetIds } } });
      if (exactCount !== filteredTargetIds.length) {
        throw new Error("REJECTED: Target user count mismatch inside transaction.");
      }

      for (const targetUser of targetUsers) {
        // Individual unique-ID update (NEVER modifies employeeId, name, rank, username, passwordHash, status)
        await tx.user.update({
          where: { id: targetUser.id },
          data: updateData,
        });

        // Individual ActivityEvent audit log
        await tx.activityEvent.create({
          data: {
            userId: adminUser.id,
            source: "WEB_ADMIN",
            eventType: "OFFICER_ALLOTMENT_CHANGED",
            oldValue: {
              role: targetUser.role,
              accessLevel: targetUser.accessLevel,
              rangeName: targetUser.rangeName,
              zoneName: targetUser.zoneName,
              divisionName: targetUser.divisionName,
              policeStationName: targetUser.policeStationName,
              sectorName: targetUser.sectorName,
              allRanges: targetUser.allRanges,
              allZones: targetUser.allZones,
              allDivisions: targetUser.allDivisions,
              allPoliceStations: targetUser.allPoliceStations,
            },
            newValue: updateData as any,
            metadata: {
              adminUserId: adminUser.id,
              adminEmployeeId: adminUser.employeeId,
              adminName: adminUser.name,
              targetUserId: targetUser.id,
              targetEmployeeId: targetUser.employeeId,
              targetName: targetUser.name,
              targetRank: targetUser.rank,
            },
            occurredAt: now,
          },
        });
      }

      // Terminate active sessions for targeted officers ONLY
      await tx.userSession.updateMany({
        where: {
          userId: { in: filteredTargetIds },
          status: "ACTIVE",
        },
        data: {
          status: "TERMINATED",
          logoutAt: now,
        },
      });
    });

    return Response.json(
      {
        success: true,
        message: `Successfully updated allotment for ${filteredTargetIds.length} officer(s).`,
        count: filteredTargetIds.length,
      },
      { headers: responseHeaders() },
    );
  } catch (error) {
    const errorMsg = error instanceof Error ? error.message : "Internal server error";
    return Response.json(
      { error: `Role Allotment transaction failed: ${errorMsg}` },
      { status: 500, headers: responseHeaders() },
    );
  }
}
