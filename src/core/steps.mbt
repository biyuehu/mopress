///|
/// Parses `item`'s data as Markdown, replacing it with the resulting AST.
pub fn[T : Show] parse_markdown(item : Item[T]) -> Item[@markdown.Markdown] {
  item.map(data => data |> @markdown.parse_markdown)
}

///|
/// Splits `item`'s data into its YAML frontmatter and Markdown body.
///
/// The data is expected to be `Show`-able text in the usual frontmatter
/// convention (a `---`-delimited YAML block at the top of the document,
/// followed by the document body). The resulting item's data is a tuple of
/// the parsed frontmatter (as a `Map[String, String]`) and the remaining
/// body text.
pub fn[T : Show] extract_markdown(
  item : Item[T],
) -> Item[(Frontmatter, String)] {
  item.map(data => data.to_string() |> parse_frontmatter)
}

///|
/// Parses `item`'s data as Markdown and renders it directly to HTML,
/// replacing the item's data with the rendered HTML string. Frontmatter,
/// if present, is not separated out by this step (see
/// `render_markdown_and_frontmatter` if frontmatter needs to be
/// preserved/handled).
pub fn[T : Show] render_markdown(item : Item[T]) -> Item[Html] {
  render_markdown_from_ast(item.map(data => data |> @markdown.parse_markdown))
}

///|
/// Renders an already-parsed Markdown AST directly to HTML, replacing
/// `item`'s data with the resulting HTML string.
pub fn render_markdown_from_ast(item : Item[@markdown.Markdown]) -> Item[Html] {
  let { html, toc, } = item.data |> @renderer.render_markdown
  item.set_var("toc", toc_to_template_value(toc)).map(_ => html)
}

///|
/// Splits `item`'s data into its YAML frontmatter and the remaining raw
/// text body, without parsing the body as Markdown (see `extract_markdown`
/// for the equivalent step used when the data is not necessarily `Show`
/// but the resulting body is still expected downstream as Markdown
/// source).
pub fn separate_frontmatter(item : Item[String]) -> Item[(Frontmatter, String)] {
  item.map(data => data |> parse_frontmatter)
}

///|
/// Renders an already-parsed Markdown AST directly to HTML, combining it
/// with the given frontmatter map. This is the AST-based counterpart of
/// `render_markdown_and_frontmatter`, for use when the Markdown has
/// already been parsed (and possibly transformed) rather than starting
/// from raw text.
pub fn render_markdown_and_frontmatter_from_ast(
  item : Item[@markdown.Markdown],
  frontmatter : Map[String, String],
) -> Item[Html] {
  let { html, toc, } = item.data |> @renderer.render_markdown
  item
  .set_var("toc", toc_to_template_value(toc))
  .add_vars(frontmatter.map((_, v) => v |> @template.String))
  .map(_ => html)
}

///|
/// Like `render_markdown`, but first separates YAML frontmatter from the
/// Markdown body (see `separate_frontmatter`) before parsing and
/// rendering, so that frontmatter present in `item`'s data does not get
/// rendered as part of the Markdown body.
pub fn[T : Show] render_markdown_and_frontmatter(item : Item[T]) -> Item[Html] {
  let (frontmatter, content) = item.data.to_string() |> parse_frontmatter
  render_markdown_and_frontmatter_from_ast(
    item.map(_ => content |> @markdown.parse_markdown),
    frontmatter,
  )
}

///|
/// Returns a copy of `item` with its target extension changed to
/// `extension` (including the leading dot, e.g. `.html`), without
/// modifying its data.
pub fn[T] set_extension(item : Item[T], extension : String) -> Item[T] {
  item.base(extension~)
}

///|
/// Renders `item`'s HTML body against the given template AST, replacing
/// `item`'s data with the rendered output.
///
/// Any variables previously attached to `item` via `Item::add_vars` /
/// `Item::set_var` (as well as any variables implicitly set by other
/// template-related steps such as `import_css`/`import_js`/`inject_head`/
/// `inject_body`) are available to the template as its rendering context.
///
/// Rendering errors (e.g. an undefined variable reference, or a failed
/// partial) are tolerated on a per-node basis: the offending template
/// node is simply rendered as empty output, and rendering continues for
/// the rest of the template, rather than the whole render failing. Use
/// `apply_template_strict` if such errors should instead abort rendering
/// entirely.
pub fn apply_template(
  body : Item[Html],
  template : @template.Template,
) -> Item[Html] {
  body.map(_ => {
    template
    |> @template.apply_template(body.set_var("body", body.data |> String).vars)
  })
}

