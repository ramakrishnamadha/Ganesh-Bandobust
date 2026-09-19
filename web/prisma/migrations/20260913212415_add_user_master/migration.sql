-- CreateTable
CREATE TABLE "User" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "employeeId" TEXT NOT NULL,
    "username" TEXT NOT NULL,
    "passwordHash" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "rank" TEXT NOT NULL,
    "phoneNumber" TEXT,
    "team" TEXT,
    "role" TEXT NOT NULL,
    "accessLevel" INTEGER NOT NULL,
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
    "allPoliceStations" BOOLEAN NOT NULL DEFAULT false,
    "allDivisions" BOOLEAN NOT NULL DEFAULT false,
    "allZones" BOOLEAN NOT NULL DEFAULT false,
    "allRanges" BOOLEAN NOT NULL DEFAULT false,
    "status" TEXT NOT NULL DEFAULT 'ACTIVE',
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL
);

-- CreateIndex
CREATE UNIQUE INDEX "User_employeeId_key" ON "User"("employeeId");

-- CreateIndex
CREATE UNIQUE INDEX "User_username_key" ON "User"("username");

-- CreateIndex
CREATE INDEX "User_employeeId_idx" ON "User"("employeeId");

-- CreateIndex
CREATE INDEX "User_username_idx" ON "User"("username");

-- CreateIndex
CREATE INDEX "User_role_idx" ON "User"("role");

-- CreateIndex
CREATE INDEX "User_accessLevel_idx" ON "User"("accessLevel");

-- CreateIndex
CREATE INDEX "User_status_idx" ON "User"("status");

-- CreateIndex
CREATE INDEX "User_rangeCode_idx" ON "User"("rangeCode");

-- CreateIndex
CREATE INDEX "User_zoneCode_idx" ON "User"("zoneCode");

-- CreateIndex
CREATE INDEX "User_divisionCode_idx" ON "User"("divisionCode");

-- CreateIndex
CREATE INDEX "User_policeStationCode_idx" ON "User"("policeStationCode");

-- CreateIndex
CREATE INDEX "User_sectorCode_idx" ON "User"("sectorCode");
