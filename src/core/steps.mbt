///|
pub fn[T : Show] parse_markdown(item : Item[T]) -> Item[@markdown.Markdown] {
  item.map(data => data |> @markdown.parse_markdown)
}

// ///|
// pub fn[T : Show] to_markdown_doc(item : Item[T]) -> Item[MarkdownDoc] {
//   item.map(data => {
//     let (meta, content) = parse_frontmatter(data.to_string())
//     MarkdownDoc::new(
//       (content |> Item::new(item.extension) |> parse_markdown).data,
//       meta,
//     )
//   })
// }

// ///|
// pub fn render_markdown_doc(item : Item[MarkdownDoc]) -> Item[Html] {
//   item.map(data => {
//     Html::new(@renderer.render_markdown(data.ast).html, item.data.frontmatter)
//   })
// }

///|
pub fn[T : Show] extract_markdown(
  item : Item[T],
) -> Item[(Frontmatter, String)] {
  item.map(data => data.to_string() |> parse_frontmatter)
}

///|
pub fn[T : Show] render_markdown(item : Item[T]) -> Item[Html] {
  item.map(data => {
    Html::new(
      (data |> @markdown.parse_markdown |> @renderer.render_markdown).html,
      Map([]),
    )
  })
}

///|
pub fn[T : Show] render_markdown_and_frontmatter(item : Item[T]) -> Item[Html] {
  item.map(data => {
    let (frontmatter, content) = data.to_string() |> parse_frontmatter
    Html::new(
      (content |> @markdown.parse_markdown |> @renderer.render_markdown).html,
      frontmatter.map((_, v) => v |> String),
    )
  })
}

///|
pub fn[T] set_extension(item : Item[T], extension : String) -> Item[T] {
  { ..item, extension: if extension.is_empty() { "" } else { "." + extension } }
}

///|
pub fn apply_template(
  body : Item[Html],
  template : @template.Template,
) -> Item[Html] {
  body.map(data => {
    data.extend(
      template
      |> @template.apply_template(
        body.data.set_var("body", body.data.html |> String).vars,
      ),
    )
  })
}

///|
pub fn apply_template_strict(
  body : Item[Html],
  template : @template.Template,
) -> Item[Html] raise {
  let rendered = template
    |> @template.apply_template_strict(
      body.data.set_var("body", body.data.html |> String).vars,
    )
  body.map(data => data.extend(rendered))
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
    data.extend(
      data.html |> inject_into_head("<link rel=\"stylesheet\" href=\"\{url}\">"),
    )
  })
}

///|
pub fn import_js(item : Item[Html], url : String) -> Item[Html] {
  item.map(data => {
    data.extend(inject_before_body_end(data.html, "<script src=\{url}\">"))
  })
}

///|
pub fn use_css(item : Item[Html], code : String) -> Item[Html] {
  item.map(data => {
    data.extend(inject_into_head(data.html, "<style>\{code}</style>"))
  })
}

///|
pub fn use_js(item : Item[Html], code : String) -> Item[Html] {
  item.map(data => {
    data.extend(inject_before_body_end(data.html, "<script>\{code}</script>"))
  })
}

///|
pub fn[T : Thingable] identify(item : Item[T]) -> Item[Thing] {
  item.map(x => x.to_thing())
}

///|
pub fn use_preprocessor(
  item : Item[MarkdownDoc],
  handlers : Array[(Item[MarkdownDoc]) -> Item[MarkdownDoc] raise],
) -> Item[MarkdownDoc] raise {
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
