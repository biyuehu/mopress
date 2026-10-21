---
title: Output Formats
---

# Output Formats

Once a pipeline completes its transformations, items must be committed to disk. In MoPress, the final emission layer is represented by the [`Thing`](https://mooncakes.io/docs/himeno/mopress/core#Thing) enum.

## Variants of Thing

- **`Doc(String)`**: Plain-text output, such as rendered HTML pages, XML feeds, or JSON files.
- **`Asset(Bytes)`**: Binary data, such as images, fonts, or minified bundles.
- **`Multiple(Array[(String, Thing)])`**: Emits multiple named output files from a single input item.
- **`Empty`**: Emits nothing. Useful for intermediate computation items.

## Writing to Disk

`unify` is the canonical final Step in most pipelines, converting any `Thingable` data (`String`, `Bytes`, `Json`) into its corresponding `Thing`:

```moonbit
raw
|> @core.render_markdown_and_frontmatter
|> @core.load_and_apply_template("templates/default.html")
|> @core.set_extension(".html")
|> @core.unify
```
