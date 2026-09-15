import {
  randomBytes,
  scryptSync,
  timingSafeEqual,
} from "node:crypto";

import {
  NextRequest,
  NextResponse,
} from "next/server";

import { prisma } from "@/lib/prisma";

import {
  getWebSession,
} from "@/lib/server/auth";

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

function hashPassword(
  password: string,
): string {
  const salt =
    randomBytes(16).toString(
      "hex",
    );

  const derivedKey =
    scryptSync(
      password,
      salt,
      64,
    );

  return [
    "scrypt",
    salt,
    derivedKey.toString("hex"),
  ].join("$");
}

export async function POST(
  request: NextRequest,
) {
  try {
    const session =
      getWebSession(request);

    if (!session) {
      return NextResponse.json(
        {
          success: false,
          error:
            "Your login session is invalid or has expired. Please login again.",
        },
        {
          status: 401,
        },
      );
    }

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

    const currentPassword =
      String(
        body.currentPassword ??
          "",
      );

    const newPassword =
      String(
        body.newPassword ??
          "",
      );

    if (
      currentPassword.length ===
        0 ||
      newPassword.length === 0
    ) {
      return NextResponse.json(
        {
          success: false,
          error:
            "Current password and new password are required.",
        },
        {
          status: 400,
        },
      );
    }

    if (
      newPassword.length < 8
    ) {
      return NextResponse.json(
        {
          success: false,
          error:
            "New password must contain at least 8 characters.",
        },
        {
          status: 400,
        },
      );
    }

    if (
      currentPassword ===
      newPassword
    ) {
      return NextResponse.json(
        {
          success: false,
          error:
            "New password must be different from the current password.",
        },
        {
          status: 400,
        },
      );
    }

    const user =
      await prisma.user.findUnique({
        where: {
          username:
            session.username,
        },
      });

    if (!user) {
      return NextResponse.json(
        {
          success: false,
          error:
            "User account could not be found.",
        },
        {
          status: 404,
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

    const currentPasswordValid =
      verifyPassword(
        currentPassword,
        user.passwordHash,
      );

    if (
      !currentPasswordValid
    ) {
      return NextResponse.json(
        {
          success: false,
          error:
            "Current password is incorrect.",
        },
        {
          status: 401,
        },
      );
    }

    const newPasswordHash =
      hashPassword(
        newPassword,
      );

    await prisma.user.update({
      where: {
        id: user.id,
      },

      data: {
        passwordHash:
          newPasswordHash,

        mustChangePassword:
          false,

        lastPasswordChangedAt:
          new Date(),
      },
    });

    await prisma.activityEvent.create({
      data: {
        userId:
          user.id,

        source:
          "WEB",

        eventType:
          "PASSWORD_CHANGED",

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

        metadata: {
          firstLoginPasswordChange:
            user.mustChangePassword,
        },

        occurredAt:
          new Date(),
      },
    });

    return NextResponse.json(
      {
        success: true,
        message:
          "Password changed successfully.",
      },
      {
        status: 200,
      },
    );
  } catch (error) {
    console.error(
      "Change password error:",
      error,
    );

    return NextResponse.json(
      {
        success: false,
        error:
          "Unable to change password.",

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