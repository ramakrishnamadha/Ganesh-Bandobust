import { readFile } from "fs/promises";
import path from "path";

import { NextRequest } from "next/server";

import { prisma } from "@/lib/prisma";
import { getWebSession } from "@/lib/server/auth";

const GANESH_API_URL =
  "https://policeportal.tspolice.gov.in/ganesh/getGanaDetails/22";

const UPSTREAM_TIMEOUT_MS = 90000;
const GPID_CACHE_TTL_MS = 5 * 60 * 1000;
const INDIA_TIME_ZONE = "Asia/Kolkata";

type JsonObject = Record<string, unknown>;
type GaneshRecord = Record<string, unknown>;
type AccessMode = "view" | "edit";

type FestivityPayload = {
  gpid?: unknown;
  applicationId?: unknown;

  festivalDay?: unknown;

  checkSource?: unknown;
  userSessionId?: unknown;
  deviceSessionId?: unknown;

  antiDigressionResult?: unknown;
  volunteerResult?: unknown;
  lightingResult?: unknown;
  sanitationResult?: unknown;
  poojaResult?: unknown;
  soundSystemResult?: unknown;
  fireSafetyResult?: unknown;

  evidenceResult?: unknown;
  remarks?: unknown;
  actionTaken?: unknown;

  status?: unknown;
  hasDeficiency?: unknown;
  requiresFollowUp?: unknown;

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

  commissionerateCode: string | null;
  commissionerateName: string | null;

  rangeCode: string | null;
  rangeName: string | null;

  zoneCode: string | null;
  zoneName: string | null;

  divisionCode: string | null;
  divisionName: string | null;

  policeStationCode: string | null;
  policeStationName: string | null;

  sectorCode: string | null;
  sectorName: string | null;

  allPoliceStations: boolean;
  allZones: boolean;

  policeStationAccesses: Array<{
    policeStationName: string;
    canView: boolean;
    canEdit: boolean;
  }>;
};

let lastSuccessfulGpidData: GaneshRecord[] | null = null;
let lastSuccessfulGpidAt: number | null = null;

function text(value: unknown): string {
  if (value === null || value === undefined) {
    return "";
  }

  const result = String(value).trim();

  if (
    result.length === 0 ||
    result.toLowerCase() === "null"
  ) {
    return "";
  }

  return result;
}

function isObject(value: unknown): value is JsonObject {
  return (
    typeof value === "object" &&
    value !== null &&
    !Array.isArray(value)
  );
}

function booleanValue(value: unknown): boolean | null {
  if (value === true || value === false) {
    return value;
  }

  const normalized = text(value).toLowerCase();

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

function numberValue(value: unknown): number | null {
  if (
    value === null ||
    value === undefined ||
    text(value).length === 0
  ) {
    return null;
  }

  const result = Number(value);

  return Number.isFinite(result) ? result : null;
}

function integerValue(value: unknown): number | null {
  const valueAsNumber = numberValue(value);

  if (
    valueAsNumber === null ||
    !Number.isInteger(valueAsNumber)
  ) {
    return null;
  }

  return valueAsNumber;
}

function dateValue(value: unknown): Date | null {
  const raw = text(value);

  if (!raw) {
    return null;
  }

  const result = new Date(raw);

  if (Number.isNaN(result.getTime())) {
    return null;
  }

  return result;
}

function normalizeAccessName(value: unknown): string {
  let normalized = text(value)
    .toLowerCase()
    .replace(/\s+/g, " ")
    .trim();

  normalized = normalized.replace(/\s+ps$/i, "");

  return normalized.trim();
}

function sameAccessName(left: unknown, right: unknown): boolean {
  const a = normalizeAccessName(left);
  const b = normalizeAccessName(right);

  return a.length > 0 && a === b;
}

function isGlobalAccess(user: UserAccess): boolean {
  return user.role === "ADMIN" || user.allZones;
}

function hasRecordAccess(
  record: GaneshRecord,
  user: UserAccess,
  mode: AccessMode,
): boolean {
  if (isGlobalAccess(user)) {
    return true;
  }

  if (user.allPoliceStations) {
    if (text(user.zoneName).length > 0) {
      return sameAccessName(record.zone_name, user.zoneName);
    }

    if (text(user.divisionName).length > 0) {
      return sameAccessName(
        record.division_name,
        user.divisionName,
      );
    }

    if (text(user.policeStationName).length > 0) {
      return sameAccessName(
        record.ps_name,
        user.policeStationName,
      );
    }

    return false;
  }

  const recordPoliceStation = normalizeAccessName(
    record.ps_name,
  );

  if (recordPoliceStation.length === 0) {
    return false;
  }

  const userPrimaryPS = normalizeAccessName(user.policeStationName);

  if (userPrimaryPS.length > 0 && userPrimaryPS === recordPoliceStation) {
    return true;
  }

  return user.policeStationAccesses.some((access) => {
    const permitted =
      mode === "edit" ? access.canEdit : access.canView;

    if (!permitted) {
      return false;
    }

    return (
      normalizeAccessName(access.policeStationName) ===
      recordPoliceStation
    );
  });
}

function filterValidGpidRecords(
  data: unknown[],
): GaneshRecord[] {
  return data.filter(
    (item): item is GaneshRecord => {
      if (typeof item !== "object" || item === null) {
        return false;
      }

      const record = item as GaneshRecord;

      return text(record.unique_id).length > 0;
    },
  );
}

async function loadPersistentGpidCache(): Promise<
  GaneshRecord[] | null
> {
  try {
    const cachePath = path.join(
      process.cwd(),
      "gpid-cache.json",
    );

    const raw = await readFile(cachePath, "utf8");
    const parsed: unknown = JSON.parse(raw);

    let sourceRecords: unknown[] | null = null;

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
      sourceRecords = (
        parsed as { records: unknown[] }
      ).records;
    }

    if (!sourceRecords) {
      return null;
    }

    const records = filterValidGpidRecords(sourceRecords);

    return records.length > 0 ? records : null;
  } catch {
    return null;
  }
}

