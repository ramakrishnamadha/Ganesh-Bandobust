import { NextRequest } from "next/server";

import { prisma } from "@/lib/prisma";
import { getWebSession } from "@/lib/server/auth";
import {
  getRoleScopeConfig,
  resolveCompleteParentHierarchy,
} from "@/lib/server/userManagementHelper";

type JsonObject = Record<
  string,
  unknown
>;

function text(value: unknown): string {
  if (
    value === null ||
    value === undefined
  ) {
    return "";
  }

  return String(value).trim();
}

function nullableText(
  value: unknown,
): string | null {
  const result = text(value);

  return result.length > 0
    ? result
    : null;
}

function isObject(
  value: unknown,
): value is JsonObject {
  return (
    typeof value === "object" &&
    value !== null &&
    !Array.isArray(value)
  );
}

function booleanValue(
  value: unknown,
): boolean | null {
  if (
    value === true ||
    value === false
  ) {
    return value;
  }

  const normalized =
    text(value).toLowerCase();

  if (
    normalized === "true" ||
    normalized === "1" ||
    normalized === "yes"
  ) {
    return true;
  }

  if (
    normalized === "false" ||
    normalized === "0" ||
    normalized === "no"
  ) {
    return false;
  }

  return null;
}

function integerValue(
  value: unknown,
): number | null {
  if (
    value === null ||
    value === undefined ||
    text(value) === ""
  ) {
    return null;
  }

  const result = Number(value);

  if (
    !Number.isFinite(result) ||
    !Number.isInteger(result)
  ) {
    return null;
  }

  return result;
}

function responseHeaders() {
  return {
    "Cache-Control": "no-store",
  };
}

