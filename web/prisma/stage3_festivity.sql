-- CreateTable
CREATE TABLE "FestivityCheckVisit" (
    "id" TEXT NOT NULL,
    "gpid" TEXT NOT NULL,
    "applicationId" TEXT,
    "festivalDay" INTEGER NOT NULL,
    "festivalDate" TIMESTAMP(3) NOT NULL,
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
    "antiDigressionResult" JSONB,
    "volunteerResult" JSONB,
    "lightingResult" JSONB,
    "sanitationResult" JSONB,
    "poojaResult" JSONB,
    "soundSystemResult" JSONB,
    "fireSafetyResult" JSONB,
    "evidenceResult" JSONB,
    "remarks" TEXT,
    "actionTaken" TEXT,
    "status" TEXT NOT NULL DEFAULT 'SAVED',
    "hasDeficiency" BOOLEAN NOT NULL DEFAULT false,
    "requiresFollowUp" BOOLEAN NOT NULL DEFAULT false,
    "poojaPending" BOOLEAN NOT NULL DEFAULT false,
    "soundPending" BOOLEAN NOT NULL DEFAULT false,
    "fireSafetyPending" BOOLEAN NOT NULL DEFAULT false,
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

    CONSTRAINT "FestivityCheckVisit_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "FestivityCheckVisit_gpid_idx" ON "FestivityCheckVisit"("gpid");

-- CreateIndex
CREATE INDEX "FestivityCheckVisit_gpid_festivalDay_idx" ON "FestivityCheckVisit"("gpid", "festivalDay");

-- CreateIndex
CREATE INDEX "FestivityCheckVisit_gpid_festivalDate_idx" ON "FestivityCheckVisit"("gpid", "festivalDate");

-- CreateIndex
CREATE INDEX "FestivityCheckVisit_gpid_checkedAt_idx" ON "FestivityCheckVisit"("gpid", "checkedAt");

-- CreateIndex
CREATE INDEX "FestivityCheckVisit_userId_checkedAt_idx" ON "FestivityCheckVisit"("userId", "checkedAt");

-- CreateIndex
CREATE INDEX "FestivityCheckVisit_policeStationCode_idx" ON "FestivityCheckVisit"("policeStationCode");

-- CreateIndex
CREATE INDEX "FestivityCheckVisit_divisionCode_idx" ON "FestivityCheckVisit"("divisionCode");

-- CreateIndex
CREATE INDEX "FestivityCheckVisit_zoneCode_idx" ON "FestivityCheckVisit"("zoneCode");

-- CreateIndex
CREATE INDEX "FestivityCheckVisit_status_idx" ON "FestivityCheckVisit"("status");

-- CreateIndex
CREATE INDEX "FestivityCheckVisit_hasDeficiency_idx" ON "FestivityCheckVisit"("hasDeficiency");

-- CreateIndex
CREATE INDEX "FestivityCheckVisit_requiresFollowUp_idx" ON "FestivityCheckVisit"("requiresFollowUp");

-- CreateIndex
CREATE INDEX "FestivityCheckVisit_poojaPending_idx" ON "FestivityCheckVisit"("poojaPending");

-- CreateIndex
CREATE INDEX "FestivityCheckVisit_soundPending_idx" ON "FestivityCheckVisit"("soundPending");

-- CreateIndex
CREATE INDEX "FestivityCheckVisit_fireSafetyPending_idx" ON "FestivityCheckVisit"("fireSafetyPending");

