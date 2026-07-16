"use server";

import { revalidatePath } from "next/cache";
import { z } from "zod";
import { prisma } from "@/lib/prisma";
import { requireSession } from "@/lib/requireAuth";
import { analyzeNotes, type CapabilityTag } from "@/lib/capabilities";
import { signOut } from "@/auth";

const VERTICALS = ["CPA", "LAW", "REAL_ESTATE", "RESTAURANT", "NAIL_SALON", "ARCHITECTURE", "HOSPITALITY", "OTHER"] as const;
const STAGES = ["ASSESSMENT", "SPRINT", "RETAINER", "COMPLETE"] as const;
const STATUSES = ["IDENTIFIED", "IN_SPRINT", "SHIPPED"] as const;
const CAPABILITY_TAGS = [
  "INTAKE_AUTOMATION",
  "RESERVATION_NOSHOW_HANDLING",
  "SALES_RECONCILIATION",
  "MISSED_CALL_HANDLING",
  "REBOOKING_FOLLOWUP",
  "DOCUMENT_AUTOMATION",
  "CASE_MATTER_TRACKING",
  "CLIENT_REPORTING",
  "LEASING_AGENT_AUTOMATION",
  "BOOKKEEPING_CATEGORIZATION",
  "PROPOSAL_BID_ASSEMBLY",
  "SHUTTLE_TRANSPORT_COORDINATION",
  "GROUP_EVENT_SALES_INQUIRY",
  "REVIEW_REPUTATION_MANAGEMENT",
] as const;

const createClientSchema = z.object({
  name: z.string().trim().min(1, "Client name is required"),
  vertical: z.enum(VERTICALS),
});

const addWorkflowSchema = z.object({
  capabilityTag: z.enum(CAPABILITY_TAGS),
  name: z.string().min(1),
  frequencyScore: z.number().int().min(1).max(5),
  timeBurdenScore: z.number().int().min(1).max(5),
  errorRiskScore: z.number().int().min(1).max(5),
  automationReadinessScore: z.number().int().min(1).max(5),
  sourceNotes: z.string(),
});

export async function createClient(formData: FormData) {
  await requireSession();
  const parsed = createClientSchema.parse({
    name: formData.get("name"),
    vertical: formData.get("vertical"),
  });

  const client = await prisma.robusClient.create({
    data: { name: parsed.name, vertical: parsed.vertical },
  });
  revalidatePath("/clients");
  return client.id;
}

export async function analyzeNotesAction(clientId: string, rawText: string) {
  await requireSession();
  await prisma.assessmentNote.create({ data: { clientId, rawText } });
  return analyzeNotes(rawText);
}

export async function addWorkflow(
  clientId: string,
  data: {
    capabilityTag: CapabilityTag;
    name: string;
    frequencyScore: number;
    timeBurdenScore: number;
    errorRiskScore: number;
    automationReadinessScore: number;
    sourceNotes: string;
  }
): Promise<{ created: boolean }> {
  await requireSession();
  const parsed = addWorkflowSchema.parse(data);

  const existing = await prisma.workflow.findFirst({
    where: { clientId, capabilityTag: parsed.capabilityTag },
  });
  if (existing) {
    // Already tracked for this client — don't create a near-duplicate row.
    revalidatePath(`/clients/${clientId}`);
    return { created: false };
  }

  await prisma.workflow.create({
    data: {
      clientId,
      capabilityTag: parsed.capabilityTag,
      name: parsed.name,
      frequencyScore: parsed.frequencyScore,
      timeBurdenScore: parsed.timeBurdenScore,
      errorRiskScore: parsed.errorRiskScore,
      automationReadinessScore: parsed.automationReadinessScore,
      sourceNotes: parsed.sourceNotes,
    },
  });
  revalidatePath(`/clients/${clientId}`);
  revalidatePath("/signal");
  return { created: true };
}

export async function updateWorkflowStatus(workflowId: string, status: (typeof STATUSES)[number]) {
  await requireSession();
  const parsedStatus = z.enum(STATUSES).parse(status);
  const wf = await prisma.workflow.update({ where: { id: workflowId }, data: { status: parsedStatus } });
  revalidatePath(`/clients/${wf.clientId}`);
  revalidatePath("/signal");
}

export async function updateClientStage(clientId: string, stage: (typeof STAGES)[number]) {
  await requireSession();
  const parsedStage = z.enum(STAGES).parse(stage);
  await prisma.robusClient.update({ where: { id: clientId }, data: { stage: parsedStage } });
  revalidatePath(`/clients/${clientId}`);
  revalidatePath("/clients");
}

export async function logOut() {
  await signOut({ redirectTo: "/login" });
}
