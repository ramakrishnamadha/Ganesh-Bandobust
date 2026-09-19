import { NextRequest } from "next/server";

import { prisma } from "@/lib/prisma";

import {
  getWebSession,
} from "@/lib/server/auth";

const GANESH_API_URL =
  "https://policeportal.tspolice.gov.in/ganesh/getGanaDetails/22";

const UPSTREAM_TIMEOUT_MS = 90000;

const GPID_CACHE_TTL_MS =
  5 * 60 * 1000;

const MODULE_KEYS = [
  "locationResult",
  "mandapResult",
  "idolResult",
  "routeResult",
  "securityResult",
  "organizerResult",
  "interDepartmentalResult",
  "permissionShoReviewResult",
] as const;

type VerificationPayload = {
  gpid?: unknown;
  applicationId?: unknown;

  locationResult?: unknown;
  mandapResult?: unknown;
  idolResult?: unknown;
  routeResult?: unknown;
  securityResult?: unknown;
  organizerResult?: unknown;
  interDepartmentalResult?: unknown;
  permissionShoReviewResult?: unknown;

  verificationStatus?: unknown;
};

type JsonObject =
  Record<string, unknown>;

type GaneshRecord =
  Record<string, unknown>;

type AccessMode =
  | "view"
  | "edit";

type UserAccess = {
  id: string;

  role: string;

  status: string;

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

    canEdit: boolean;
  }>;
};

let lastSuccessfulGpidData:
  GaneshRecord[] | null = null;

let lastSuccessfulGpidAt:
  number | null = null;

