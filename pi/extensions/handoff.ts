/**
 * Handoff extension - transfer context to a new focused session
 *
 * Instead of compacting (which is lossy), handoff extracts what matters
 * for your next task and creates a new session with a generated prompt.
 *
 * Provides both:
 * - /handoff command: user types `/handoff <goal>`
 * - handoff tool: agent can call when user explicitly requests a handoff
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
import { Type } from "@sinclair/typebox";

type MessageEntry = Extract<SessionEntry, { type: "message" }>;
type ConversationMessage = MessageEntry["message"];

const CONTEXT_SUMMARY_SYSTEM_PROMPT = `You are a context transfer assistant. Given a conversation history and the user's goal for a new thread, generate a focused prompt that:

1. Summarizes relevant context from the conversation (decisions made, approaches taken, key findings)
2. Lists any relevant files that were discussed or modified
3. Clearly states the next task based on the user's goal
4. Is self-contained - the new thread should be able to proceed without the old conversation

Format your response as a prompt the user can send to start the new thread. Be concise but include all necessary context. Do not include any preamble like "Here's the prompt" - just output the prompt itself.

Example output format:
## Context
We've been working on X. Key decisions:
- Decision 1
- Decision 2

Files involved:
- path/to/file1.ts
- path/to/file2.ts

## Task
[Clear description of what to do next based on user's goal]`;

function getConversationMessages(ctx: ExtensionCommandContext): ConversationMessage[] {
	return ctx.sessionManager
		.getBranch()
		.filter((entry): entry is MessageEntry => entry.type === "message")
		.map((entry) => entry.message);
}

function buildFinalPrompt(goal: string, summary: string, parentSession: string | undefined): string {
	if (!parentSession) {
		return `${goal}\n\n${summary}`;
	}

	return `${goal}\n\n/skill:session-query\n\n**Parent session:** \`${parentSession}\`\n\n${summary}`;
}

function normalizeGoalForCommand(goal: string): string {
	return goal.replace(/\s+/g, " ").trim();
}

async function generateContextSummary(
	model: NonNullable<ExtensionCommandContext["model"]>,
	apiKey: string,
	messages: ConversationMessage[],
	goal: string,
	signal?: AbortSignal,
): Promise<string | null> {
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
		{ systemPrompt: CONTEXT_SUMMARY_SYSTEM_PROMPT, messages: [userMessage] },
		{ apiKey, signal },
	);

	if (response.stopReason === "aborted") {
		return null;
	}

	return response.content
		.filter((content): content is { type: "text"; text: string } => content.type === "text")
		.map((content) => content.text)
		.join("\n");
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

	const summary = await ctx.ui.custom<string | null>((tui, theme, _kb, done) => {
		const loader = new BorderedLoader(tui, theme, "Generating handoff prompt...");
		loader.onAbort = () => done(null);

		const generate = async () => {
			const apiKey = await ctx.modelRegistry.getApiKey(ctx.model!);
			return generateContextSummary(ctx.model!, apiKey, messages, goal, loader.signal);
		};

		generate()
			.then(done)
			.catch((error) => {
				console.error("Handoff generation failed:", error);
				done(null);
			});

		return loader;
	});

	if (summary === null) {
		return "Cancelled";
	}

	const finalPrompt = buildFinalPrompt(goal, summary, currentSessionFile);
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

	pi.registerTool({
		name: "handoff",
		label: "Handoff",
		description:
			"Transfer context to a new focused session. ONLY use this when the user explicitly asks for a handoff. Provide a goal describing what the new session should focus on.",
		promptSnippet: "Create a focused handoff to a new session when the user explicitly asks for one",
		promptGuidelines: [
			"Only use this tool when the user explicitly asks for a handoff or new focused session.",
			"Provide a concise goal describing what the new session should focus on.",
		],
		parameters: Type.Object({
			goal: Type.String({ description: "The goal/task for the new session" }),
		}),
		async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
			const goal = normalizeGoalForCommand(params.goal);
			if (!goal) {
				return {
					content: [{ type: "text", text: "Error: goal must not be empty." }],
				};
			}

			if (!ctx.hasUI) {
				return {
					content: [{ type: "text", text: "Error: handoff requires interactive mode." }],
				};
			}

			pi.sendUserMessage(`/handoff ${goal}`, { deliverAs: "followUp" });
			return {
				content: [
					{
						type: "text",
						text: "Queued /handoff as a follow-up. Pi will generate the handoff prompt after the current turn completes.",
					},
				],
			};
		},
	});
}
