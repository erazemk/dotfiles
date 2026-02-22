/**
 * Ollama Web Tools
 *
 * Provides web_search and web_fetch tools backed by Ollama's web search API.
 * Requires OLLAMA_API_KEY to be set in the environment.
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import {
	DEFAULT_MAX_BYTES,
	DEFAULT_MAX_LINES,
	formatSize,
	truncateHead,
	type TruncationResult,
} from "@mariozechner/pi-coding-agent";
import { Type } from "@sinclair/typebox";
import { mkdtemp, writeFile } from "node:fs/promises";
import os from "node:os";
import path from "node:path";

const OLLAMA_BASE_URL = "https://ollama.com/api";
const DEFAULT_MAX_RESULTS = 5;
const MAX_RESULTS = 10;

const WebSearchParams = Type.Object({
	query: Type.String({ description: "Search query" }),
	max_results: Type.Optional(
		Type.Integer({
			description: "Maximum results to return (default 5, max 10)",
			minimum: 1,
			maximum: MAX_RESULTS,
		}),
	),
});

type WebSearchParamsType = {
	query: string;
	max_results?: number;
};

type WebFetchParamsType = {
	url: string;
};

const WebFetchParams = Type.Object({
	url: Type.String({ description: "URL to fetch" }),
});

type WebSearchResult = {
	title?: string;
	url?: string;
	content?: string;
};

type WebSearchResponse = {
	results?: WebSearchResult[];
};

type WebFetchResponse = {
	title?: string;
	content?: string;
	links?: string[];
};

type ToolOutput = {
	text: string;
	truncation?: TruncationResult;
	fullOutputPath?: string;
};

function clamp(value: number, min: number, max: number): number {
	return Math.min(Math.max(value, min), max);
}

function getApiKey(): string {
	const apiKey = process.env.OLLAMA_API_KEY;
	if (!apiKey) {
		throw new Error("OLLAMA_API_KEY is not set. Set it to your Ollama API key to use web search/fetch.");
	}
	return apiKey;
}

async function postJson<T>(endpoint: string, body: unknown, signal?: AbortSignal): Promise<T> {
	const response = await fetch(`${OLLAMA_BASE_URL}${endpoint}`, {
		method: "POST",
		headers: {
			Authorization: `Bearer ${getApiKey()}`,
			"Content-Type": "application/json",
		},
		body: JSON.stringify(body),
		signal,
	});

	const text = await response.text();
	if (!response.ok) {
		throw new Error(`Ollama API error (${response.status} ${response.statusText}): ${text}`);
	}

	try {
		return JSON.parse(text) as T;
	} catch (error) {
		const message = error instanceof Error ? error.message : String(error);
		throw new Error(`Failed to parse Ollama API response: ${message}`);
	}
}

function normalizeUrl(input: string): string {
	const trimmed = input.trim();
	if (!trimmed) return trimmed;
	if (/^https?:\/\//i.test(trimmed)) return trimmed;
	return `https://${trimmed}`;
}

function formatSearchResults(results: WebSearchResult[]): string {
	if (results.length === 0) return "No results returned.";

	return results
		.map((result, index) => {
			const title = result.title ?? "Untitled";
			const url = result.url ?? "";
			const content = result.content ?? "";
			const lines: string[] = [`${index + 1}. ${title}`];
			if (url) lines.push(`URL: ${url}`);
			if (content) lines.push(`Snippet: ${content}`);
			return lines.join("\n");
		})
		.join("\n\n");
}

function formatFetchResult(result: WebFetchResponse): string {
	const title = result.title ?? "Untitled";
	const content = result.content ?? "";
	const links = Array.isArray(result.links) ? result.links : [];
	const lines: string[] = [`Title: ${title}`];

	if (content) {
		lines.push("", "Content:", content);
	}

	if (links.length > 0) {
		lines.push("", "Links:", ...links.map((link) => `- ${link}`));
	}

	return lines.join("\n");
}

async function truncateOutput(label: string, output: string): Promise<ToolOutput> {
	const truncation = truncateHead(output, {
		maxLines: DEFAULT_MAX_LINES,
		maxBytes: DEFAULT_MAX_BYTES,
	});

	let text = truncation.content;
	let fullOutputPath: string | undefined;

	if (truncation.truncated) {
		const tempDir = await mkdtemp(path.join(os.tmpdir(), "pi-ollama-web-"));
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

export default function ollamaWebExtension(pi: ExtensionAPI) {
	pi.registerTool({
		name: "web_search",
		label: "Ollama Web Search",
		description: `Search the web via Ollama's web search API. Requires OLLAMA_API_KEY. Output is truncated to ${DEFAULT_MAX_LINES} lines or ${formatSize(
			DEFAULT_MAX_BYTES,
		)}.`,
		parameters: WebSearchParams,
		async execute(_toolCallId, params, signal) {
			const { query, max_results } = params as WebSearchParamsType;
			const maxResults = clamp(max_results ?? DEFAULT_MAX_RESULTS, 1, MAX_RESULTS);

			const response = await postJson<WebSearchResponse>(
				"/web_search",
				{ query, max_results: maxResults },
				signal,
			);
			const results = Array.isArray(response.results) ? response.results : [];
			const output = formatSearchResults(results);
			const truncated = await truncateOutput("web-search", output);

			return {
				content: [{ type: "text", text: truncated.text }],
				details: {
					query,
					maxResults,
					resultCount: results.length,
					truncation: truncated.truncation,
					fullOutputPath: truncated.fullOutputPath,
				},
			};
		},
	});

	pi.registerTool({
		name: "web_fetch",
		label: "Ollama Web Fetch",
		description: `Fetch a single web page via Ollama's web fetch API. Requires OLLAMA_API_KEY. Output is truncated to ${DEFAULT_MAX_LINES} lines or ${formatSize(
			DEFAULT_MAX_BYTES,
		)}. If the URL has no scheme, https:// is assumed.`,
		parameters: WebFetchParams,
		async execute(_toolCallId, params, signal) {
			const { url } = params as WebFetchParamsType;
			const normalizedUrl = normalizeUrl(url);

			const response = await postJson<WebFetchResponse>(
				"/web_fetch",
				{ url: normalizedUrl },
				signal,
			);
			const output = formatFetchResult(response);
			const truncated = await truncateOutput("web-fetch", output);

			return {
				content: [{ type: "text", text: truncated.text }],
				details: {
					url: normalizedUrl,
					title: response.title ?? null,
					linkCount: Array.isArray(response.links) ? response.links.length : 0,
					truncation: truncated.truncation,
					fullOutputPath: truncated.fullOutputPath,
				},
			};
		},
	});
}
