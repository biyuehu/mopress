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

## Development

```sh
moon info
moon fmt
moon test
```