async function requireAdmin(
  request: NextRequest,
) {
  const session =
    getWebSession(request);

  if (!session) {
    return {
      error: Response.json(
        {
          error: "Unauthorized",
        },
        {
          status: 401,
          headers: responseHeaders(),
        },
      ),
      session: null,
      adminUser: null,
    };
  }

  const user =
    await prisma.user.findUnique({
      where: {
        id: session.userId,
      },
      select: {
        id: true,
        employeeId: true,
        name: true,
        role: true,
        status: true,
      },
    });

  if (
    !user ||
    user.status !== "ACTIVE"
  ) {
    return {
      error: Response.json(
        {
          error:
            "User account is inactive or unavailable.",
        },
        {
          status: 403,
          headers: responseHeaders(),
        },
      ),
      session: null,
      adminUser: null,
    };
  }

  if (
    user.role.toUpperCase() !== "ADMIN"
  ) {
    return {
      error: Response.json(
        {
          error:
            "Administrator access required.",
        },
        {
          status: 403,
          headers: responseHeaders(),
        },
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

export async function GET(
  request: NextRequest,
) {
  try {
    const authorization =
      await requireAdmin(request);

    if (authorization.error) {
      return authorization.error;
    }

    const users =
      await prisma.user.findMany({
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

          commissionerateCode: true,
          commissionerateName: true,

          rangeCode: true,
          rangeName: true,

          zoneCode: true,
          zoneName: true,

          divisionCode: true,
          divisionName: true,

          policeStationCode: true,
          policeStationName: true,

          sectorCode: true,
          sectorName: true,

          allPoliceStations: true,
          allDivisions: true,
          allZones: true,
          allRanges: true,

          status: true,

          mustChangePassword: true,

          createdAt: true,
          updatedAt: true,

          policeStationAccesses: {
            select: {
              id: true,

              policeStationCode: true,

              policeStationName: true,

              canView: true,
              canEdit: true,
            },

            orderBy: {
              policeStationName: "asc",
            },
          },
        },

        orderBy: [
          {
            name: "asc",
          },
          {
            employeeId: "asc",
          },
        ],
      });

    // Compute dynamic summary stats from database records
    let totalUsers = 0;
    let activeUsers = 0;
    let inactiveUsers = 0;

    let fieldOfficers = 0;
    let sectorIncharges = 0;
    let psSupervisors = 0;
    let divisionalSupervisors = 0;
    let zonalSupervisors = 0;
    let rangeSupervisors = 0;
    let admins = 0;

    for (const u of users) {
      totalUsers += 1;
      if (u.status === "ACTIVE") {
        activeUsers += 1;
      } else {
        inactiveUsers += 1;
      }

      const roleUpper = (
        u.role || ""
      ).toUpperCase();

      if (
        roleUpper === "FIELD_OFFICER"
      ) {
        fieldOfficers += 1;
      } else if (
        roleUpper === "SECTOR_INCHARGE"
      ) {
        sectorIncharges += 1;
      } else if (
        roleUpper === "PS_SUPERVISOR" ||
        roleUpper === "SHO"
      ) {
        psSupervisors += 1;
      } else if (
        roleUpper ===
        "DIVISIONAL_SUPERVISOR"
      ) {
        divisionalSupervisors += 1;
      } else if (
        roleUpper === "ZONAL_SUPERVISOR"
      ) {
        zonalSupervisors += 1;
      } else if (
        roleUpper === "RANGE_SUPERVISOR"
      ) {
        rangeSupervisors += 1;
      } else if (
        roleUpper === "ADMIN"
      ) {
        admins += 1;
      }
    }

    const summaryCards = {
      totalUsers,
      activeUsers,
      inactiveUsers,
      fieldOfficers,
      sectorIncharges,
      psSupervisors,
      divisionalSupervisors,
      zonalSupervisors,
      rangeSupervisors,
      admins,
    };

    return Response.json(
      {
        users,
        summaryCards,
      },
      {
        status: 200,
        headers: responseHeaders(),
      },
    );
  } catch (error) {
    console.error(
      "Admin users GET error:",
      error,
    );

    return Response.json(
      {
        error: "Unable to load users.",
      },
      {
        status: 500,
        headers: responseHeaders(),
      },
    );
  }
}

export async function PATCH(
  request: NextRequest,
) {
  try {
    const authorization =
      await requireAdmin(request);

    if (
      authorization.error ||
      !authorization.session ||
      !authorization.adminUser
    ) {
      return authorization.error!;
    }

    const body: unknown =
      await request.json();

    if (!isObject(body)) {
      return Response.json(
        {
          error:
            "Invalid request body.",
        },
        {
          status: 400,
          headers: responseHeaders(),
        },
      );
    }

    const userId = text(body.userId);

    if (!userId) {
      return Response.json(
        {
          error: "User ID is required.",
        },
        {
          status: 400,
          headers: responseHeaders(),
        },
      );
    }

    const existingUser =
      await prisma.user.findUnique({
        where: {
          id: userId,
        },
        select: {
          id: true,
          employeeId: true,
          name: true,
          role: true,
          accessLevel: true,
          status: true,
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

    if (!existingUser) {
      return Response.json(
        {
          error: "User not found.",
        },
        {
          status: 404,
          headers: responseHeaders(),
        },
      );
    }

    const updateData: Record<
      string,
      string | number | boolean | null
    > = {};

    let targetRole = existingUser.role;
    if (body.role !== undefined) {
      const role = text(body.role);
      if (!role) {
        return Response.json(
          {
            error:
              "Role cannot be empty.",
          },
          {
            status: 400,
            headers: responseHeaders(),
          },
        );
      }
      targetRole = role;
      updateData.role = role;

      // Apply role scope config
      const scopeConfig =
        getRoleScopeConfig(role);
      updateData.accessLevel =
        scopeConfig.accessLevel;
      updateData.allRanges =
        scopeConfig.allRanges;
      updateData.allZones =
        scopeConfig.allZones;
      updateData.allDivisions =
        scopeConfig.allDivisions;
      updateData.allPoliceStations =
        scopeConfig.allPoliceStations;
    }

    if (
      body.accessLevel !== undefined &&
      updateData.accessLevel ===
        undefined
    ) {
      const parsedAccessLevel =
        integerValue(body.accessLevel);
      if (
        parsedAccessLevel === null ||
        parsedAccessLevel < 0
      ) {
        return Response.json(
          {
            error:
              "Access level must be a non-negative integer.",
          },
          {
            status: 400,
            headers: responseHeaders(),
          },
        );
      }
      updateData.accessLevel =
        parsedAccessLevel;
    }

    if (body.status !== undefined) {
      const status = text(
        body.status,
      ).toUpperCase();

      if (
        ![
          "ACTIVE",
          "INACTIVE",
        ].includes(status)
      ) {
        return Response.json(
          {
            error:
              "Status must be ACTIVE or INACTIVE.",
          },
          {
            status: 400,
            headers: responseHeaders(),
          },
        );
      }

      updateData.status = status;
    }

    // Safeguard A: Self-Demotion & Self-Deactivation
    if (
      userId ===
      authorization.session.userId
    ) {
      if (
        body.role !== undefined &&
        text(
          body.role,
        ).toUpperCase() !== "ADMIN"
      ) {
        return Response.json(
          {
            error:
              "You cannot demote your own administrator account.",
          },
          {
            status: 400,
            headers: responseHeaders(),
          },
        );
      }

      if (
        body.status !== undefined &&
        text(
          body.status,
        ).toUpperCase() === "INACTIVE"
      ) {
        return Response.json(
          {
            error:
              "You cannot deactivate your own administrator account.",
          },
          {
            status: 400,
            headers: responseHeaders(),
          },
        );
      }
    }

    // Safeguard B: Last Active Admin
    const isTargetActiveAdmin =
      (
        existingUser.role || ""
      ).toUpperCase() === "ADMIN" &&
      existingUser.status === "ACTIVE";

    if (isTargetActiveAdmin) {
      const isDemotion =
        body.role !== undefined &&
        text(
          body.role,
        ).toUpperCase() !== "ADMIN";
      const isDeactivation =
        body.status !== undefined &&
        text(
          body.status,
        ).toUpperCase() === "INACTIVE";

      if (
        isDemotion ||
        isDeactivation
      ) {
        const activeAdminCount =
          await prisma.user.count({
            where: {
              role: "ADMIN",
              status: "ACTIVE",
            },
          });

        if (activeAdminCount <= 1) {
          return Response.json(
            {
              error:
                "Cannot demote or deactivate the last active administrator account.",
            },
            {
              status: 400,
              headers:
                responseHeaders(),
            },
          );
        }
      }
    }

    // Resolve complete parent hierarchy if range/zone/division/ps are supplied
    const rangeName =
      body.rangeName !== undefined
        ? nullableText(body.rangeName)
        : existingUser.rangeName;
    const zoneName =
      body.zoneName !== undefined
        ? nullableText(body.zoneName)
        : existingUser.zoneName;
    const divisionName =
      body.divisionName !== undefined
        ? nullableText(
            body.divisionName,
          )
        : existingUser.divisionName;
    const policeStationName =
      body.policeStationName !==
      undefined
        ? nullableText(
            body.policeStationName,
          )
        : existingUser.policeStationName;
    const sectorName =
      body.sectorName !== undefined
        ? nullableText(body.sectorName)
        : existingUser.sectorName;

    if (
      body.rangeName !== undefined ||
      body.zoneName !== undefined ||
      body.divisionName !== undefined ||
      body.policeStationName !==
        undefined
    ) {
      const hierarchy =
        resolveCompleteParentHierarchy({
          rangeName,
          zoneName,
          divisionName,
          policeStationName,
        });

      updateData.commissionerateName =
        hierarchy.commissionerateName;
      updateData.rangeName =
        hierarchy.rangeName;
      updateData.zoneName =
        hierarchy.zoneName;
      updateData.divisionName =
        hierarchy.divisionName;
      updateData.policeStationName =
        hierarchy.policeStationName;
    }

    if (body.sectorName !== undefined) {
      updateData.sectorName =
        sectorName;
    }

    if (
      body.commissionerateCode !==
      undefined
    ) {
      updateData.commissionerateCode =
        nullableText(
          body.commissionerateCode,
        );
    }
    if (body.rangeCode !== undefined) {
      updateData.rangeCode =
        nullableText(body.rangeCode);
    }
    if (body.zoneCode !== undefined) {
      updateData.zoneCode =
        nullableText(body.zoneCode);
    }
    if (
      body.divisionCode !== undefined
    ) {
      updateData.divisionCode =
        nullableText(body.divisionCode);
    }
    if (
      body.policeStationCode !==
      undefined
    ) {
      updateData.policeStationCode =
        nullableText(
          body.policeStationCode,
        );
    }
    if (body.sectorCode !== undefined) {
      updateData.sectorCode =
        nullableText(body.sectorCode);
    }

    const booleanFields: Array<{
      requestKey:
        | "allRanges"
        | "allZones"
        | "allDivisions"
        | "allPoliceStations";
      value: unknown;
    }> = [
      {
        requestKey: "allRanges",
        value: body.allRanges,
      },
      {
        requestKey: "allZones",
        value: body.allZones,
      },
      {
        requestKey: "allDivisions",
        value: body.allDivisions,
      },
      {
        requestKey: "allPoliceStations",
        value: body.allPoliceStations,
      },
    ];

    for (const field of booleanFields) {
      if (field.value === undefined) {
        continue;
      }

      const parsed = booleanValue(
        field.value,
      );

      if (parsed === null) {
        return Response.json(
          {
            error: `${field.requestKey} must be true or false.`,
          },
          {
            status: 400,
            headers: responseHeaders(),
          },
        );
      }

      if (
        field.requestKey === "allRanges"
      ) {
        updateData.allRanges = parsed;
      }
      if (
        field.requestKey === "allZones"
      ) {
        updateData.allZones = parsed;
      }
      if (
        field.requestKey ===
        "allDivisions"
      ) {
        updateData.allDivisions =
          parsed;
      }
      if (
        field.requestKey ===
        "allPoliceStations"
      ) {
        updateData.allPoliceStations =
          parsed;
      }
    }

    let policeStationAccesses:
      | Array<{
          policeStationCode:
            string | null;
          policeStationName: string;
          canView: boolean;
          canEdit: boolean;
        }>
      | undefined;

    if (
      body.policeStationAccesses !==
      undefined
    ) {
      if (
        !Array.isArray(
          body.policeStationAccesses,
        )
      ) {
        return Response.json(
          {
            error:
              "Police Station accesses must be an array.",
          },
          {
            status: 400,
            headers: responseHeaders(),
          },
        );
      }

      const accessMap = new Map<
        string,
        {
          policeStationCode:
            string | null;
          policeStationName: string;
          canView: boolean;
          canEdit: boolean;
        }
      >();

      for (const item of body.policeStationAccesses) {
        if (!isObject(item)) {
          return Response.json(
            {
              error:
                "Invalid Police Station access entry.",
            },
            {
              status: 400,
              headers:
                responseHeaders(),
            },
          );
        }

        const policeStationNameInput =
          text(item.policeStationName);

        if (!policeStationNameInput) {
          return Response.json(
            {
              error:
                "Police Station name is required for additional access.",
            },
            {
              status: 400,
              headers:
                responseHeaders(),
            },
          );
        }

        const canView =
          item.canView === undefined
            ? true
            : booleanValue(
                item.canView,
              );
        const canEdit =
          item.canEdit === undefined
            ? true
            : booleanValue(
                item.canEdit,
              );

        if (
          canView === null ||
          canEdit === null
        ) {
          return Response.json(
            {
              error:
                "Police Station canView and canEdit must be true or false.",
            },
            {
              status: 400,
              headers:
                responseHeaders(),
            },
          );
        }

        accessMap.set(
          policeStationNameInput.toLowerCase(),
          {
            policeStationCode:
              nullableText(
                item.policeStationCode,
              ),
            policeStationName:
              policeStationNameInput,
            canView,
            canEdit,
          },
        );
      }

      policeStationAccesses =
        Array.from(accessMap.values());
    }

    const now = new Date();

    const updatedUser =
      await prisma.$transaction(
        async (tx) => {
          const updated =
            await tx.user.update({
              where: {
                id: userId,
              },
              data: updateData,
            });

          if (
            policeStationAccesses !==
            undefined
          ) {
            await tx.userPoliceStationAccess.deleteMany(
              {
                where: {
                  userId,
                },
              },
            );

            if (
              policeStationAccesses.length >
              0
            ) {
              await tx.userPoliceStationAccess.createMany(
                {
                  data: policeStationAccesses.map(
                    (access) => ({
                      userId,
                      policeStationCode:
                        access.policeStationCode,
                      policeStationName:
                        access.policeStationName,
                      canView:
                        access.canView,
                      canEdit:
                        access.canEdit,
                    }),
                  ),
                },
              );
            }
          }

          // Record ActivityEvent audit trail
          await tx.activityEvent.create(
            {
              data: {
                userId:
                  authorization
                    .adminUser!.id,
                source: "WEB_ADMIN",
                eventType:
                  "USER_ROLE_ASSIGNED",
                oldValue: {
                  role: existingUser.role,
                  accessLevel:
                    existingUser.accessLevel,
                  rangeName:
                    existingUser.rangeName,
                  zoneName:
                    existingUser.zoneName,
                  divisionName:
                    existingUser.divisionName,
                  policeStationName:
                    existingUser.policeStationName,
                  sectorName:
                    existingUser.sectorName,
                  allRanges:
                    existingUser.allRanges,
                  allZones:
                    existingUser.allZones,
                  allDivisions:
                    existingUser.allDivisions,
                  allPoliceStations:
                    existingUser.allPoliceStations,
                },
                newValue: updateData,
                metadata: {
                  adminEmployeeId:
                    authorization
                      .adminUser!
                      .employeeId,
                  adminName:
                    authorization
                      .adminUser!.name,
                  affectedUserId:
                    existingUser.id,
                  affectedEmployeeId:
                    existingUser.employeeId,
                  affectedName:
                    existingUser.name,
                },
                occurredAt: now,
              },
            },
          );

          return updated;
        },
      );

    const refreshedUser =
      await prisma.user.findUnique({
        where: {
          id: updatedUser.id,
        },
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

          commissionerateCode: true,
          commissionerateName: true,

          rangeCode: true,
          rangeName: true,

          zoneCode: true,
          zoneName: true,

          divisionCode: true,
          divisionName: true,

          policeStationCode: true,
          policeStationName: true,

          sectorCode: true,
          sectorName: true,

          allPoliceStations: true,
          allDivisions: true,
          allZones: true,
          allRanges: true,

          status: true,

          mustChangePassword: true,

          createdAt: true,
          updatedAt: true,

          policeStationAccesses: {
            select: {
              id: true,
              policeStationCode: true,
              policeStationName: true,
              canView: true,
              canEdit: true,
            },
            orderBy: {
              policeStationName: "asc",
            },
          },
        },
      });

    return Response.json(
      {
        success: true,
        message:
          "User role and jurisdiction updated successfully.",
        user: refreshedUser,
      },
      {
        status: 200,
        headers: responseHeaders(),
      },
    );
  } catch (error) {
    console.error(
      "Admin users PATCH error:",
      error,
    );

    return Response.json(
      {
        error:
          "Unable to update user role and jurisdiction.",
      },
      {
        status: 500,
        headers: responseHeaders(),
      },
    );
  }
}
