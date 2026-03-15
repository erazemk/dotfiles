import { fileURLToPath } from "node:url";

import { StringEnum } from "@mariozechner/pi-ai";
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Type } from "@sinclair/typebox";

const GENERATED_CLI_PATH = fileURLToPath(new URL("./datadog.js", import.meta.url));
const NODE_PATH = process.execPath;
const CLI_TIMEOUT_MS = 120_000;

const ExtraColumnSchema = Type.Object({
	name: Type.String({ description: "Column name as it should appear in the SQL virtual table." }),
	type: StringEnum(
		[
			"string",
			"int64",
			"float64",
			"bool",
			"timestamp",
			"json",
			"array<string>",
			"array<int64>",
			"array<float64>",
			"array<bool>",
			"array<timestamp>",
		] as const,
		{
			description: "Column type for an extra SQL log column.",
		},
	),
});

const AnalyzeDatadogLogsParams = Type.Object({
	sql_query: Type.String({
		description: "SQL query to run against the virtual logs table.",
	}),
	filter: Type.Optional(
		Type.String({
			description: "Datadog log query used to filter logs before SQL analysis. Defaults to *.",
		}),
	),
	from: Type.Optional(Type.String({ description: "Start of the time window." })),
	to: Type.Optional(Type.String({ description: "End of the time window." })),
	indexes: Type.Optional(Type.Array(Type.String(), { description: "Restrict analysis to specific log indexes." })),
	extra_columns: Type.Optional(
		Type.Array(ExtraColumnSchema, {
			description: "Additional typed columns to expose in the SQL logs table.",
		}),
	),
	max_tokens: Type.Optional(Type.Number({ description: "Maximum number of tokens to include in the response." })),
	start_at: Type.Optional(Type.Number({ description: "Offset to start returning results from." })),
	storage_tier: Type.Optional(
		StringEnum(["flex_and_indexes", "cloudprem"] as const, {
			description: "Storage tier selection.",
		}),
	),
});

const GetDatadogTraceParams = Type.Object({
	trace_id: Type.String({
		description: "Trace ID to retrieve.",
	}),
	only_service_entry_spans: Type.Optional(
		Type.Boolean({
			description: "If true, retrieve a summarized trace collapsed to service entry spans.",
		}),
	),
	expand_span_id: Type.Optional(
		Type.String({
			description: "Span ID to expand when drilling into a summarized trace.",
		}),
	),
	extra_fields: Type.Optional(
		Type.Array(Type.String(), {
			description: "Additional meta or metrics tags to include beyond the defaults.",
		}),
	),
	include_path: Type.Optional(
		Type.Array(Type.String(), {
			description: "Only include matching spans and their ancestors/descendants in the trace.",
		}),
	),
	max_tokens: Type.Optional(Type.Number({ description: "Maximum number of tokens to include in the response." })),
});

const SearchDatadogLogsParams = Type.Object({
	query: Type.String({
		description: "Datadog log query to search.",
	}),
	from: Type.Optional(Type.String({ description: "Start time for the log search." })),
	to: Type.Optional(Type.String({ description: "End time for the log search." })),
	indexes: Type.Optional(Type.Array(Type.String(), { description: "Indexes to search." })),
	extra_fields: Type.Optional(
		Type.Array(Type.String(), {
			description: "Extra attributes or tags to include in the response.",
		}),
	),
	max_tokens: Type.Optional(Type.Number({ description: "Maximum number of tokens to include in the response." })),
	sort: Type.Optional(
		StringEnum(["timestamp", "-timestamp"] as const, {
			description: "Sort order for returned logs.",
		}),
	),
	start_at: Type.Optional(Type.Number({ description: "Offset to start returning results from." })),
	storage_tier: Type.Optional(
		StringEnum(["flex_and_indexes", "online_archives_and_indexes", "cloudprem"] as const, {
			description: "Storage tier selection.",
		}),
	),
	use_log_patterns: Type.Optional(
		Type.Boolean({
			description: "If true, return clusters of logs with similar message values instead of raw logs.",
		}),
	),
});

const SearchDatadogMonitorsParams = Type.Object({
	query: Type.Optional(Type.String({ description: "Monitor search query." })),
	sort: Type.Optional(Type.String({ description: "Sort monitors by the given field." })),
	start_at: Type.Optional(Type.Number({ description: "Offset to start returning results from." })),
	max_tokens: Type.Optional(Type.Number({ description: "Maximum number of tokens to include in the response." })),
});

