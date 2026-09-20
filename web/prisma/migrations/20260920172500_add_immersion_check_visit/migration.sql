CREATE TABLE "ImmersionCheckVisit" (
    "id" TEXT NOT NULL,
    "gpid" TEXT NOT NULL,
    "applicationId" TEXT,
    "userId" TEXT NOT NULL,
    "officerEmployeeId" TEXT,
    "officerName" TEXT NOT NULL,
    "officerRank" TEXT,
    "officerRole" TEXT,
    "commissionerateCode" TEXT,
    "commissionerateName" TEXT,
    "rangeCode" TEXT,
    "rangeName" TEXT,
    "zoneCode" TEXT,
    "zoneName" TEXT,
    "divisionCode" TEXT,
    "divisionName" TEXT,
    "policeStationCode" TEXT,
    "policeStationName" TEXT,
    "sectorCode" TEXT,
    "sectorName" TEXT,
    "clusterCode" TEXT,
    "clusterName" TEXT,
    "preVerificationResult" JSONB,
    "processionFormationResult" JSONB,
    "routeManagementResult" JSONB,
    "trackingResult" JSONB,
    "immersionPointResult" JSONB,
    "finalConfirmationResult" JSONB,
    "status" TEXT NOT NULL DEFAULT 'IN_PROGRESS',
    "currentStep" INTEGER NOT NULL DEFAULT 0,
    "latitude" DOUBLE PRECISION,
    "longitude" DOUBLE PRECISION,
    "accuracy" DOUBLE PRECISION,
    "checkSource" TEXT,
    "userSessionId" TEXT,
    "deviceSessionId" TEXT,
    "checkStartedAt" TIMESTAMP(3),
    "checkedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "submittedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "ImmersionCheckVisit_pkey" PRIMARY KEY ("id")
);
CREATE INDEX "ImmersionCheckVisit_gpid_idx" ON "ImmersionCheckVisit"("gpid");
CREATE INDEX "ImmersionCheckVisit_gpid_checkedAt_idx" ON "ImmersionCheckVisit"("gpid", "checkedAt");
CREATE INDEX "ImmersionCheckVisit_userId_checkedAt_idx" ON "ImmersionCheckVisit"("userId", "checkedAt");
CREATE INDEX "ImmersionCheckVisit_gpid_userId_status_idx" ON "ImmersionCheckVisit"("gpid", "userId", "status");
CREATE INDEX "ImmersionCheckVisit_policeStationCode_idx" ON "ImmersionCheckVisit"("policeStationCode");
CREATE INDEX "ImmersionCheckVisit_divisionCode_idx" ON "ImmersionCheckVisit"("divisionCode");
CREATE INDEX "ImmersionCheckVisit_zoneCode_idx" ON "ImmersionCheckVisit"("zoneCode");
CREATE INDEX "ImmersionCheckVisit_status_idx" ON "ImmersionCheckVisit"("status");
