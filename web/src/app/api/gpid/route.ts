import {
  createHmac,
  timingSafeEqual,
} from "node:crypto";

import {
  NextRequest,
  NextResponse,
} from "next/server";

import { prisma } from "@/lib/prisma";

const GANESH_API_URL =
  "https://policeportal.tspolice.gov.in/ganesh/getGanaDetails/22";

const SESSION_COOKIE_NAME =
  "ganesh_web_session";

const UPSTREAM_TIMEOUT_MS =
  90000;

type GaneshRecord =
  Record<string, unknown>;

type WebSessionPayload = {
  userId: string;
  expiresAt: number;
  [key: string]: unknown;
};

let lastSuccessfulData:
  GaneshRecord[] | null = null;

let lastSuccessfulAt:
  string | null = null;

function getSessionSecret(): string {
  const secret =
    process.env
      .GANESH_WEB_SESSION_SECRET;

  if (
    !secret ||
    secret.trim().length < 32
  ) {
    throw new Error(
      "GANESH_WEB_SESSION_SECRET must be configured with at least 32 characters.",
    );
  }

  return secret;
}

function signPayload(
  encodedPayload: string,
): string {
  return createHmac(
    "sha256",
    getSessionSecret(),
  )
    .update(encodedPayload)
    .digest("base64url");
}

function verifySessionToken(
  token: string,
): WebSessionPayload | null {
  try {
    const parts =
      token.split(".");

    if (parts.length !== 2) {
      return null;
    }

    const encodedPayload =
      parts[0];

    const suppliedSignature =
      parts[1];

    if (
      !encodedPayload ||
      !suppliedSignature
    ) {
      return null;
    }

    const expectedSignature =
      signPayload(
        encodedPayload,
      );

    const suppliedBuffer =
      Buffer.from(
        suppliedSignature,
        "utf8",
      );

    const expectedBuffer =
      Buffer.from(
        expectedSignature,
        "utf8",
      );

    if (
      suppliedBuffer.length !==
      expectedBuffer.length
    ) {
      return null;
    }

    if (
      !timingSafeEqual(
        suppliedBuffer,
        expectedBuffer,
      )
    ) {
      return null;
    }

    const decoded =
      Buffer.from(
        encodedPayload,
        "base64url",
      ).toString("utf8");

    const payload =
      JSON.parse(
        decoded,
      ) as WebSessionPayload;

    if (
      !payload ||
      typeof payload !==
        "object"
    ) {
      return null;
    }

    if (
      typeof payload.userId !==
        "string" ||
      payload.userId.trim()
        .length === 0
    ) {
      return null;
    }

    if (
      typeof payload.expiresAt !==
        "number"
    ) {
      return null;
    }

    const now =
      Math.floor(
        Date.now() / 1000,
      );

    if (
      payload.expiresAt <= now
    ) {
      return null;
    }

    return payload;
  } catch {
    return null;
  }
}

function text(
  value: unknown,
): string {
  if (
    value === null ||
    value === undefined
  ) {
    return "";
  }

  const result =
    String(value).trim();

  if (
    result.length === 0 ||
    result.toLowerCase() ===
      "null"
  ) {
    return "";
  }

  return result;
}

function normalizeAccessName(
  value: unknown,
): string {
  let normalized =
    text(value)
      .toLowerCase()
      .replace(/\s+/g, " ")
      .trim();

  normalized =
    normalized.replace(
      /\s+ps$/i,
      "",
    );

  return normalized.trim();
}

function sameAccessName(
  left: unknown,
  right: unknown,
): boolean {
  const a =
    normalizeAccessName(
      left,
    );

  const b =
    normalizeAccessName(
      right,
    );

  return (
    a.length > 0 &&
    a === b
  );
}

function filterValidRecords(
  data: unknown[],
): GaneshRecord[] {
  return data.filter(
    (
      item,
    ): item is GaneshRecord => {
      if (
        typeof item !==
          "object" ||
        item === null
      ) {
        return false;
      }

      const record =
        item as GaneshRecord;

      return (
        text(
          record.unique_id,
        ).length > 0
      );
    },
  );
}

function filterRecordsForUser(
  records: GaneshRecord[],
  user: {
    role: string;

    zoneName:
      string | null;

    divisionName:
      string | null;

    policeStationName:
      string | null;

    allPoliceStations:
      boolean;

    allZones:
      boolean;

    policeStationAccesses: Array<{
      policeStationName: string;
      canView: boolean;
    }>;
  },
): GaneshRecord[] {
  if (
    user.role === "ADMIN" ||
    user.allZones
  ) {
    return records;
  }

  if (
    user.allPoliceStations
  ) {
    if (
      text(
        user.zoneName,
      ).length > 0
    ) {
      return records.filter(
        (record) =>
          sameAccessName(
            record.zone_name,
            user.zoneName,
          ),
      );
    }

    if (
      text(
        user.divisionName,
      ).length > 0
    ) {
      return records.filter(
        (record) =>
          sameAccessName(
            record.division_name,
            user.divisionName,
          ),
      );
    }

    if (
      text(
        user.policeStationName,
      ).length > 0
    ) {
      return records.filter(
        (record) =>
          sameAccessName(
            record.ps_name,
            user.policeStationName,
          ),
      );
    }

    return [];
  }

  const allowedPoliceStations =
    new Set(
      user.policeStationAccesses
        .filter(
          (access) =>
            access.canView,
        )
        .map(
          (access) =>
            normalizeAccessName(
              access
                .policeStationName,
            ),
        )
        .filter(
          (name) =>
            name.length > 0,
        ),
    );

  if (
    allowedPoliceStations.size ===
    0
  ) {
    return [];
  }

  return records.filter(
    (record) =>
      allowedPoliceStations.has(
        normalizeAccessName(
          record.ps_name,
        ),
      ),
  );
}