///|
/// Like `apply_template`, but raises a template rendering error (see
/// `@template.TemplateRenderError`) as soon as any node fails to render,
/// instead of tolerating the failure by rendering that node as empty
/// output.
pub fn apply_template_strict(
  body : Item[Html],
  template : @template.Template,
) -> Item[Html] raise {
  body.map_with_raise(_ => {
    template
    |> @template.apply_template_strict(
      body.set_var("body", body.data |> String).vars,
    )
  })
}

///|
/// Loads the template file at `path`, parses it, and applies it to
/// `item`, combining `@template.parse_template` with `apply_template` (or
/// `apply_template_strict` when `strict` is `true`) in one step.
///
/// When `strict` is `false` (the default), rendering errors are tolerated
/// on a per-node basis (the offending node renders as empty output);
/// when `true`, any such error instead raises immediately, aborting the
/// render.
///
/// Raises if the template file cannot be read or cannot be parsed (see
/// `@template.TemplateParseError`) — regardless of `strict` — or, when
/// `strict` is `true`, if rendering itself fails (see
/// `@template.TemplateRenderError`).
pub fn load_and_apply_template(
  body : Item[Html],
  template_path : String,
  strict~ : Bool = false,
) -> Item[Html] raise {
  let template = template_path
    |> @fs.read_file_to_string
    |> @template.parse_template
  if strict {
    apply_template_strict(body, template)
  } else {
    apply_template(body, template)
  }
}

///|
/// Adds `<link>`-style CSS imports (rather than inlined styles) to
/// `item`, referencing external stylesheets by path/URL rather than
/// embedding their contents — as opposed to `use_css`, which injects raw
/// CSS code directly.
pub fn import_css(item : Item[Html], urls : Array[String]) -> Item[Html] {
  let mut item = item
  for url in urls {
    item = item.map(data => {
      data |> inject_into_head("<link rel=\"stylesheet\" href=\"\{url}\">\n")
    })
  }
  item
}

///|
/// Adds `<script src>`-style JS imports (rather than inlined scripts) to
/// `item`, referencing external scripts by path/URL rather than embedding
/// their contents — as opposed to `use_js`, which injects raw JS code
/// directly.
pub fn import_js(item : Item[Html], urls : Array[String]) -> Item[Html] {
  let mut item = item
  for url in urls {
    item = item.map(data => {
      data |> inject_before_body_end("<script src=\"\{url}\"></script>\n")
    })
  }
  item
}

///|
/// Adds `code` entries as inline `<style>` blocks injected just before
/// `</head>`, one `<style>` tag per array element — as opposed to
/// `import_css`, which references external stylesheets via `<link>`.
pub fn use_css(item : Item[Html], codes : Array[String]) -> Item[Html] {
  let mut item = item
  for code in codes {
    item = item.map(data => data |> inject_into_head("<style>\{code}</style>\n"))
  }
  item
}

///|
/// Adds `code` entries as inline `<script>` blocks injected just before
/// `</body>`, one `<script>` tag per array element — as opposed to
/// `import_js`, which references external scripts via `<script src>`.
pub fn use_js(item : Item[Html], codes : Array[String]) -> Item[Html] {
  let mut item = item
  for code in codes {
    item = item.map(data => {
      data |> inject_before_body_end("<script>\{code}</script>\n")
    })
  }
  item
}

///|
/// Appends `html` as a raw HTML snippet to be injected into the rendered
/// page's `<head>`.
pub fn inject_head(item : Item[Html], code : String) -> Item[Html] {
  item.map(data => data |> inject_into_head(code))
}

///|
/// Injects a canonical link (`<link rel="canonical" href="...">`) into
/// `item`'s `<head>`.
pub fn inject_canonical(item : Item[Html], url : String) -> Item[Html] {
  let tag = "<link rel=\"canonical\" href=\"\{escape_html_attr(url)}\">\n"
  item.map(data => data |> inject_into_head(tag))
}

