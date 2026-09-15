import { NextRequest, NextResponse } from "next/server";

import { prisma } from "@/lib/prisma";

function cleanString(
  value: unknown,
): string | null {
  if (value === null || value === undefined) {
    return null;
  }

  const text = String(value).trim();

  return text.length > 0 ? text : null;
}

function normalizeUpper(
  value: unknown,
): string | null {
  const text = cleanString(value);

  return text ? text.toUpperCase() : null;
}

//
// ============================================================
// POST
// Create a new login + device tracking session.
//
// Mobile/Web sends this after successful authentication.
//
// This does NOT authenticate the user by itself.
// It records an already authenticated application's session.
// ============================================================
//

export async function POST(
  request: NextRequest,
) {
  try {
    const body = await request.json();

    const userId = cleanString(body.userId);

    if (!userId) {
      return NextResponse.json(
        {
          success: false,
          error: "userId is required.",
        },
        {
          status: 400,
        },
      );
    }

    const source =
      normalizeUpper(body.source);

    if (
      source !== "MOBILE" &&
      source !== "WEB"
    ) {
      return NextResponse.json(
        {
          success: false,
          error:
            "source must be MOBILE or WEB.",
        },
        {
          status: 400,
        },
      );
    }

    const deviceType =
      normalizeUpper(
        body.deviceType ?? body.source,
      );

    if (
      deviceType !== "MOBILE" &&
      deviceType !== "WEB"
    ) {
      return NextResponse.json(
        {
          success: false,
          error:
            "deviceType must be MOBILE or WEB.",
        },
        {
          status: 400,
        },
      );
    }

    const now = new Date();

    const result =
      await prisma.$transaction(
        async (tx) => {
          const userSession =
            await tx.userSession.create({
              data: {
                userId,
                userName:
                  cleanString(body.userName),
                rank:
                  cleanString(body.rank),
                role:
                  cleanString(body.role),

                source,

                commissionerateCode:
                  cleanString(
                    body.commissionerateCode,
                  ),
                rangeCode:
                  cleanString(
                    body.rangeCode,
                  ),
                zoneCode:
                  cleanString(
                    body.zoneCode,
                  ),
                divisionCode:
                  cleanString(
                    body.divisionCode,
                  ),
                policeStationCode:
                  cleanString(
                    body.policeStationCode,
                  ),
                sectorCode:
                  cleanString(
                    body.sectorCode,
                  ),

                status: "ACTIVE",

                loginAt: now,
                lastSeenAt: now,
              },
            });

          const trackingEnabled =
            body.trackingEnabled === true;

          const trackingStatus =
            trackingEnabled
              ? "LOCATION_ACTIVE"
              : "TRACKING_STOPPED";

          const deviceSession =
            await tx.deviceSession.create({
              data: {
                userSessionId:
                  userSession.id,

                userId,

                deviceType,

                deviceId:
                  cleanString(
                    body.deviceId,
                  ),
                deviceName:
                  cleanString(
                    body.deviceName,
                  ),
                manufacturer:
                  cleanString(
                    body.manufacturer,
                  ),
                model:
                  cleanString(
                    body.model,
                  ),
                platform:
                  cleanString(
                    body.platform,
                  ),
                osVersion:
                  cleanString(
                    body.osVersion,
                  ),
                appVersion:
                  cleanString(
                    body.appVersion,
                  ),

                trackingEnabled,
                trackingStatus,

                createdAt: now,
                lastSeenAt: now,
              },
            });

          await tx.activityEvent.create({
            data: {
              userId,

              userSessionId:
                userSession.id,
              deviceSessionId:
                deviceSession.id,

              source,

              eventType: "LOGIN",

              commissionerateCode:
                cleanString(
                  body.commissionerateCode,
                ),
              rangeCode:
                cleanString(
                  body.rangeCode,
                ),
              zoneCode:
                cleanString(
                  body.zoneCode,
                ),
              divisionCode:
                cleanString(
                  body.divisionCode,
                ),
              policeStationCode:
                cleanString(
                  body.policeStationCode,
                ),
              sectorCode:
                cleanString(
                  body.sectorCode,
                ),

              occurredAt: now,

              metadata: {
                deviceType,
                deviceId:
                  cleanString(
                    body.deviceId,
                  ),
                deviceName:
                  cleanString(
                    body.deviceName,
                  ),
                manufacturer:
                  cleanString(
                    body.manufacturer,
                  ),
                model:
                  cleanString(
                    body.model,
                  ),
                platform:
                  cleanString(
                    body.platform,
                  ),
                osVersion:
                  cleanString(
                    body.osVersion,
                  ),
                appVersion:
                  cleanString(
                    body.appVersion,
                  ),
              },
            },
          });

          return {
            userSession,
            deviceSession,
          };
        },
      );

    return NextResponse.json(
      {
        success: true,

        userSessionId:
          result.userSession.id,

        deviceSessionId:
          result.deviceSession.id,

        userId:
          result.userSession.userId,

        source:
          result.userSession.source,

        deviceType:
          result.deviceSession.deviceType,

        trackingEnabled:
          result.deviceSession
            .trackingEnabled,

        trackingStatus:
          result.deviceSession
            .trackingStatus,

        loginAt:
          result.userSession.loginAt,
      },
      {
        status: 201,
      },
    );
  } catch (error) {
    console.error(
      "Tracking session POST error:",
      error,
    );

    return NextResponse.json(
      {
        success: false,
        error:
          "Unable to create tracking session.",
        details:
          error instanceof Error
            ? error.message
            : String(error),
      },
      {
        status: 500,
      },
    );
  }
}