function hasOwn(
  object: object,
  key: PropertyKey,
): boolean {
  return Object.prototype.hasOwnProperty.call(
    object,
    key,
  );
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

function countCompletedModules(
  data: Record<string, unknown>,
): number {
  return MODULE_KEYS.filter(
    (key) =>
      data[key] !== null &&
      data[key] !== undefined,
  ).length;
}

function getAutomaticStatus(
  data: Record<string, unknown>,
): string {
  const completed =
    countCompletedModules(
      data,
    );

  if (completed === 8) {
    return "COMPLETED";
  }

  if (completed > 0) {
    return "IN_PROGRESS";
  }

  return "PENDING";
}

function canViewConfidentialVerification(
  role: string,
): boolean {
  return (
    role === "ADMIN" ||
    role === "SHO"
  );
}

function redactOrganizerResult(
  value: unknown,
): unknown {
  if (!isObject(value)) {
    return value;
  }

  const cloned: JsonObject = {
    ...value,
  };

  const organizers =
    Array.isArray(
      value.organizers,
    )
      ? value.organizers
      : [];

  cloned.organizers =
    organizers.map(
      (item) => {
        if (!isObject(item)) {
          return item;
        }

        return {
          ...item,

          adverseInformation:
            null,

          adverseCases:
            [],

          confidentialDataRestricted:
            true,
        };
      },
    );

  cloned.confidentialDataRestricted =
    true;

  return cloned;
}

function isConfidentialFinding(
  item: unknown,
): boolean {
  if (!isObject(item)) {
    return false;
  }

  const finding =
    typeof item.finding ===
    "string"
      ? item.finding
          .trim()
          .toUpperCase()
      : "";

  return finding.startsWith(
    "CONFIDENTIAL:",
  );
}

function redactInterDepartmentalResult(
  value: unknown,
): unknown {
  if (!isObject(value)) {
    return value;
  }

  const cloned: JsonObject = {
    ...value,
  };

  const requirements =
    Array.isArray(
      value.autoIdentifiedRequirements,
    )
      ? value.autoIdentifiedRequirements
      : [];

  cloned.autoIdentifiedRequirements =
    requirements.filter(
      (item) =>
        !isConfidentialFinding(
          item,
        ),
    );

  cloned.confidentialDataRestricted =
    true;

  return cloned;
}

function redactRecordForRole(
  record: Record<
    string,
    unknown
  >,
  role: string,
): Record<string, unknown> {
  if (
    canViewConfidentialVerification(
      role,
    )
  ) {
    return record;
  }

  return {
    ...record,

    organizerResult:
      redactOrganizerResult(
        record.organizerResult,
      ),

    interDepartmentalResult:
      redactInterDepartmentalResult(
        record
          .interDepartmentalResult,
      ),
  };
}

async function getCurrentUser(
  userId: string,
): Promise<UserAccess | null> {
  const user =
    await prisma.user.findUnique({
      where: {
        id: userId,
      },

      select: {
        id: true,

        role: true,

        status: true,

        zoneName: true,

        divisionName: true,

        policeStationName:
          true,

        allPoliceStations:
          true,

        allZones:
          true,

        policeStationAccesses: {
          select: {
            policeStationName:
              true,

            canView:
              true,

            canEdit:
              true,
          },
        },
      },
    });

  return user;
}

function isGlobalAccess(
  user: UserAccess,
): boolean {
  return (
    user.role === "ADMIN" ||
    user.allZones
  );
}

function hasRecordAccess(
  record: GaneshRecord,
  user: UserAccess,
  mode: AccessMode,
): boolean {
  if (
    isGlobalAccess(
      user,
    )
  ) {
    return true;
  }

  if (
    user.allPoliceStations
  ) {
    if (
      text(
        user.zoneName,
      ).length > 0
    ) {
      return sameAccessName(
        record.zone_name,
        user.zoneName,
      );
    }

    if (
      text(
        user.divisionName,
      ).length > 0
    ) {
      return sameAccessName(
        record.division_name,
        user.divisionName,
      );
    }

    if (
      text(
        user.policeStationName,
      ).length > 0
    ) {
      return sameAccessName(
        record.ps_name,
        user.policeStationName,
      );
    }

    return false;
  }

  const recordPoliceStation =
    normalizeAccessName(
      record.ps_name,
    );

  if (
    recordPoliceStation.length ===
    0
  ) {
    return false;
  }

  return user
    .policeStationAccesses
    .some(
      (access) => {
        const permitted =
          mode === "edit"
            ? access.canEdit
            : access.canView;

        if (!permitted) {
          return false;
        }

        return (
          normalizeAccessName(
            access
              .policeStationName,
          ) ===
          recordPoliceStation
        );
      },
    );
}

function filterValidGpidRecords(
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

async function loadGpidMaster(): Promise<
  GaneshRecord[]
> {
  if (
    lastSuccessfulGpidData &&
    lastSuccessfulGpidAt !==
      null &&
    Date.now() -
      lastSuccessfulGpidAt <
      GPID_CACHE_TTL_MS
  ) {
    return lastSuccessfulGpidData;
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

          cache:
            "no-store",

          signal:
            controller.signal,
        },
      );

    if (!response.ok) {
      throw new Error(
        `Ganesh upstream returned ${response.status}`,
      );
    }

    const data: unknown =
      await response.json();

    if (
      !Array.isArray(data)
    ) {
      throw new Error(
        "Unexpected Ganesh API response format.",
      );
    }

    const records =
      filterValidGpidRecords(
        data,
      );

    lastSuccessfulGpidData =
      records;

    lastSuccessfulGpidAt =
      Date.now();

    return records;
  } catch (error) {
    console.error(
      "Verification GPID master fetch error:",
      error,
    );

    if (
      lastSuccessfulGpidData
    ) {
      return lastSuccessfulGpidData;
    }

    throw error;
  } finally {
    clearTimeout(
      timeout,
    );
  }
}

function buildGpidMap(
  records: GaneshRecord[],
): Map<
  string,
  GaneshRecord
> {
  const result =
    new Map<
      string,
      GaneshRecord
    >();

  for (
    const record of records
  ) {
    const gpid =
      text(
        record.unique_id,
      );

    if (gpid) {
      result.set(
        gpid,
        record,
      );
    }
  }

  return result;
}

