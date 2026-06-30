# himeno/mopress

[![wakatime](https://wakatime.com/badge/user/018dc603-712a-4205-a226-d4c9ccd0d02b/project/c6909f20-193d-49a4-b3ab-f9b7732b5d76.svg)](https://wakatime.com/badge/user/018dc603-712a-4205-a226-d4c9ccd0d02b/project/c6909f20-193d-49a4-b3ab-f9b7732b5d76) [![Language](https://img.shields.io/badge/MoonBit-BF2586?style=flat)](https://www.moonbitlang.com/) [![License](https://img.shields.io/badge/License-GPL_v3-007ec6?style=flat)](https://www.gnu.org/licenses/gpl-3.0) [![CI](https://github.com/biyuehu/mopress/actions/workflows/ci.yml/badge.svg)](https://github.com/biyuehu/mopress/actions/workflows/ci.yml)

A modern documentation and static site generator for the MoonBit ecosystem, inspired by mdBook and Hakyll.

## Overview

mopress offers two usage modes:

**Book mode** — out-of-the-box experience similar to mdBook. Configure via `sena.toml` and write Markdown. No code required.

**Site mode** — declare rules and pipelines in `site.mbt` for full control over how your content is processed and rendered. Inspired by Hakyll's composable compiler design.

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
- Lefthook

### Build

```bash
just init
moon test
moon build
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
        |> identify
      }),
    ),
  Glob("images/*", Binary(raw => raw |> identify)),
  Glob("css/*", Copy),
  ])
}
```

## License

Under the terms of the GNU General Public License, version 3 (GPLv3).
