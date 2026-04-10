import { existsSync } from "node:fs";
import { mkdtemp, writeFile } from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";

import {
	DEFAULT_MAX_BYTES,
	DEFAULT_MAX_LINES,
	defineTool,
	formatSize,
	truncateHead,
	type ExtensionAPI,
	type TruncationResult,
} from "@mariozechner/pi-coding-agent";
import { Type } from "@sinclair/typebox";

const GENERATED_CLI_PATH = fileURLToPath(new URL("./augment.cjs", import.meta.url));
const NODE_PATH = process.execPath;
const CLI_TIMEOUT_MS = 120_000;
const AUGMENT_SESSION_PATH = path.join(os.homedir(), ".augment", "session.json");

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

function hasExecutableOnPath(command: string): boolean {
	const pathValue = process.env.PATH;
	if (!pathValue) return false;

	for (const dir of pathValue.split(path.delimiter)) {
		if (!dir) continue;
		const candidate = path.join(dir, command);
		if (existsSync(candidate)) return true;
	}

	return false;
}

function hasAugmentCapability(): boolean {
	const hasAuth = Boolean(process.env.AUGMENT_SESSION_AUTH?.trim()) || existsSync(AUGMENT_SESSION_PATH);
	return hasExecutableOnPath("auggie") && hasAuth;
}

function resolveDirectoryPath(input: string | undefined, cwd: string): string {
	const candidate = normalizePathInput(input?.trim() || cwd);
	return path.isAbsolute(candidate) ? path.resolve(candidate) : path.resolve(cwd, candidate);
}

type ToolOutput = {
	text: string;
	truncation?: TruncationResult;
	fullOutputPath?: string;
};

function prepareAliasedArguments<T extends Record<string, unknown>>(
	args: unknown,
	aliases: Record<string, keyof T & string>,
): T {
	if (!args || typeof args !== "object" || Array.isArray(args)) {
		return args as T;
	}

	const input = args as Record<string, unknown>;
	const next: Record<string, unknown> = { ...input };
	let changed = false;

	for (const [from, to] of Object.entries(aliases)) {
		if (next[to] === undefined && input[from] !== undefined) {
			next[to] = input[from];
			changed = true;
		}
	}

	return (changed ? next : args) as T;
}

async function truncateOutput(label: string, output: string): Promise<ToolOutput> {
	const truncation = truncateHead(output, {
		maxLines: DEFAULT_MAX_LINES,
		maxBytes: DEFAULT_MAX_BYTES,
	});

	let text = truncation.content;
	let fullOutputPath: string | undefined;

	if (truncation.truncated) {
		const tempDir = await mkdtemp(path.join(os.tmpdir(), "pi-augment-"));
		fullOutputPath = path.join(tempDir, `${label}.txt`);
		await writeFile(fullOutputPath, output, "utf8");

		const truncatedLines = truncation.totalLines - truncation.outputLines;
		const truncatedBytes = truncation.totalBytes - truncation.outputBytes;

		text += `\n\n[Output truncated: showing ${truncation.outputLines} of ${truncation.totalLines} lines`;
		text += ` (${formatSize(truncation.outputBytes)} of ${formatSize(truncation.totalBytes)}).`;
		text += ` ${truncatedLines} lines (${formatSize(truncatedBytes)}) omitted.`;
		text += ` Full output saved to: ${fullOutputPath}]`;
	}

	return {
		text,
		truncation: truncation.truncated ? truncation : undefined,
		fullOutputPath,
	};
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
	if (!hasAugmentCapability()) {
		console.warn(
			"augment extension: skipping search_codebase registration because auggie or Augment auth is unavailable",
		);
		return;
	}

	const searchCodebaseTool = defineTool({
		name: "search_codebase",
		label: "Search Codebase",
		description:
			"Use this tool for semantic codebase search and understanding when exact file locations are unknown, when gathering high-level context about architecture or implementation, or before edits that require understanding related symbols. Prefer grep/bash for exact string matching or when you already know the identifier or file. Results reflect the current state of files on disk.",
		promptSnippet:
			"Use search_codebase for semantic code search and high-level codebase understanding. Defaults to the current working directory.",
		promptGuidelines: [
			"Use this tool when you need semantic understanding or do not know exact file locations.",
			"Use this tool for architecture questions, implementation discovery, and broad codebase exploration.",
			"Omit directory_path to search the current working directory.",
		],
		parameters: toolParameters,
		prepareArguments(args) {
			return prepareAliasedArguments(args, {
				directoryPath: "directory_path",
			});
		},
		async execute(_toolCallId, params, signal, onUpdate, ctx) {
			const directoryPath = resolveDirectoryPath(params.directory_path, ctx.cwd);

			onUpdate?.({
				content: [{ type: "text", text: `Searching codebase in ${directoryPath}` }],
				details: { status: "running", directoryPath },
			});

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
			const truncated = await truncateOutput("search-codebase", formatted);

			return {
				content: [{ type: "text", text: truncated.text }],
				details: {
					directoryPath,
					truncation: truncated.truncation,
					fullOutputPath: truncated.fullOutputPath,
					generatedCli: GENERATED_CLI_PATH,
				},
			};
		},
	});

	pi.registerTool(searchCodebaseTool);
}
