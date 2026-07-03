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
  render_markdown_from_ast(item.map(data => data |> @markdown.parse_markdown))
}

///|
pub fn render_markdown_from_ast(item : Item[@markdown.Markdown]) -> Item[Html] {
  let { html, .. } = item.data |> @renderer.render_markdown
  item.map(_ => html)
}

///|
pub fn separate_frontmatter(item : Item[String]) -> Item[(Frontmatter, String)] {
  item.map(data => data |> parse_frontmatter)
}

///|
pub fn render_markdown_and_frontmatter_from_ast(
  item : Item[@markdown.Markdown],
  frontmatter : Map[String, String],
) -> Item[Html] {
  let { html, .. } = item.data |> @renderer.render_markdown
  item.map(_ => html, vars=frontmatter.map((_, v) => v |> @template.String))
}

///|
pub fn[T : Show] render_markdown_and_frontmatter(item : Item[T]) -> Item[Html] {
  let (frontmatter, content) = item.data.to_string() |> parse_frontmatter
  render_markdown_and_frontmatter_from_ast(
    item.map(_ => content |> @markdown.parse_markdown),
    frontmatter,
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
  body.map(_ => {
    template
    |> @template.apply_template(body.set_var("body", body.data |> String).vars)
  })
}

///|
pub fn apply_template_strict(
  body : Item[Html],
  template : @template.Template,
) -> Item[Html] raise {
  body.map_with_eff(_ => {
    template
    |> @template.apply_template_strict(
      body.set_var("body", body.data |> String).vars,
    )
  })
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
pub fn use_css(item : Item[Html], codes : Array[String]) -> Item[Html] {
  let mut item = item
  for code in codes {
    item = item.map(data => data |> inject_into_head("<style>\{code}</style>\n"))
  }
  item
}

///|
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
pub fn inject_head(item : Item[Html], code : String) -> Item[Html] {
  item.map(data => data |> inject_into_head(code))
}

///|
pub fn inject_body(item : Item[Html], code : String) -> Item[Html] {
  item.map(data => data |> inject_before_body_end(code))
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
