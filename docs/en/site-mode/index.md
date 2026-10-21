---
title: Site Mode Overview
---

# Site Mode

Site mode is the programmatic way to use MoPress: instead of relying exclusively on configuration files, you express build rules and pipelines directly in MoonBit code via an embedded DSL. Inspired by [Hakyll](https://jaspervdj.be/hakyll/)'s composable compiler philosophy, Site mode decomposes static site generation into fine-grained functional steps that can be freely combined.

## Why Site Mode?

- Creating general static websites (blogs, portfolios, product landing pages) rather than strictly documentation books.
- Applying different pipelines to different subsets of files.
- Injecting native in-process MoonBit logic, data transformations, and custom AST walks.
- Harnessing the power and safety of functional programming.

## Core Abstractions

1. **`Item[T]`**: The data container flowing through pipelines, carrying typed payload `T`, route destination, and template variables.
2. **Step**: A function of shape `(Item[T]) -> Item[R]` that transforms data.
3. **`Rule`**: Declarative binding of Glob patterns to Handlers.
4. **`Pipeline`**: An execution graph of Steps connected via MoonBit's pipe operator `|>`.

## Sections

- [Getting Started with Site Mode](./starting.md): Creating your first `site.mbtx` script.
- [Rules, Handlers, and Steps](./rules-handlers-steps.md): Core concepts and lifecycle.
- [Composing Steps](./composing-steps.md): Built-in steps and composition patterns.
- [Output Formats](./output-formats.md): Documents, assets, and data emission.

