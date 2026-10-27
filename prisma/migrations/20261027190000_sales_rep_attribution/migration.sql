-- CreateEnum
CREATE TYPE "SalesRep" AS ENUM ('KEVIN', 'ZACH', 'SAMUEL', 'DAVE');

-- Preserve any existing free-text relationshipLead values under a new name
-- before converting the column to the enum below — nothing gets dropped.
ALTER TABLE "RobusClient" RENAME COLUMN "relationshipLead" TO "relationshipLeadNote";

-- CreateColumn
ALTER TABLE "RobusClient" ADD COLUMN "relationshipLead" "SalesRep";

-- Best-effort backfill: match old free-text names to the new enum. Anything
-- that doesn't clearly match a rep's name is left NULL (unassigned) rather
-- than guessed — the original text survives in relationshipLeadNote either way.
UPDATE "RobusClient" SET "relationshipLead" =
  CASE
    WHEN "relationshipLeadNote" ILIKE '%kevin%' THEN 'KEVIN'::"SalesRep"
    WHEN "relationshipLeadNote" ILIKE '%zach%' THEN 'ZACH'::"SalesRep"
    WHEN "relationshipLeadNote" ILIKE '%samuel%' OR "relationshipLeadNote" ILIKE '%sam%' THEN 'SAMUEL'::"SalesRep"
    WHEN "relationshipLeadNote" ILIKE '%dave%' OR "relationshipLeadNote" ILIKE '%david%' THEN 'DAVE'::"SalesRep"
    ELSE NULL
  END
WHERE "relationshipLeadNote" IS NOT NULL;

-- Clear the note where it was a clean, exact rep-name match (nothing extra
-- to preserve); leave it in place wherever it held more than just a name.
UPDATE "RobusClient" SET "relationshipLeadNote" = NULL
WHERE "relationshipLead" IS NOT NULL
  AND lower(trim("relationshipLeadNote")) IN ('kevin', 'zach', 'samuel', 'sam', 'dave', 'david');
