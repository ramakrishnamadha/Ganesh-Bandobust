-- ============================================================================
-- PHASE 1: DAILY MANDAP CHECKING & TARGET MANAGEMENT DDL
-- Non-destructive schema addition for Ganesh Bandobust 2026
-- ============================================================================

-- 1. CreateTable MandapDailyVisit
CREATE TABLE IF NOT EXISTS "MandapDailyVisit" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "officerEmployeeId" TEXT NOT NULL,
    "officerName" TEXT NOT NULL,
    "officerRank" TEXT NOT NULL,
    "officerRole" TEXT NOT NULL,
    "gpid" TEXT NOT NULL,
    "pandalName" TEXT,
    "commissionerateName" TEXT NOT NULL DEFAULT 'Hyderabad',
    "rangeName" TEXT NOT NULL,
    "zoneName" TEXT NOT NULL,
    "divisionName" TEXT NOT NULL,
    "policeStationName" TEXT NOT NULL,
    "sectorName" TEXT,
    "clusterName" TEXT,
    "sensitivity" TEXT NOT NULL DEFAULT 'NORMAL',
    "date" TEXT NOT NULL,
    "festivalDay" INTEGER NOT NULL,
    "visitSequenceForDay" INTEGER NOT NULL DEFAULT 1,
    "checkStartedAt" TIMESTAMP(3),
    "checkedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "latitude" DOUBLE PRECISION NOT NULL,
    "longitude" DOUBLE PRECISION NOT NULL,
    "accuracy" DOUBLE PRECISION,
    "distanceFromMandapMeters" DOUBLE PRECISION,
    "isWithinGeofence" BOOLEAN NOT NULL DEFAULT true,
    "visitType" TEXT NOT NULL DEFAULT 'ROUTINE',
    "stage" TEXT NOT NULL DEFAULT 'STAGE_3_FESTIVITY',
    "remarks" TEXT,
    "actionTaken" TEXT,
    "evidenceUrls" JSONB,
    "hasDeficiency" BOOLEAN NOT NULL DEFAULT false,
    "deficiencyCategories" JSONB,
    "requiresFollowUp" BOOLEAN NOT NULL DEFAULT false,
    "completionStatus" TEXT NOT NULL DEFAULT 'COMPLETED',
    "verificationSource" TEXT NOT NULL DEFAULT 'QR_SCAN',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "MandapDailyVisit_pkey" PRIMARY KEY ("id")
);

-- Indexes for MandapDailyVisit
CREATE INDEX IF NOT EXISTS "MandapDailyVisit_gpid_date_idx" ON "MandapDailyVisit"("gpid", "date");
CREATE INDEX IF NOT EXISTS "MandapDailyVisit_userId_date_idx" ON "MandapDailyVisit"("userId", "date");
CREATE INDEX IF NOT EXISTS "MandapDailyVisit_policeStationName_date_idx" ON "MandapDailyVisit"("policeStationName", "date");
CREATE INDEX IF NOT EXISTS "MandapDailyVisit_divisionName_date_idx" ON "MandapDailyVisit"("divisionName", "date");
CREATE INDEX IF NOT EXISTS "MandapDailyVisit_zoneName_date_idx" ON "MandapDailyVisit"("zoneName", "date");
CREATE INDEX IF NOT EXISTS "MandapDailyVisit_rangeName_date_idx" ON "MandapDailyVisit"("rangeName", "date");
CREATE INDEX IF NOT EXISTS "MandapDailyVisit_hasDeficiency_idx" ON "MandapDailyVisit"("hasDeficiency");
CREATE INDEX IF NOT EXISTS "MandapDailyVisit_sensitivity_idx" ON "MandapDailyVisit"("sensitivity");