///|
/// Injects Open Graph metadata (`<meta property="og:*">`) into `item`'s `<head>`.
pub fn inject_open_graph(
  item : Item[Html],
  options : OpenGraphOptions,
) -> Item[Html] {
  let b = StringBuilder()
  match options.og_type {
    Some(t) =>
      b.write_string(
        "<meta property=\"og:type\" content=\"\{escape_html_attr(t)}\">\n",
      )
    None => ()
  }
  match options.url {
    Some(u) =>
      b.write_string(
        "<meta property=\"og:url\" content=\"\{escape_html_attr(u)}\">\n",
      )
    None => ()
  }
  match options.title {
    Some(t) =>
      b.write_string(
        "<meta property=\"og:title\" content=\"\{escape_html_attr(t)}\">\n",
      )
    None => ()
  }
  match options.description {
    Some(d) =>
      b.write_string(
        "<meta property=\"og:description\" content=\"\{escape_html_attr(d)}\">\n",
      )
    None => ()
  }
  match options.image {
    Some(i) =>
      b.write_string(
        "<meta property=\"og:image\" content=\"\{escape_html_attr(i)}\">\n",
      )
    None => ()
  }
  match options.site_name {
    Some(s) =>
      b.write_string(
        "<meta property=\"og:site_name\" content=\"\{escape_html_attr(s)}\">\n",
      )
    None => ()
  }
  match options.locale {
    Some(l) =>
      b.write_string(
        "<meta property=\"og:locale\" content=\"\{escape_html_attr(l)}\">\n",
      )
    None => ()
  }
  let tags = b.to_string()
  if tags == "" {
    item
  } else {
    item.map(data => data |> inject_into_head(tags))
  }
}

///|
/// Injects Twitter Card metadata (`<meta name="twitter:*">`) into `item`'s `<head>`.
pub fn inject_twitter_card(
  item : Item[Html],
  options : TwitterCardOptions,
) -> Item[Html] {
  let b = StringBuilder()
  match options.card {
    Some(c) =>
      b.write_string(
        "<meta name=\"twitter:card\" content=\"\{escape_html_attr(c)}\">\n",
      )
    None => ()
  }
  match options.title {
    Some(t) =>
      b.write_string(
        "<meta name=\"twitter:title\" content=\"\{escape_html_attr(t)}\">\n",
      )
    None => ()
  }
  match options.description {
    Some(d) =>
      b.write_string(
        "<meta name=\"twitter:description\" content=\"\{escape_html_attr(d)}\">\n",
      )
    None => ()
  }
  match options.image {
    Some(i) =>
      b.write_string(
        "<meta name=\"twitter:image\" content=\"\{escape_html_attr(i)}\">\n",
      )
    None => ()
  }
  match options.creator {
    Some(c) =>
      b.write_string(
        "<meta name=\"twitter:creator\" content=\"\{escape_html_attr(c)}\">\n",
      )
    None => ()
  }
  let tags = b.to_string()
  if tags == "" {
    item
  } else {
    item.map(data => data |> inject_into_head(tags))
  }
}

///|
/// Injects an RSS/Atom feed auto-discovery link into `item`'s `<head>`.
pub fn inject_feed_discovery(
  item : Item[Html],
  feed_url : String,
  title~ : String = "Feed",
  mime_type~ : String = "application/atom+xml",
) -> Item[Html] {
  let tag = "<link rel=\"alternate\" type=\"\{escape_html_attr(mime_type)}\" title=\"\{escape_html_attr(title)}\" href=\"\{escape_html_attr(feed_url)}\">\n"
  item.map(data => data |> inject_into_head(tag))
}

///|
/// Injects a sitemap auto-discovery link into `item`'s `<head>`.

///|
/// Injects alternate language links (`<link rel="alternate" hreflang="..." href="...">`) into `item`'s `<head>`.
pub fn inject_alternate_languages(
  item : Item[Html],
  alternates : Array[(String, String)],
) -> Item[Html] {
  if alternates.is_empty() {
    item
  } else {
    let b = StringBuilder()
    for alt in alternates {
      let (lang, url) = alt
      b.write_string(
        "<link rel=\"alternate\" hreflang=\"\{escape_html_attr(lang)}\" href=\"\{escape_html_attr(url)}\">\n",
      )
    }
    let tags = b.to_string()
    item.map(data => data |> inject_into_head(tags))
  }
}

