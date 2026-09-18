import { GANESH_HIERARCHY, GaneshHierarchyRecord } from "@/lib/hierarchy/ganeshHierarchy";

export type RoleScopeConfig = {
  role: string;
  accessLevel: number;
  allRanges: boolean;
  allZones: boolean;
  allDivisions: boolean;
  allPoliceStations: boolean;
};

export const ROLE_SCOPE_MAP: Record<string, RoleScopeConfig> = {
  FIELD_OFFICER: {
    role: "FIELD_OFFICER",
    accessLevel: 1,
    allRanges: false,
    allZones: false,
    allDivisions: false,
    allPoliceStations: false,
  },
  SECTOR_INCHARGE: {
    role: "SECTOR_INCHARGE",
    accessLevel: 2,
    allRanges: false,
    allZones: false,
    allDivisions: false,
    allPoliceStations: false,
  },
  PS_SUPERVISOR: {
    role: "PS_SUPERVISOR",
    accessLevel: 3,
    allRanges: false,
    allZones: false,
    allDivisions: false,
    allPoliceStations: false,
  },
  SHO: {
    role: "SHO",
    accessLevel: 3,
    allRanges: false,
    allZones: false,
    allDivisions: false,
    allPoliceStations: false,
  },
  DIVISIONAL_SUPERVISOR: {
    role: "DIVISIONAL_SUPERVISOR",
    accessLevel: 4,
    allRanges: false,
    allZones: false,
    allDivisions: false,
    allPoliceStations: true,
  },
  ZONAL_SUPERVISOR: {
    role: "ZONAL_SUPERVISOR",
    accessLevel: 5,
    allRanges: false,
    allZones: false,
    allDivisions: true,
    allPoliceStations: true,
  },
  RANGE_SUPERVISOR: {
    role: "RANGE_SUPERVISOR",
    accessLevel: 6,
    allRanges: false,
    allZones: true,
    allDivisions: true,
    allPoliceStations: true,
  },
  ADMIN: {
    role: "ADMIN",
    accessLevel: 7,
    allRanges: true,
    allZones: true,
    allDivisions: true,
    allPoliceStations: true,
  },
};

export function getRoleScopeConfig(role: string): RoleScopeConfig {
  const normalizedRole = role.trim().toUpperCase();
  return (
    ROLE_SCOPE_MAP[normalizedRole] ?? {
      role: normalizedRole,
      accessLevel: 1,
      allRanges: false,
      allZones: false,
      allDivisions: false,
      allPoliceStations: false,
    }
  );
}

function normalize(val?: string | null): string {
  return String(val ?? "").trim().toLowerCase();
}

/**
 * Resolves full parent hierarchy (Commissionerate, Range, Zone, Division, Police Station)
 * using authoritative GANESH_HIERARCHY master.
 */
export function resolveCompleteParentHierarchy(input: {
  rangeName?: string | null;
  zoneName?: string | null;
  divisionName?: string | null;
  policeStationName?: string | null;
}): {
  commissionerateName: string;
  rangeName: string | null;
  zoneName: string | null;
  divisionName: string | null;
  policeStationName: string | null;
} {
  const psNorm = normalize(input.policeStationName);
  const divNorm = normalize(input.divisionName);
  const zoneNorm = normalize(input.zoneName);
  const rangeNorm = normalize(input.rangeName);

  let match: GaneshHierarchyRecord | undefined;

  if (psNorm) {
    match = GANESH_HIERARCHY.find(
      (h) => normalize(h.policeStation) === psNorm
    );
  }

  if (!match && divNorm) {
    match = GANESH_HIERARCHY.find(
      (h) => normalize(h.division) === divNorm && (!zoneNorm || normalize(h.zone) === zoneNorm)
    );
  }

  if (!match && zoneNorm) {
    match = GANESH_HIERARCHY.find(
      (h) => normalize(h.zone) === zoneNorm && (!rangeNorm || normalize(h.range) === rangeNorm)
    );
  }

  if (!match && rangeNorm) {
    match = GANESH_HIERARCHY.find(
      (h) => normalize(h.range) === rangeNorm
    );
  }

  if (match) {
    return {
      commissionerateName: match.commissionerate || "Hyderabad",
      rangeName: match.range || input.rangeName || null,
      zoneName: input.zoneName || match.zone || null,
      divisionName: input.divisionName || match.division || null,
      policeStationName: input.policeStationName || match.policeStation || null,
    };
  }

  return {
    commissionerateName: "Hyderabad",
    rangeName: input.rangeName ? String(input.rangeName).trim() : null,
    zoneName: input.zoneName ? String(input.zoneName).trim() : null,
    divisionName: input.divisionName ? String(input.divisionName).trim() : null,
    policeStationName: input.policeStationName ? String(input.policeStationName).trim() : null,
  };
}
