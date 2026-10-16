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
- [ ] i18n support
- [x] JSON / YAML / TOML data sources

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
