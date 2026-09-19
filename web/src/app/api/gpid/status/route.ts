import { NextRequest, NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { verifySessionToken, SESSION_COOKIE_NAME } from "@/lib/server/auth";
import {
  loadGpidMaster,
  filterRecordsForUser,
  isRecordPermittedForUser,
  findGpidRecord,
  text,
} from "@/lib/server/gpidMaster";

export const dynamic = "force-dynamic";
export const runtime = "nodejs";

export async function GET(request: NextRequest) {
  try {
    // 1. Authentication check
    const sessionToken = request.cookies.get(SESSION_COOKIE_NAME)?.value;

    if (!sessionToken) {
      return NextResponse.json(
        {
          success: false,
          error: "Authentication required.",
        },
        {
          status: 401,
          headers: {
            "Cache-Control": "no-store",
          },
        },
      );
    }

    const session = verifySessionToken(sessionToken);

    if (!session) {
      return NextResponse.json(
        {
          success: false,
          error: "Invalid or expired session.",
        },
        {
          status: 401,
          headers: {
            "Cache-Control": "no-store",
          },
        },
      );
    }

    // 2. Fetch authenticated officer profile & jurisdiction
    const user = await prisma.user.findUnique({
      where: {
        id: session.userId,
      },
      include: {
        policeStationAccesses: {
          where: {
            canView: true,
          },
          select: {
            policeStationName: true,
            canView: true,
            canEdit: true,
          },
        },
      },
    });

    if (!user) {
      return NextResponse.json(
        {
          success: false,
          error: "User account not found.",
        },
        {
          status: 401,
          headers: {
            "Cache-Control": "no-store",
          },
        },
      );
    }

    if (user.status !== "ACTIVE") {
      return NextResponse.json(
        {
          success: false,
          error: "This user account is inactive. Please contact your administrator.",
        },
        {
          status: 403,
          headers: {
            "Cache-Control": "no-store",
          },
        },
      );
    }

    // 3. Load GPID master records (fast in-memory cache or fallback)
    const { records, version, lastSuccessfulAt, source } = await loadGpidMaster();

    // 4. Determine user scope & filtered records
    const permittedRecords = filterRecordsForUser(records, user);

    // 5. Check if a specific GPID was requested
    const targetGpidParam = request.nextUrl.searchParams.get("gpid");

    // Case A: General GPID Cache Status (Mobile app sync check)
    if (targetGpidParam === null) {
      return NextResponse.json(
        {
          success: true,
          version,
          totalCount: permittedRecords.length,
          lastSuccessfulAt,
          cacheSource: source,
          officer: {
            employeeId: user.employeeId,
            name: user.name,
            rank: user.rank,
            role: user.role,
            policeStationName: user.policeStationName,
            divisionName: user.divisionName,
            zoneName: user.zoneName,
            rangeName: user.rangeName,
            accessibleCount: permittedRecords.length,
            systemTotalCount: records.length,
          },
        },
        {
          status: 200,
          headers: {
            "Cache-Control": "no-store",
            "X-GPID-Version": version,
          },
        },
      );
    }

    // Case B: Specific GPID Query & Validation
    const requestedGpid = targetGpidParam.trim();

    if (requestedGpid.length === 0) {
      return NextResponse.json(
        {
          success: false,
          error: "The 'gpid' parameter must not be empty.",
        },
        {
          status: 400,
          headers: {
            "Cache-Control": "no-store",
          },
        },
      );
    }

    const matchedRecord = findGpidRecord(records, requestedGpid);

    if (!matchedRecord) {
      return NextResponse.json(
        {
          success: false,
          error: `GPID not found: ${requestedGpid}`,
          gpid: requestedGpid,
        },
        {
          status: 404,
          headers: {
            "Cache-Control": "no-store",
          },
        },
      );
    }

    // Enforce jurisdictional permission
    const isPermitted = isRecordPermittedForUser(matchedRecord, user);

    if (!isPermitted) {
      const jurisdictionLabel =
        user.policeStationName ||
        user.divisionName ||
        user.zoneName ||
        "assigned jurisdiction";

      return NextResponse.json(
        {
          success: false,
          error: `Access Denied: GPID '${requestedGpid}' is in '${text(matchedRecord.ps_name)}' PS, which is outside your authorized scope (${jurisdictionLabel}).`,
          gpid: requestedGpid,
          authorized: false,
        },
        {
          status: 403,
          headers: {
            "Cache-Control": "no-store",
          },
        },
      );
    }

    const canonGpid = text(matchedRecord.unique_id);

    // Query Stage 1, Stage 2, and Stage 3 statuses for this GPID
    const [stage1Verification, latestStage2Visit, latestStage3Visit] =
      await Promise.all([
        prisma.preInstallationVerification.findUnique({
          where: { gpid: canonGpid },
          select: {
            verificationStatus: true,
            submittedAt: true,
            updatedAt: true,
          },
        }),
        prisma.installationCheckVisit.findFirst({
          where: { gpid: canonGpid },
          orderBy: { checkedAt: "desc" },
          select: {
            id: true,
            status: true,
            hasDeficiency: true,
            requiresFollowUp: true,
            poojaPending: true,
            checkedAt: true,
            officerName: true,
            officerRank: true,
          },
        }),
        prisma.festivityCheckVisit.findFirst({
          where: { gpid: canonGpid },
          orderBy: { checkedAt: "desc" },
          select: {
            id: true,
            festivalDay: true,
            festivalDate: true,
            status: true,
            hasDeficiency: true,
            requiresFollowUp: true,
            poojaPending: true,
            soundPending: true,
            fireSafetyPending: true,
            checkedAt: true,
            officerName: true,
            officerRank: true,
          },
        }),
      ]);

    return NextResponse.json(
      {
        success: true,
        version,
        totalCount: permittedRecords.length,
        gpid: canonGpid,
        applicationId: text(matchedRecord.ref_no),
        found: true,
        authorized: true,
        record: {
          unique_id: canonGpid,
          ref_no: text(matchedRecord.ref_no),
          name: text(matchedRecord.name),
          association: text(matchedRecord.association),
          mobile_no: text(matchedRecord.mobile_no),
          address: text(matchedRecord.address),
          ps_name: text(matchedRecord.ps_name),
          division_name: text(matchedRecord.division_name),
          zone_name: text(matchedRecord.zone_name),
          range_name: text(matchedRecord.range_name) || "South Range",
          dist_name: text(matchedRecord.dist_name),
          idol_height: text(matchedRecord.idol_height),
          idol_type: text(matchedRecord.idol_type),
          instal_from_date: text(matchedRecord.instal_from_date),
          instal_to_date: text(matchedRecord.instal_to_date),
          immr_date: text(matchedRecord.immr_date),
          riv_name: text(matchedRecord.riv_name),
          latitude: matchedRecord.latitude ?? null,
          longitude: matchedRecord.longitude ?? null,
        },
        stages: {
          stage1: {
            name: "Pre-Installation",
            status: stage1Verification?.verificationStatus ?? "NOT_STARTED",
            submittedAt: stage1Verification?.submittedAt ?? null,
          },
          stage2: {
            name: "Installation",
            status: latestStage2Visit?.status ?? "NOT_STARTED",
            hasDeficiency: latestStage2Visit?.hasDeficiency ?? false,
            poojaPending: latestStage2Visit?.poojaPending ?? false,
            checkedAt: latestStage2Visit?.checkedAt ?? null,
            officerName: latestStage2Visit?.officerName ?? null,
          },
          stage3: {
            name: "During Festivity",
            status: latestStage3Visit?.status ?? "NOT_STARTED",
            hasDeficiency: latestStage3Visit?.hasDeficiency ?? false,
            poojaPending: latestStage3Visit?.poojaPending ?? false,
            soundPending: latestStage3Visit?.soundPending ?? false,
            fireSafetyPending: latestStage3Visit?.fireSafetyPending ?? false,
            festivalDay: latestStage3Visit?.festivalDay ?? null,
            checkedAt: latestStage3Visit?.checkedAt ?? null,
            officerName: latestStage3Visit?.officerName ?? null,
          },
        },
      },
      {
        status: 200,
        headers: {
          "Cache-Control": "no-store",
          "X-GPID-Version": version,
        },
      },
    );
  } catch (error) {
    console.error("GPID status endpoint error:", error);
    return NextResponse.json(
      {
        success: false,
        error: "An internal server error occurred while retrieving GPID status.",
      },
      {
        status: 500,
        headers: {
          "Cache-Control": "no-store",
        },
      },
    );
  }
}
