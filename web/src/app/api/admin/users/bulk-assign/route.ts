import { NextRequest } from "next/server";
import { prisma } from "@/lib/prisma";
import { getWebSession } from "@/lib/server/auth";
import {
  getRoleScopeConfig,
  resolveCompleteParentHierarchy,
} from "@/lib/server/userManagementHelper";

function responseHeaders() {
  return {
    "Cache-Control": "no-store",
  };
}

async function requireAdmin(request: NextRequest) {
  const session = getWebSession(request);

  if (!session) {
    return {
      error: Response.json(
        { error: "Unauthorized" },
        { status: 401, headers: responseHeaders() }
      ),
      session: null,
    };
  }

  const user = await prisma.user.findUnique({
    where: { id: session.userId },
    select: { id: true, employeeId: true, name: true, role: true, status: true },
  });

  if (!user || user.status !== "ACTIVE") {
    return {
      error: Response.json(
        { error: "User account is inactive or unavailable." },
        { status: 403, headers: responseHeaders() }
      ),
      session: null,
      adminUser: null,
    };
  }

  if (user.role.toUpperCase() !== "ADMIN") {
    return {
      error: Response.json(
        { error: "Administrator access required." },
        { status: 403, headers: responseHeaders() }
      ),
      session: null,
      adminUser: null,
    };
  }

  return {
    error: null,
    session,
    adminUser: user,
  };
}

export async function POST(request: NextRequest) {
  try {
    const auth = await requireAdmin(request);
    if (auth.error || !auth.session || !auth.adminUser) {
      return auth.error!;
    }

    const body = await request.json().catch(() => null);

    if (!body || typeof body !== "object" || Array.isArray(body)) {
      return Response.json(
        { error: "Invalid JSON request payload." },
        { status: 400, headers: responseHeaders() }
      );
    }

    const userIds: string[] = Array.isArray(body.userIds)
      ? body.userIds.map((id: unknown) => String(id).trim()).filter(Boolean)
      : [];

    const targetRole = String(body.role ?? "").trim();
    const rangeName = body.rangeName ? String(body.rangeName).trim() : null;
    const zoneName = body.zoneName ? String(body.zoneName).trim() : null;
    const divisionName = body.divisionName ? String(body.divisionName).trim() : null;
    const policeStationName = body.policeStationName ? String(body.policeStationName).trim() : null;
    const sectorName = body.sectorName ? String(body.sectorName).trim() : null;

    if (userIds.length === 0) {
      return Response.json(
        { error: "At least one user ID must be selected for bulk assignment." },
        { status: 400, headers: responseHeaders() }
      );
    }

    if (!targetRole) {
      return Response.json(
        { error: "Target application role is required." },
        { status: 400, headers: responseHeaders() }
      );
    }

    // Safeguard: Do not permit accidental bulk ADMIN assignment
    if (targetRole.toUpperCase() === "ADMIN") {
      return Response.json(
        { error: "Bulk assignment of ADMIN role is prohibited. Assign ADMIN role individually." },
        { status: 400, headers: responseHeaders() }
      );
    }

    // Fetch targeted users to verify existence & store old states for audit trail
    const targetUsers = await prisma.user.findMany({
      where: { id: { in: userIds } },
      select: {
        id: true,
        employeeId: true,
        name: true,
        role: true,
        accessLevel: true,
        rangeName: true,
        zoneName: true,
        divisionName: true,
        policeStationName: true,
        sectorName: true,
        allRanges: true,
        allZones: true,
        allDivisions: true,
        allPoliceStations: true,
      },
    });

    if (targetUsers.length === 0) {
      return Response.json(
        { error: "No matching valid users found for bulk update." },
        { status: 404, headers: responseHeaders() }
      );
    }

    // Safeguard C: Prohibit bulk role reassignment for any target account holding ADMIN role
    if (targetUsers.some((u) => (u.role || "").toUpperCase() === "ADMIN")) {
      return Response.json(
        {
          error:
            "Bulk role reassignment cannot be applied to administrator accounts. Please manage administrator accounts individually.",
        },
        { status: 400, headers: responseHeaders() }
      );
    }

    // Resolve role scope & parent hierarchy
    const scopeConfig = getRoleScopeConfig(targetRole);
    const hierarchy = resolveCompleteParentHierarchy({
      rangeName,
      zoneName,
      divisionName,
      policeStationName,
    });

    const updatePayload = {
      role: scopeConfig.role,
      accessLevel: scopeConfig.accessLevel,
      commissionerateName: hierarchy.commissionerateName,
      rangeName: hierarchy.rangeName,
      zoneName: hierarchy.zoneName,
      divisionName: hierarchy.divisionName,
      policeStationName: hierarchy.policeStationName,
      sectorName,
      allRanges: scopeConfig.allRanges,
      allZones: scopeConfig.allZones,
      allDivisions: scopeConfig.allDivisions,
      allPoliceStations: scopeConfig.allPoliceStations,
    };

    const batchId = `BULK_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`;
    const now = new Date();

    // Transactional bulk update & audit logging
    const resultCount = await prisma.$transaction(async (tx) => {
      // 1. Bulk update users
      const updateResult = await tx.user.updateMany({
        where: { id: { in: targetUsers.map((u) => u.id) } },
        data: updatePayload,
      });

      // 2. Log ActivityEvent entries for each modified user
      const auditEntries = targetUsers.map((oldUser) => ({
        userId: auth.adminUser!.id,
        source: "WEB_ADMIN",
        eventType: "USER_ROLE_BULK_ASSIGNED",
        oldValue: {
          role: oldUser.role,
          accessLevel: oldUser.accessLevel,
          rangeName: oldUser.rangeName,
          zoneName: oldUser.zoneName,
          divisionName: oldUser.divisionName,
          policeStationName: oldUser.policeStationName,
          sectorName: oldUser.sectorName,
          allRanges: oldUser.allRanges,
          allZones: oldUser.allZones,
          allDivisions: oldUser.allDivisions,
          allPoliceStations: oldUser.allPoliceStations,
        },
        newValue: updatePayload,
        metadata: {
          batchId,
          isBulk: true,
          adminEmployeeId: auth.adminUser!.employeeId,
          adminName: auth.adminUser!.name,
          affectedUserId: oldUser.id,
          affectedEmployeeId: oldUser.employeeId,
          affectedName: oldUser.name,
        },
        occurredAt: now,
      }));

      await tx.activityEvent.createMany({
        data: auditEntries,
      });

      return updateResult.count;
    });

    return Response.json(
      {
        success: true,
        message: `Successfully updated ${resultCount} officers to ${scopeConfig.role}.`,
        updatedCount: resultCount,
        batchId,
      },
      { status: 200, headers: responseHeaders() }
    );
  } catch (error) {
    console.error("Bulk role assign error:", error);
    return Response.json(
      { error: "Unable to process bulk role assignment." },
      { status: 500, headers: responseHeaders() }
    );
  }
}
