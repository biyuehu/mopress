---
title: Frontmatter Metadata
---

# Frontmatter Metadata

Frontmatter is a block of YAML or key-value metadata placed at the very top of a Markdown document, delimited by `---`. It describes page-specific properties without being rendered into the visible body content.

## Basic Syntax

```markdown
---
title: My First Page
description: An introductory guide
date: 2026-10-21
---

# Page Title

Content begins here.
```

## Standard Recognized Fields

In Book mode, the built-in template engine and SEO/Feed generators recognize standard frontmatter fields:

- `title`: Page title (falls back to the chapter link text from `SUMMARY.md`).
- `description`: Summary for `<meta name="description">` and Feed `<summary>`.
- `keywords`: Comma-separated keywords for `<meta name="keywords">`.
- `authors`: Page authors, falling back to global `book.authors`.
- `date`: Release or update timestamp for Feeds and Sitemaps.
- `language`: Page-level language override (e.g. `en` or `zh`).

## Custom Frontmatter

You can define arbitrary custom keys (e.g. `draft: true`, `hero_image: /banner.jpg`). In Book mode, all frontmatter keys are automatically transformed into template variables accessible via `$var_name$`.
