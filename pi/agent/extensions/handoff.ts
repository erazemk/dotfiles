/**
 * Handoff extension - transfer context to a new focused session
 *
 * Instead of compacting (which is lossy), handoff extracts what matters
 * for your next task and creates a new session with a generated prompt.
 *
 * Provides:
 * - /handoff command: user types `/handoff <goal>`
 *
 * Usage:
 *   /handoff now implement this for teams as well
 *
 * The new session keeps using the current model.
 * The generated prompt appears as a draft in the editor for review/editing.
 *
 * Source: https://github.com/pasky/pi-amplike/blob/main/extensions/handoff.ts
 */

import { complete, type Message } from "@mariozechner/pi-ai";
import type { ExtensionAPI, ExtensionCommandContext, SessionEntry } from "@mariozechner/pi-coding-agent";
import { BorderedLoader, convertToLlm, serializeConversation } from "@mariozechner/pi-coding-agent";

type MessageEntry = Extract<SessionEntry, { type: "message" }>;
type ConversationMessage = MessageEntry["message"];

type HandoffContext = {
	relevantInformation: string[];
	relevantFiles: string[];
};

const HANDOFF_EXTRACTION_SYSTEM_PROMPT = `You are a context transfer assistant. Given a conversation history and the user's goal for a new thread, extract only the context that matters for continuing the work.

Return ONLY valid JSON with this exact shape:
{
  "relevantInformation": ["bullet 1", "bullet 2"],
  "relevantFiles": ["path/to/file1.ts", "path/to/file2.ts"]
}

Rules:
- relevantInformation must be an array of concise bullet-style strings.
- Write relevantInformation from the user's perspective when appropriate (for example: "I decided...", "I asked...", "We already verified...").
- Include only details that are useful for the new goal.
- Focus on decisions, constraints, key findings, open questions, and important implementation details.
- Do NOT write the final handoff prompt.
- Do NOT include markdown, explanations, or code fences.
- relevantFiles must contain only workspace-relative file or directory paths.
- Include at most 10 relevantFiles, ordered by importance.
- If no files are clearly relevant, return an empty array.`;

function getConversationMessages(ctx: ExtensionCommandContext): ConversationMessage[] {
	return ctx.sessionManager
		.getBranch()
		.filter((entry): entry is MessageEntry => entry.type === "message")
		.map((entry) => entry.message);
}

function normalizeList(values: unknown): string[] {
	if (Array.isArray(values)) {
		return values
			.filter((value): value is string => typeof value === "string")
			.map((value) => value.trim().replace(/^[*-]\s+/, ""))
			.filter(Boolean);
	}

	if (typeof values === "string") {
		return values
			.split(/\r?\n+/)
			.map((value) => value.trim().replace(/^[*-]\s+/, ""))
			.filter(Boolean);
	}

	return [];
}

function isRelativePath(path: string): boolean {
	return !path.startsWith("/") && !/^[a-zA-Z]:[\\/]/.test(path);
}

function stripCodeFences(text: string): string {
	const trimmed = text.trim();
	const fencedMatch = trimmed.match(/^```(?:json)?\s*([\s\S]*?)\s*```$/i);
	return fencedMatch ? fencedMatch[1]!.trim() : trimmed;
}

function parseHandoffContext(raw: string): HandoffContext {
	const cleaned = stripCodeFences(raw);

	try {
		const parsed = JSON.parse(cleaned) as {
			relevantInformation?: unknown;
			relevantFiles?: unknown;
		};

		const relevantInformation = [...new Set(normalizeList(parsed.relevantInformation))];
		const relevantFiles = [...new Set(normalizeList(parsed.relevantFiles).filter(isRelativePath))].slice(0, 10);

		return {
			relevantInformation,
			relevantFiles,
		};
	} catch {
		return {
			relevantInformation: normalizeList(cleaned),
			relevantFiles: [],
		};
	}
}

function buildBulletSection(title: string, items: string[]): string | null {
	if (items.length === 0) {
		return null;
	}

	return `## ${title}\n${items.map((item) => `- ${item}`).join("\n")}`;
}

