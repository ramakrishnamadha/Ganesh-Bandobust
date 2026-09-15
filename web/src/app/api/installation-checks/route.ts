import { readFile } from "fs/promises";
import path from "path";

import { NextRequest } from "next/server";

import { prisma } from "@/lib/prisma";
import { getWebSession } from "@/lib/server/auth";

const GANESH_API_URL =
  "https://policeportal.tspolice.gov.in/ganesh/getGanaDetails/22";

const UPSTREAM_TIMEOUT_MS = 90000;

const GPID_CACHE_TTL_MS =
  5 * 60 * 1000;

const INDIA_TIME_ZONE =
  "Asia/Kolkata";

type JsonObject =
  Record<string, unknown>;

type GaneshRecord =
  Record<string, unknown>;

type AccessMode =
  | "view"
  | "edit";

type InstallationPayload = {
  gpid?: unknown;
  applicationId?: unknown;

  checkSource?: unknown;
  userSessionId?: unknown;
  deviceSessionId?: unknown;

  // Legacy Installation/CHECKING prototype payloads
  installationResult?: unknown;
  volunteerResult?: unknown;
  lightingResult?: unknown;
  sanitationResult?: unknown;
  poojaResult?: unknown;
  antiDesecrationResult?: unknown;

  // Final Stage-2 Installation verification modules
  idolInstallationResult?: unknown;
  geoTaggedVerificationResult?: unknown;
  clusterSectorResult?: unknown;
  documentarySetupResult?: unknown;
  prePlannedSetupResult?: unknown;
  spectacularExhibitionResult?: unknown;

  evidenceResult?: unknown;

  remarks?: unknown;
  actionTaken?: unknown;

  status?: unknown;
  hasDeficiency?: unknown;
  requiresFollowUp?: unknown;

  poojaCompleted?: unknown;

  latitude?: unknown;
  longitude?: unknown;
  accuracy?: unknown;

  checkStartedAt?: unknown;
  checkedAt?: unknown;
};

type UserAccess = {
  id: string;

  employeeId: string;
  name: string;
  rank: string;
  role: string;
  status: string;

  commissionerateCode:
    string | null;
  commissionerateName:
    string | null;

  rangeCode:
    string | null;
  rangeName:
    string | null;

  zoneCode:
    string | null;
  zoneName:
    string | null;

  divisionCode:
    string | null;
  divisionName:
    string | null;

  policeStationCode:
    string | null;
  policeStationName:
    string | null;

  sectorCode:
    string | null;
  sectorName:
    string | null;

  allPoliceStations: boolean;
  allZones: boolean;

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
    normalized === "yes" ||
    normalized === "1"
  ) {
    return true;
  }

  if (
    normalized === "false" ||
    normalized === "no" ||
    normalized === "0"
  ) {
    return false;
  }

  return null;
}

function numberValue(
  value: unknown,
): number | null {
  if (
    value === null ||
    value === undefined ||
    text(value).length === 0
  ) {
    return null;
  }

  const result =
    Number(value);

  return Number.isFinite(result)
    ? result
    : null;
}