function jsonRecordsResponse(
  records: GaneshRecord[],
  source:
    | "live"
    | "fallback-cache",
): NextResponse {
  return NextResponse.json(
    records,
    {
      status: 200,
      headers: {
        "Cache-Control":
          "no-store",
        "X-GPID-Data-Source":
          source,
        "X-GPID-Last-Successful-At":
          lastSuccessfulAt ?? "",
      },
    },
  );
}

export async function GET(
  request: NextRequest,
) {
  try {
    const sessionToken =
      request.cookies.get(
        SESSION_COOKIE_NAME,
      )?.value;

    if (!sessionToken) {
      return NextResponse.json(
        {
          error:
            "Authentication required.",
        },
        {
          status: 401,
        },
      );
    }

    const session =
      verifySessionToken(
        sessionToken,
      );

    if (!session) {
      return NextResponse.json(
        {
          error:
            "Invalid or expired session.",
        },
        {
          status: 401,
        },
      );
    }

    const user =
      await prisma.user.findUnique({
        where: {
          id: session.userId,
        },
        include: {
          policeStationAccesses: {
            where: {
              canView: true,
            },
            select: {
              policeStationName:
                true,
              canView:
                true,
            },
          },
        },
      });

    if (!user) {
      return NextResponse.json(
        {
          error:
            "User account not found.",
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
          error:
            "This user account is inactive.",
        },
        {
          status: 403,
        },
      );
    }

    const controller =
      new AbortController();

    const timeout =
      setTimeout(
        () => {
          controller.abort();
        },
        UPSTREAM_TIMEOUT_MS,
      );

    try {
      const response =
        await fetch(
          GANESH_API_URL,
          {
            method: "POST",
            cache: "no-store",
            signal:
              controller.signal,
          },
        );

      if (!response.ok) {
        console.error(
          `Ganesh upstream returned status ${response.status}`,
        );

        if (
          lastSuccessfulData
        ) {
          const permittedRecords =
            filterRecordsForUser(
              lastSuccessfulData,
              user,
            );

          return jsonRecordsResponse(
            permittedRecords,
            "fallback-cache",
          );
        }

        return NextResponse.json(
          {
            error:
              "Failed to load Ganesh records",
            upstreamStatus:
              response.status,
            fallbackAvailable:
              false,
          },
          {
            status: 503,
          },
        );
      }

      const data: unknown =
        await response.json();

      if (
        !Array.isArray(data)
      ) {
        console.error(
          "Ganesh upstream response was not an array.",
        );

        if (
          lastSuccessfulData
        ) {
          const permittedRecords =
            filterRecordsForUser(
              lastSuccessfulData,
              user,
            );

          return jsonRecordsResponse(
            permittedRecords,
            "fallback-cache",
          );
        }

        return NextResponse.json(
          {
            error:
              "Unexpected Ganesh API response",
            fallbackAvailable:
              false,
          },
          {
            status: 502,
          },
        );
      }

      const validRecords =
        filterValidRecords(
          data,
        );

      lastSuccessfulData =
        validRecords;

      lastSuccessfulAt =
        new Date().toISOString();

      const permittedRecords =
        filterRecordsForUser(
          validRecords,
          user,
        );

      return jsonRecordsResponse(
        permittedRecords,
        "live",
      );
    } catch (error) {
      console.error(
        "Ganesh upstream fetch error:",
        error,
      );

      if (
        lastSuccessfulData
      ) {
        const permittedRecords =
          filterRecordsForUser(
            lastSuccessfulData,
            user,
          );

        return jsonRecordsResponse(
          permittedRecords,
          "fallback-cache",
        );
      }

      return NextResponse.json(
        {
          error:
            error instanceof Error &&
            error.name === "AbortError"
              ? "Ganesh master API timed out."
              : "Unable to connect to Ganesh master API.",
          fallbackAvailable:
            false,
        },
        {
          status: 503,
        },
      );
    } finally {
      clearTimeout(
        timeout,
      );
    }
  } catch (error) {
    console.error(
      "GPID proxy error:",
      error,
    );

    return NextResponse.json(
      {
        error:
          "Unable to load GPID records.",
      },
      {
        status: 503,
      },
    );
  }
}