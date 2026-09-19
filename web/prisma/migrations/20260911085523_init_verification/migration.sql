-- CreateTable
CREATE TABLE "PreInstallationVerification" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "gpid" TEXT NOT NULL,
    "applicationId" TEXT,
    "locationResult" JSONB,
    "mandapResult" JSONB,
    "idolResult" JSONB,
    "routeResult" JSONB,
    "securityResult" JSONB,
    "organizerResult" JSONB,
    "interDepartmentalResult" JSONB,
    "permissionShoReviewResult" JSONB,
    "verificationStatus" TEXT NOT NULL DEFAULT 'COMPLETED',
    "submittedAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL
);

-- CreateIndex
CREATE UNIQUE INDEX "PreInstallationVerification_gpid_key" ON "PreInstallationVerification"("gpid");
