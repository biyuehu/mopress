///|
pub fn[T : Show] parse_markdown(item : Item[T]) -> Item[@markdown.Markdown] {
  item.map(data => data |> @markdown.parse_markdown)
}

///|
pub fn[T : Show] extract_markdown(
  item : Item[T],
) -> Item[(Frontmatter, String)] {
  item.map(data => data.to_string() |> parse_frontmatter)
}

///|
pub fn[T : Show] render_markdown(item : Item[T]) -> Item[Html] {
  let { html, toc } = item.data
    |> @markdown.parse_markdown
    |> @renderer.render_markdown
  item.map(
    _ => html,
    vars=Map([
      ("body", html |> String),
      (
        "toc",
        toc.map(item => item.to_json() |> @template.Value::from_json) |> Array,
      ),
    ]),
  )
}

///|
pub fn[T : Show] render_markdown_and_frontmatter(item : Item[T]) -> Item[Html] {
  let (frontmatter, content) = item.data.to_string() |> parse_frontmatter
  let { html, toc } = content
    |> @markdown.parse_markdown
    |> @renderer.render_markdown
  item.map(
    _ => html,
    vars=frontmatter
      .map((_, v) => v |> @template.String)
      .merge(
        Map([
          ("body", html |> String),
          (
            "toc",
            toc.map(item => item.to_json() |> @template.Value::from_json)
            |> Array,
          ),
        ]),
      ),
  )
}

///|
pub fn[T] set_extension(item : Item[T], extension : String) -> Item[T] {
  item.extend(extension~)
}

///|
pub fn apply_template(
  body : Item[Html],
  template : @template.Template,
) -> Item[Html] {
  body.map(_ => template |> @template.apply_template(body.vars))
}

///|
pub fn apply_template_strict(
  body : Item[Html],
  template : @template.Template,
) -> Item[Html] raise {
  let rendered = template |> @template.apply_template_strict(body.vars)
  body.map(_ => rendered)
}

///|
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
pub fn import_css(item : Item[Html], url : String) -> Item[Html] {
  item.map(data => {
    data |> inject_into_head("<link rel=\"stylesheet\" href=\"\{url}\">\n")
  })
}

///|
pub fn import_js(item : Item[Html], url : String) -> Item[Html] {
  item.map(data => inject_before_body_end(data, "<script src=\"\{url}\"/>\n"))
}

///|
pub fn use_css(item : Item[Html], code : String) -> Item[Html] {
  item.map(data => inject_into_head(data, "<style>\{code}</style>\n"))
}

///|
pub fn use_js(item : Item[Html], code : String) -> Item[Html] {
  item.map(data => inject_before_body_end(data, "<script>\{code}</script>\n"))
}

///|
pub fn[T : Thingable] identify(item : Item[T]) -> Item[Thing] {
  item.map(x => x.to_thing())
}

///|
pub fn use_preprocessor(
  item : Item[String],
  handlers : Array[(Item[String]) -> Item[String] raise],
) -> Item[String] raise {
  handlers.fold(init=item, (cur, h) => h(cur))
}

///|
pub fn use_transformer(
  item : Item[@markdown.Markdown],
  handlers : Array[(Item[@markdown.Markdown]) -> Item[@markdown.Markdown] raise],
) -> Item[@markdown.Markdown] raise {
  handlers.fold(init=item, (cur, h) => h(cur))
}

///|
// pub fn generate_tocs(item : Item[MarkdownDoc]) -> Item[Tocs] {
//   ...
// }

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
