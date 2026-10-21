---
title: Getting Started with Site Mode
---

# Getting Started with Site Mode

This guide walks through creating your first static site project powered by a `site.mbtx` MoonBit script.

## Create a Project

Run the scaffold command:

```bash
mopress new my-site
cd my-site
```

This generates the standard site scaffold:

```text
my-site/
├── site.mbtx
├── index.md
├── about.md
├── contact.md
├── posts/
│   └── hello-world.md
├── templates/
│   └── default.html
└── styles/
    └── default.css
```

## The Pipeline Script (`site.mbtx`)

```moonbit
import "himeno/mopress/core" as @core

async fn main {
  let builder = @core.SiteBuilder::new()
  
  builder.rule(
    "**/*.md",
    @core.Handler::text(raw => {
      raw
      |> @core.separate_frontmatter
      |> @core.render_markdown_and_frontmatter
      |> @core.load_and_apply_template("templates/default.html")
      |> @core.set_extension(".html")
      |> @core.unify
    })
  )

  builder.rule("styles/**/*", @core.Handler::copy())

  builder.run()
}
```

## Running the Build

Build the project using the native target:

```bash
moon run --target native site.mbtx build
```

Run a live local server:

```bash
moon run --target native site.mbtx serve
```