async function loadGpidMaster(): Promise<GaneshRecord[]> {
  if (
    lastSuccessfulGpidData &&
    lastSuccessfulGpidAt !== null &&
    Date.now() - lastSuccessfulGpidAt < GPID_CACHE_TTL_MS
  ) {
    return lastSuccessfulGpidData;
  }

  const persistentCache = await loadPersistentGpidCache();

  if (persistentCache) {
    lastSuccessfulGpidData = persistentCache;
    lastSuccessfulGpidAt = Date.now();

    return persistentCache;
  }

  const controller = new AbortController();

  const timeout = setTimeout(() => {
    controller.abort();
  }, UPSTREAM_TIMEOUT_MS);

  try {
    const response = await fetch(GANESH_API_URL, {
      method: "POST",
      cache: "no-store",
      signal: controller.signal,
    });

    if (!response.ok) {
      throw new Error(
        `Ganesh upstream returned ${response.status}`,
      );
    }

    const data: unknown = await response.json();

    if (!Array.isArray(data)) {
      throw new Error(
        "Unexpected Ganesh API response format.",
      );
    }

    const records = filterValidGpidRecords(data);

    lastSuccessfulGpidData = records;
    lastSuccessfulGpidAt = Date.now();

    return records;
  } finally {
    clearTimeout(timeout);
  }
}

function buildGpidMap(
  records: GaneshRecord[],
): Map<string, GaneshRecord> {
  const result = new Map<string, GaneshRecord>();

  for (const record of records) {
    const gpid = text(record.unique_id);

    if (gpid) {
      result.set(gpid, record);
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
      allZones: true,

      policeStationAccesses: {
        select: {
          policeStationName: true,
          canView: true,
          canEdit: true,
        },
      },
    },
  });
}

function indiaTimeParts(date: Date): {
  hour: number;
  minute: number;
} {
  const parts = new Intl.DateTimeFormat("en-GB", {
    timeZone: INDIA_TIME_ZONE,
    hour: "2-digit",
    minute: "2-digit",
    hourCycle: "h23",
  }).formatToParts(date);

  const hour = Number(
    parts.find((item) => item.type === "hour")?.value ??
      "0",
  );

  const minute = Number(
    parts.find((item) => item.type === "minute")?.value ??
      "0",
  );

  return {
    hour: Number.isFinite(hour) ? hour : 0,
    minute: Number.isFinite(minute) ? minute : 0,
  };
}

function indiaMinutes(date: Date): number {
  const { hour, minute } = indiaTimeParts(date);
  return hour * 60 + minute;
}

// Final Stage-3 rule: lighting check applies from 07:00 PM through 06:00 AM.
function isLightingApplicable(date: Date): boolean {
  const minutes = indiaMinutes(date);

  return minutes >= 19 * 60 || minutes <= 6 * 60;
}

// Pooja completion applies only from 08:00 PM through 11:59 PM.
function isPoojaApplicable(date: Date): boolean {
  const minutes = indiaMinutes(date);

  return minutes >= 20 * 60 && minutes <= 23 * 60 + 59;
}

// Late-night sound rule starts at 10:01 PM.
function isLateNightSoundApplicable(date: Date): boolean {
  return indiaMinutes(date) >= 22 * 60 + 1;
}

function festivalDateForDay(day: number): Date {
  // Day 1 = 14-09-2026, Day 11 = 24-09-2026.
  // Stored as the UTC instant corresponding to 00:00 IST.
  return new Date(
    Date.UTC(
      2026,
      8,
      12 + day,
      18,
      30,
      0,
      0,
    ),
  );
}

