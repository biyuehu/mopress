# himeno/mopress

MoPress is an experimental MoonBit book generator inspired by mdBook and Hakyll.
The goal is to build a reliable MoonBit-native documentation tool that works
out of the box for mdBook-style books while also allowing deeper customization
through a `site.mbt` configuration layer.

This is not intended to be a general-purpose static site generator. The focus is
still book-oriented documentation, but with a more programmable pipeline for
projects that need custom loading, transformation, routing, rendering, or output
behavior without relying on mdBook's existing extension model.

The project is still in its foundation stage. Current work focuses on stable
configuration parsing, core book data structures, and the package boundaries
needed for summary parsing, Markdown handling, rendering, and future `site.mbt`
integration.

## Direction

MoPress is planned around two compatible modes:

- A conventional book mode with `book.toml`, `SUMMARY.md`, Markdown chapters,
  and sensible defaults for users who want an mdBook-like workflow.
- A programmable `site.mbt` mode for projects that need to describe custom
  resource loading, transformation, routing, rendering, or asset behavior in
  MoonBit.

The internal architecture should keep these modes close together: the default
book generator can be expressed as a standard site pipeline, while advanced
users can replace or extend parts of that pipeline directly.

One possible extension path is to preserve raw HTML in Markdown and let custom
Web Components provide richer client-side behavior. That keeps the Markdown
pipeline simple while leaving room for MoonBit-authored frontend components via
the JavaScript backend.

## Development

```sh
moon info
moon fmt
moon test
```