const SearchDatadogDashboardsParams = Type.Object({
	query: Type.Optional(Type.String({ description: "Dashboard search query." })),
	sort_by: Type.Optional(Type.String({ description: "Sort dashboards by the given field." })),
	start_at: Type.Optional(Type.Number({ description: "Offset to start returning results from." })),
	max_tokens: Type.Optional(Type.Number({ description: "Maximum number of tokens to include in the response." })),
	include_template_variables: Type.Optional(
		Type.Boolean({
			description: "If true, include information about template variables.",
		}),
	),
	max_queries_per_dashboard: Type.Optional(
		Type.Number({
			description: "Maximum number of queries to return per dashboard.",
		}),
	),
});

const SearchDatadogServicesParams = Type.Object({
	query: Type.Optional(Type.String({ description: "Service search query." })),
	start_at: Type.Optional(Type.Number({ description: "Offset to start returning results from." })),
	max_tokens: Type.Optional(Type.Number({ description: "Maximum number of tokens to include in the response." })),
	detailed_output: Type.Optional(
		Type.Boolean({
			description: "If true, include more detailed metadata for each service.",
		}),
	),
});

const SearchDatadogSpansParams = Type.Object({
	query: Type.String({
		description: "Datadog span query to search.",
	}),
	from: Type.Optional(Type.String({ description: "Start time for the span search." })),
	to: Type.Optional(Type.String({ description: "End time for the span search." })),
	custom_attributes: Type.Optional(
		Type.Array(Type.String(), {
			description: "Custom attributes to include in the response.",
		}),
	),
	max_tokens: Type.Optional(Type.Number({ description: "Maximum number of tokens to include in the response." })),
	sort: Type.Optional(Type.String({ description: "Sort order for spans." })),
	start_at: Type.Optional(Type.Number({ description: "Offset to start returning results from." })),
});

const SearchDatadogMetricsParams = Type.Object({
	from: Type.Optional(Type.String({ description: "Lookback time window for filtering metrics." })),
	name_filter: Type.Optional(Type.String({ description: "Filter metrics by name." })),
	tag_filter: Type.Optional(Type.String({ description: "Filter metrics by tags." })),
	max_tokens: Type.Optional(Type.Number({ description: "Maximum number of tokens to include in the response." })),
	start_at: Type.Optional(Type.Number({ description: "Offset to start returning results from." })),
	has_related_assets: Type.Optional(Type.Boolean({ description: "Filter by whether metrics have related assets." })),
	is_configured: Type.Optional(Type.Boolean({ description: "Filter by Metrics Without Limits configuration status." })),
	is_queried: Type.Optional(Type.Boolean({ description: "Filter by whether metrics were queried in the lookback window." })),
	percentiles_enabled: Type.Optional(Type.Boolean({ description: "Filter by percentile aggregation status." })),
});

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

function buildTelemetryIntent(toolName: string): string {
	switch (toolName) {
		case "analyze_datadog_logs":
			return "Analyze Datadog logs for debugging and telemetry investigation.";
		case "get_datadog_trace":
			return "Retrieve a Datadog trace for debugging and request flow investigation.";
		case "search_datadog_logs":
			return "Search Datadog logs for debugging and log inspection.";
		case "search_datadog_monitors":
			return "Search Datadog monitors relevant to an incident or investigation.";
		case "search_datadog_dashboards":
			return "Search Datadog dashboards relevant to an investigation or service.";
		case "search_datadog_services":
			return "Search Datadog services relevant to an investigation or system.";
		case "search_datadog_spans":
			return "Search Datadog spans for trace and performance investigation.";
		case "search_datadog_metrics":
			return "Search Datadog metrics relevant to monitoring or analysis.";
		default:
			return "Use Datadog MCP via pi for telemetry investigation.";
	}
}

function formatExecError(toolName: string, stdout: string, stderr: string, exitCode: number | null) {
	const combined = [stderr.trim(), stdout.trim()].filter(Boolean).join("\n\n");
	const message = combined || `Generated Datadog CLI exited while running ${toolName} with code ${exitCode ?? "unknown"}.`;

	if (/spawn\s+.*datadog\s+ENOENT|command not found|No such file or directory/i.test(message)) {
		return new Error(
			"Datadog MCP requires the local Datadog binary on your PATH (expected at ~/.local/bin/datadog). Reinstall it if needed.",
		);
	}

	if (/unauthoriz|auth|login|token/i.test(message)) {
		return new Error(`${message}\n\nIf Datadog is not authenticated, run \`~/.local/bin/datadog login\`.`);
	}

	return new Error(message);
}