//
// ============================================================
// PATCH
// Update session heartbeat / tracking state.
// ============================================================
//

export async function PATCH(
  request: NextRequest,
) {
  try {
    const body = await request.json();

    const userSessionId =
      cleanString(body.userSessionId);

    const deviceSessionId =
      cleanString(body.deviceSessionId);

    if (
      !userSessionId ||
      !deviceSessionId
    ) {
      return NextResponse.json(
        {
          success: false,
          error:
            "userSessionId and deviceSessionId are required.",
        },
        {
          status: 400,
        },
      );
    }

    const existingDevice =
      await prisma.deviceSession.findUnique({
        where: {
          id: deviceSessionId,
        },
      });

    if (
      !existingDevice ||
      existingDevice.userSessionId !==
        userSessionId
    ) {
      return NextResponse.json(
        {
          success: false,
          error:
            "Device session not found.",
        },
        {
          status: 404,
        },
      );
    }

    const now = new Date();

    const trackingStatus =
      normalizeUpper(
        body.trackingStatus,
      );

    const allowedStatuses = new Set([
      "LOCATION_ACTIVE",
      "LOCATION_PERMISSION_DENIED",
      "GPS_DISABLED",
      "NETWORK_OFFLINE",
      "BACKGROUND_TRACKING_PAUSED",
      "TRACKING_STOPPED",
    ]);

    if (
      trackingStatus &&
      !allowedStatuses.has(
        trackingStatus,
      )
    ) {
      return NextResponse.json(
        {
          success: false,
          error:
            "Invalid trackingStatus.",
        },
        {
          status: 400,
        },
      );
    }

    const trackingEnabled =
      typeof body.trackingEnabled ===
      "boolean"
        ? body.trackingEnabled
        : existingDevice.trackingEnabled;

    const updatedDevice =
      await prisma.$transaction(
        async (tx) => {
          await tx.userSession.update({
            where: {
              id: userSessionId,
            },
            data: {
              lastSeenAt: now,
            },
          });

          return tx.deviceSession.update({
            where: {
              id: deviceSessionId,
            },
            data: {
              lastSeenAt: now,

              trackingEnabled,

              ...(trackingStatus
                ? {
                    trackingStatus,
                  }
                : {}),
            },
          });
        },
      );

    return NextResponse.json({
      success: true,

      userSessionId,
      deviceSessionId,

      trackingEnabled:
        updatedDevice.trackingEnabled,

      trackingStatus:
        updatedDevice.trackingStatus,

      lastSeenAt:
        updatedDevice.lastSeenAt,
    });
  } catch (error) {
    console.error(
      "Tracking session PATCH error:",
      error,
    );

    return NextResponse.json(
      {
        success: false,
        error:
          "Unable to update tracking session.",
        details:
          error instanceof Error
            ? error.message
            : String(error),
      },
      {
        status: 500,
      },
    );
  }
}

//
// ============================================================
// DELETE
// End/logout a tracking session.
// ============================================================
//

export async function DELETE(
  request: NextRequest,
) {
  try {
    const body = await request.json();

    const userSessionId =
      cleanString(body.userSessionId);

    const deviceSessionId =
      cleanString(body.deviceSessionId);

    if (
      !userSessionId ||
      !deviceSessionId
    ) {
      return NextResponse.json(
        {
          success: false,
          error:
            "userSessionId and deviceSessionId are required.",
        },
        {
          status: 400,
        },
      );
    }

    const deviceSession =
      await prisma.deviceSession.findUnique({
        where: {
          id: deviceSessionId,
        },
      });

    if (
      !deviceSession ||
      deviceSession.userSessionId !==
        userSessionId
    ) {
      return NextResponse.json(
        {
          success: false,
          error:
            "Device session not found.",
        },
        {
          status: 404,
        },
      );
    }

    const userSession =
      await prisma.userSession.findUnique({
        where: {
          id: userSessionId,
        },
      });

    if (!userSession) {
      return NextResponse.json(
        {
          success: false,
          error:
            "User session not found.",
        },
        {
          status: 404,
        },
      );
    }

    const now = new Date();

    await prisma.$transaction(
      async (tx) => {
        await tx.deviceSession.update({
          where: {
            id: deviceSessionId,
          },
          data: {
            trackingEnabled: false,
            trackingStatus:
              "TRACKING_STOPPED",
            lastSeenAt: now,
            endedAt: now,
          },
        });

        await tx.userSession.update({
          where: {
            id: userSessionId,
          },
          data: {
            status: "LOGGED_OUT",
            logoutAt: now,
            lastSeenAt: now,
          },
        });

        await tx.activityEvent.create({
          data: {
            userId:
              userSession.userId,

            userSessionId,
            deviceSessionId,

            source:
              userSession.source,

            eventType: "LOGOUT",

            commissionerateCode:
              userSession
                .commissionerateCode,
            rangeCode:
              userSession.rangeCode,
            zoneCode:
              userSession.zoneCode,
            divisionCode:
              userSession.divisionCode,
            policeStationCode:
              userSession
                .policeStationCode,
            sectorCode:
              userSession.sectorCode,

            occurredAt: now,
          },
        });
      },
    );

    return NextResponse.json({
      success: true,
      userSessionId,
      deviceSessionId,
      status: "LOGGED_OUT",
      logoutAt: now,
    });
  } catch (error) {
    console.error(
      "Tracking session DELETE error:",
      error,
    );

    return NextResponse.json(
      {
        success: false,
        error:
          "Unable to close tracking session.",
        details:
          error instanceof Error
            ? error.message
            : String(error),
      },
      {
        status: 500,
      },
    );
  }
}