export async function GET(
  request: NextRequest,
) {
  try {
    const session =
      getWebSession(
        request,
      );

    if (!session) {
      return Response.json(
        {
          error:
            "Unauthorized",
        },
        {
          status: 401,

          headers: {
            "Cache-Control":
              "no-store",
          },
        },
      );
    }

    const user =
      await getCurrentUser(
        session.userId,
      );

    if (!user) {
      return Response.json(
        {
          error:
            "User account not found.",
        },
        {
          status: 401,

          headers: {
            "Cache-Control":
              "no-store",
          },
        },
      );
    }

    if (
      user.status !== "ACTIVE"
    ) {
      return Response.json(
        {
          error:
            "This user account is inactive.",
        },
        {
          status: 403,

          headers: {
            "Cache-Control":
              "no-store",
          },
        },
      );
    }

    const records =
      await prisma
        .preInstallationVerification
        .findMany({
          orderBy: {
            updatedAt:
              "desc",
          },
        });

    let authorizedRecords =
      records;

    if (
      !isGlobalAccess(
        user,
      )
    ) {
      let master:
        GaneshRecord[];

      try {
        master =
          await loadGpidMaster();
      } catch {
        return Response.json(
          {
            error:
              "Unable to verify GPID jurisdiction at this time.",
          },
          {
            status: 503,

            headers: {
              "Cache-Control":
                "no-store",
            },
          },
        );
      }

      const gpidMap =
        buildGpidMap(
          master,
        );

      authorizedRecords =
        records.filter(
          (record) => {
            const gpid =
              text(
                record.gpid,
              );

            const masterRecord =
              gpidMap.get(
                gpid,
              );

            if (
              !masterRecord
            ) {
              return false;
            }

            return hasRecordAccess(
              masterRecord,
              user,
              "view",
            );
          },
        );
    }

    const visibleRecords =
      authorizedRecords.map(
        (record) =>
          redactRecordForRole(
            record as unknown as Record<
              string,
              unknown
            >,
            user.role,
          ),
      );

    return Response.json(
      visibleRecords,
      {
        status: 200,

        headers: {
          "Cache-Control":
            "no-store",
        },
      },
    );
  } catch (error) {
    console.error(
      "Verification GET error:",
      error,
    );

    return Response.json(
      {
        error:
          "Unable to load verification records",
      },
      {
        status: 500,

        headers: {
          "Cache-Control":
            "no-store",
        },
      },
    );
  }
}

