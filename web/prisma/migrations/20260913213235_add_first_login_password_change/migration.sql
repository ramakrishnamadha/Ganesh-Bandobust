-- RedefineTables
PRAGMA defer_foreign_keys=ON;
PRAGMA foreign_keys=OFF;
CREATE TABLE "new_User" (
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
    "mustChangePassword" BOOLEAN NOT NULL DEFAULT true,
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
    "lastPasswordChangedAt" DATETIME,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL
);
INSERT INTO "new_User" ("accessLevel", "allDivisions", "allPoliceStations", "allRanges", "allZones", "commissionerateCode", "commissionerateName", "createdAt", "divisionCode", "divisionName", "employeeId", "id", "name", "passwordHash", "phoneNumber", "policeStationCode", "policeStationName", "rangeCode", "rangeName", "rank", "role", "sectorCode", "sectorName", "status", "team", "updatedAt", "username", "zoneCode", "zoneName") SELECT "accessLevel", "allDivisions", "allPoliceStations", "allRanges", "allZones", "commissionerateCode", "commissionerateName", "createdAt", "divisionCode", "divisionName", "employeeId", "id", "name", "passwordHash", "phoneNumber", "policeStationCode", "policeStationName", "rangeCode", "rangeName", "rank", "role", "sectorCode", "sectorName", "status", "team", "updatedAt", "username", "zoneCode", "zoneName" FROM "User";
DROP TABLE "User";
ALTER TABLE "new_User" RENAME TO "User";
CREATE UNIQUE INDEX "User_employeeId_key" ON "User"("employeeId");
CREATE UNIQUE INDEX "User_username_key" ON "User"("username");
CREATE INDEX "User_employeeId_idx" ON "User"("employeeId");
CREATE INDEX "User_username_idx" ON "User"("username");
CREATE INDEX "User_role_idx" ON "User"("role");
CREATE INDEX "User_accessLevel_idx" ON "User"("accessLevel");
CREATE INDEX "User_status_idx" ON "User"("status");
CREATE INDEX "User_rangeCode_idx" ON "User"("rangeCode");
CREATE INDEX "User_zoneCode_idx" ON "User"("zoneCode");
CREATE INDEX "User_divisionCode_idx" ON "User"("divisionCode");
CREATE INDEX "User_policeStationCode_idx" ON "User"("policeStationCode");
CREATE INDEX "User_sectorCode_idx" ON "User"("sectorCode");
PRAGMA foreign_keys=ON;
PRAGMA defer_foreign_keys=OFF;