-- 2. CreateTable DailyVisitTargetRule
CREATE TABLE IF NOT EXISTS "DailyVisitTargetRule" (
    "id" TEXT NOT NULL,
    "role" TEXT NOT NULL,
    "frequencyPerMandap" INTEGER NOT NULL DEFAULT 1,
    "minMandapsPerUnit" INTEGER NOT NULL DEFAULT 0,
    "scopeLevel" TEXT NOT NULL,
    "requiresSensitiveMandap" BOOLEAN NOT NULL DEFAULT false,
    "shiftType" TEXT NOT NULL DEFAULT 'DAY',
    "activeFromDay" INTEGER NOT NULL DEFAULT 1,
    "activeToDay" INTEGER NOT NULL DEFAULT 11,
    "active" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "DailyVisitTargetRule_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX IF NOT EXISTS "DailyVisitTargetRule_role_key" ON "DailyVisitTargetRule"("role");

-- 3. CreateTable GaneshDutyAssignment
CREATE TABLE IF NOT EXISTS "GaneshDutyAssignment" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "officerEmployeeId" TEXT NOT NULL,
    "officerName" TEXT NOT NULL,
    "officerRank" TEXT NOT NULL,
    "assignedRole" TEXT NOT NULL,
    "commissionerateName" TEXT NOT NULL DEFAULT 'Hyderabad',
    "rangeName" TEXT NOT NULL,
    "zoneName" TEXT NOT NULL,
    "divisionName" TEXT NOT NULL,
    "policeStationName" TEXT NOT NULL,
    "sectorName" TEXT,
    "clusterName" TEXT,
    "assignedGpids" JSONB,
    "effectiveFrom" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "effectiveTo" TIMESTAMP(3),
    "status" TEXT NOT NULL DEFAULT 'ACTIVE',
    "notes" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "GaneshDutyAssignment_pkey" PRIMARY KEY ("id")
);

CREATE INDEX IF NOT EXISTS "GaneshDutyAssignment_userId_status_idx" ON "GaneshDutyAssignment"("userId", "status");
CREATE INDEX IF NOT EXISTS "GaneshDutyAssignment_policeStationName_status_idx" ON "GaneshDutyAssignment"("policeStationName", "status");
CREATE INDEX IF NOT EXISTS "GaneshDutyAssignment_sectorName_status_idx" ON "GaneshDutyAssignment"("sectorName", "status");
CREATE INDEX IF NOT EXISTS "GaneshDutyAssignment_clusterName_status_idx" ON "GaneshDutyAssignment"("clusterName", "status");

-- 4. CreateTable DailyOfficerTargetSummary
CREATE TABLE IF NOT EXISTS "DailyOfficerTargetSummary" (
    "id" TEXT NOT NULL,
    "date" TEXT NOT NULL,
    "festivalDay" INTEGER NOT NULL,
    "userId" TEXT NOT NULL,
    "officerEmployeeId" TEXT NOT NULL,
    "officerName" TEXT NOT NULL,
    "officerRank" TEXT NOT NULL,
    "officerRole" TEXT NOT NULL,
    "commissionerateName" TEXT NOT NULL DEFAULT 'Hyderabad',
    "rangeName" TEXT NOT NULL,
    "zoneName" TEXT NOT NULL,
    "divisionName" TEXT NOT NULL,
    "policeStationName" TEXT NOT NULL,
    "sectorName" TEXT,
    "clusterName" TEXT,
    "targetMandapCount" INTEGER NOT NULL DEFAULT 0,
    "targetTotalVisits" INTEGER NOT NULL DEFAULT 0,
    "completedUniqueMandaps" INTEGER NOT NULL DEFAULT 0,
    "completedTotalVisits" INTEGER NOT NULL DEFAULT 0,
    "sensitiveTargetCount" INTEGER NOT NULL DEFAULT 0,
    "sensitiveCompletedCount" INTEGER NOT NULL DEFAULT 0,
    "deficienciesReported" INTEGER NOT NULL DEFAULT 0,
    "compliancePercentage" DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    "status" TEXT NOT NULL DEFAULT 'DEFICIT',
    "lastVisitedAt" TIMESTAMP(3),
    "calculatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "DailyOfficerTargetSummary_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX IF NOT EXISTS "DailyOfficerTargetSummary_date_userId_key" ON "DailyOfficerTargetSummary"("date", "userId");
CREATE INDEX IF NOT EXISTS "DailyOfficerTargetSummary_date_policeStationName_idx" ON "DailyOfficerTargetSummary"("date", "policeStationName");
CREATE INDEX IF NOT EXISTS "DailyOfficerTargetSummary_date_divisionName_idx" ON "DailyOfficerTargetSummary"("date", "divisionName");
CREATE INDEX IF NOT EXISTS "DailyOfficerTargetSummary_date_zoneName_idx" ON "DailyOfficerTargetSummary"("date", "zoneName");
CREATE INDEX IF NOT EXISTS "DailyOfficerTargetSummary_date_rangeName_idx" ON "DailyOfficerTargetSummary"("date", "rangeName");
CREATE INDEX IF NOT EXISTS "DailyOfficerTargetSummary_date_status_idx" ON "DailyOfficerTargetSummary"("date", "status");
