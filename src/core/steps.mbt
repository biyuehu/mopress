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
  let { html, .. } = item.data |> @renderer.render_markdown
  item.map(_ => html)
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
  let { html, .. } = item.data |> @renderer.render_markdown
  item.map(_ => html, vars=frontmatter.map((_, v) => v |> @template.String))
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
  item.extend(extension~)
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
  strict? : Bool = false,
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
/// handed off as the result of a `Mode::Text` or `Mode::Binary` handler.
pub fn[T : Thingable] identify(item : Item[T]) -> Item[Thing] {
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