function buildRequiredCliFlags(toolName: string, params: Record<string, unknown>, telemetryIntent: string): string[] {
	const flags = ["--telemetry", telemetryIntent];

	switch (toolName) {
		case "analyze_datadog_logs":
			flags.unshift("--sql-query", String(params.sql_query ?? ""));
			break;
		case "get_datadog_trace":
			flags.unshift("--trace-id", String(params.trace_id ?? ""));
			break;
		case "search_datadog_logs":
		case "search_datadog_spans":
			flags.unshift("--query", String(params.query ?? ""));
			break;
	}

	return flags;
}

async function runDatadogTool(pi: ExtensionAPI, toolName: string, params: Record<string, unknown>, signal?: AbortSignal) {
	const telemetryIntent = buildTelemetryIntent(toolName);
	const rawArgs = JSON.stringify({
		...params,
	});
	const requiredCliFlags = buildRequiredCliFlags(toolName, params, telemetryIntent);

	const result = await pi.exec(
		NODE_PATH,
		[
			GENERATED_CLI_PATH,
			"--timeout",
			String(CLI_TIMEOUT_MS),
			"--output",
			"markdown",
			toolName.replace(/_/g, "-"),
			...requiredCliFlags,
			"--raw",
			rawArgs,
		],
		{ signal, timeout: CLI_TIMEOUT_MS },
	);

	if (result.code !== 0) {
		throw formatExecError(toolName, result.stdout, result.stderr, result.code);
	}

	const formatted = result.stdout.trim() || result.stderr.trim() || "";
	return truncateText(formatted);
}

