# Todo

## Plugins

- [x] MarkDown links transform to HTML links when rendered
- [x] Check local links
- [x] Refer to a local file as code block
- [ ] MoonBit Playground
- [x] Bilibili Video Embedding
- [x] Plugin list page
- [ ] Plugin process reuse

## Book Mode

- [x] Improve better 404 page
- [x] Feed & Sitemap generation
  - feed/sitemap 文档需提及：`description` / `keywords` / `authors` / `title` / `date` / `language` 均为可选，有则用、无则忽略
  - 暂定：feed 用 Atom，收录 SUMMARY 全部页面，条目时间戳统一用构建时间；sitemap 同样收 SUMMARY 全部
  - 新增顶层配置 `site_url`（feed 必需，缺失则跳过 feed）、`feed_enabled`、`feed_limit`、`sitemap_enabled`

## Features

- [ ] Template engine enhancements
- [ ] i18n support
- [ ] JSON / YAML data sources

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
