---
title: Site Mode Quickstart
language: en
---

# Site Mode Quickstart

This tutorial walks you through creating a static site from scratch using MoonBit script pipelines in **Site Mode**.

## Prerequisites

Follow the installation instructions in the [Quick Start](/en/starting.html) guide to ensure `mopress` and the `moon` toolchain are installed.

In Site Mode, your project entry point is a MoonBit script (`site.mbtx`), providing programmatic, functional control over the build process.

## Creating a Project

Run:

```bash
mopress new my-site
cd my-site
```

This scaffolds:

```text
├── site.mbtx
├── index.md
├── about.md
├── contact.md
├── posts
│   └── hello-world.md
├── templates
│   └── default.html
└── styles
    └── default.css
```

### The Build Script (`site.mbtx`)

The generated `site.mbtx` declares functional processing pipelines using the pipe operator (`|>`):

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
        |> @core.add_excerpt(separator="<!--more-->", max_length=160)
        |> @core.add_reading_time(words_per_minute=300)
        |> @core.set_extension(".html")
        |> @core.render_markdown_and_frontmatter
        |> @core.load_and_apply_template("templates/default.html")
        |> @core.inject_open_graph({
          og_type: Some("website"),
          url: None,
          title: None,
          description: None,
          image: None,
          site_name: Some("MoPress Site"),
          locale: Some("en"),
        })
        |> @core.inject_twitter_card({
          card: Some("summary"),
          title: None,
          description: None,
          image: None,
          creator: None,
        })
        |> @core.use_js(["console.log('Built with MoPress Site Mode')"])
        |> @core.unify
      }),
    ),
    Glob("styles/**/*", Copy),
  ])
}
```

## Running the Build

```bash
moon run --target native site.mbtx build
```

The compiled pages, extracted excerpts, reading time estimates, Open Graph/Twitter Card tags, and styles will be written to `./dest`.

## Template Options

When creating a new site, you can choose between templates:
- `mopress new my-blog --template blog` (default, with posts and full SEO pipeline)
- `mopress new my-site --template minimal` (lightweight minimal pages)