export async function POST(
  request: NextRequest,
) {
  try {
    const session =
      getWebSession(
        request,
      );

    if (!session) {
      return Response.json(
        {
          error:
            "Unauthorized",
        },
        {
          status: 401,

          headers: {
            "Cache-Control":
              "no-store",
          },
        },
      );
    }

    const user =
      await getCurrentUser(
        session.userId,
      );

    if (!user) {
      return Response.json(
        {
          error:
            "User account not found.",
        },
        {
          status: 401,

          headers: {
            "Cache-Control":
              "no-store",
          },
        },
      );
    }

    if (
      user.status !== "ACTIVE"
    ) {
      return Response.json(
        {
          error:
            "This user account is inactive.",
        },
        {
          status: 403,

          headers: {
            "Cache-Control":
              "no-store",
          },
        },
      );
    }

    const body =
      (await request.json()) as
        VerificationPayload;

    const gpid =
      String(
        body.gpid ?? "",
      ).trim();

    if (!gpid) {
      return Response.json(
        {
          error:
            "GPID is required",
        },
        {
          status: 400,

          headers: {
            "Cache-Control":
              "no-store",
          },
        },
      );
    }

    if (
      !isGlobalAccess(
        user,
      )
    ) {
      let master:
        GaneshRecord[];

      try {
        master =
          await loadGpidMaster();
      } catch {
        return Response.json(
          {
            error:
              "Unable to verify GPID jurisdiction at this time. Please try again.",
          },
          {
            status: 503,

            headers: {
              "Cache-Control":
                "no-store",
            },
          },
        );
      }

      const gpidMap =
        buildGpidMap(
          master,
        );

      const masterRecord =
        gpidMap.get(
          gpid,
        );

      if (!masterRecord) {
        return Response.json(
          {
            error:
              "GPID is not available within your permitted jurisdiction.",
          },
          {
            status: 403,

            headers: {
              "Cache-Control":
                "no-store",
            },
          },
        );
      }

      if (
        !hasRecordAccess(
          masterRecord,
          user,
          "edit",
        )
      ) {
        return Response.json(
          {
            error:
              "You do not have permission to edit verification data for this GPID.",
          },
          {
            status: 403,

            headers: {
              "Cache-Control":
                "no-store",
            },
          },
        );
      }
    }

    const existing =
      await prisma
        .preInstallationVerification
        .findUnique({
          where: {
            gpid,
          },
        });

    const mergedData: Record<
      string,
      unknown
    > = {
      applicationId:
        hasOwn(
          body,
          "applicationId",
        )
          ? body.applicationId !=
            null
            ? String(
                body.applicationId,
              )
            : null
          : existing
                ?.applicationId ??
            null,

      locationResult:
        hasOwn(
          body,
          "locationResult",
        )
          ? body.locationResult
          : existing
                ?.locationResult ??
            null,

      mandapResult:
        hasOwn(
          body,
          "mandapResult",
        )
          ? body.mandapResult
          : existing
                ?.mandapResult ??
            null,

      idolResult:
        hasOwn(
          body,
          "idolResult",
        )
          ? body.idolResult
          : existing
                ?.idolResult ??
            null,

      routeResult:
        hasOwn(
          body,
          "routeResult",
        )
          ? body.routeResult
          : existing
                ?.routeResult ??
            null,

      securityResult:
        hasOwn(
          body,
          "securityResult",
        )
          ? body.securityResult
          : existing
                ?.securityResult ??
            null,

      organizerResult:
        hasOwn(
          body,
          "organizerResult",
        )
          ? body.organizerResult
          : existing
                ?.organizerResult ??
            null,

      interDepartmentalResult:
        hasOwn(
          body,
          "interDepartmentalResult",
        )
          ? body
              .interDepartmentalResult
          : existing
                ?.interDepartmentalResult ??
            null,

      permissionShoReviewResult:
        hasOwn(
          body,
          "permissionShoReviewResult",
        )
          ? body
              .permissionShoReviewResult
          : existing
                ?.permissionShoReviewResult ??
            null,
    };

    const verificationStatus =
      hasOwn(
        body,
        "verificationStatus",
      ) &&
      body.verificationStatus !=
        null &&
      String(
        body.verificationStatus,
      ).trim()
        ? String(
            body.verificationStatus,
          ).trim()
        : getAutomaticStatus(
            mergedData,
          );

    const record =
      await prisma
        .preInstallationVerification
        .upsert({
          where: {
            gpid,
          },

          update: {
            applicationId:
              mergedData
                .applicationId as
                | string
                | null,

            locationResult:
              mergedData
                .locationResult as never,

            mandapResult:
              mergedData
                .mandapResult as never,

            idolResult:
              mergedData
                .idolResult as never,

            routeResult:
              mergedData
                .routeResult as never,

            securityResult:
              mergedData
                .securityResult as never,

            organizerResult:
              mergedData
                .organizerResult as never,

            interDepartmentalResult:
              mergedData
                .interDepartmentalResult as never,

            permissionShoReviewResult:
              mergedData
                .permissionShoReviewResult as never,

            verificationStatus,
          },

          create: {
            gpid,

            applicationId:
              mergedData
                .applicationId as
                | string
                | null,

            locationResult:
              mergedData
                .locationResult as never,

            mandapResult:
              mergedData
                .mandapResult as never,

            idolResult:
              mergedData
                .idolResult as never,

            routeResult:
              mergedData
                .routeResult as never,

            securityResult:
              mergedData
                .securityResult as never,

            organizerResult:
              mergedData
                .organizerResult as never,

            interDepartmentalResult:
              mergedData
                .interDepartmentalResult as never,

            permissionShoReviewResult:
              mergedData
                .permissionShoReviewResult as never,

            verificationStatus,
          },
        });

    const responseRecord =
      redactRecordForRole(
        record as unknown as Record<
          string,
          unknown
        >,
        user.role,
      );

    return Response.json(
      {
        success: true,

        message:
          "Verification data synchronized successfully.",

        modulesCompleted:
          countCompletedModules(
            record as unknown as Record<
              string,
              unknown
            >,
          ),

        record:
          responseRecord,
      },
      {
        status: 200,

        headers: {
          "Cache-Control":
            "no-store",
        },
      },
    );
  } catch (error) {
    console.error(
      "Verification POST error:",
      error,
    );

    return Response.json(
      {
        error:
          "Unable to save verification record",
      },
      {
        status: 500,

        headers: {
          "Cache-Control":
            "no-store",
        },
      },
    );
  }
}