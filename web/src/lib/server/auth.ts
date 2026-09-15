 import {
  createHmac,
  timingSafeEqual,
} from "crypto";

import { NextRequest } from "next/server";

export const SESSION_COOKIE_NAME =
  "ganesh_web_session";

export type WebSessionPayload = {
  userId: string;
  employeeId: string;
  username: string;

  officerName: string;
  rank: string;

  role: string;
  accessLevel: number;

  commissionerateCode:
    | string
    | null;

  commissionerateName:
    | string
    | null;

  rangeCode:
    | string
    | null;

  rangeName:
    | string
    | null;

  zoneCode:
    | string
    | null;

  zoneName:
    | string
    | null;

  divisionCode:
    | string
    | null;

  divisionName:
    | string
    | null;

  policeStationCode:
    | string
    | null;

  policeStationName:
    | string
    | null;

  sectorCode:
    | string
    | null;

  sectorName:
    | string
    | null;

  /*
   * Compatibility fields used by
   * existing screens and API code.
   */
  policeStation: string;
  sector: string;

  canViewLiveTracking: boolean;

  mustChangePassword: boolean;

  /*
   * UNIX timestamps in SECONDS.
   */
  issuedAt: number;
  expiresAt: number;
};

function getSessionSecret(): string {
  const secret =
    process.env
      .GANESH_WEB_SESSION_SECRET;

  if (
    !secret ||
    secret.trim().length < 32
  ) {
    throw new Error(
      "GANESH_WEB_SESSION_SECRET must be configured and contain at least 32 characters.",
    );
  }

  return secret;
}

function sign(
  encodedPayload: string,
): string {
  return createHmac(
    "sha256",
    getSessionSecret(),
  )
    .update(encodedPayload)
    .digest("base64url");
}

function decodePayload(
  encodedPayload: string,
): WebSessionPayload | null {
  try {
    const json =
      Buffer.from(
        encodedPayload,
        "base64url",
      ).toString("utf8");

    const value =
      JSON.parse(
        json,
      ) as Partial<WebSessionPayload>;

    if (
      typeof value.userId !==
        "string" ||
      typeof value.employeeId !==
        "string" ||
      typeof value.username !==
        "string" ||
      typeof value.officerName !==
        "string" ||
      typeof value.rank !==
        "string" ||
      typeof value.role !==
        "string" ||
      typeof value.accessLevel !==
        "number" ||
      typeof value.policeStation !==
        "string" ||
      typeof value.sector !==
        "string" ||
      typeof value.canViewLiveTracking !==
        "boolean" ||
      typeof value.mustChangePassword !==
        "boolean" ||
      typeof value.issuedAt !==
        "number" ||
      typeof value.expiresAt !==
        "number"
    ) {
      return null;
    }

    return {
      userId:
        value.userId,

      employeeId:
        value.employeeId,

      username:
        value.username,

      officerName:
        value.officerName,

      rank:
        value.rank,

      role:
        value.role,

      accessLevel:
        value.accessLevel,

      commissionerateCode:
        typeof value
          .commissionerateCode ===
        "string"
          ? value
              .commissionerateCode
          : null,

      commissionerateName:
        typeof value
          .commissionerateName ===
        "string"
          ? value
              .commissionerateName
          : null,

      rangeCode:
        typeof value.rangeCode ===
        "string"
          ? value.rangeCode
          : null,

      rangeName:
        typeof value.rangeName ===
        "string"
          ? value.rangeName
          : null,

      zoneCode:
        typeof value.zoneCode ===
        "string"
          ? value.zoneCode
          : null,

      zoneName:
        typeof value.zoneName ===
        "string"
          ? value.zoneName
          : null,

      divisionCode:
        typeof value.divisionCode ===
        "string"
          ? value.divisionCode
          : null,

      divisionName:
        typeof value.divisionName ===
        "string"
          ? value.divisionName
          : null,

      policeStationCode:
        typeof value
          .policeStationCode ===
        "string"
          ? value
              .policeStationCode
          : null,

      policeStationName:
        typeof value
          .policeStationName ===
        "string"
          ? value
              .policeStationName
          : value.policeStation,

      sectorCode:
        typeof value.sectorCode ===
        "string"
          ? value.sectorCode
          : null,

      sectorName:
        typeof value.sectorName ===
        "string"
          ? value.sectorName
          : value.sector,

      policeStation:
        value.policeStation,

      sector:
        value.sector,

      canViewLiveTracking:
        value.canViewLiveTracking,

      mustChangePassword:
        value.mustChangePassword,

      issuedAt:
        value.issuedAt,

      expiresAt:
        value.expiresAt,
    };
  } catch {
    return null;
  }
}

export function verifySessionToken(
  token: string | undefined,
): WebSessionPayload | null {
  if (!token) {
    return null;
  }

  const separatorIndex =
    token.lastIndexOf(".");

  if (
    separatorIndex <= 0
  ) {
    return null;
  }

  const encodedPayload =
    token.slice(
      0,
      separatorIndex,
    );

  const providedSignature =
    token.slice(
      separatorIndex + 1,
    );

  if (
    !encodedPayload ||
    !providedSignature
  ) {
    return null;
  }

  const expectedSignature =
    sign(encodedPayload);

  const providedBuffer =
    Buffer.from(
      providedSignature,
    );

  const expectedBuffer =
    Buffer.from(
      expectedSignature,
    );

  if (
    providedBuffer.length !==
    expectedBuffer.length
  ) {
    return null;
  }

  if (
    !timingSafeEqual(
      providedBuffer,
      expectedBuffer,
    )
  ) {
    return null;
  }

  const session =
    decodePayload(
      encodedPayload,
    );

  if (!session) {
    return null;
  }

  /*
   * IMPORTANT:
   *
   * Login creates issuedAt and expiresAt
   * as UNIX timestamps in SECONDS.
   *
   * Date.now() returns MILLISECONDS.
   *
   * Therefore convert Date.now()
   * to seconds before comparison.
   */
  const currentUnixTime =
    Math.floor(
      Date.now() / 1000,
    );

  if (
    currentUnixTime >=
    session.expiresAt
  ) {
    return null;
  }

  return session;
}

export function getWebSession(
  request: NextRequest,
): WebSessionPayload | null {
  const token =
    request.cookies.get(
      SESSION_COOKIE_NAME,
    )?.value;

  return verifySessionToken(
    token,
  );
}

export function hasAccessLevel(
  session:
    | WebSessionPayload
    | null,
  requiredLevel: number,
): boolean {
  if (!session) {
    return false;
  }

  return (
    session.accessLevel >=
    requiredLevel
  );
}

export function canViewLiveTracking(
  session:
    | WebSessionPayload
    | null,
): boolean {
  if (!session) {
    return false;
  }

  return (
    session.role === "ADMIN" &&
    session.accessLevel === 7 &&
    session
      .canViewLiveTracking ===
      true
  );
}

export function requiresPasswordChange(
  session:
    | WebSessionPayload
    | null,
): boolean {
  return (
    session
      ?.mustChangePassword ===
    true
  );
}