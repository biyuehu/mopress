# Todo

## Plugins

- [x] MarkDown links transform to HTML links when rendered
- [x] Check local links
- [x] Refer to a local file as code block
- [ ] MoonBit Playground
- [x] Bilibili Video Embedding
- [ ] Plugin list page
- [ ] Plugin process reuse

## Book Mode

- [x] Improve better 404 page
- [ ] Feed & Sitemap generation

## Features

- [ ] Template engine enhancements
- [ ] i18n support
- [ ] JSON / YAML data sources

## Site Mode

- [x] `--explain` / `--dry-run`

## Docs

- [ ] Fix documentation inconsistencies
- [ ] Fill in `docs/contributing.md`
- [ ] Update hardcoded version in `docs/index.html`
- [ ] Replace placeholder entry in `docs/plugins.json`

## Tests

- [ ] bridge: cover `run_markdown_preprocessors` / `run_markdown_transformers` against a real fixture process
- [ ] summary: cover `Summary::index_articles` against a fixture directory
- [ ] template: cover `$partial$` path edge cases (`..`, absolute, empty)
- [ ] markdown: cover `parse_html_block` termination conditions