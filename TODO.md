# Todo

## Plugins

- [x] MarkDown links transform to HTML links when rendered
- [x] Check local links
- [x] Refer to a local file as code block
- [x] MoonBit Playground
- [x] Bilibili Video Embedding
- [x] Plugin list page
- [x] Plugin process reuse

## Book Mode

- [x] Improve better 404 page
- [x] Feed & Sitemap generation

## Features

- [x] Template engine enhancements
- [x] Build performance profiling (`mopress build --analyze` & `--analyze-json`)
- [ ] Build performance & caching
  - [x] Data sources preloading and caching
  - [x] Incremental build with content hashing
  - [x] Dev server live reloading (`mopress serve`)
- [ ] Template partial / include syntax (`$include("partials/footer.html")$`)
- [ ] Native code block syntax highlighting & copy button (`features.code_copy`)
- [ ] Table of Contents (TOC) extraction & `$toc$` template variable
- [ ] Search index generation (`features.search`)
- [ ] i18n / multi-language support
- [x] JSON / YAML / TOML data sources
- [ ] Standard step combinators library for Site Mode (`@mopress/steps`)

## Site Mode

- [x] `--explain` / `--dry-run`

## Docs

- [x] Fix documentation inconsistencies
- [x] Fill in `docs/contributing.md`
- [x] Update hardcoded version in `docs/index.html`
- [x] Replace placeholder entry in `docs/plugins.json`

## Tests

- [x] bridge: cover `run_markdown_preprocessors` / `run_markdown_transformers` against a real fixture process
- [x] summary: cover `Summary::index_articles` against a fixture directory
- [x] template: cover `$partial$` path edge cases (`..`, absolute, empty)
- [x] markdown: cover `parse_html_block` termination conditions
- [x] glob: cover tokenizer, scanner, and wildcard edge cases
- [x] core: cover `process_markdown_page` and `mo_build` `no_emit`
