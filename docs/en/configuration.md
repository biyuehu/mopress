---
title: Configuration
language: en
---

# Configuration (sena.toml)

In Book Mode, `sena.toml` is the central configuration file located at your project root. Running `mopress init` automatically generates a complete `sena.toml` with sensible defaults.

## Basic Format

`sena.toml` is written in standard [TOML](https://toml.io/) format.

## Configuration Fields

Top-level fields supported in `sena.toml` (defined by [`BookConfig`](https://mooncakes.io/docs/himeno/mopress/config#BookConfig)):

| Field | Type | Description |
| --- | --- | --- |
| `title` | String | Site title, used for `<title>` tags and site identity |
| `description` | String | Site description, injected into `<meta name="description">` |
| `keywords` | String | Site keywords, injected into `<meta name="keywords">` |
| `favicon` | String | Path to favicon relative to site root |
| `logo` | String | Path to site logo |
| `authors` | Array[String] | List of site authors |
| `language` | String | Primary site language for the HTML `lang` attribute (e.g. `en`, `zh`) |
| `languages` | Array[String] | Complete list of supported languages for i18n and `hreflang` generation |
| `repository` | String? | Source repository URL, exposed to templates via `$repository$` |
| `src` | String | Source directory containing Markdown content (defaults to `./`) |
| `dest` | String | Build output directory (defaults to `./dest`) |
| `base_url` | String | Base URL prefix for links and assets (defaults to `/`) |
| `site_url` | String? | Canonical absolute URL (e.g. `https://example.com`), required for Feed & Sitemap |
| `feed_enabled` | Bool | Whether to generate Atom feed (`feed.xml`), defaults to `true` |
| `feed_limit` | Int | Maximum entries in `feed.xml`, defaults to `20` |
| `sitemap_enabled` | Bool | Whether to generate XML sitemap (`sitemap.xml`), defaults to `true` |
| `[features]` | FeaturesConfig | Built-in feature toggles (highlighting, MathJax, Open Graph, Twitter Cards, robots.txt) |
| `[extensions]` | ExtensionsConfig | Template, asset injection, and external plugin pipelines |

## Feed & Sitemap Generation

Book Mode includes automated Feed and Sitemap generators:

- **Feed (`feed.xml`)**: Generates an Atom 1.0 feed indexing up to `feed_limit` documents from `SUMMARY.md`. Because Atom requires absolute URLs, you must set `site_url` for Feed generation.
- **Sitemap (`sitemap.xml`)**: Generates standard Sitemap 0.9 XML covering all indexed pages.
- **Metadata Recognition**: The generator extracts `title`, `description`, `keywords`, `authors`, and `date` from frontmatter when available.

## Multi-Language (i18n) Support

- **Primary and Secondary Languages**: Specify the default language with `language = "en"` and declare all supported locales with `languages = ["en", "zh"]`.
- **Automatic hreflang Injection**: When `site_url` and `languages` are configured, MoPress automatically injects `<link rel="alternate" hreflang="..." href="...">` tags into `<head>` for every page.
- **Template Integration**: The template context provides `$site_language$` and `$site_languages$`, enabling easy rendering of language switcher controls using `$for(site_languages)$`.

