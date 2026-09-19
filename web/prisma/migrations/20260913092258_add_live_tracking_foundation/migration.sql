-- CreateTable
CREATE TABLE "UserSession" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "userId" TEXT NOT NULL,
    "userName" TEXT,
    "rank" TEXT,
    "role" TEXT,
    "source" TEXT NOT NULL,
    "commissionerateCode" TEXT,
    "rangeCode" TEXT,
    "zoneCode" TEXT,
    "divisionCode" TEXT,
    "policeStationCode" TEXT,
    "sectorCode" TEXT,
    "status" TEXT NOT NULL DEFAULT 'ACTIVE',
    "loginAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "logoutAt" DATETIME,
    "lastSeenAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- CreateTable
CREATE TABLE "DeviceSession" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "userSessionId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "deviceType" TEXT NOT NULL,
    "deviceId" TEXT,
    "deviceName" TEXT,
    "manufacturer" TEXT,
    "model" TEXT,
    "platform" TEXT,
    "osVersion" TEXT,
    "appVersion" TEXT,
    "trackingStatus" TEXT NOT NULL DEFAULT 'TRACKING_STOPPED',
    "trackingEnabled" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "lastSeenAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "endedAt" DATETIME,
    CONSTRAINT "DeviceSession_userSessionId_fkey" FOREIGN KEY ("userSessionId") REFERENCES "UserSession" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "OfficerCurrentLocation" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "deviceSessionId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "latitude" REAL NOT NULL,
    "longitude" REAL NOT NULL,
    "accuracy" REAL,
    "speed" REAL,
    "heading" REAL,
    "batteryLevel" INTEGER,
    "locationSource" TEXT NOT NULL,
    "activityStatus" TEXT,
    "activeGpid" TEXT,
    "capturedAt" DATETIME NOT NULL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL,
    CONSTRAINT "OfficerCurrentLocation_deviceSessionId_fkey" FOREIGN KEY ("deviceSessionId") REFERENCES "DeviceSession" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "OfficerLocationHistory" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "deviceSessionId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "latitude" REAL NOT NULL,
    "longitude" REAL NOT NULL,
    "accuracy" REAL,
    "speed" REAL,
    "heading" REAL,
    "batteryLevel" INTEGER,
    "locationSource" TEXT NOT NULL,
    "eventType" TEXT NOT NULL DEFAULT 'HEARTBEAT',
    "activeGpid" TEXT,
    "capturedAt" DATETIME NOT NULL,
    "receivedAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "OfficerLocationHistory_deviceSessionId_fkey" FOREIGN KEY ("deviceSessionId") REFERENCES "DeviceSession" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "ActivityEvent" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "userId" TEXT NOT NULL,
    "userSessionId" TEXT,
    "deviceSessionId" TEXT,
    "source" TEXT NOT NULL,
    "eventType" TEXT NOT NULL,
    "gpid" TEXT,
    "applicationId" TEXT,
    "commissionerateCode" TEXT,
    "rangeCode" TEXT,
    "zoneCode" TEXT,
    "divisionCode" TEXT,
    "policeStationCode" TEXT,
    "sectorCode" TEXT,
    "latitude" REAL,
    "longitude" REAL,
    "accuracy" REAL,
    "oldValue" JSONB,
    "newValue" JSONB,
    "metadata" JSONB,
    "occurredAt" DATETIME NOT NULL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "ActivityEvent_userSessionId_fkey" FOREIGN KEY ("userSessionId") REFERENCES "UserSession" ("id") ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT "ActivityEvent_deviceSessionId_fkey" FOREIGN KEY ("deviceSessionId") REFERENCES "DeviceSession" ("id") ON DELETE SET NULL ON UPDATE CASCADE
);

-- CreateIndex
CREATE INDEX "UserSession_userId_idx" ON "UserSession"("userId");

-- CreateIndex
CREATE INDEX "UserSession_status_idx" ON "UserSession"("status");

-- CreateIndex
CREATE INDEX "UserSession_policeStationCode_idx" ON "UserSession"("policeStationCode");

-- CreateIndex
CREATE INDEX "UserSession_sectorCode_idx" ON "UserSession"("sectorCode");

-- CreateIndex
CREATE INDEX "UserSession_lastSeenAt_idx" ON "UserSession"("lastSeenAt");

-- CreateIndex
CREATE INDEX "DeviceSession_userId_idx" ON "DeviceSession"("userId");

-- CreateIndex
CREATE INDEX "DeviceSession_userSessionId_idx" ON "DeviceSession"("userSessionId");

-- CreateIndex
CREATE INDEX "DeviceSession_deviceType_idx" ON "DeviceSession"("deviceType");

-- CreateIndex
CREATE INDEX "DeviceSession_trackingStatus_idx" ON "DeviceSession"("trackingStatus");

-- CreateIndex
CREATE INDEX "DeviceSession_lastSeenAt_idx" ON "DeviceSession"("lastSeenAt");

-- CreateIndex
CREATE UNIQUE INDEX "OfficerCurrentLocation_deviceSessionId_key" ON "OfficerCurrentLocation"("deviceSessionId");

-- CreateIndex
CREATE INDEX "OfficerCurrentLocation_userId_idx" ON "OfficerCurrentLocation"("userId");

-- CreateIndex
CREATE INDEX "OfficerCurrentLocation_activeGpid_idx" ON "OfficerCurrentLocation"("activeGpid");

-- CreateIndex
CREATE INDEX "OfficerCurrentLocation_capturedAt_idx" ON "OfficerCurrentLocation"("capturedAt");

-- CreateIndex
CREATE INDEX "OfficerCurrentLocation_activityStatus_idx" ON "OfficerCurrentLocation"("activityStatus");

-- CreateIndex
CREATE INDEX "OfficerLocationHistory_userId_capturedAt_idx" ON "OfficerLocationHistory"("userId", "capturedAt");

-- CreateIndex
CREATE INDEX "OfficerLocationHistory_deviceSessionId_capturedAt_idx" ON "OfficerLocationHistory"("deviceSessionId", "capturedAt");

-- CreateIndex
CREATE INDEX "OfficerLocationHistory_activeGpid_idx" ON "OfficerLocationHistory"("activeGpid");

-- CreateIndex
CREATE INDEX "OfficerLocationHistory_eventType_idx" ON "OfficerLocationHistory"("eventType");

-- CreateIndex
CREATE INDEX "ActivityEvent_userId_occurredAt_idx" ON "ActivityEvent"("userId", "occurredAt");

-- CreateIndex
CREATE INDEX "ActivityEvent_gpid_occurredAt_idx" ON "ActivityEvent"("gpid", "occurredAt");

-- CreateIndex
CREATE INDEX "ActivityEvent_eventType_idx" ON "ActivityEvent"("eventType");

-- CreateIndex
CREATE INDEX "ActivityEvent_policeStationCode_idx" ON "ActivityEvent"("policeStationCode");

-- CreateIndex
CREATE INDEX "ActivityEvent_sectorCode_idx" ON "ActivityEvent"("sectorCode");

-- CreateIndex
CREATE INDEX "ActivityEvent_createdAt_idx" ON "ActivityEvent"("createdAt");