function buildFinalPrompt(goal: string, context: HandoffContext, parentSession: string | undefined): string {
	const sections: string[] = [];

	if (parentSession) {
		sections.push(`Parent session: \`${parentSession}\``);
		sections.push(
			`If you need more detail from the earlier work, use the \`session_query\` tool with this parent session path and a focused question.`,
		);
	}

	const filesSection = buildBulletSection("Relevant Files", context.relevantFiles);
	if (filesSection) {
		sections.push(filesSection);
	}

	const contextSection = buildBulletSection("Relevant Context", context.relevantInformation);
	if (contextSection) {
		sections.push(contextSection);
	}

	sections.push(`## Task\n${goal}`);
	return sections.join("\n\n");
}

async function generateHandoffContext(
	model: NonNullable<ExtensionCommandContext["model"]>,
	apiKey: string | undefined,
	messages: ConversationMessage[],
	goal: string,
	signal?: AbortSignal,
): Promise<HandoffContext | null> {
	const conversationText = serializeConversation(convertToLlm(messages));

	const userMessage: Message = {
		role: "user",
		content: [
			{
				type: "text",
				text: `## Conversation History\n\n${conversationText}\n\n## User's Goal for New Thread\n\n${goal}`,
			},
		],
		timestamp: Date.now(),
	};

	const response = await complete(
		model,
		{ systemPrompt: HANDOFF_EXTRACTION_SYSTEM_PROMPT, messages: [userMessage] },
		{ apiKey, signal },
	);

	if (response.stopReason === "aborted") {
		return null;
	}

	const rawResponse = response.content
		.filter((content): content is { type: "text"; text: string } => content.type === "text")
		.map((content) => content.text)
		.join("\n");

	return parseHandoffContext(rawResponse);
}

async function runHandoffCommand(ctx: ExtensionCommandContext, goal: string): Promise<string | undefined> {
	if (!ctx.hasUI) {
		return "handoff requires interactive mode";
	}

	if (!ctx.model) {
		return "No model selected";
	}

	const messages = getConversationMessages(ctx);
	if (messages.length === 0) {
		return "No conversation to hand off";
	}

	const currentSessionFile = ctx.sessionManager.getSessionFile();

	const handoffContext = await ctx.ui.custom<HandoffContext | null>((tui, theme, _kb, done) => {
		const loader = new BorderedLoader(tui, theme, "Generating handoff prompt...");
		loader.onAbort = () => done(null);

		const generate = async () => {
			const apiKey = await ctx.modelRegistry.getApiKey(ctx.model!);
			return generateHandoffContext(ctx.model!, apiKey, messages, goal, loader.signal);
		};

		generate()
			.then(done)
			.catch((error) => {
				console.error("Handoff generation failed:", error);
				done(null);
			});

		return loader;
	});

	if (handoffContext === null) {
		return "Cancelled";
	}

	const finalPrompt = buildFinalPrompt(goal, handoffContext, currentSessionFile);
	const editedPrompt = await ctx.ui.editor("Edit handoff prompt", finalPrompt);
	if (editedPrompt === undefined) {
		return "Cancelled";
	}

	const newSessionResult = await ctx.newSession({ parentSession: currentSessionFile });
	if (newSessionResult.cancelled) {
		return "New session cancelled";
	}

	ctx.ui.setEditorText(editedPrompt);
	ctx.ui.notify("Handoff ready. Submit when ready.", "info");
	return undefined;
}

export default function (pi: ExtensionAPI) {
	pi.registerCommand("handoff", {
		description: "Transfer context to a new focused session",
		handler: async (args, ctx) => {
			const goal = args.trim();
			if (!goal) {
				ctx.ui.notify("Usage: /handoff <goal>", "error");
				return;
			}

			const error = await runHandoffCommand(ctx, goal);
			if (error && error !== "Cancelled") {
				ctx.ui.notify(error, "error");
			} else if (error === "Cancelled") {
				ctx.ui.notify("Cancelled", "info");
			}
		},
	});
}
