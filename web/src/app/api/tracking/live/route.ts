import { NextRequest, NextResponse } from "next/server";

import { prisma } from "@/lib/prisma";

import {
  canViewLiveTracking,
  getWebSession,
} from "@/lib/server/auth";

export async function GET(
  request: NextRequest,
) {
  try {
    const session =
      getWebSession(request);

    if (!session) {
      return NextResponse.json(
        {
          success: false,
          error: "Unauthorized.",
        },
        {
          status: 401,
        },
      );
    }

    if (
      !canViewLiveTracking(
        session,
      )
    ) {
      return NextResponse.json(
        {
          success: false,
          error:
            "You are not authorized to view live tracking.",
        },
        {
          status: 403,
        },
      );
    }

    const now =
      new Date();

    const fiveMinutesAgo =
      new Date(
        now.getTime() -
          5 * 60 * 1000,
      );

    const locations =
      await prisma.officerCurrentLocation.findMany({
        include: {
          deviceSession: {
            include: {
              userSession: true,
            },
          },
        },

        orderBy: {
          capturedAt: "desc",
        },
      });

    /*
     * OfficerCurrentLocation may contain current-location rows
     * belonging to multiple historical device sessions for the
     * same officer.
     *
     * The live GIS must show only one marker per officer.
     *
     * Because the query above is ordered by capturedAt DESC,
     * the first row encountered for a userId is that officer's
     * latest known current position.
     *
     * Older session rows remain untouched in the database.
     */
    const seenUserIds =
      new Set<string>();

    const latestLocations =
      locations.filter((item) => {
        if (
          seenUserIds.has(
            item.userId,
          )
        ) {
          return false;
        }

        seenUserIds.add(
          item.userId,
        );

        return true;
      });

    const officers =
      latestLocations.map(
        (item) => {
          const device =
            item.deviceSession;

          const userSession =
            device.userSession;

          const isRecentlySeen =
            device.lastSeenAt >=
            fiveMinutesAgo;

          const sessionActive =
            userSession.status ===
              "ACTIVE" &&
            device.endedAt === null;

          let liveStatus:
            | "ACTIVE"
            | "STALE"
            | "OFFLINE";

          if (
            sessionActive &&
            isRecentlySeen &&
            device.trackingEnabled
          ) {
            liveStatus = "ACTIVE";
          } else if (
            sessionActive
          ) {
            liveStatus = "STALE";
          } else {
            liveStatus = "OFFLINE";
          }

          return {
            userId:
              item.userId,

            userName:
              userSession.userName,

            rank:
              userSession.rank,

            role:
              userSession.role,

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

            deviceSessionId:
              device.id,

            deviceType:
              device.deviceType,

            deviceName:
              device.deviceName,

            manufacturer:
              device.manufacturer,

            model:
              device.model,

            platform:
              device.platform,

            osVersion:
              device.osVersion,

            trackingEnabled:
              device.trackingEnabled,

            trackingStatus:
              device.trackingStatus,

            liveStatus,

            latitude:
              item.latitude,

            longitude:
              item.longitude,

            accuracy:
              item.accuracy,

            speed:
              item.speed,

            heading:
              item.heading,

            batteryLevel:
              item.batteryLevel,

            locationSource:
              item.locationSource,

            activityStatus:
              item.activityStatus,

            activeGpid:
              item.activeGpid,

            capturedAt:
              item.capturedAt,

            locationUpdatedAt:
              item.updatedAt,

            lastSeenAt:
              device.lastSeenAt,

            loginAt:
              userSession.loginAt,
          };
        },
      );

    const summary = {
      total:
        officers.length,

      active:
        officers.filter(
          (item) =>
            item.liveStatus ===
            "ACTIVE",
        ).length,

      stale:
        officers.filter(
          (item) =>
            item.liveStatus ===
            "STALE",
        ).length,

      offline:
        officers.filter(
          (item) =>
            item.liveStatus ===
            "OFFLINE",
        ).length,

      verifying:
        officers.filter(
          (item) =>
            item.activityStatus ===
            "VERIFYING",
        ).length,
    };

    return NextResponse.json({
      success: true,

      viewer: {
        username:
          session.username,

        role:
          session.role,

        canViewLiveTracking:
          session
            .canViewLiveTracking,
      },

      generatedAt: now,

      summary,

      officers,
    });
  } catch (error) {
    console.error(
      "Live tracking GET error:",
      error,
    );

    return NextResponse.json(
      {
        success: false,
        error:
          "Unable to load live tracking data.",
        details:
          process.env.NODE_ENV ===
          "development"
            ? error instanceof Error
              ? error.message
              : String(error)
            : undefined,
      },
      {
        status: 500,
      },
    );
  }
}