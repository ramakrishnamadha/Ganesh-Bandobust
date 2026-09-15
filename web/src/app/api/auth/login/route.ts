import {
  createHmac,
  scryptSync,
  timingSafeEqual,
} from "node:crypto";

import { prisma } from "@/lib/prisma";

import {
  NextRequest,
  NextResponse,
} from "next/server";

const SESSION_COOKIE_NAME = "ganesh_web_session";

const SESSION_DURATION_SECONDS = 8 * 60 * 60;

type WebSessionPayload = {
  userId: string;
  employeeId: string;
  username: string;

  officerName: string;
  rank: string;

  role: string;
  accessLevel: number;

  commissionerateCode: string;
  commissionerateName: string;

  rangeCode: string;
  rangeName: string;

  zoneCode: string;
  zoneName: string;

  divisionCode: string;
  divisionName: string;

  policeStationCode: string;
  policeStationName: string;

  sectorCode: string;
  sectorName: string;

  policeStation: string;
  sector: string;

  canViewLiveTracking: boolean;
  mustChangePassword: boolean;

  issuedAt: number;
  expiresAt: number;
};

function getSessionSecret(): string {
  const secret = process.env.GANESH_WEB_SESSION_SECRET;

  if (!secret || secret.trim().length < 32) {
    throw new Error(
      "GANESH_WEB_SESSION_SECRET must be configured with at least 32 characters.",
    );
  }

  return secret;
}

function encodePayload(payload: WebSessionPayload): string {
  return Buffer.from(
    JSON.stringify(payload),
    "utf8",
  ).toString("base64url");
}

function signPayload(encodedPayload: string): string {
  return createHmac(
    "sha256",
    getSessionSecret(),
  )
    .update(encodedPayload)
    .digest("base64url");
}

function createSessionToken(
  payload: WebSessionPayload,
): string {
  const encodedPayload = encodePayload(payload);

  const signature = signPayload(
    encodedPayload,
  );

  return `${encodedPayload}.${signature}`;
}

function verifyPassword(
  password: string,
  storedPasswordHash: string,
): boolean {
  try {
    const parts =
      storedPasswordHash.split("$");

    if (
      parts.length !== 3 ||
      parts[0] !== "scrypt"
    ) {
      return false;
    }

    const salt = parts[1];

    const storedHashHex =
      parts[2];

    if (
      !salt ||
      !storedHashHex
    ) {
      return false;
    }

    const storedHash =
      Buffer.from(
        storedHashHex,
        "hex",
      );

    if (
      storedHash.length === 0
    ) {
      return false;
    }

    const calculatedHash =
      scryptSync(
        password,
        salt,
        storedHash.length,
      );

    if (
      calculatedHash.length !==
      storedHash.length
    ) {
      return false;
    }

    return timingSafeEqual(
      calculatedHash,
      storedHash,
    );
  } catch {
    return false;
  }
}

function canViewLiveTracking(
  role: string,
): boolean {
  return role === "ADMIN";
}

