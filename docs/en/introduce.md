---
title: Introduction
---

# MoPress

MoPress is a modern documentation and general static site generator built for the MoonBit ecosystem, inspired by [mdBook](https://rust-lang.github.io/mdBook/) and [Hakyll](https://jaspervdj.be/hakyll/). It utilizes an embedded DSL (Domain Specific Language) for configuration and functional pipelines to express build workflows, accompanied by a rich, language-agnostic plugin ecosystem and extensive customization capabilities.

## Why MoPress?

If you just want to quickly write documentation or publish a blog, you shouldn't have to reinvent the wheel with a custom build system. But if your needs go beyond writing standard Markdown and applying a default template, you shouldn't be boxed in by tool constraints either. MoPress is designed to solve both problems through two harmonious modes:

- [**Book Mode**](./book-mode/index.md): Ready out of the box, offering an experience familiar to users of mdBook. All you need is a `sena.toml` configuration file and a collection of Markdown documents—no code required. At the same time, it provides features beyond mdBook, including multiple plugin models, code injection, custom templates, frontmatter metadata, and AST transformers.
- [**Site Mode**](./site-mode/index.md): Express custom rules and processing pipelines as a DSL in `site.mbtx`. Using a wide array of granular, composable Steps, you gain full control over how content is processed and rendered, leveraging the expressiveness of functional programming without getting bogged down in low-level plumbing.

Both modes share the same foundational engine (Markdown parsing, template engine, external plugin protocol, etc.). In essence, Site mode is a general-purpose static site generator, while Book mode is an out-of-the-box documentation generator implemented as a best-practice opinionated workflow on top of Site mode.

## Where to Go Next

- To see results immediately, start with [Quick Start](./starting.md).
- If you already know which workflow suits your project, jump directly to [Book Mode](./book-mode/index.md) or [Site Mode](./site-mode/index.md).
- For deeper customization, explores templates, globbing, and plugins in [Advanced](./advance/index.md).

## Support MoPress

<div align="center">
  <a href="https://i.arimuraromi.com/donate" target="_blank"><strong style="border-radius: 5px; padding: 10px; background-color: rgb(250, 58, 33); color: white; text-decoration: none;">👉 Keep This Project Alive 👈</strong></a>
</div>

