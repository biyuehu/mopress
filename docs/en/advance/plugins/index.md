---
title: Plugins Overview
---

# Plugins Overview

MoPress provides three complementary plugin architectures suited to different environments:

| Plugin Type | Runtime Environment | Best Suited For |
| --- | --- | --- |
| External CLI Subprocesses | Any language (Python, Node.js, Rust, Go) | Cross-language text and AST transforms ([Protocol](./protocol.md)) |
| Web Components | Browser DOM runtime | Interactive widgets, tabs, reactive components ([Guide](./web-components.md)) |
| MoonBit Native Modules | MoonBit native in-process | Composable, zero-overhead steps for Site mode ([Guide](./moonbit-modules.md)) |

## Preprocessors vs. Transformers

- **Preprocessors**: Run on raw Markdown text before AST parsing.
- **Transformers**: Run on parsed Markdown AST blocks before HTML rendering.
