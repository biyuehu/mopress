# himeno/mopress

[![MoonBit](https://img.shields.io/badge/MoonBit-BF2586?style=flat)](https://www.moonbitlang.com/) [![License](https://img.shields.io/badge/License-GPL_v3-007ec6?style=flat)](https://www.gnu.org/licenses/gpl-3.0) [![CI](https://github.com/biyuehu/mopress/actions/workflows/ci.yml/badge.svg)](https://github.com/biyuehu/mopress/actions/workflows/ci.yml) ![TypeScript](https://img.shields.io/badge/TypeScript-3178C6?logo=typescript&logoColor=white) ![Codeberg](https://img.shields.io/badge/Hosted_on-Codeberg-2185D0?logo=codeberg&logoColor=white)

MoPress is a modern document and static site generator for the MoonBit ecosystem, designed with reference to both [mdBook](https://rust-lang.github.io/mdBook/) and [Hakyll](https://jaspervdj.be/hakyll/). At its core, it uses an embedded DSL (Domain Specific Language) to declare configurations, while also offering a rich plugin system and customization capabilities to meet various needs.

## Overview

MoPress offers two usage modes:

**Book mode** — out-of-the-box experience similar to mdBook. Configure via `sena.toml` and write Markdown. No code required.

**Site mode** — declare rules and pipelines by DSL in `site.mbtx` for full control over how your content is processed and rendered. Inspired by Hakyll's composable compiler design.

## Features

- Composable pipeline API — chain transforms with `|>`
- Front matter support
- Built-in preprocessors: callout blocks, math (LaTeX), file includes
- External preprocessor protocol (stdin/stdout, language-agnostic)
- WebComponent-friendly — raw HTML in Markdown is preserved, bring your own components
- Global CSS/JS injection
- Lightweight template engine built-in
- Outputs clean static HTML

## Development

### Environment

- MoonBit
- Just
- Bun
- Lefthook

### Build

```bash
just init
just build
just test
```

<!-- ## Installation

```bash
moon add himeno/mopress
```

## Quick Start

```toml
# sena.toml
title = "My Book"
src = "src"
```

```text
src/
├── SUMMARY.md
└── intro.md
```

```bash
mopress build
``` -->

## Example

```moonbit
fn main {
  mopress([
    Glob(
      "*.markdown",
      Text(raw => {
        raw
        |> set_extension("html")
        |> render_markdown_and_frontmatter
        |> load_and_apply_template("test/src/templates/default.html")
        |> import_js("./custom.js")
        |> import_css("./custom.css")
        |> use_js("console.log('hi, moonbit! hi, mopress!')")
        |> use_css("some css code")
        |> unify
      }),
    ),
  Glob("images/*", Binary(raw => raw |> unify)),
  Glob("css/*", Copy),
  ])
}
```

## License

Under the terms of the GNU General Public License, version 3 (GPLv3).
