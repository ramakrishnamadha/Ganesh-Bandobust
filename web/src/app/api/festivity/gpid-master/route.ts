import { NextResponse } from "next/server";

export const dynamic = "force-dynamic";
export const runtime = "nodejs";

type RawRecord = Record<string, unknown>;

type SafeGeoRecord = {
  latitude: number;
  longitude: number;
  matchType: string | null;
};

function text(value: unknown): string | null {
  if (value === null || value === undefined) {
    return null;
  }

  const result = String(value).trim();

  return result ? result : null;
}

function numberValue(value: unknown): number | null {
  if (
    value === null ||
    value === undefined ||
    value === ""
  ) {
    return null;
  }

  const parsed = Number(value);

  return Number.isFinite(parsed)
    ? parsed
    : null;
}

async function fetchPolicePortal(): Promise<unknown> {
  const controller = new AbortController();

  const timeout = setTimeout(() => {
    controller.abort();
  }, 60000);

  try {
    const response = await fetch(
      "https://policeportal.tspolice.gov.in/ganesh/getGanaDetails/22",
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Accept: "application/json",
        },
        cache: "no-store",
        signal: controller.signal,
      },
    );

    if (!response.ok) {
      throw new Error(
        `Police portal returned HTTP ${response.status}.`,
      );
    }

    const responseText =
      await response.text();

    if (!responseText.trim()) {
      throw new Error(
        "Police portal returned an empty response.",
      );
    }

    return JSON.parse(responseText);
  } finally {
    clearTimeout(timeout);
  }
}

/*
 * /api/pre-geo already performs the conservative matching between:
 *
 *   2026 GPID master
 *          +
 *   2025 geo-tagging data
 *
 * We reuse only its finalLinkedRecords output.
 *
 * Ambiguous/unresolved records are NOT used here.
 */
async function fetchSafePreGeoLinks(): Promise<
  Map<string, SafeGeoRecord>
> {
  const geoMap =
    new Map<string, SafeGeoRecord>();

  const port =
    process.env.PORT || "3000";

  const url =
    `http://127.0.0.1:${port}/api/pre-geo`;

  const controller =
    new AbortController();

  const timeout = setTimeout(() => {
    controller.abort();
  }, 60000);

  try {
    const response = await fetch(
      url,
      {
        method: "GET",
        headers: {
          Accept: "application/json",
        },
        cache: "no-store",
        signal: controller.signal,
      },
    );

    if (!response.ok) {
      console.error(
        `Pre-Geo API returned HTTP ${response.status}.`,
      );

      return geoMap;
    }

    const data =
      (await response.json()) as RawRecord;

    const linkedRecords =
      data.finalLinkedRecords;

    if (!Array.isArray(linkedRecords)) {
      console.error(
        "Pre-Geo API finalLinkedRecords is unavailable.",
      );

      return geoMap;
    }

    for (const item of linkedRecords) {
      if (
        item === null ||
        typeof item !== "object"
      ) {
        continue;
      }

      const row =
        item as RawRecord;

      const gpid =
        text(row.gpid);

      const latitude =
        numberValue(
          row.preGeo2025Latitude,
        );

      const longitude =
        numberValue(
          row.preGeo2025Longitude,
        );

      if (
        !gpid ||
        latitude === null ||
        longitude === null
      ) {
        continue;
      }

      /*
       * Basic coordinate validation.
       * This does not judge whether a location is correct;
       * it only rejects impossible coordinates.
       */
      if (
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180
      ) {
        continue;
      }

      geoMap.set(
        gpid,
        {
          latitude,
          longitude,
          matchType:
            text(row.matchType),
        },
      );
    }

    return geoMap;
  } catch (error) {
    /*
     * Geo enrichment must not bring down
     * the entire GPID master API.
     *
     * If Pre-Geo is temporarily unavailable,
     * current GPID data will still be returned.
     */
    console.error(
      "Unable to load safe Pre-Geo links:",
      error,
    );

    return geoMap;
  } finally {
    clearTimeout(timeout);
  }
}

