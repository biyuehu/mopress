---
title: Structuring Chapters
---

# Structuring Chapters (SUMMARY.md)

`SUMMARY.md` defines the navigation structure of your documentation site, typically located at the project root. It establishes the sidebar tree, breadcrumbs, and previous/next page link ordering.

## Basic Syntax

`SUMMARY.md` uses Markdown list syntax to describe the hierarchy of documents:

```markdown
# Summary

[Introduction](./introduce.md)

---

## Guide

- [Quick Start](./starting.md)
- [Book Mode](./book-mode/index.md)
  - [Configuration](./book-mode/configuration.md)
  - [Structuring Chapters](./book-mode/summary-file.md)

---

[Contributing](./contributing.md)
```

Key rules:
- Any bare links before the first unordered list (i.e. `- [Title](path)`) are treated as **Prefix Chapters** (such as introductory pages).
- Any bare links after the last unordered list are treated as **Suffix Chapters** (appendices, FAQs, changelogs).
- Section headings (e.g. `## Guide`) serve as **Part Titles** to group chapters visually.
- Unordered list items `- [Title](path)` define **Numbered Chapters** with automatic hierarchy numbering in the sidebar.
- Indented list items define nested child sub-chapters.
- Horizontal dividers `---` create visual separators between sections.

## Important Note

`SUMMARY.md` **only** defines navigation metadata (sidebar hierarchy, breadcrumbs, previous/next links). It does **not** restrict which files are compiled.

During Book mode builds, MoPress discovers and compiles all matching Markdown files in your source directory. Unlisted Markdown files are still rendered to HTML, but will not have sidebar links or previous/next breadcrumbs calculated. Conversely, links in `SUMMARY.md` pointing to non-existent files will cause a build error.