///|
pub fn inject_sitemap_discovery(
  item : Item[Html],
  sitemap_url : String,
) -> Item[Html] {
  let tag = "<link rel=\"sitemap\" type=\"application/xml\" title=\"Sitemap\" href=\"\{escape_html_attr(sitemap_url)}\">\n"
  item.map(data => data |> inject_into_head(tag))
}

///|
/// Appends `html` as a raw HTML snippet to be injected at the end of the
/// rendered page's `<body>`.
pub fn inject_body(item : Item[Html], code : String) -> Item[Html] {
  item.map(data => data |> inject_before_body_end(code))
}

///|
/// Converts `item`'s data into a `Thing`, the common output representation
/// used when writing build results to disk (see `Thing::write`).
///
/// This is typically the final step applied to an item before it is
/// handed off as the result of a `Handler::Text` or `Handler::Binary` handler.
pub fn[T : Thingable] unify(item : Item[T]) -> Item[Thing] {
  item.map(x => x.to_thing())
}

///|
/// Runs `item` through a sequence of preprocessing steps in order, each
/// receiving the output of the previous one as its input.
///
/// This is the in-process counterpart to
/// `@bridge.run_markdown_preprocessors`'s external-command pipeline;
/// `preprocessors` here are ordinary MoonBit functions rather than
/// external processes.
///
/// Raises if any step in `preprocessors` raises.
pub fn use_preprocessor(
  item : Item[String],
  handlers : Array[(Item[String]) -> Item[String] raise],
) -> Item[String] raise {
  handlers.fold(init=item, (cur, h) => h(cur))
}

///|
/// Runs `item` through a sequence of AST-transforming steps in order,
/// each receiving the output of the previous one as its input.
///
/// This is the in-process counterpart to
/// `@bridge.run_markdown_transformers`'s external-command pipeline;
/// `transformers` here are ordinary MoonBit functions rather than
/// external processes.
///
/// Raises if any step in `transformers` raises.
pub fn use_transformer(
  item : Item[@markdown.Markdown],
  handlers : Array[(Item[@markdown.Markdown]) -> Item[@markdown.Markdown] raise],
) -> Item[@markdown.Markdown] raise {
  handlers.fold(init=item, (cur, h) => h(cur))
}

///|
/// Counts words and characters in the content, supporting both CJK characters
/// (counted individually) and Western words (whitespace-delimited).
pub fn count_words(content : String) -> Int32 {
  let mut in_tag = false
  let mut in_code_fence = false
  let mut cjk_count = 0
  let mut western_words = 0
  let mut in_word = false

  let len = content.length()
  let mut i = 0
  while i < len {
    let ch = content[i]

    // Handle code fence ```
    if ch == '`' &&
      i + 2 < len &&
      content[i + 1] == '`' &&
      content[i + 2] == '`' {
      in_code_fence = !in_code_fence
      i += 3
      continue
    }
    if in_code_fence {
      i += 1
      continue
    }

    // Handle HTML tag <...>
    if ch == '<' {
      in_tag = true
      i += 1
      continue
    }
    if ch == '>' && in_tag {
      in_tag = false
      i += 1
      continue
    }
    if in_tag {
      i += 1
      continue
    }
    let code = ch.to_int()
    // CJK unified ideographs
    if (code >= 0x4E00 && code <= 0x9FFF) || (code >= 0x3400 && code <= 0x4DBF) {
      cjk_count += 1
      if in_word {
        western_words += 1
        in_word = false
      }
    } else if (ch >= 'a' && ch <= 'z') ||
      (ch >= 'A' && ch <= 'Z') ||
      (ch >= '0' && ch <= '9') {
      in_word = true
    } else if in_word {
      western_words += 1
      in_word = false
    }
    i += 1
  }
  if in_word {
    western_words += 1
  }
  cjk_count + western_words
}

///|
/// Estimates the reading time in minutes for the given content.
pub fn calculate_reading_time(
  content : String,
  words_per_minute~ : Int32 = 300,
) -> Int32 {
  let words = count_words(content)
  let wpm = if words_per_minute <= 0 { 300 } else { words_per_minute }
  if words == 0 {
    0
  } else {
    let mins = (words + wpm - 1) / wpm
    if mins < 1 {
      1
    } else {
      mins
    }
  }
}

