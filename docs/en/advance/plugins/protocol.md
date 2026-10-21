---
title: External Plugin Protocol
---

# External Plugin Protocol

External preprocessors and transformers communicate with MoPress over standard input (stdin) and standard output (stdout) via JSON. You can write plugins in Python, Node.js, Go, Rust, or any CLI environment.

## Protocol Lifecycle

1. **Request (stdin)**: MoPress writes a JSON payload containing site config, file target, input type, and content payload.
2. **Response (stdout)**: The plugin returns processed JSON (`{ "data": ... }`). An empty stdout indicates the content was untouched.
3. **Error Reporting**: Non-zero exit code or stderr output halts the build process with error diagnostics.

## JSON Schemas

### Request Schema

```json
{
  "config": { ... },
  "type": "markdown-text", // or "markdown-ast"
  "data": "raw text or serialized AST blocks",
  "target": "path/to/page.md"
}
```

### Response Schema

```json
{
  "data": "transformed text or AST blocks"
}
```

