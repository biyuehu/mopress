---
title: Introduction
language: en
---

# MoPress

MoPress is a modern documentation and general-purpose static site generator for the MoonBit ecosystem, inspired by both [mdBook](https://rust-lang.github.io/mdBook/) and [Hakyll](https://jaspervdj.be/hakyll/). At its core, it leverages an embedded DSL and functional pipelines to express build workflows, combined with a versatile, language-agnostic plugin architecture to accommodate diverse needs.

## Why MoPress?

If you just want to author documentation or publish a technical blog quickly, you shouldn't need to write a build system from scratch. But when your requirements expand beyond simply rendering Markdown against a static template, you shouldn't be constrained by rigid tooling limits either. MoPress is designed to excel in both scenarios, offering two complementary modes:

- [**Book Mode**](/book-mode/index.html): Out-of-the-box convenience, akin to mdBook. All you need is a single `sena.toml` configuration file and Markdown documents—zero code required. Yet it includes powerful features beyond conventional tools: multiple plugin mechanisms, asset and head/body injection, custom templates, YAML/TOML data sources, frontmatter support, AST transformations, and fine-grained SEO optimizations.
- [**Site Mode**](/site-mode/index.html): Declare matching rules and processing pipelines via an expressive DSL in `site.mbtx`. Using a rich catalog of atomic steps (reading time calculation, excerpt extraction, atomic SEO injection, pagination, and template application), you have full control over content transformation with the elegance and safety of MoonBit's functional pipeline syntax (`|>`).

Both modes share the identical underlying engine (Markdown AST parser, custom template engine, structured data loader, and external plugin bridge). In essence, Site Mode is the general-purpose static site toolkit, while Book Mode is an out-of-the-box generator built as a best-practice distribution on top of Site Mode.

## Getting Started

- To get up and running in minutes, check out [Quick Start](./starting.md).
- To explore Book Mode configuration and features, see [Configuration](/book-mode/configuration.html).
- To build custom pipelines using MoonBit scripts, head over to [Site Mode](/site-mode/index.html).

## Support MoPress

<div align="center">
  <a href="https://i.arimuraromi.com/donate" target="_blank"><strong style="border-radius: 5px; padding: 10px; background-color: rgb(250, 58, 33); color: white; text-decoration: none;">👉 Keep This Project Alive 👈</strong></a>
</div>
