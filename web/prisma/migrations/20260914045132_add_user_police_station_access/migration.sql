-- CreateTable
CREATE TABLE "UserPoliceStationAccess" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "userId" TEXT NOT NULL,
    "policeStationCode" TEXT,
    "policeStationName" TEXT NOT NULL,
    "canView" BOOLEAN NOT NULL DEFAULT true,
    "canEdit" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL,
    CONSTRAINT "UserPoliceStationAccess_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);

-- CreateIndex
CREATE INDEX "UserPoliceStationAccess_userId_idx" ON "UserPoliceStationAccess"("userId");

-- CreateIndex
CREATE INDEX "UserPoliceStationAccess_policeStationName_idx" ON "UserPoliceStationAccess"("policeStationName");

-- CreateIndex
CREATE INDEX "UserPoliceStationAccess_policeStationCode_idx" ON "UserPoliceStationAccess"("policeStationCode");

-- CreateIndex
CREATE UNIQUE INDEX "UserPoliceStationAccess_userId_policeStationName_key" ON "UserPoliceStationAccess"("userId", "policeStationName");