export async function GET() {
  try {
    /*
     * Load current GPIDs and historical safe
     * geo-links in parallel.
     */
    const [
      data,
      safePreGeoLinks,
    ] = await Promise.all([
      fetchPolicePortal(),
      fetchSafePreGeoLinks(),
    ]);

    if (!Array.isArray(data)) {
      return NextResponse.json(
        {
          success: false,
          message:
            "Unexpected Ganesh master API response.",
        },
        {
          status: 502,
        },
      );
    }

    let currentGeoCount = 0;
    let preGeoLinkedCount = 0;
    let geoUnavailableCount = 0;

    const records = data
      .map((item) => {
        const row =
          item as RawRecord;

        const gpid =
          text(row.unique_id) ||
          text(row.ref_no) ||
          "";

        /*
         * Prefer current 2026 coordinates
         * if the API ever starts supplying them.
         */
        const currentLatitude =
          numberValue(
            row.latitude,
          ) ??
          numberValue(
            row.lat,
          );

        const currentLongitude =
          numberValue(
            row.longitude,
          ) ??
          numberValue(
            row.lng,
          ) ??
          numberValue(
            row.lon,
          );

        const hasCurrentGeo =
          currentLatitude !== null &&
          currentLongitude !== null &&
          currentLatitude >= -90 &&
          currentLatitude <= 90 &&
          currentLongitude >= -180 &&
          currentLongitude <= 180;

        const historicalGeo =
          gpid
            ? safePreGeoLinks.get(
                gpid,
              )
            : undefined;

        let latitude: number | null =
          null;

        let longitude: number | null =
          null;

        let geoSource:
          | "CURRENT_2026_API"
          | "PRE_GEO_2025"
          | null = null;

        let geoMatchType:
          string | null = null;

        if (hasCurrentGeo) {
          latitude =
            currentLatitude;

          longitude =
            currentLongitude;

          geoSource =
            "CURRENT_2026_API";

          currentGeoCount++;
        } else if (historicalGeo) {
          latitude =
            historicalGeo.latitude;

          longitude =
            historicalGeo.longitude;

          geoSource =
            "PRE_GEO_2025";

          geoMatchType =
            historicalGeo.matchType;

          preGeoLinkedCount++;
        } else {
          geoUnavailableCount++;
        }

        return {
          gpid,

          name:
            text(row.name),

          address:
            text(row.address),

          association:
            text(row.association),

          mobile:
            text(row.mobile_no),

          /*
           * Range is not supplied
           * by this GPID API.
           *
           * Do not infer or fabricate it.
           */
          range: null,

          zone:
            text(row.zone_name),

          division:
            text(
              row.division_name,
            ),

          policeStation:
            text(row.ps_name),

          installFromDate:
            text(
              row.instal_from_date,
            ),

          installToDate:
            text(
              row.instal_to_date,
            ),

          idolHeight:
            text(row.idol_height),

          pandalHeight:
            text(row.pendal_height),

          idolType:
            text(row.idol_type),

          immersionDate:
            text(row.immr_date),

          immersionPlace:
            text(row.riv_name),

          areaType:
            text(
              row.idol_area_type,
            ),

          status:
            text(row.status),

          latitude,
          longitude,

          /*
           * Makes the provenance explicit
           * to Web/Mobile/supervisory screens.
           */
          geoSource,

          /*
           * Present when location came
           * from the historical safe-match set.
           */
          geoMatchType,

          hasGeoLocation:
            latitude !== null &&
            longitude !== null,
        };
      })
      .filter(
        (record) =>
          Boolean(record.gpid),
      );

    /*
     * Keep one record per GPID.
     */
    const uniqueRecords =
      Array.from(
        new Map(
          records.map(
            (record) => [
              record.gpid,
              record,
            ],
          ),
        ).values(),
      );

    /*
     * Recalculate summary against
     * deduplicated final records.
     */
    const finalCurrentGeoCount =
      uniqueRecords.filter(
        (record) =>
          record.geoSource ===
          "CURRENT_2026_API",
      ).length;

    const finalPreGeoLinkedCount =
      uniqueRecords.filter(
        (record) =>
          record.geoSource ===
          "PRE_GEO_2025",
      ).length;

    const finalGeoUnavailableCount =
      uniqueRecords.filter(
        (record) =>
          !record.hasGeoLocation,
      ).length;

    return NextResponse.json(
      {
        success: true,

        fetchedAt:
          new Date().toISOString(),

        total:
          uniqueRecords.length,

        rangeAvailable:
          false,

        geoSummary: {
          current2026Coordinates:
            finalCurrentGeoCount,

          safePreGeo2025Coordinates:
            finalPreGeoLinkedCount,

          totalWithGeo:
            finalCurrentGeoCount +
            finalPreGeoLinkedCount,

          geoUnavailable:
            finalGeoUnavailableCount,

          /*
           * Number of valid safe links
           * provided by /api/pre-geo.
           *
           * A small number may not appear
           * in final records if a GPID is
           * blank/invalid/deduplicated.
           */
          safePreGeoLinkPool:
            safePreGeoLinks.size,
        },

        records:
          uniqueRecords,
      },
      {
        headers: {
          "Cache-Control":
            "no-store, no-cache, must-revalidate",
        },
      },
    );
  } catch (error) {
    console.error(
      "Ganesh GPID master API error:",
      error,
    );

    return NextResponse.json(
      {
        success: false,

        message:
          error instanceof Error
            ? error.message
            : "Unable to fetch current Ganesh master data.",
      },
      {
        status: 500,
      },
    );
  }
}