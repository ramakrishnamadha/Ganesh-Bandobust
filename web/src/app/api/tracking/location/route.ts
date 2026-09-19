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

function parseNumber(
  value: unknown,
): number | null {
  if (
    value === null ||
    value === undefined ||
    value === ""
  ) {
    return null;
  }

  const number = Number(value);

  return Number.isFinite(number)
    ? number
    : null;
}

function parseDate(
  value: unknown,
): Date | null {
  if (
    value === null ||
    value === undefined ||
    value === ""
  ) {
    return null;
  }

  const date = new Date(
    String(value),
  );

  if (
    Number.isNaN(
      date.getTime(),
    )
  ) {
    return null;
  }

  return date;
}

function isValidLatitude(
  latitude: number,
): boolean {
  return (
    latitude >= -90 &&
    latitude <= 90
  );
}

function isValidLongitude(
  longitude: number,
): boolean {
  return (
    longitude >= -180 &&
    longitude <= 180
  );
}

//
// ============================================================
// POST
//
// Receive one GPS/location update from Mobile or Web.
//
// Every valid point is:
// 1. stored in OfficerLocationHistory
// 2. used to update OfficerCurrentLocation only if it is
//    newer than the presently stored live point
// 3. used to refresh UserSession + DeviceSession lastSeenAt
//
// This protects the live map from delayed/out-of-order GPS
// packets overwriting a newer officer position.
// ============================================================
//