export async function POST(
  request: NextRequest,
) {
  try {
    let body: Record<string, unknown>;

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

    const username = String(
      body.username ?? "",
    ).trim();

    const password = String(
      body.password ?? "",
    );

    if (
      username.length === 0 ||
      password.length === 0
    ) {
      return NextResponse.json(
        {
          success: false,
          error:
            "Username and password are required.",
        },
        {
          status: 400,
        },
      );
    }

    const user =
      await prisma.user.findUnique({
        where: {
          username,
        },

        include: {
          policeStationAccesses: {
            where: {
              canView: true,
            },

            orderBy: {
              policeStationName:
                "asc",
            },
          },
        },
      });

    if (!user) {
      return NextResponse.json(
        {
          success: false,
          error:
            "Invalid username or password.",
        },
        {
          status: 401,
        },
      );
    }

    if (
      user.status !== "ACTIVE"
    ) {
      return NextResponse.json(
        {
          success: false,
          error:
            "This user account is inactive. Please contact the administrator.",
        },
        {
          status: 403,
        },
      );
    }

    const passwordValid =
      verifyPassword(
        password,
        user.passwordHash,
      );

    if (!passwordValid) {
      return NextResponse.json(
        {
          success: false,
          error:
            "Invalid username or password.",
        },
        {
          status: 401,
        },
      );
    }

    const now = Math.floor(
      Date.now() / 1000,
    );

    const liveTrackingAccess =
      canViewLiveTracking(
        user.role,
      );

    const allowedPoliceStations =
      user.policeStationAccesses.map(
        (access) => ({
          id: access.id,

          policeStationCode:
            access.policeStationCode,

          policeStationName:
            access.policeStationName,

          canView:
            access.canView,

          canEdit:
            access.canEdit,
        }),
      );

    const sessionPayload: WebSessionPayload = {
      userId:
        user.id,

      employeeId:
        user.employeeId,

      username:
        user.username,

      officerName:
        user.name,

      rank:
        user.rank,

      role:
        user.role,

      accessLevel:
        user.accessLevel,

      commissionerateCode:
        user.commissionerateCode ??
        "",

      commissionerateName:
        user.commissionerateName ??
        "",

      rangeCode:
        user.rangeCode ??
        "",

      rangeName:
        user.rangeName ??
        "",

      zoneCode:
        user.zoneCode ??
        "",

      zoneName:
        user.zoneName ??
        "",

      divisionCode:
        user.divisionCode ??
        "",

      divisionName:
        user.divisionName ??
        "",

      policeStationCode:
        user.policeStationCode ??
        "",

      policeStationName:
        user.policeStationName ??
        "",

      sectorCode:
        user.sectorCode ??
        "",

      sectorName:
        user.sectorName ??
        "",

      policeStation:
        user.policeStationName ??
        "",

      sector:
        user.sectorName ??
        user.sectorCode ??
        "",

      canViewLiveTracking:
        liveTrackingAccess,

      mustChangePassword:
        user.mustChangePassword,

      issuedAt:
        now,

      expiresAt:
        now +
        SESSION_DURATION_SECONDS,
    };

    const sessionToken =
      createSessionToken(
        sessionPayload,
      );

    await prisma.userSession.create({
      data: {
        userId:
          user.id,

        userName:
          user.name,

        rank:
          user.rank,

        role:
          user.role,

        source:
          "WEB",

        commissionerateCode:
          user.commissionerateCode,

        rangeCode:
          user.rangeCode,

        zoneCode:
          user.zoneCode,

        divisionCode:
          user.divisionCode,

        policeStationCode:
          user.policeStationCode,

        sectorCode:
          user.sectorCode,

        status:
          "ACTIVE",
      },
    });

    const response =
      NextResponse.json(
        {
          success: true,

          user: {
            id:
              user.id,

            employeeId:
              user.employeeId,

            username:
              user.username,

            officerName:
              user.name,

            rank:
              user.rank,

            phoneNumber:
              user.phoneNumber,

            team:
              user.team,

            role:
              user.role,

            accessLevel:
              user.accessLevel,

            jurisdiction: {
              commissionerateCode:
                user.commissionerateCode,

              commissionerateName:
                user.commissionerateName,

              rangeCode:
                user.rangeCode,

              rangeName:
                user.rangeName,

              zoneCode:
                user.zoneCode,

              zoneName:
                user.zoneName,

              divisionCode:
                user.divisionCode,

              divisionName:
                user.divisionName,

              policeStationCode:
                user.policeStationCode,

              policeStationName:
                user.policeStationName,

              sectorCode:
                user.sectorCode,

              sectorName:
                user.sectorName,

              allPoliceStations:
                user.allPoliceStations,

              allDivisions:
                user.allDivisions,

              allZones:
                user.allZones,

              allRanges:
                user.allRanges,

              allowedPoliceStations,
            },

            canViewLiveTracking:
              liveTrackingAccess,

            mustChangePassword:
              user.mustChangePassword,
          },

          requiresPasswordChange:
            user.mustChangePassword,
        },
        {
          status: 200,
        },
      );

    response.cookies.set(
      SESSION_COOKIE_NAME,
      sessionToken,
      {
        httpOnly:
          true,

        sameSite:
          "lax",

        secure:
          process.env.NODE_ENV ===
          "production",

        path:
          "/",

        maxAge:
          SESSION_DURATION_SECONDS,
      },
    );

    return response;
  } catch (error) {
    console.error(
      "Web login error:",
      error,
    );

    return NextResponse.json(
      {
        success: false,

        error:
          "Unable to complete login.",

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