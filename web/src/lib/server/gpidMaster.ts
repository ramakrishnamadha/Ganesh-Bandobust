import { readFile } from "fs/promises";
import { existsSync } from "fs";
import path from "path";

export const GANESH_API_URL =
  "https://policeportal.tspolice.gov.in/ganesh/getGanaDetails/22";

export const UPSTREAM_TIMEOUT_MS = 25000;
export const CACHE_TTL_MS = 10 * 60 * 1000; // 10 minutes

export type GaneshRecord = Record<string, unknown>;

export type UserJurisdictionScope = {
  role: string;
  zoneName: string | null;
  divisionName: string | null;
  policeStationName: string | null;
  allPoliceStations: boolean;
  allZones: boolean;
  policeStationAccesses: Array<{
    policeStationName: string;
    canView: boolean;
    canEdit?: boolean;
  }>;
};

// Global in-memory cache
let memoryCache: GaneshRecord[] | null = null;
let lastSuccessfulAt: string | null = null;
let lastCacheSource: "live" | "memory-cache" | "file-fallback" = "live";
let cacheVersion: string | null = null;

export function text(value: unknown): string {
  if (value === null || value === undefined) {
    return "";
  }

  const result = String(value).trim();
  if (result.length === 0 || result.toLowerCase() === "null") {
    return "";
  }

  return result;
}

export function normalizeAccessName(value: unknown): string {
  let normalized = text(value)
    .toLowerCase()
    .replace(/\s+/g, " ")
    .trim();

  normalized = normalized.replace(/\s+ps$/i, "");
  return normalized.trim();
}

export function sameAccessName(left: unknown, right: unknown): boolean {
  const a = normalizeAccessName(left);
  const b = normalizeAccessName(right);
  return a.length > 0 && a === b;
}

export function filterValidRecords(data: unknown[]): GaneshRecord[] {
  return data.filter((item): item is GaneshRecord => {
    if (typeof item !== "object" || item === null) {
      return false;
    }
    const record = item as GaneshRecord;
    return text(record.unique_id).length > 0;
  });
}

function computeVersionToken(records: GaneshRecord[], timestampIso: string): string {
  const timeMs = new Date(timestampIso).getTime();
  const sample = records.length > 0 ? text(records[0].unique_id) : "empty";
  const str = `${timeMs}_${records.length}_${sample}`;
  let hash = 0;
  for (let i = 0; i < str.length; i++) {
    hash = (hash * 31 + str.charCodeAt(i)) >>> 0;
  }
  return `v_${timeMs}_${hash.toString(16)}`;
}

async function tryReadFileFallback(): Promise<GaneshRecord[] | null> {
  const candidatePaths = [
    path.resolve(process.cwd(), "../mobile/ganesh_api.json"),
    path.resolve(process.cwd(), "ganesh_api.json"),
    path.resolve(process.cwd(), "public/ganesh_api.json"),
    path.resolve("/var/www/ganesh-bandobust/mobile/ganesh_api.json"),
    path.resolve("/var/www/ganesh-bandobust/ganesh_api.json"),
  ];

  for (const candidate of candidatePaths) {
    try {
      if (existsSync(candidate)) {
        const raw = await readFile(candidate, "utf8");
        const parsed = JSON.parse(raw);
        if (Array.isArray(parsed) && parsed.length > 0) {
          return filterValidRecords(parsed);
        }
      }
    } catch {
      // Continue to next candidate
    }
  }

  return null;
}