export default function datadogExtension(pi: ExtensionAPI) {
	pi.registerTool({
		name: "analyze_datadog_logs",
		label: "Analyze Datadog Logs",
		description:
			"Analyze Datadog logs using SQL. Great for both exploratory queries and analytics: quickly peek at a few recent logs with a LIMIT, SELECT specific columns, or perform aggregations (counts, group-bys, etc.). SQL runs against a virtual 'logs' table filtered by your search query. For discovering available custom attributes to use as extra_columns, first call search_datadog_logs with the extra_fields parameter. If a query times out, try again with a shorter time range.",
		promptGuidelines: [
			"Use this tool instead of raw log search when the user needs counts, aggregations, grouped summaries, or numerical analysis of logs.",
			"Use search_datadog_logs first if you need to discover custom log attributes before declaring extra_columns.",
		],
		parameters: AnalyzeDatadogLogsParams,
		async execute(_toolCallId, params, signal) {
			const truncated = await runDatadogTool(pi, "analyze_datadog_logs", params as Record<string, unknown>, signal);
			return { content: [{ type: "text", text: truncated.text }], details: { truncated: truncated.truncated, generatedCli: GENERATED_CLI_PATH } };
		},
	});

	pi.registerTool({
		name: "get_datadog_trace",
		label: "Get Datadog Trace",
		description:
			"Retrieve a trace by trace ID from Datadog APM. This tool fetches all spans within a specific trace by default, providing detailed information about the request flow, timing, and service interactions. For large traces or to retrieve a summarized trace, set only_service_entry_spans=true to get a hierarchical condensed view that shows service boundaries, collapsing internal operations. The summarized view will indicate expandable spans with hidden_child_spans_count.",
		promptGuidelines: [
			"Use this tool when you already have a trace ID and need the full or summarized trace details.",
		],
		parameters: GetDatadogTraceParams,
		async execute(_toolCallId, params, signal) {
			const truncated = await runDatadogTool(pi, "get_datadog_trace", params as Record<string, unknown>, signal);
			return { content: [{ type: "text", text: truncated.text }], details: { truncated: truncated.truncated, generatedCli: GENERATED_CLI_PATH } };
		},
	});

	pi.registerTool({
		name: "search_datadog_logs",
		label: "Search Datadog Logs",
		description:
			"Search and retrieve raw log entries or log patterns from Datadog. IMPORTANT: Do NOT use this tool for counting, aggregations, or numerical analysis - use analyze_datadog_logs with SQL queries instead. This tool is best for: (1) viewing small numbers of raw logs, (2) discovering patterns in large volumes of logs, (3) discovering available custom attributes via extra_fields parameter (e.g., extra_fields: ['*'] or extra_fields: ['http*']) which can then be used as extra_columns in analyze_datadog_logs SQL queries.",
		promptGuidelines: [
			"Do not use this tool for counts or aggregations; use analyze_datadog_logs instead.",
			"Use this tool for raw log inspection, pattern discovery, and discovering custom attributes via extra_fields.",
		],
		parameters: SearchDatadogLogsParams,
		async execute(_toolCallId, params, signal) {
			const truncated = await runDatadogTool(pi, "search_datadog_logs", params as Record<string, unknown>, signal);
			return { content: [{ type: "text", text: truncated.text }], details: { truncated: truncated.truncated, generatedCli: GENERATED_CLI_PATH } };
		},
	});

	pi.registerTool({
		name: "search_datadog_monitors",
		label: "Search Datadog Monitors",
		description:
			"List and retrieve information about Datadog monitors. This tool helps discover monitors, their status, configuration, and alerts. Use this tool when you need to find monitors for investigation, management, or analysis purposes.",
		parameters: SearchDatadogMonitorsParams,
		async execute(_toolCallId, params, signal) {
			const truncated = await runDatadogTool(pi, "search_datadog_monitors", params as Record<string, unknown>, signal);
			return { content: [{ type: "text", text: truncated.text }], details: { truncated: truncated.truncated, generatedCli: GENERATED_CLI_PATH } };
		},
	});

	pi.registerTool({
		name: "search_datadog_dashboards",
		label: "Search Datadog Dashboards",
		description:
			"List and retrieve information about Datadog dashboards. This tool helps discover available dashboards, their IDs, titles, and underlying queries. Use this tool when you need to find specific dashboards, get an overview of all dashboards in your Datadog account, or find important logs+metrics queries in dashboards.",
		parameters: SearchDatadogDashboardsParams,
		async execute(_toolCallId, params, signal) {
			const truncated = await runDatadogTool(pi, "search_datadog_dashboards", params as Record<string, unknown>, signal);
			return { content: [{ type: "text", text: truncated.text }], details: { truncated: truncated.truncated, generatedCli: GENERATED_CLI_PATH } };
		},
	});

	pi.registerTool({
		name: "search_datadog_services",
		label: "Search Datadog Services",
		description:
			"List and retrieve information about Datadog services. This tool helps discover services in your environment, their descriptions, teams, and links. Use this tool when you need to find services for investigation, management, or analysis purposes.",
		parameters: SearchDatadogServicesParams,
		async execute(_toolCallId, params, signal) {
			const truncated = await runDatadogTool(pi, "search_datadog_services", params as Record<string, unknown>, signal);
			return { content: [{ type: "text", text: truncated.text }], details: { truncated: truncated.truncated, generatedCli: GENERATED_CLI_PATH } };
		},
	});

	pi.registerTool({
		name: "search_datadog_spans",
		label: "Search Datadog Spans",
		description:
			"Retrieve and analyze spans from APM traces from Datadog. This tool helps investigate distributed traces across your services, showing the complete request flow, timing information, and service dependencies. Use this tool when debugging performance issues, analyzing service interactions, or investigating request failures. The results include trace IDs, spans, timing data, and associated metadata.",
		parameters: SearchDatadogSpansParams,
		async execute(_toolCallId, params, signal) {
			const truncated = await runDatadogTool(pi, "search_datadog_spans", params as Record<string, unknown>, signal);
			return { content: [{ type: "text", text: truncated.text }], details: { truncated: truncated.truncated, generatedCli: GENERATED_CLI_PATH } };
		},
	});

	pi.registerTool({
		name: "search_datadog_metrics",
		label: "Search Datadog Metrics",
		description:
			"List available metrics in Datadog. This tool helps discover metrics available in your environment, with optional filtering by name, tags, configuration status, and query activity. Use this tool when you need to find metrics for monitoring or analysis purposes.",
		parameters: SearchDatadogMetricsParams,
		async execute(_toolCallId, params, signal) {
			const truncated = await runDatadogTool(pi, "search_datadog_metrics", params as Record<string, unknown>, signal);
			return { content: [{ type: "text", text: truncated.text }], details: { truncated: truncated.truncated, generatedCli: GENERATED_CLI_PATH } };
		},
	});
}
