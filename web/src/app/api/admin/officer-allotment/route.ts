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
  return (
    typeof value === "object" &&
    value !== null &&
    !Array.isArray(value)
  );
}

function booleanValue(value: unknown): boolean {
  if (value === true || value === false) {
    return value;
  }
  const normalized = text(value).toLowerCase();
  return normalized === "true" || normalized === "1" || normalized === "yes";
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

    const targetUserId = text(body.targetUserId || body.userId);
    if (!targetUserId) {
      return Response.json(
        { error: "REJECTED: Target user ID is required. Single-user target strictly enforced." },
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

    const targetUserCount = await prisma.user.count({
      where: { id: targetUserId },
    });

    if (targetUserCount !== 1) {
      return Response.json(
        { error: "REJECTED: Allotment update must target exactly ONE user." },
        { status: 400, headers: responseHeaders() },
      );
    }

    const existingUser = await prisma.user.findUnique({
      where: { id: targetUserId },
      include: {
        policeStationAccesses: true,
      },
    });

    if (!existingUser) {
      return Response.json(
        { error: "Target officer record not found." },
        { status: 404, headers: responseHeaders() },
      );
    }

    // Safeguard A: Self Demotion
    if (existingUser.id === adminUser.id && requestedRole !== "ADMIN") {
      return Response.json(
        { error: "You cannot demote your own administrator account." },
        { status: 400, headers: responseHeaders() },
      );
    }

    // Safeguard B: Last Active Admin
    if (existingUser.role.toUpperCase() === "ADMIN" && existingUser.status === "ACTIVE" && requestedRole !== "ADMIN") {
      const activeAdminCount = await prisma.user.count({
        where: { role: "ADMIN", status: "ACTIVE" },
      });
      if (activeAdminCount <= 1) {
        return Response.json(
          { error: "Cannot demote the last active administrator account." },
          { status: 400, headers: responseHeaders() },
        );
      }
    }

    // 1. Resolve role scope configuration from authoritative ROLE_SCOPE_MAP
    const roleConfig = getRoleScopeConfig(requestedRole);

    // 2. Server-side Parent Hierarchy Derivation
    let inputPoliceStation = nullableText(body.policeStationName);
    let inputDivision = nullableText(body.divisionName);
    let inputZone = nullableText(body.zoneName);
    let inputRange = nullableText(body.rangeName);
    const inputSector = nullableText(body.sectorName);

    // Enforce role-based terminal jurisdiction rules before derivation
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

    // Server independently derives parent hierarchy from GANESH_HIERARCHY master data
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

    // Build update dataset
    const updateData: Record<string, unknown> = {
      role: roleConfig.role,
      accessLevel: roleConfig.accessLevel,

      // Explicitly overwrite all 4 boolean flags from ROLE_SCOPE_MAP (no stale flags)
      allRanges: roleConfig.allRanges,
      allZones: roleConfig.allZones,
      allDivisions: roleConfig.allDivisions,
      allPoliceStations: roleConfig.allPoliceStations,

      // Server-derived hierarchy
      commissionerateName: derivedHierarchy.commissionerateName,
      rangeName: roleConfig.allRanges ? null : derivedHierarchy.rangeName,
      zoneName: roleConfig.allZones ? null : derivedHierarchy.zoneName,
      divisionName: roleConfig.allDivisions ? null : derivedHierarchy.divisionName,
      policeStationName: roleConfig.allPoliceStations ? null : derivedHierarchy.policeStationName,
      sectorName: roleConfig.allPoliceStations ? null : inputSector,
    };

    // Process optional Additional Police Station Accesses
    let parsedAdditionalAccesses: Array<{
      policeStationCode: string | null;
      policeStationName: string;
      canView: boolean;
      canEdit: boolean;
    }> | undefined;

    if (body.additionalPoliceStationAccesses !== undefined) {
      if (!Array.isArray(body.additionalPoliceStationAccesses)) {
        return Response.json(
          { error: "additionalPoliceStationAccesses must be an array." },
          { status: 400, headers: responseHeaders() },
        );
      }

      const accessMap = new Map<string, {
        policeStationCode: string | null;
        policeStationName: string;
        canView: boolean;
        canEdit: boolean;
      }>();

      for (const item of body.additionalPoliceStationAccesses) {
        if (!isObject(item)) continue;
        const psName = text(item.policeStationName);
        if (!psName) continue;

        // Verify station exists in master data
        const match = GANESH_HIERARCHY.find(
          (h) => h.policeStation.toLowerCase() === psName.toLowerCase(),
        );
        const validStationName = match ? match.policeStation : psName;

        const canView = item.canView === undefined ? true : booleanValue(item.canView);
        // Map UI "canManage" / "canEdit" to schema field `canEdit`
        const canEdit = item.canEdit !== undefined ? booleanValue(item.canEdit) : (item.canManage !== undefined ? booleanValue(item.canManage) : true);

        accessMap.set(validStationName.toLowerCase(), {
          policeStationCode: nullableText(item.policeStationCode),
          policeStationName: validStationName,
          canView,
          canEdit,
        });
      }

      parsedAdditionalAccesses = Array.from(accessMap.values());
    }

    const now = new Date();

    // Execute atomic transaction for update, additional access sync, audit log, and session termination
    const result = await prisma.$transaction(async (tx) => {
      // 1. Guard: Re-verify single target count inside transaction
      const exactCount = await tx.user.count({ where: { id: targetUserId } });
      if (exactCount !== 1) {
        throw new Error("REJECTED: Target user count must be exactly 1.");
      }

      // 2. Update single user record (NEVER touches employeeId, username, passwordHash, name, rank, phoneNumber)
      const updatedUser = await tx.user.update({
        where: { id: targetUserId },
        data: updateData,
      });

      // 3. Synchronize UserPoliceStationAccess
      if (parsedAdditionalAccesses !== undefined) {
        await tx.userPoliceStationAccess.deleteMany({
          where: { userId: targetUserId },
        });

        if (parsedAdditionalAccesses.length > 0) {
          await tx.userPoliceStationAccess.createMany({
            data: parsedAdditionalAccesses.map((acc) => ({
              userId: targetUserId,
              policeStationCode: acc.policeStationCode,
              policeStationName: acc.policeStationName,
              canView: acc.canView,
              canEdit: acc.canEdit,
            })),
          });
        }
      }

      // 4. Create ActivityEvent Audit Log
      await tx.activityEvent.create({
        data: {
          userId: adminUser.id,
          source: "WEB_ADMIN",
          eventType: "OFFICER_ALLOTMENT_CHANGED",
          oldValue: {
            role: existingUser.role,
            accessLevel: existingUser.accessLevel,
            rangeName: existingUser.rangeName,
            zoneName: existingUser.zoneName,
            divisionName: existingUser.divisionName,
            policeStationName: existingUser.policeStationName,
            sectorName: existingUser.sectorName,
            allRanges: existingUser.allRanges,
            allZones: existingUser.allZones,
            allDivisions: existingUser.allDivisions,
            allPoliceStations: existingUser.allPoliceStations,
            additionalAccesses: existingUser.policeStationAccesses.map((a) => ({
              policeStationName: a.policeStationName,
              canView: a.canView,
              canEdit: a.canEdit,
            })),
          },
          newValue: {
            ...updateData,
            additionalAccesses: parsedAdditionalAccesses,
          },
          metadata: {
            adminUserId: adminUser.id,
            adminEmployeeId: adminUser.employeeId,
            adminName: adminUser.name,
            targetUserId: existingUser.id,
            targetEmployeeId: existingUser.employeeId,
            targetName: existingUser.name,
            targetRank: existingUser.rank,
          },
          occurredAt: now,
        },
      });

      // 5. Terminate active sessions for target officer ONLY
      await tx.userSession.updateMany({
        where: {
          userId: targetUserId,
          status: "ACTIVE",
        },
        data: {
          status: "TERMINATED",
          logoutAt: now,
        },
      });

      return updatedUser;
    });

    const isSelfEdit = targetUserId === adminUser.id;

    return Response.json(
      {
        success: true,
        message: `Officer allotment updated successfully for ${existingUser.name} (${existingUser.employeeId}).`,
        isSelfEditWarning: isSelfEdit
          ? "You updated your own account allotment. Changes take effect on your next session request."
          : undefined,
        user: {
          id: result.id,
          employeeId: result.employeeId,
          name: result.name,
          rank: result.rank,
          role: result.role,
          accessLevel: result.accessLevel,
          rangeName: result.rangeName,
          zoneName: result.zoneName,
          divisionName: result.divisionName,
          policeStationName: result.policeStationName,
          sectorName: result.sectorName,
          allRanges: result.allRanges,
          allZones: result.allZones,
          allDivisions: result.allDivisions,
          allPoliceStations: result.allPoliceStations,
        },
      },
      { headers: responseHeaders() },
    );
  } catch (error) {
    const errorMsg = error instanceof Error ? error.message : "Internal server error";
    return Response.json(
      { error: `Officer Allotment transaction failed: ${errorMsg}` },
      { status: 500, headers: responseHeaders() },
    );
  }
}
