---
title: Feature Presets
---

# Feature Presets (`[features]`)

The `[features]` table in `sena.toml` provides convenient one-click flags for common web capabilities. When enabled, MoPress automatically expands these presets into the appropriate `[extensions]` configurations (scripts, stylesheets, meta tags, and robots directives).

## Field Reference

| Field | Type | Default | Description |
| --- | --- | --- | --- |
| `highlight-enabled` | Bool | `false` | Enable client-side code syntax highlighting via Highlight.js |
| `highlight-theme` | String | `"github"` | Theme name for syntax highlighting (e.g. `github-dark`, `tokyo-night-dark`) |
| `mathjax-enabled` | Bool | `false` | Enable MathJax math formula rendering |
| `open-graph` | Bool | `true` | Automatically inject Open Graph social metadata tags |
| `twitter-card` | Bool | `true` | Automatically inject Twitter Card metadata tags |
| `robots-txt` | Bool | `true` | Automatically emit standard `robots.txt` file into output |

## How Presets Work

`features` act as configuration syntactic sugar. During config loading, active feature flags automatically append necessary assets (CSS/JS files, tags) directly into your extension pipeline. If you need bespoke custom styling or custom CDNs, simply keep the preset disabled and provide your custom assets via `[extensions]`.