///|
/// Appends reading time and word count variables (`$word_count$`, `$reading_time$`)
/// to `item`'s template variables.
pub fn[T : Show] add_reading_time(
  item : Item[T],
  words_per_minute~ : Int32 = 300,
  words_var~ : String = "word_count",
  time_var~ : String = "reading_time",
) -> Item[T] {
  let content = item.data.to_string()
  let words = count_words(content)
  let mins = calculate_reading_time(content, words_per_minute~)
  item
  .set_var(words_var, @template.Value::Number(words.to_double()))
  .set_var(words_var + "_str", @template.Value::String(words.to_string()))
  .set_var(time_var, @template.Value::Number(mins.to_double()))
  .set_var(time_var + "_str", @template.Value::String(mins.to_string()))
}

///|
/// Helper to strip basic Markdown syntax and HTML tags from a string.
fn strip_markdown_formatting(s : String) -> String {
  let b = StringBuilder()
  let mut in_tag = false
  for ch in s {
    if ch == '<' {
      in_tag = true
      continue
    }
    if ch == '>' && in_tag {
      in_tag = false
      continue
    }
    if in_tag {
      continue
    }
    if ch == '*' || ch == '_' || ch == '`' || ch == '#' {
      continue
    }
    b.write_char(ch)
  }
  b.to_string().trim().to_owned()
}

///|
/// Extracts an excerpt string from content.
pub fn extract_excerpt(
  content : String,
  max_length~ : Int32 = 200,
  separator~ : String = "<!--more-->",
) -> String {
  let sep_idx = match content.find(separator) {
    Some(idx) => Some(idx)
    None =>
      if separator == "<!--more-->" {
        content.find("<!-- more -->")
      } else {
        None
      }
  }
  match sep_idx {
    Some(idx) => {
      let raw_excerpt = Show::to_string(content[0:idx])
      let lines = raw_excerpt
        .replace_all(old="\r\n", new="\n")
        .split("\n")
        .to_array()
      let p_lines : Array[String] = []
      let mut in_fm = false
      for i, line in lines {
        let trimmed = line.trim().to_owned()
        if i == 0 && trimmed == "---" {
          in_fm = true
          continue
        }
        if in_fm {
          if trimmed == "---" {
            in_fm = false
          }
          continue
        }
        if trimmed == "" || trimmed.has_prefix("#") {
          continue
        }
        p_lines.push(trimmed)
      }
      let combined = p_lines.join(" ")
      let stripped = strip_markdown_formatting(combined)
      if stripped.length() <= max_length {
        stripped
      } else {
        Show::to_string(stripped[0:max_length]) + "..."
      }
    }
    None => {
      let lines = content
        .replace_all(old="\r\n", new="\n")
        .split("\n")
        .to_array()
      let p_lines : Array[String] = []
      let mut found_paragraph = false
      let mut in_fm = false
      for idx, line in lines {
        let trimmed = line.trim().to_owned()
        if idx == 0 && trimmed == "---" {
          in_fm = true
          continue
        }
        if in_fm {
          if trimmed == "---" {
            in_fm = false
          }
          continue
        }
        if !found_paragraph {
          if trimmed == "" ||
            trimmed.has_prefix("#") ||
            trimmed.has_prefix("```") {
            continue
          }
          found_paragraph = true
          p_lines.push(trimmed)
        } else {
          if trimmed == "" {
            break
          }
          p_lines.push(trimmed)
        }
      }
      let combined = p_lines.join(" ")
      let stripped = strip_markdown_formatting(combined)
      if stripped.length() <= max_length {
        stripped
      } else {
        Show::to_string(stripped[0:max_length]) + "..."
      }
    }
  }
}

///|
/// Extracts an excerpt and attaches it as a template variable `$excerpt$`.
pub fn[T : Show] add_excerpt(
  item : Item[T],
  separator~ : String = "<!--more-->",
  max_length~ : Int32 = 200,
  var_name~ : String = "excerpt",
) -> Item[T] {
  match item.vars.get(var_name) {
    Some(_) => item
    None => {
      let content = item.data.to_string()
      let excerpt = extract_excerpt(content, max_length~, separator~)
      item.set_var(var_name, @template.Value::String(excerpt))
    }
  }
}

