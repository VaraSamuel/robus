-- CreateTable
CREATE TABLE "User" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "email" TEXT NOT NULL,
    "passwordHash" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "role" TEXT NOT NULL DEFAULT 'PARTNER'
);

-- CreateTable
CREATE TABLE "RobusClient" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "name" TEXT NOT NULL,
    "vertical" TEXT NOT NULL,
    "stage" TEXT NOT NULL DEFAULT 'ASSESSMENT',
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- CreateTable
CREATE TABLE "AssessmentNote" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "clientId" TEXT NOT NULL,
    "rawText" TEXT NOT NULL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "AssessmentNote_clientId_fkey" FOREIGN KEY ("clientId") REFERENCES "RobusClient" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "Workflow" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "clientId" TEXT NOT NULL,
    "capabilityTag" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "frequencyScore" INTEGER NOT NULL,
    "timeBurdenScore" INTEGER NOT NULL,
    "errorRiskScore" INTEGER NOT NULL,
    "automationReadinessScore" INTEGER NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'IDENTIFIED',
    "sourceNotes" TEXT,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "Workflow_clientId_fkey" FOREIGN KEY ("clientId") REFERENCES "RobusClient" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "Playbook" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "capabilityTag" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "commonTools" TEXT NOT NULL,
    "steps" TEXT NOT NULL,
    "estimatedHoursWithout" REAL NOT NULL,
    "estimatedHoursWith" REAL NOT NULL
);

-- CreateIndex
CREATE UNIQUE INDEX "User_email_key" ON "User"("email");

-- CreateIndex
CREATE INDEX "Workflow_capabilityTag_idx" ON "Workflow"("capabilityTag");

-- CreateIndex
CREATE INDEX "Workflow_clientId_idx" ON "Workflow"("clientId");

-- CreateIndex
CREATE UNIQUE INDEX "Playbook_capabilityTag_key" ON "Playbook"("capabilityTag");
