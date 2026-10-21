---
title: Page Customization
---

# Page Customization

This section explains how to customize HTML templates, stylesheets, scripts, and inject custom behaviors in Book mode.

## Custom Templates

Set `extensions.template` in `sena.toml` to specify your custom HTML template (default: `templates/default.html`).

## Template Variables in Book Mode

| Variable | Type | Description |
| --- | --- | --- |
| `body` | String | Rendered HTML content of the markdown page |
| `site_title` | String | Site title from `book.title` |
| `site_description` | String | Site description from `book.description` |
| `site_language` | String | Primary language from `book.language` |
| `site_languages` | Array[String] | Supported languages from `book.languages` |
| `is_en` | Bool | Whether current page is in the English documentation hierarchy |
| `toc` | Json | Extracted table of contents outline |
| `data` | Object | Structured data loaded from `data/` directory |
| `prev` | Json? | Previous page navigation object (`title`, `location`) |
| `next` | Json? | Next page navigation object (`title`, `location`) |
| `current` | String | Current page relative path |
| `build_time` | String | Timestamp of build generation |
| `version` | String | MoPress version |

## Handling Navigation in Templates

```html
$if(prev)$
  <a href="$prev.location$">← $prev.title$</a>
$endif$
$if(next)$
  <a href="$next.location$">$next.title$ →</a>
$endif$
```