///|
/// Converts an Item into a PaginatedItem for archive and list rendering.
pub fn[T] Item::to_paginated_item(
  self : Item[T],
  url~ : String? = None,
) -> PaginatedItem {
  let title = match self.vars.get("title") {
    Some(@template.Value::String(t)) => t
    _ => self.target
  }
  let date = match self.vars.get("date") {
    Some(@template.Value::String(d)) => Some(d)
    _ => None
  }
  let description = match self.vars.get("description") {
    Some(@template.Value::String(d)) => Some(d)
    _ => None
  }
  let excerpt = match self.vars.get("excerpt") {
    Some(@template.Value::String(e)) => Some(e)
    _ => None
  }
  {
    title,
    url: url.unwrap_or(self.location()),
    date,
    description,
    excerpt,
    vars: self.vars,
  }
}

///|
/// Renders an array of items into paginated HTML pages wrapped in `Thing::Multiple`.
pub fn paginate(
  items : Array[PaginatedItem],
  config : PaginationConfig,
) -> Thing raise {
  let template = config.template_path
    |> @fs.read_file_to_string
    |> @template.parse_template
  let page_size = if config.page_size <= 0 { 10 } else { config.page_size }
  let total_items = items.length()
  let total_pages = if total_items == 0 {
    1
  } else {
    (total_items + page_size - 1) / page_size
  }
  let base = if config.base_path == "" || config.base_path == "." {
    ""
  } else if config.base_path.has_suffix("/") {
    Show::to_string(config.base_path[0:config.base_path.length() - 1])
  } else {
    config.base_path
  }
  let outputs : Array[(String, Thing)] = []
  for page_num = 1; page_num <= total_pages; page_num = page_num + 1 {
    let start_idx = (page_num - 1) * page_size
    let end_idx = if start_idx + page_size > total_items {
      total_items
    } else {
      start_idx + page_size
    }
    let page_slice : Array[PaginatedItem] = []
    for i = start_idx; i < end_idx; i = i + 1 {
      page_slice.push(items[i])
    }
    let out_path = if page_num == 1 {
      if base == "" {
        "index.html"
      } else {
        base + "/index.html"
      }
    } else if base == "" {
      "page-\{page_num}.html"
    } else {
      base + "/page-\{page_num}.html"
    }
    let prev_url = if page_num == 1 {
      ""
    } else if page_num == 2 {
      if base == "" {
        "/index.html"
      } else {
        "/" + base + "/index.html"
      }
    } else if base == "" {
      "/page-\{page_num - 1}.html"
    } else {
      "/" + base + "/page-\{page_num - 1}.html"
    }
    let next_url = if page_num < total_pages {
      if base == "" {
        "/page-\{page_num + 1}.html"
      } else {
        "/" + base + "/page-\{page_num + 1}.html"
      }
    } else {
      ""
    }
    let ctx : Map[String, @template.Value] = Map([
      ("page_number", @template.Value::Number(page_num.to_double())),
      ("total_pages", @template.Value::Number(total_pages.to_double())),
      ("total_items", @template.Value::Number(total_items.to_double())),
      ("has_prev", @template.Value::Bool(page_num > 1)),
      ("has_next", @template.Value::Bool(page_num < total_pages)),
      ("prev_url", @template.Value::String(prev_url)),
      ("next_url", @template.Value::String(next_url)),
      (
        "items",
        @template.Value::Array(page_slice.map(it => it.to_template_value())),
      ),
      (
        "posts",
        @template.Value::Array(page_slice.map(it => it.to_template_value())),
      ),
    ])
    let rendered = template |> @template.apply_template(ctx)
    outputs.push((out_path, Thing::Doc(rendered)))
  }
  Thing::Multiple(outputs)
}

///|
/// Generates paginated archive pages from a collection of items.
pub fn generate_pagination(
  items : Array[PaginatedItem],
  page_size~ : Int32 = 10,
  base_path~ : String = "posts",
  template_path~ : String,
) -> Thing raise {
  paginate(items, { page_size, base_path, template_path, })
}

// pub fn minify_css(item : Item[String]) -> Item[String] {
//   ...
// }

// ///|
// pub fn minify_js(item : Item[String]) -> Item[String] {
//   ...
// }

// ///|
// pub fn optimize_image(item : Item[Bytes]) -> Item[Bytes] {
//   ...
// }
