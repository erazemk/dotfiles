import path from "node:path";
import { fileURLToPath } from "node:url";

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Type } from "@sinclair/typebox";

const GENERATED_CLI_PATH = fileURLToPath(new URL("./augment.js", import.meta.url));
const NODE_PATH = process.execPath;
const CLI_TIMEOUT_MS = 120_000;

const toolParameters = Type.Object({
	information_request: Type.String({
		description: "Natural-language description of the information you need from the codebase",
	}),
	directory_path: Type.Optional(
		Type.String({
			description:
				"Directory to search. Relative paths resolve from the current pi working directory. Defaults to the current working directory.",
		}),
	),
});

function normalizePathInput(input: string): string {
	return input.startsWith("@") ? input.slice(1) : input;
}

function resolveDirectoryPath(input: string | undefined, cwd: string): string {
	const candidate = normalizePathInput(input?.trim() || cwd);
	return path.isAbsolute(candidate) ? path.resolve(candidate) : path.resolve(cwd, candidate);
}

function truncateText(text: string, maxLines = 2000, maxBytes = 50 * 1024) {
	const lines = text.split("\n");
	let output = text;
	let truncated = false;
	let reason = "";

	if (lines.length > maxLines) {
		output = lines.slice(0, maxLines).join("\n");
		truncated = true;
		reason = `showing first ${maxLines} of ${lines.length} lines`;
	}

	while (Buffer.byteLength(output, "utf8") > maxBytes) {
		output = output.slice(0, Math.max(0, output.length - 1024));
		truncated = true;
		reason = reason ? `${reason}; capped at ${(maxBytes / 1024).toFixed(0)}KB` : `capped at ${(maxBytes / 1024).toFixed(0)}KB`;
	}

	if (truncated) {
		output += `\n\n[Output truncated: ${reason}]`;
	}

	return { text: output, truncated };
}

function formatExecError(stdout: string, stderr: string, exitCode: number | null) {
	const combined = [stderr.trim(), stdout.trim()].filter(Boolean).join("\n\n");
	const message = combined || `Generated Augment CLI exited with code ${exitCode ?? "unknown"}.`;

	if (/spawn\s+auggie\s+ENOENT|command not found|No such file or directory/i.test(message)) {
		return new Error(
			"Augment Context Engine requires `auggie` on your PATH. Install it with `npm install -g @augmentcode/auggie@latest`.",
		);
	}

	if (/unauthoriz|auth|login|token/i.test(message)) {
		return new Error(`${message}\n\nIf Augment is not authenticated, run \`auggie login\`.`);
	}

	return new Error(message);
}

export default function augmentExtension(pi: ExtensionAPI) {
	pi.registerTool({
		name: "codebase_retrieval",
		label: "Augment Codebase Retrieval",
		description:
			"Primary tool for semantic code search and codebase understanding via Augment Context Engine MCP. Use this first when exact file locations are unknown, when gathering high-level context about architecture or implementation, or before edits that require understanding related symbols. Prefer grep/bash only for exact string matching or when you already know the identifier or file.",
		promptSnippet:
			"Use Augment Context Engine semantic search for codebase discovery and high-level understanding. Defaults to the current working directory.",
		promptGuidelines: [
			"Use this tool before grep/bash when you need semantic understanding or do not know exact file locations.",
			"Prefer this tool for architecture questions, implementation discovery, and broad codebase exploration.",
			"Omit directory_path to search the current working directory.",
		],
		parameters: toolParameters,
		async execute(_toolCallId, params, signal, _onUpdate, ctx) {
			const directoryPath = resolveDirectoryPath(params.directory_path, ctx.cwd);

			const result = await pi.exec(
				NODE_PATH,
				[
					GENERATED_CLI_PATH,
					"--timeout",
					String(CLI_TIMEOUT_MS),
					"--output",
					"markdown",
					"codebase-retrieval",
					"--information-request",
					params.information_request,
					"--directory-path",
					directoryPath,
				],
				{ signal, timeout: CLI_TIMEOUT_MS },
			);

			if (result.code !== 0) {
				throw formatExecError(result.stdout, result.stderr, result.code);
			}

			const formatted = result.stdout.trim() || result.stderr.trim() || "";
			const truncated = truncateText(formatted);

			return {
				content: [{ type: "text", text: truncated.text }],
				details: {
					directoryPath,
					truncated: truncated.truncated,
					generatedCli: GENERATED_CLI_PATH,
				},
			};
		},
	});
}