export async function POST(
  request: NextRequest,
) {
  try {
    let body: Record<
      string,
      unknown
    >;

    try {
      body =
        (await request.json()) as Record<
          string,
          unknown
        >;
    } catch {
      return NextResponse.json(
        {
          success: false,
          error:
            "Request body must contain valid JSON.",
        },
        {
          status: 400,
        },
      );
    }

    const userSessionId =
      cleanString(
        body.userSessionId,
      );

    const deviceSessionId =
      cleanString(
        body.deviceSessionId,
      );

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

    const latitude =
      parseNumber(
        body.latitude,
      );

    const longitude =
      parseNumber(
        body.longitude,
      );

    if (
      latitude === null ||
      longitude === null
    ) {
      return NextResponse.json(
        {
          success: false,
          error:
            "latitude and longitude are required numeric values.",
        },
        {
          status: 400,
        },
      );
    }

    if (
      !isValidLatitude(
        latitude,
      )
    ) {
      return NextResponse.json(
        {
          success: false,
          error:
            "latitude must be between -90 and 90.",
        },
        {
          status: 400,
        },
      );
    }

    if (
      !isValidLongitude(
        longitude,
      )
    ) {
      return NextResponse.json(
        {
          success: false,
          error:
            "longitude must be between -180 and 180.",
        },
        {
          status: 400,
        },
      );
    }

    const accuracy =
      parseNumber(
        body.accuracy,
      );

    if (
      accuracy !== null &&
      accuracy < 0
    ) {
      return NextResponse.json(
        {
          success: false,
          error:
            "accuracy cannot be negative.",
        },
        {
          status: 400,
        },
      );
    }

    const speed =
      parseNumber(
        body.speed,
      );

    if (
      speed !== null &&
      speed < 0
    ) {
      return NextResponse.json(
        {
          success: false,
          error:
            "speed cannot be negative.",
        },
        {
          status: 400,
        },
      );
    }

    const heading =
      parseNumber(
        body.heading,
      );

    if (
      heading !== null &&
      (
        heading < 0 ||
        heading > 360
      )
    ) {
      return NextResponse.json(
        {
          success: false,
          error:
            "heading must be between 0 and 360.",
        },
        {
          status: 400,
        },
      );
    }

    const batteryNumber =
      parseNumber(
        body.batteryLevel,
      );

    let batteryLevel:
      number | null = null;

    if (
      batteryNumber !== null
    ) {
      if (
        batteryNumber < 0 ||
        batteryNumber > 100
      ) {
        return NextResponse.json(
          {
            success: false,
            error:
              "batteryLevel must be between 0 and 100.",
          },
          {
            status: 400,
          },
        );
      }

      batteryLevel =
        Math.round(
          batteryNumber,
        );
    }

    const locationSource =
      normalizeUpper(
        body.locationSource,
      ) ?? "MOBILE_GPS";

    const allowedSources =
      new Set([
        "MOBILE_GPS",
        "WEB_BROWSER_GEO",
        "MANUAL_MAP_SELECTION",
      ]);

    if (
      !allowedSources.has(
        locationSource,
      )
    ) {
      return NextResponse.json(
        {
          success: false,
          error:
            "Invalid locationSource.",
        },
        {
          status: 400,
        },
      );
    }

    const eventType =
      normalizeUpper(
        body.eventType,
      ) ?? "HEARTBEAT";

    const allowedEventTypes =
      new Set([
        "HEARTBEAT",
        "VERIFICATION_STARTED",
        "LOCATION_CONFIRMED",
        "LOCATION_CHANGED",
        "EVIDENCE_CAPTURED",
        "SUBMISSION",
      ]);

    if (
      !allowedEventTypes.has(
        eventType,
      )
    ) {
      return NextResponse.json(
        {
          success: false,
          error:
            "Invalid location eventType.",
        },
        {
          status: 400,
        },
      );
    }

    const activityStatus =
      normalizeUpper(
        body.activityStatus,
      );

    const allowedActivityStatuses =
      new Set([
        "ONLINE",
        "IDLE",
        "MOVING",
        "VERIFYING",
        "OFFLINE",
      ]);

    if (
      activityStatus &&
      !allowedActivityStatuses.has(
        activityStatus,
      )
    ) {
      return NextResponse.json(
        {
          success: false,
          error:
            "Invalid activityStatus.",
        },
        {
          status: 400,
        },
      );
    }

    const activeGpid =
      cleanString(
        body.activeGpid,
      );

    const suppliedCapturedAt =
      parseDate(
        body.capturedAt,
      );

    if (
      body.capturedAt !==
        undefined &&
      body.capturedAt !==
        null &&
      !suppliedCapturedAt
    ) {
      return NextResponse.json(
        {
          success: false,
          error:
            "capturedAt is not a valid date/time.",
        },
        {
          status: 400,
        },
      );
    }

    const capturedAt =
      suppliedCapturedAt ??
      new Date();

    const serverNow =
      new Date();

    //
    // Prevent an obviously wrong device clock from reporting
    // a point far into the future.
    //
    const fiveMinutes =
      5 * 60 * 1000;

    if (
      capturedAt.getTime() >
      serverNow.getTime() +
        fiveMinutes
    ) {
      return NextResponse.json(
        {
          success: false,
          error:
            "capturedAt is too far in the future.",
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
        include: {
          userSession: true,
          currentLocation: true,
        },
      });

    if (!deviceSession) {
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

    if (
      deviceSession.userSessionId !==
      userSessionId
    ) {
      return NextResponse.json(
        {
          success: false,
          error:
            "Device session does not belong to the supplied user session.",
        },
        {
          status: 403,
        },
      );
    }

    if (
      deviceSession.endedAt !==
      null
    ) {
      return NextResponse.json(
        {
          success: false,
          error:
            "Device session has already ended.",
        },
        {
          status: 409,
        },
      );
    }

    if (
      deviceSession.userSession
        .status !== "ACTIVE"
    ) {
      return NextResponse.json(
        {
          success: false,
          error:
            "User session is not active.",
        },
        {
          status: 409,
        },
      );
    }

    if (
      !deviceSession
        .trackingEnabled
    ) {
      return NextResponse.json(
        {
          success: false,
          error:
            "Location tracking is not enabled for this device session.",
        },
        {
          status: 409,
        },
      );
    }

    const userId =
      deviceSession.userId;

    //
    // Determine whether this point should replace the current
    // live position.
    //
    // Historical storage happens regardless, but a late packet
    // must not move the officer backwards on the live map.
    //
    const existingCurrent =
      deviceSession.currentLocation;

    const shouldUpdateCurrent =
      existingCurrent === null ||
      capturedAt.getTime() >=
        existingCurrent
          .capturedAt
          .getTime();

    const result =
      await prisma.$transaction(
        async (tx) => {
          const history =
            await tx.officerLocationHistory.create({
              data: {
                deviceSessionId,
                userId,

                latitude,
                longitude,

                accuracy,
                speed,
                heading,

                batteryLevel,

                locationSource,
                eventType,

                activeGpid,

                capturedAt,
                receivedAt:
                  serverNow,
              },
            });

          let currentLocation =
            existingCurrent;

          if (
            shouldUpdateCurrent
          ) {
            currentLocation =
              await tx.officerCurrentLocation.upsert({
                where: {
                  deviceSessionId,
                },
                create: {
                  deviceSessionId,
                  userId,

                  latitude,
                  longitude,

                  accuracy,
                  speed,
                  heading,

                  batteryLevel,

                  locationSource,

                  activityStatus:
                    activityStatus ??
                    "ONLINE",

                  activeGpid,

                  capturedAt,
                },
                update: {
                  userId,

                  latitude,
                  longitude,

                  accuracy,
                  speed,
                  heading,

                  batteryLevel,

                  locationSource,

                  ...(activityStatus
                    ? {
                        activityStatus,
                      }
                    : {}),

                  activeGpid,

                  capturedAt,
                },
              });
          }

          await tx.deviceSession.update({
            where: {
              id:
                deviceSessionId,
            },
            data: {
              lastSeenAt:
                serverNow,

              trackingStatus:
                "LOCATION_ACTIVE",
            },
          });

          await tx.userSession.update({
            where: {
              id:
                userSessionId,
            },
            data: {
              lastSeenAt:
                serverNow,
            },
          });

          return {
            history,
            currentLocation,
          };
        },
      );

    return NextResponse.json(
      {
        success: true,

        userSessionId,
        deviceSessionId,
        userId,

        locationHistoryId:
          result.history.id,

        latitude,
        longitude,
        accuracy,

        activeGpid,

        eventType,
        activityStatus:
          activityStatus ??
          result.currentLocation
            ?.activityStatus ??
          null,

        locationSource,

        capturedAt,

        receivedAt:
          result.history
            .receivedAt,

        currentLocationUpdated:
          shouldUpdateCurrent,

        currentLocation:
          result.currentLocation
            ? {
                latitude:
                  result.currentLocation
                    .latitude,
                longitude:
                  result.currentLocation
                    .longitude,
                accuracy:
                  result.currentLocation
                    .accuracy,
                activeGpid:
                  result.currentLocation
                    .activeGpid,
                activityStatus:
                  result.currentLocation
                    .activityStatus,
                capturedAt:
                  result.currentLocation
                    .capturedAt,
              }
            : null,
      },
      {
        status: 201,
      },
    );
  } catch (error) {
    console.error(
      "Tracking location POST error:",
      error,
    );

    return NextResponse.json(
      {
        success: false,
        error:
          "Unable to save tracking location.",
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