function dateValue(
  value: unknown,
): Date | null {
  const raw =
    text(value);

  if (!raw) {
    return null;
  }

  const result =
    new Date(raw);

  if (
    Number.isNaN(
      result.getTime(),
    )
  ) {
    return null;
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

async function loadPersistentGpidCache(): Promise<
  GaneshRecord[] | null
> {
  try {
    const cachePath =
      path.join(
        process.cwd(),
        "gpid-cache.json",
      );

    const raw =
      await readFile(
        cachePath,
        "utf8",
      );

    const parsed: unknown =
      JSON.parse(raw);

    let sourceRecords:
      unknown[] | null = null;

    if (Array.isArray(parsed)) {
      sourceRecords = parsed;
    } else if (
      typeof parsed === "object" &&
      parsed !== null &&
      "records" in parsed &&
      Array.isArray(
        (parsed as { records?: unknown }).records,
      )
    ) {
      sourceRecords =
        (parsed as { records: unknown[] }).records;
    }

    if (!sourceRecords) {
      return null;
    }

    const records =
      filterValidGpidRecords(
        sourceRecords,
      );

    return records.length > 0
      ? records
      : null;
  } catch {
    return null;
  }
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

  const persistentCache =
    await loadPersistentGpidCache();

  if (persistentCache) {
    lastSuccessfulGpidData =
      persistentCache;

    lastSuccessfulGpidAt =
      Date.now();

    return persistentCache;
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
  } finally {
    clearTimeout(
      timeout,
    );
  }
}

function buildGpidMap(
  records: GaneshRecord[],
): Map<string, GaneshRecord> {
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

async function getCurrentUser(
  userId: string,
): Promise<UserAccess | null> {
  return prisma.user.findUnique({
    where: {
      id: userId,
    },

    select: {
      id: true,

      employeeId: true,
      name: true,
      rank: true,
      role: true,
      status: true,

      commissionerateCode:
        true,
      commissionerateName:
        true,

      rangeCode: true,
      rangeName: true,

      zoneCode: true,
      zoneName: true,

      divisionCode: true,
      divisionName: true,

      policeStationCode:
        true,
      policeStationName:
        true,

      sectorCode: true,
      sectorName: true,

      allPoliceStations:
        true,
      allZones: true,

      policeStationAccesses: {
        select: {
          policeStationName:
            true,
          canView: true,
          canEdit: true,
        },
      },
    },
  });
}

function indiaHour(
  date: Date,
): number {
  const parts =
    new Intl.DateTimeFormat(
      "en-GB",
      {
        timeZone:
          INDIA_TIME_ZONE,
        hour: "2-digit",
        hourCycle: "h23",
      },
    ).formatToParts(date);

  const hourPart =
    parts.find(
      (item) =>
        item.type === "hour",
    );

  const hour =
    Number(
      hourPart?.value ?? "0",
    );

  return Number.isFinite(hour)
    ? hour
    : 0;
}

function isLightingApplicable(
  date: Date,
): boolean {
  const hour =
    indiaHour(date);

  return (
    hour >= 18 ||
    hour < 7
  );
}

function isPoojaApplicable(
  date: Date,
): boolean {
  return (
    indiaHour(date) >= 21
  );
}

function extractPoojaCompleted(
  body: InstallationPayload,
): boolean | null {
  const direct =
    booleanValue(
      body.poojaCompleted,
    );

  if (direct !== null) {
    return direct;
  }

  if (
    isObject(
      body.poojaResult,
    )
  ) {
    const candidates = [
      body.poojaResult
        .poojaCompleted,
      body.poojaResult
        .completed,
      body.poojaResult
        .isCompleted,
    ];

    for (
      const candidate
      of candidates
    ) {
      const value =
        booleanValue(
          candidate,
        );

      if (value !== null) {
        return value;
      }
    }
  }

  return null;
}

function responseHeaders() {
  return {
    "Cache-Control":
      "no-store",
  };
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
          headers:
            responseHeaders(),
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
          headers:
            responseHeaders(),
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
          headers:
            responseHeaders(),
        },
      );
    }

    const requestedGpid =
      text(
        request.nextUrl
          .searchParams
          .get("gpid"),
      );

    const includePreInstallation =
      request.nextUrl
        .searchParams
        .get("includePreInstallation") ===
      "true";

    const requestedLimit =
      Number(
        request.nextUrl
          .searchParams
          .get("limit") ??
          "200",
      );

    const limit =
      Number.isFinite(
        requestedLimit,
      )
        ? Math.min(
            Math.max(
              Math.trunc(
                requestedLimit,
              ),
              1,
            ),
            500,
          )
        : 200;

    const records =
      await prisma
        .installationCheckVisit
        .findMany({
          where:
            requestedGpid
              ? {
                  gpid:
                    requestedGpid,
                }
              : undefined,

          orderBy: {
            checkedAt:
              "desc",
          },

          take: limit,
        });

    const preInstallation =
      requestedGpid
        ? await prisma
            .preInstallationVerification
            .findUnique({
              where: {
                gpid:
                  requestedGpid,
              },
            })
        : null;

    if (
      isGlobalAccess(
        user,
      )
    ) {
      return Response.json(
        includePreInstallation &&
        requestedGpid
          ? {
              records,
              preInstallation,
            }
          : records,
        {
          status: 200,
          headers:
            responseHeaders(),
        },
      );
    }

    let master:
      GaneshRecord[];

    try {
      master =
        await loadGpidMaster();
    } catch (error) {
      console.error(
        "Installation GPID master load error:",
        error,
      );

      return Response.json(
        {
          error:
            "Unable to verify GPID jurisdiction at this time.",
        },
        {
          status: 503,
          headers:
            responseHeaders(),
        },
      );
    }

    const gpidMap =
      buildGpidMap(
        master,
      );

    const authorized =
      records.filter(
        (record) => {
          const masterRecord =
            gpidMap.get(
              record.gpid,
            );

          if (!masterRecord) {
            return false;
          }

          return hasRecordAccess(
            masterRecord,
            user,
            "view",
          );
        },
      );

    const requestedMasterRecord =
      requestedGpid
        ? gpidMap.get(
            requestedGpid,
          )
        : null;

    const canViewRequestedGpid =
      requestedMasterRecord
        ? hasRecordAccess(
            requestedMasterRecord,
            user,
            "view",
          )
        : false;

    return Response.json(
      includePreInstallation &&
      requestedGpid &&
      canViewRequestedGpid
        ? {
            records:
              authorized,
            preInstallation,
          }
        : authorized,
      {
        status: 200,
        headers:
          responseHeaders(),
      },
    );
  } catch (error) {
    console.error(
      "Installation checks GET error:",
      error,
    );

    return Response.json(
      {
        error:
          "Unable to load installation check records.",
      },
      {
        status: 500,
        headers:
          responseHeaders(),
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
          headers:
            responseHeaders(),
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
          headers:
            responseHeaders(),
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
          headers:
            responseHeaders(),
        },
      );
    }

    const body =
      (await request.json()) as
        InstallationPayload;

    const gpid =
      text(
        body.gpid,
      );

    if (!gpid) {
      return Response.json(
        {
          error:
            "GPID is required.",
        },
        {
          status: 400,
          headers:
            responseHeaders(),
        },
      );
    }

    let master:
      GaneshRecord[];

    try {
      master =
        await loadGpidMaster();
    } catch (error) {
      console.error(
        "Installation GPID master load error:",
        error,
      );

      return Response.json(
        {
          error:
            "Unable to verify GPID jurisdiction at this time. Please try again.",
        },
        {
          status: 503,
          headers:
            responseHeaders(),
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
            "GPID was not found in the current GPID master.",
        },
        {
          status: 404,
          headers:
            responseHeaders(),
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
            "You do not have permission to submit an Installation check for this GPID.",
        },
        {
          status: 403,
          headers:
            responseHeaders(),
        },
      );
    }

    const checkedAt =
      dateValue(
        body.checkedAt,
      ) ??
      new Date();

    const checkStartedAt =
      dateValue(
        body.checkStartedAt,
      );

    const lightingApplicable =
      isLightingApplicable(
        checkedAt,
      );

    const poojaApplicable =
      isPoojaApplicable(
        checkedAt,
      );

    const poojaCompleted =
      poojaApplicable
        ? extractPoojaCompleted(
            body,
          )
        : null;

    const poojaPending =
      poojaApplicable &&
      poojaCompleted !== true;

    const requestedDeficiency =
      booleanValue(
        body.hasDeficiency,
      ) === true;

    const requestedFollowUp =
      booleanValue(
        body.requiresFollowUp,
      ) === true;

    const hasDeficiency =
      requestedDeficiency ||
      poojaPending;

    const requiresFollowUp =
      requestedFollowUp ||
      hasDeficiency;

    const suppliedStatus =
      text(
        body.status,
      );

    const status =
      suppliedStatus ||
      (
        requiresFollowUp
          ? "FOLLOW_UP_REQUIRED"
          : "SAVED"
      );

    const latitude =
      numberValue(
        body.latitude,
      );

    const longitude =
      numberValue(
        body.longitude,
      );

    const accuracy =
      numberValue(
        body.accuracy,
      );

    const applicationId =
      text(
        body.applicationId,
      ) || null;

    const checkSource =
      text(
        body.checkSource,
      ) || "MOBILE";

    const recordPsName =
      text(
        masterRecord.ps_name,
      ) || null;

    const recordDivisionName =
      text(
        masterRecord.division_name,
      ) || null;

    const recordZoneName =
      text(
        masterRecord.zone_name,
      ) || null;

    const record =
      await prisma
        .$transaction(
          async (
            tx,
          ) => {
            const created =
              await tx
                .installationCheckVisit
                .create({
                  data: {
                    gpid,
                    applicationId,

                    userId:
                      user.id,

                    officerEmployeeId:
                      user.employeeId,

                    officerName:
                      user.name,

                    officerRank:
                      user.rank,

                    officerRole:
                      user.role,

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
                      recordZoneName ??
                      user.zoneName,

                    divisionCode:
                      user.divisionCode,

                    divisionName:
                      recordDivisionName ??
                      user.divisionName,

                    policeStationCode:
                      user.policeStationCode,

                    policeStationName:
                      recordPsName ??
                      user.policeStationName,

                    sectorCode:
                      user.sectorCode,

                    sectorName:
                      user.sectorName,

                    clusterCode:
                      null,

                    clusterName:
                      null,

                    stage:
                      "INSTALLATION",

                    checkSource,

                    userSessionId:
                      text(
                        body.userSessionId,
                      ) || null,

                    deviceSessionId:
                      text(
                        body.deviceSessionId,
                      ) || null,

                    installationResult:
                      body.installationResult as never,

                    volunteerResult:
                      body.volunteerResult as never,

                    lightingResult:
                      (
                        isObject(
                          body.lightingResult,
                        )
                          ? {
                              ...body.lightingResult,
                              applicable:
                                lightingApplicable,
                            }
                          : {
                              applicable:
                                lightingApplicable,
                            }
                      ) as never,

                    sanitationResult:
                      body.sanitationResult as never,

                    poojaResult:
                      (
                        isObject(
                          body.poojaResult,
                        )
                          ? {
                              ...body.poojaResult,
                              applicable:
                                poojaApplicable,
                              completed:
                                poojaCompleted,
                              pending:
                                poojaPending,
                            }
                          : {
                              applicable:
                                poojaApplicable,
                              completed:
                                poojaCompleted,
                              pending:
                                poojaPending,
                            }
                      ) as never,

                    antiDesecrationResult:
                      body.antiDesecrationResult as never,

                    // Final Stage-2 Installation verification modules
                    idolInstallationResult:
                      body.idolInstallationResult as never,

                    geoTaggedVerificationResult:
                      body.geoTaggedVerificationResult as never,

                    clusterSectorResult:
                      body.clusterSectorResult as never,

                    documentarySetupResult:
                      body.documentarySetupResult as never,

                    prePlannedSetupResult:
                      body.prePlannedSetupResult as never,

                    spectacularExhibitionResult:
                      body.spectacularExhibitionResult as never,

                    evidenceResult:
                      body.evidenceResult as never,

                    remarks:
                      text(
                        body.remarks,
                      ) || null,

                    actionTaken:
                      text(
                        body.actionTaken,
                      ) || null,

                    status,

                    hasDeficiency,

                    requiresFollowUp,

                    poojaApplicable,

                    poojaCompleted,

                    poojaPending,

                    latitude,
                    longitude,
                    accuracy,

                    checkStartedAt,
                    checkedAt,
                  },
                });

            await tx
              .activityEvent
              .create({
                data: {
                  userId:
                    user.id,

                  source:
                    checkSource,

                  eventType:
                    "INSTALLATION_CHECK_SUBMITTED",

                  gpid,

                  applicationId,

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

                  latitude,
                  longitude,
                  accuracy,

                  newValue: {
                    installationCheckVisitId:
                      created.id,

                    stage:
                      "INSTALLATION",

                    status,

                    hasDeficiency,

                    requiresFollowUp,

                    poojaApplicable,

                    poojaCompleted,

                    poojaPending,

                    lightingApplicable,
                  },

                  metadata: {
                    officerEmployeeId:
                      user.employeeId,

                    officerName:
                      user.name,

                    officerRank:
                      user.rank,

                    recordPoliceStationName:
                      recordPsName,

                    recordDivisionName,

                    recordZoneName,
                  },

                  occurredAt:
                    checkedAt,
                },
              });

            return created;
          },
        );

    return Response.json(
      {
        success: true,

        message:
          "Installation check visit saved successfully.",

        lightingApplicable,

        poojaApplicable,

        poojaPending,

        record,
      },
      {
        status: 201,
        headers:
          responseHeaders(),
      },
    );
  } catch (error) {
    console.error(
      "Installation checks POST error:",
      error,
    );

    return Response.json(
      {
        error:
          "Unable to save Installation check visit.",
      },
      {
        status: 500,
        headers:
          responseHeaders(),
      },
    );
  }
}
