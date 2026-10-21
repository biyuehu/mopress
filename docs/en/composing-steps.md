---
title: Composing Steps
---

# Composing Steps

The core library provides a suite of fundamental steps that can be freely assembled into a custom static site processing pipeline using MoonBit's pipe operator `|>`. This section covers common step categories, their usage, and template variable mechanics.

## Common Steps

### Metadata and Parsing

```moonbit
pub fn separate_frontmatter(item : Item[String]) -> Item[(Map[String, String], String)]

pub fn[T : Show] extract_markdown(item : Item[T]) -> Item[(Map[String, String], String)]

pub fn[T : Show] parse_markdown(item : Item[T]) -> Item[Array[@markdown.Block]]
```

`separate_frontmatter` splits raw text into YAML frontmatter metadata (`Map[String, String]`) and body text, expecting `Item[String]` as input. `extract_markdown` performs the same operation but accepts any type implementing `Show`. `parse_markdown` parses Markdown text into an [AST node array](https://mooncakes.io/docs/himeno/mopress/markdown#Markdown).

### Rendering

```moonbit
pub fn[T : Show] render_markdown(item : Item[T]) -> Item[String]

pub fn[T : Show] render_markdown_and_frontmatter(item : Item[T]) -> Item[String]

pub fn render_markdown_from_ast(item : Item[Array[@markdown.Block]]) -> Item[String]

pub fn render_markdown_and_frontmatter_from_ast(
  item : Item[Array[@markdown.Block]],
  frontmatter : Map[String, String],
) -> Item[String]
```

- `render_markdown` renders text directly to HTML without stripping frontmatter.
- `render_markdown_and_frontmatter` calls `separate_frontmatter` first to isolate metadata before rendering.
- `render_markdown_from_ast` and `render_markdown_and_frontmatter_from_ast` work directly with parsed ASTs, suitable when inserting custom transformations (e.g. AST transformers) between parsing and rendering.

### Content Excerpts and Reading Time

```moonbit
pub fn[T : Show] add_excerpt(
  item : Item[T],
  separator? : String, // Default: "<!--more-->"
  max_length? : Int32, // Default: 200
  var_name? : String,  // Default: "excerpt"
) -> Item[T]

pub fn[T : Show] add_reading_time(
  item : Item[T],
  words_per_minute? : Int32, // Default: 300
  words_var? : String,       // Default: "word_count"
  time_var? : String,        // Default: "reading_time"
) -> Item[T]
```

`add_excerpt` searches for the `separator` delimiter or truncates at `max_length` to extract a plain-text excerpt into `$excerpt$`. `add_reading_time` computes mixed Chinese/English word counts and estimates reading duration, setting `$word_count$` and `$reading_time$`.

### Granular SEO Injections

```moonbit
pub fn inject_canonical(item : Item[Html], url : String) -> Item[Html]

pub fn inject_open_graph(item : Item[Html], options : OpenGraphOptions) -> Item[Html]

pub fn inject_twitter_card(item : Item[Html], options : TwitterCardOptions) -> Item[Html]

pub fn inject_feed_discovery(
  item : Item[Html],
  feed_url : String,
  title? : String,
  mime_type? : String,
) -> Item[Html]

pub fn inject_sitemap_discovery(item : Item[Html], sitemap_url : String) -> Item[Html]
```

These steps inject standard `<head>` SEO tags, including Canonical links, Open Graph metadata, Twitter Cards, and discovery declarations for RSS/Atom feeds and Sitemaps.

### Pagination Generation

```moonbit
pub fn generate_pagination(
  items : Array[PaginatedItem],
  page_size? : Int32,          // Default: 10
  base_path? : String,         // Default: "posts"
  template_path~ : String,
) -> Thing raise
```

`generate_pagination` partitions an array of `PaginatedItem` into paginated pages (e.g. `posts/index.html`, `posts/page/2/index.html`) and populates variables such as `items`, `current_page`, `total_pages`, `prev_url`, and `next_url`.

### Templates and Asset Injection

```moonbit
pub fn apply_template(item : Item[String], template : Array[@template.TemplateNode]) -> Item[String]

pub fn apply_template_strict(item : Item[String], template : Array[@template.TemplateNode]) -> Item[String] raise

pub fn load_and_apply_template(item : Item[String], path : String, strict? : Bool) -> Item[String] raise

pub fn use_css(item : Item[String], code : Array[String]) -> Item[String]

pub fn use_js(item : Item[String], code : Array[String]) -> Item[String]

pub fn import_css(item : Item[String], paths : Array[String]) -> Item[String]

pub fn import_js(item : Item[String], paths : Array[String]) -> Item[String]

pub fn inject_head(item : Item[String], html : String) -> Item[String]

pub fn inject_body(item : Item[String], html : String) -> Item[String]
```

- `apply_template` renders templates leniently (missing variables or branches fallback gracefully).
- `apply_template_strict` validates strictly, raising errors when issues occur.
- `load_and_apply_template` reads, parses, and applies a template file in a single step.
- `use_css` / `use_js` inlines raw code as `<style>` or `<script>` tags before `</head>` or `</body>`.
- `import_css` / `import_js` adds `<link rel="stylesheet">` or `<script src>` tags referencing external asset paths.
- `inject_head` / `inject_body` injects raw HTML snippets into the document head or body.

### Typing and Pipeline Finalization

```moonbit
pub fn[T] set_extension(item : Item[T], extension : String) -> Item[T]

pub fn[T : Thingable] unify(item : Item[T]) -> Item[Thing]
```

`set_extension` sets the output file extension (including the leading dot, e.g. `.html`). `unify` wraps the computed data into a final `Thing` instance, completing the item pipeline.

```moonbit
pub trait Thingable {
  fn to_thing(Self) -> Thing
}

pub impl Thingable for String
pub impl Thingable for Bytes
pub impl Thingable for Json
```

- `String` converts to `Thing::Doc`
- `Bytes` converts to `Thing::Asset`
- `Json` converts to its native JSON representation

### In-Process Step Composition

In addition to external command plugins, Site mode allows passing plain MoonBit functions directly:

```moonbit
pub fn use_preprocessor(
  item : Item[String],
  preprocessors : Array[(Item[String]) -> Item[String] raise],
) -> Item[String] raise

pub fn use_transformer(
  item : Item[Array[@markdown.Block]],
  transformers : Array[(Item[Array[@markdown.Block]]) -> Item[Array[@markdown.Block]] raise],
) -> Item[Array[@markdown.Block]] raise
```

In-process composition executes directly in the native host process without serialization overhead or subprocess spawning, offering optimal performance and native debugging support.

## Template Variables

In Site mode, variables are passed into templates via `Item::add_vars`, `Item::set_var`, or automatically provided by steps (such as `body` generated by `render_markdown`).

To automatically bind frontmatter entries to template variables:

```moonbit
raw
|> @core.separate_frontmatter
|> x => {
  let (frontmatter, body) = x.data
  x.map(_ => body).add_vars(frontmatter.map(k, v => (k, @template.Value::String(v))))
}
```

### Loading Structured Data (JSON / TOML)

To load external data files (such as authors, navigation menus, or site configuration), use `@data.load_data` to load all `.json` and `.toml` files in a folder into `$data.*$` variables:

```moonbit
raw
|> @data.load_data("data")
|> @core.separate_frontmatter
// Templates can now access data via $data.authors$, etc.
```

## Complete Example

Book mode's markdown processing function [`process_markdown_page`](https://mooncakes.io/docs/himeno/himeno/mopress#process_markdown_page) is the primary reference implementation for assembling steps into an end-to-end pipeline.
