# MoPress

<div align="center">

  [![MoonBit](https://img.shields.io/badge/MoonBit-BF2586?style=flat)](https://www.moonbitlang.com/) [![License](https://img.shields.io/badge/License-GPL_v3-007ec6?style=flat)](https://www.gnu.org/licenses/gpl-3.0) [![CI](https://github.com/biyuehu/mopress/actions/workflows/ci.yml/badge.svg)](https://github.com/biyuehu/mopress/actions/workflows/ci.yml) ![TypeScript](https://img.shields.io/badge/TypeScript-3178C6?logo=typescript&logoColor=white) ![Codeberg](https://img.shields.io/badge/Hosted_on-Codeberg-2185D0?logo=codeberg&logoColor=white)

  <a target="_blank" href="https://mo.himeno-sena.com/"><strong>👉 Reading MoPress Book 👈</strong></a>
</div>

MoPress is a modern documentation and general-purpose static site generator for the MoonBit ecosystem. Its design draws inspiration from both [mdBook](https://rust-lang.github.io/mdBook/) and [Hakyll](https://jaspervdj.be/hakyll/). At its core, MoPress uses an embedded DSL (Domain-Specific Language) for declarative configuration and functional processing pipelines to express build workflows. It also provides a rich, language-agnostic plugin system and extensive customization capabilities to accommodate a wide range of use cases.

## Why MoPress?

If all you want is to quickly write some documentation or publish a blog, you should not have to reinvent the wheel by building an entire build system from scratch. But when your requirements go beyond writing Markdown and applying templates, your tools should not get in your way—nor should you have to repeatedly deal with tedious implementation details.

MoPress attempts to serve both cases by providing two complementary modes of use:

- [**Book Mode**](./book-mode/index.md): An out-of-the-box experience similar to mdBook. All you need is a `sena.toml` configuration file and a collection of Markdown files—no code required. At the same time, it provides many capabilities beyond mdBook, including multiple plugin systems, code injection, custom templates, front matter, and AST transformations (i.e. transformers).

- [**Site Mode**](./site-mode/index.md): Declare Rules and processing Pipelines through a DSL in `site.mbtx`. Build workflows are expressed using a rich set of atomic Steps, giving you complete control over how content is processed and rendered. Through functional composition, Steps can be combined freely and flexibly for virtually unlimited expressiveness, without requiring you to concern yourself with tedious low-level implementation details. ~~Combined with MoonBit's elegant syntax, this declarative style might be particularly exciting for functional programming enthusiasts.~~

Both modes share the same underlying capabilities, including Markdown parsing, the template engine, and the external plugin protocol. In fact, Site Mode is designed as a general-purpose static site generator, while Book Mode is both a best-practice example built on top of Site Mode and an out-of-the-box generator that presets a complete build workflow for book-style documentation websites.

## Features

- Composable pipeline API — chain transforms with `|>`
- Functional programming style
- DSL for configuration and pipeline definition
- Front matter support
- Built-in preprocessors: callout blocks, math (LaTeX), file includes
- External preprocessor protocol (stdin/stdout, language-agnostic)
- WebComponent-friendly — raw HTML in Markdown is preserved, bring your own components
- Global CSS/JS injection
- Lightweight template engine built-in
- Outputs clean static HTML

## Installation

### By MoonBit

```bash
moon add himeno/mopress
```

### Release

Please refer to the [release page](https://github.com/biyuehu/mopress/releases) for the latest release.

## Start By Book Mode

```bash
mopress init
mopress build
mopress serve
```

```toml
title = "MoPress Doc"
description = "A modern documentation and static site generator for the MoonBit ecosystem, inspired by mdBook and Hakyll"
keywords = "Documentation,Static Site Generator,SSG,MoonBit,MoonLang,Moon,Functional,Haskell,mdBook,Hakyll"
favicon = "https://himeno-sena.com/favicon.ico"
logo = "https://himeno-sena.com/favicon.ico"
authors = ["Himeno Sena"]
language = "en"
src = "./"
dest = "./dest"
repository = "https://github.com/biyuehu/mopress"
```

```text
src/
├── SUMMARY.md
└── intro.md
```

## Start By Site Mode

```bash
mopress new my-book
cd my-book
moon run --target native site.mbtx build
moon run --target native site.mbtx serve
```

```moonbit
import {
  "himeno/mopress/core",
  "moonbitlang/async",
}

///|
async fn main {
  @core.mopress([
    Glob(
      "**/*.md",
      Text(raw => {
        raw
        |> @core.set_extension(".html")
        |> @core.render_markdown_and_frontmatter
        |> @core.load_and_apply_template("templates/default.html")
        |> @core.use_js(["console.log('hi, moonbit! hi, mopress!')"])
        |> @core.unify
      }),
    ),
    Glob("styles/**/*", Copy),
  ])
}
```

## Supports

<div align="center">
  <a target="_blank" href="https://i.arimuraromi.com/donate" target="_blank"><strong style="border-radius: 5px; padding: 10px; background-color: rgb(250, 58, 33); color: white; text-decoration: none;">👉 Keep This Project Alive 👈</strong></a>
</div>

## License

Under the terms of the GNU General Public License, version 3 (GPLv3).
