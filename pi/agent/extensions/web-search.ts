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
const MAX_RETRIES = 2;
const RETRY_BASE_DELAY_MS = 500;
const MAX_FETCH_LINKS = 10;

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

class NonRetryableRequestError extends Error {}

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

function sleep(ms: number, signal?: AbortSignal): Promise<void> {
	return new Promise((resolve, reject) => {
		const timeout = setTimeout(() => {
			signal?.removeEventListener("abort", onAbort);
			resolve();
		}, ms);

		const onAbort = () => {
			clearTimeout(timeout);
			reject(new Error("Request aborted"));
		};

		if (signal) {
			if (signal.aborted) {
				clearTimeout(timeout);
				reject(new Error("Request aborted"));
				return;
			}
			signal.addEventListener("abort", onAbort, { once: true });
		}
	});
}

function getRetryDelayMs(attempt: number, retryAfterHeader: string | null): number {
	const retryAfterSeconds = Number(retryAfterHeader);
	if (Number.isFinite(retryAfterSeconds) && retryAfterSeconds >= 0) {
		return Math.min(retryAfterSeconds * 1000, 10_000);
	}
	return RETRY_BASE_DELAY_MS * 2 ** attempt;
}

async function postJson<T>(
	endpoint: string,
	body: unknown,
	signal?: AbortSignal,
	onStatus?: (message: string, details?: Record<string, unknown>) => void,
): Promise<T> {
	let lastError: Error | undefined;

	for (let attempt = 0; attempt <= MAX_RETRIES; attempt++) {
		try {
			onStatus?.(`Requesting ${endpoint} (attempt ${attempt + 1}/${MAX_RETRIES + 1})...`, {
				phase: "request",
				endpoint,
				attempt: attempt + 1,
				maxAttempts: MAX_RETRIES + 1,
			});
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
				const shouldRetry = (response.status === 429 || response.status >= 500) && attempt < MAX_RETRIES;
				if (shouldRetry) {
					const delayMs = getRetryDelayMs(attempt, response.headers.get("retry-after"));
					onStatus?.(
						`Ollama API returned ${response.status} ${response.statusText}. Retrying in ${delayMs}ms...`,
						{
							phase: "retry",
							endpoint,
							attempt: attempt + 1,
							nextAttempt: attempt + 2,
							delayMs,
							status: response.status,
						},
					);
					await sleep(delayMs, signal);
					continue;
				}
				throw new NonRetryableRequestError(`Ollama API error (${response.status} ${response.statusText}): ${text}`);
			}

			try {
				return JSON.parse(text) as T;
			} catch (error) {
				const message = error instanceof Error ? error.message : String(error);
				throw new NonRetryableRequestError(`Failed to parse Ollama API response: ${message}`);
			}
		} catch (error) {
			if (signal?.aborted || error instanceof NonRetryableRequestError) {
				throw error;
			}

			const err = error instanceof Error ? error : new Error(String(error));
			lastError = err;
			if (attempt >= MAX_RETRIES) {
				break;
			}

			const delayMs = RETRY_BASE_DELAY_MS * 2 ** attempt;
			onStatus?.(`Request failed: ${err.message}. Retrying in ${delayMs}ms...`, {
				phase: "retry",
				endpoint,
				attempt: attempt + 1,
				nextAttempt: attempt + 2,
				delayMs,
				error: err.message,
			});
			await sleep(delayMs, signal);
		}
	}

	throw lastError ?? new Error("Ollama API request failed.");
}

function normalizeUrl(input: string): string {
	const trimmed = input.trim();
	if (!trimmed) return trimmed;
	if (/^https?:\/\//i.test(trimmed)) return trimmed;
	return `https://${trimmed}`;
}

function formatSearchResults(query: string, results: WebSearchResult[]): string {
	if (results.length === 0) return `Search results for \"${query}\":\n\nNo results returned.`;

	const sections = results.map((result, index) => {
		const title = result.title ?? "Untitled";
		const url = result.url ?? "";
		const content = result.content ?? "";
		const lines: string[] = [`${index + 1}. ${title}`];
		if (url) lines.push(`URL: ${url}`);
		if (content) lines.push(`Snippet: ${content}`);
		return lines.join("\n");
	});

	return [`Search results for \"${query}\":`, "", ...sections].join("\n\n");
}

function formatFetchResult(url: string, result: WebFetchResponse): string {
	const title = result.title ?? "Untitled";
	const content = result.content ?? "";
	const links = Array.isArray(result.links) ? result.links : [];
	const displayedLinks = links.slice(0, MAX_FETCH_LINKS);
	const lines: string[] = [`Title: ${title}`, `URL: ${url}`];

	if (content) {
		lines.push("", "Content:", content);
	}

	if (displayedLinks.length > 0) {
		const linksHeading = links.length > MAX_FETCH_LINKS ? `Links (first ${MAX_FETCH_LINKS} of ${links.length}):` : "Links:";
		lines.push("", linksHeading, ...displayedLinks.map((link) => `- ${link}`));
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
		description: `Search the web via Ollama's web search API. Output is truncated to ${DEFAULT_MAX_LINES} lines or ${formatSize(
			DEFAULT_MAX_BYTES,
		)}.`,
		promptSnippet: "Search the web via Ollama's web search API.",
		promptGuidelines: [
			"Use web_search when researching general topics or when you need to discover relevant sources on the web.",
			"Use web_fetch after web_search when you want the full content of a specific result.",
		],
		parameters: WebSearchParams,
		async execute(_toolCallId, params, signal, onUpdate) {
			const { query, max_results } = params as WebSearchParamsType;
			const maxResults = clamp(max_results ?? DEFAULT_MAX_RESULTS, 1, MAX_RESULTS);

			onUpdate?.({
				content: [{ type: "text", text: `Searching the web for: ${query}` }],
				details: { phase: "start", query, maxResults },
			});

			const response = await postJson<WebSearchResponse>(
				"/web_search",
				{ query, max_results: maxResults },
				signal,
				(message, details) => {
					onUpdate?.({
						content: [{ type: "text", text: message }],
						details: { query, maxResults, ...details },
					});
				},
			);
			const results = Array.isArray(response.results) ? response.results : [];
			const output = formatSearchResults(query, results);
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
		description: `Fetch a single web page via Ollama's web fetch API. Output is truncated to ${DEFAULT_MAX_LINES} lines or ${formatSize(
			DEFAULT_MAX_BYTES,
		)}. If the URL has no scheme, https:// is assumed.`,
		promptSnippet: "Fetch the full content of a specific web page via Ollama.",
		promptGuidelines: [
			"Use web_fetch when the user provides a URL or when you need the full content of a specific page.",
			"Prefer web_search first when you need to discover which page to fetch.",
		],
		parameters: WebFetchParams,
		async execute(_toolCallId, params, signal, onUpdate) {
			const { url } = params as WebFetchParamsType;
			const normalizedUrl = normalizeUrl(url);

			onUpdate?.({
				content: [{ type: "text", text: `Fetching: ${normalizedUrl}` }],
				details: { phase: "start", url: normalizedUrl },
			});

			const response = await postJson<WebFetchResponse>(
				"/web_fetch",
				{ url: normalizedUrl },
				signal,
				(message, details) => {
					onUpdate?.({
						content: [{ type: "text", text: message }],
						details: { url: normalizedUrl, ...details },
					});
				},
			);
			const output = formatFetchResult(normalizedUrl, response);
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
