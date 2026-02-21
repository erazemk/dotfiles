#!/usr/bin/env -S deno run --allow-read --allow-env --allow-net --allow-sys
import { JSDOM } from "npm:jsdom@^26.0.0";
import { extname } from "node:path";
import { readFileSync } from "node:fs";

// Set up browser environment BEFORE importing mermaid
const dom = new JSDOM("<!DOCTYPE html><html><body></body></html>");
(globalThis as any).window = dom.window;
(globalThis as any).document = dom.window.document;
(globalThis as any).SVGElement = dom.window.SVGElement;
Object.defineProperty(globalThis, "navigator", {
  value: dom.window.navigator,
  writable: true,
  configurable: true,
});

// Now import mermaid so DOMPurify sees the DOM environment
const mermaid = (await import("npm:mermaid@^11.4.0")).default;

mermaid.initialize({
  startOnLoad: false,
  suppressErrors: true,
  securityLevel: "loose",
});

const file = Deno.args[0];
if (!file) {
  console.error("Usage: validate <file.mmd|file.md>");
  Deno.exit(1);
}

const content = readFileSync(file, "utf8");
const ext = extname(file).toLowerCase();

interface Block {
  code: string;
  line: number;
}

const blocks: Block[] = [];

if ([".md", ".mdx", ".markdown"].includes(ext)) {
  const regex = /```mermaid\s*\n([\s\S]*?)```/g;
  let match;
  while ((match = regex.exec(content)) !== null) {
    const line = content.slice(0, match.index).split("\n").length + 1;
    blocks.push({ code: match[1].trim(), line });
  }
  if (blocks.length === 0) {
    console.error(`No \`\`\`mermaid blocks found in ${file}`);
    Deno.exit(1);
  }
} else {
  blocks.push({ code: content.trim(), line: 1 });
}

let failed = 0;

for (let i = 0; i < blocks.length; i++) {
  const { code, line } = blocks[i];
  const label = blocks.length > 1 ? `Block ${i + 1} (line ${line})` : file;

  try {
    await mermaid.parse(code);
    console.log(`✓ ${label}`);
  } catch (e) {
    failed++;
    console.error(`✗ ${label}\n`);
    console.error(" ", (e as Error).message || e);
    console.error();
  }
}

if (failed > 0) {
  console.error(
    `${failed}/${blocks.length} block${blocks.length > 1 ? "s" : ""} failed validation`
  );
  Deno.exit(1);
} else {
  const n = blocks.length;
  console.log(`\nAll ${n} block${n > 1 ? "s" : ""} valid`);
}
