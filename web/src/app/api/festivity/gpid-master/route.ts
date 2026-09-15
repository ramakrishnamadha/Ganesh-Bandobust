import { NextResponse } from "next/server";
import { execFile } from "node:child_process";
import { promisify } from "node:util";

export const dynamic = "force-dynamic";
export const runtime = "nodejs";

const execFileAsync = promisify(execFile);

type RawRecord = Record<string, unknown>;

function text(value: unknown): string | null {
  if (value === null || value === undefined) return null;

  const result = String(value).trim();
  return result ? result : null;
}

function numberValue(value: unknown): number | null {
  if (value === null || value === undefined || value === "") {
    return null;
  }

  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : null;
}

async function fetchPolicePortal(): Promise<unknown> {
  const { stdout } = await execFileAsync(
    "curl.exe",
    [
      "-sS",
      "--connect-timeout",
      "10",
      "--max-time",
      "30",
      "-X",
      "POST",
      "https://policeportal.tspolice.gov.in/ganesh/getGanaDetails/22",
      "-H",
      "Content-Type: application/json",
      "-H",
      "Accept: application/json",
    ],
    {
      timeout: 35000,
      maxBuffer: 25 * 1024 * 1024,
      windowsHide: true,
    },
  );

  if (!stdout || !stdout.trim()) {
    throw new Error(
      "Police portal returned an empty response.",
    );
  }

  return JSON.parse(stdout);
}

export async function GET() {
  try {
    const data = await fetchPolicePortal();

    if (!Array.isArray(data)) {
      return NextResponse.json(
        {
          success: false,
          message: "Unexpected Ganesh master API response.",
        },
        { status: 502 },
      );
    }

    const records = data
      .map((item) => {
        const row = item as RawRecord;

        const gpid =
          text(row.unique_id) ||
          text(row.ref_no) ||
          "";

        return {
          gpid,

          name: text(row.name),
          address: text(row.address),
          association: text(row.association),
          mobile: text(row.mobile_no),

          // Range is not supplied by this API.
          // Do not infer or fabricate it.
          range: null,

          zone: text(row.zone_name),
          division: text(row.division_name),
          policeStation: text(row.ps_name),

          installFromDate: text(row.instal_from_date),
          installToDate: text(row.instal_to_date),

          idolHeight: text(row.idol_height),
          pandalHeight: text(row.pendal_height),
          idolType: text(row.idol_type),

          immersionDate: text(row.immr_date),
          immersionPlace: text(row.riv_name),

          areaType: text(row.idol_area_type),
          status: text(row.status),

          latitude:
            numberValue(row.latitude) ??
            numberValue(row.lat),

          longitude:
            numberValue(row.longitude) ??
            numberValue(row.lng) ??
            numberValue(row.lon),
        };
      })
      .filter((record) => Boolean(record.gpid));

    const uniqueRecords = Array.from(
      new Map(
        records.map((record) => [
          record.gpid,
          record,
        ]),
      ).values(),
    );

    return NextResponse.json(
      {
        success: true,
        fetchedAt: new Date().toISOString(),
        total: uniqueRecords.length,
        rangeAvailable: false,
        records: uniqueRecords,
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
      "Ganesh policeportal API error:",
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
      { status: 500 },
    );
  }
}
