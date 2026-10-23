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
- **Prefix & Suffix Chapters**: Bare links not wrapped in a list (such as `[Introduction](./introduce.md)` or `[Contributing](./contributing.md)`) render without chapter numbers, suitable for introductory notes, appendices, or project links.
- **Part Titles**: Headings (`# Part Title` or `## Guide`) serve as section headers in the sidebar to group chapters logically without mapping to a physical document.
- **Numbered Chapters**: Unordered list items `- [Title](path)` define body chapters. Within each Part section, top-level numbered chapters **automatically and independently start numbering from 1**.
- **Nested Sub-chapters**: Indented list items (2 or 4 spaces) represent hierarchical sub-chapters and inherit parent prefixes (e.g. `2.1`, `2.2`, `2.2.1`).
- **Separators**: Horizontal rules `---` create visual dividers in the sidebar. Separators, prefix/suffix chapters, and parts strictly follow their written document order, seamlessly supporting bilingual or multi-section architectures.

## Important Note

`SUMMARY.md` **only** defines navigation metadata (sidebar hierarchy, breadcrumbs, previous/next links). It does **not** restrict which files are compiled.

During Book mode builds, MoPress discovers and compiles all matching Markdown files in your source directory. Unlisted Markdown files are still rendered to HTML, but will not have sidebar links or previous/next breadcrumbs calculated. Conversely, links in `SUMMARY.md` pointing to non-existent files will cause a build error.

