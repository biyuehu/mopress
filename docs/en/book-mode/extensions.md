---
title: Extension Configuration
---

# Extension Configuration (`[extensions]`)

The `[extensions]` table in `sena.toml` configures templates, asset copying, head/body injections, and external plugins—serving as the primary entry point for customizing Book mode builds.

## Field Reference

| Field | Type | Description |
| --- | --- | --- |
| `template` | String | Path to custom HTML template applied to all pages |
| `assets` | Array[String] | Glob patterns for static assets copied as-is to output |
| `data_dir` | String | Structured data directory (default: `data`), exposing JSON/TOML to `$data.*$` |
| `inject_head` | Array[String] | Raw HTML snippets injected into `<head>` |
| `inject_body` | Array[String] | Raw HTML snippets injected before `</body>` |
| `use_css` | Array[String] | Inline CSS code snippets injected into `<style>` tags |
| `use_js` | Array[String] | Inline JavaScript code snippets injected into `<script>` tags |
| `import_css` | Array[String] | External stylesheet URLs or paths referenced via `<link>` |
| `import_js` | Array[String] | External script URLs or paths referenced via `<script src>` |
| `preprocessors` | Array[String] | External commands modifying raw Markdown before parsing |
| `transformers` | Array[String] | External commands transforming the Markdown AST |

## External Preprocessors and Transformers

- **Preprocessors**: Run on raw text before parsing. E.g. `preprocessors = ["python expand_macros.py"]`.
- **Transformers**: Run on parsed AST blocks via JSON protocol. E.g. `transformers = ["node highlight.js"]`.