function explicitFalse(
  source: unknown,
  keys: string[],
): boolean {
  if (!isObject(source)) {
    return false;
  }

  return keys.some(
    (key) => booleanValue(source[key]) === false,
  );
}

function explicitTrue(
  source: unknown,
  keys: string[],
): boolean {
  if (!isObject(source)) {
    return false;
  }

  return keys.some(
    (key) => booleanValue(source[key]) === true,
  );
}

function extractPoojaCompleted(
  source: unknown,
): boolean | null {
  if (!isObject(source)) {
    return null;
  }

  const candidates = [
    source.poojaCompleted,
    source.completed,
    source.isCompleted,
  ];

  for (const candidate of candidates) {
    const value = booleanValue(candidate);

    if (value !== null) {
      return value;
    }
  }

  return null;
}



function responseHeaders() {
  return {
    "Cache-Control": "no-store, max-age=0",
    "Content-Type": "application/json",
  };
}

export async function POST(request: NextRequest) {
  try {
    const session = getWebSession(request);
    if (!session) {
      return Response.json({ error: "Unauthorized" }, { status: 401, headers: responseHeaders() });
    }

    const user = await getCurrentUser(session.userId);
    if (!user) {
      return Response.json({ error: "Unauthorized" }, { status: 401, headers: responseHeaders() });
    }
    
    if (user.status !== "ACTIVE") {
      return Response.json({ error: "Inactive account" }, { status: 403, headers: responseHeaders() });
    }

    const body = await request.json();
    const gpid = text(body.gpid);
    const step = numberValue(body.step);

    if (!gpid || !step || step < 1 || step > 5) {
      return Response.json({ error: "Invalid request payload" }, { status: 400, headers: responseHeaders() });
    }

    let master: GaneshRecord[];
    try {
      master = await loadGpidMaster();
    } catch (error) {
      return Response.json({ error: "Service unavailable" }, { status: 503, headers: responseHeaders() });
    }

    const gpidMap = buildGpidMap(master);
    const masterRecord = gpidMap.get(gpid);

    if (!masterRecord) {
      return Response.json({ error: "GPID not found" }, { status: 404, headers: responseHeaders() });
    }

    if (!hasRecordAccess(masterRecord, user, "edit")) {
      return Response.json({ error: "Permission denied" }, { status: 403, headers: responseHeaders() });
    }

    const resultData = body.data; // Changed from body.result to body.data based on mobile app implementation
    const checkedAt = dateValue(body.checkedAt) ?? new Date();
    const checkStartedAt = dateValue(body.checkStartedAt);

    await prisma.$transaction(async (tx) => {
      let visit = await tx.immersionCheckVisit.findFirst({
        where: { gpid, userId: user.id, status: "IN_PROGRESS" },
        orderBy: { checkedAt: "desc" }
      });

      if (!visit) {
        visit = await tx.immersionCheckVisit.create({
          data: {
            gpid,
            userId: user.id,
            officerEmployeeId: user.employeeId,
            officerName: user.name,
            officerRank: user.rank,
            officerRole: user.role,
            commissionerateCode: user.commissionerateCode,
            commissionerateName: user.commissionerateName,
            rangeCode: user.rangeCode,
            rangeName: user.rangeName,
            zoneCode: user.zoneCode,
            zoneName: text(masterRecord.zone_name) || user.zoneName,
            divisionCode: user.divisionCode,
            divisionName: text(masterRecord.division_name) || user.divisionName,
            policeStationCode: user.policeStationCode,
            policeStationName: text(masterRecord.ps_name) || user.policeStationName,
            checkSource: text(body.checkSource) || "MOBILE",
            userSessionId: text(body.userSessionId) || null,
            deviceSessionId: text(body.deviceSessionId) || null,
            status: "IN_PROGRESS",
            currentStep: step,
            checkStartedAt,
            checkedAt
          }
        });
      }

      const updateData: any = { currentStep: Math.max(visit.currentStep, step), updatedAt: new Date() };

      switch (step) {
        case 1: updateData.preVerificationResult = resultData as any; break;
        case 2: updateData.processionFormationResult = resultData as any; break;
        case 3: updateData.routeManagementResult = resultData as any; break;
        case 4: updateData.trackingResult = resultData as any; break;
        case 5: updateData.immersionPointResult = resultData as any; break;
      }

      await tx.immersionCheckVisit.update({
        where: { id: visit.id },
        data: updateData
      });

      await tx.activityEvent.create({
        data: {
          userId: user.id,
          source: text(body.checkSource) || "MOBILE",
          eventType: "IMMERSION_STEP_SUBMITTED",
          metadata: { gpid, step, result: resultData } as any,
          occurredAt: new Date()
        }
      });
    });

    return Response.json({ success: true }, { status: 200, headers: responseHeaders() });
  } catch (error) {
    console.error("Immersion step POST error:", error);
    return Response.json({ error: "Internal server error" }, { status: 500, headers: responseHeaders() });
  }
}
