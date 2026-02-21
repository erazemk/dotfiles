---
name: web-search
description: Web search using Jina Search API. Returns search results with titles, URLs, and descriptions. Use for finding documentation, facts, current information, or any web content.
---

# Web Search

Perform web searches using the Jina Search API. Returns formatted search results with titles, URLs, and descriptions.

## Usage

```bash
scripts/search.py "your search query"
```

## Examples

```bash
# Basic search
scripts/search.py "python async await tutorial"

# Search for recent news
scripts/search.py "latest AI developments 2024"

# Find documentation
scripts/search.py "nodejs fs promises API"
```

## Output Format

Returns markdown-formatted search results:

```
## Search Results

[Title of first result](https://example.com/page1)
Description or snippet from the search result...

[Title of second result](https://example.com/page2)
Description or snippet from the search result...
```

## When to Use

- Searching for documentation or API references
- Looking up facts or current information
- Finding relevant web pages for research
- Any task requiring web search without interactive browsing