export async function loadGpidMaster(options?: {
  forceNetwork?: boolean;
  timeoutMs?: number;
}): Promise<{
  records: GaneshRecord[];
  version: string;
  lastSuccessfulAt: string;
  source: "live" | "memory-cache" | "file-fallback";
}> {
  const forceNetwork = options?.forceNetwork ?? false;
  const timeoutMs = options?.timeoutMs ?? UPSTREAM_TIMEOUT_MS;

  // 1. Check in-memory cache if not forced
  if (
    !forceNetwork &&
    memoryCache !== null &&
    memoryCache.length > 0 &&
    lastSuccessfulAt !== null
  ) {
    const elapsed = Date.now() - new Date(lastSuccessfulAt).getTime();
    if (elapsed < CACHE_TTL_MS && cacheVersion) {
      return {
        records: memoryCache,
        version: cacheVersion,
        lastSuccessfulAt,
        source: "memory-cache",
      };
    }
  }

  // 2. Try fetching from upstream
  const controller = new AbortController();
  const timeoutId = setTimeout(() => {
    controller.abort();
  }, timeoutMs);

  try {
    const response = await fetch(GANESH_API_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Accept: "application/json",
      },
      cache: "no-store",
      signal: controller.signal,
    });

    if (response.ok) {
      const data = await response.json();
      if (Array.isArray(data) && data.length > 0) {
        const valid = filterValidRecords(data);
        memoryCache = valid;
        lastSuccessfulAt = new Date().toISOString();
        cacheVersion = computeVersionToken(valid, lastSuccessfulAt);
        lastCacheSource = "live";

        return {
          records: valid,
          version: cacheVersion,
          lastSuccessfulAt,
          source: "live",
        };
      }
    }
  } catch (error) {
    console.warn("Upstream Ganesh API fetch failed/timed out, checking cache:", error);
  } finally {
    clearTimeout(timeoutId);
  }

  // 3. Fallback to existing memory cache even if older than TTL
  if (memoryCache !== null && memoryCache.length > 0 && lastSuccessfulAt && cacheVersion) {
    return {
      records: memoryCache,
      version: cacheVersion,
      lastSuccessfulAt,
      source: "memory-cache",
    };
  }

  // 4. Fallback to file snapshot if memory cache was never populated
  const fileFallback = await tryReadFileFallback();
  if (fileFallback && fileFallback.length > 0) {
    memoryCache = fileFallback;
    lastSuccessfulAt = lastSuccessfulAt || new Date().toISOString();
    cacheVersion = computeVersionToken(fileFallback, lastSuccessfulAt);
    lastCacheSource = "file-fallback";

    return {
      records: fileFallback,
      version: cacheVersion,
      lastSuccessfulAt,
      source: "file-fallback",
    };
  }

  throw new Error("Unable to retrieve Ganesh master records from upstream or local cache.");
}

export function isRecordPermittedForUser(
  record: GaneshRecord,
  user: UserJurisdictionScope,
): boolean {
  if (user.role === "ADMIN" || user.allZones) {
    return true;
  }

  if (user.allPoliceStations) {
    if (text(user.zoneName).length > 0) {
      return sameAccessName(record.zone_name, user.zoneName);
    }
    if (text(user.divisionName).length > 0) {
      return sameAccessName(record.division_name, user.divisionName);
    }
    if (text(user.policeStationName).length > 0) {
      return sameAccessName(record.ps_name, user.policeStationName);
    }
    return false;
  }

  const allowedPoliceStations = new Set(
    user.policeStationAccesses
      .filter((access) => access.canView)
      .map((access) => normalizeAccessName(access.policeStationName))
      .filter((name) => name.length > 0),
  );

  if (text(user.policeStationName).length > 0) {
    allowedPoliceStations.add(normalizeAccessName(user.policeStationName));
  }

  if (allowedPoliceStations.size === 0) {
    return false;
  }

  return allowedPoliceStations.has(normalizeAccessName(record.ps_name));
}

export function filterRecordsForUser(
  records: GaneshRecord[],
  user: UserJurisdictionScope,
): GaneshRecord[] {
  return records.filter((record) => isRecordPermittedForUser(record, user));
}

export function findGpidRecord(
  records: GaneshRecord[],
  gpid: string,
): GaneshRecord | null {
  const normalizedGpid = gpid.trim().toUpperCase();
  if (normalizedGpid.length === 0) {
    return null;
  }

  for (const record of records) {
    const uniqueId = text(record.unique_id).toUpperCase();
    const refNo = text(record.ref_no).toUpperCase();

    if (uniqueId === normalizedGpid || refNo === normalizedGpid) {
      return record;
    }
  }

  return null;
}
