///|
pub fn[T : Show] parse_markdown(item : Item[T]) -> Item[@markdown.Markdown] {
  item.bind(data => data |> @markdown.parse_markdown)
}

///|
pub fn[T : Show] to_markdown_doc(item : Item[T]) -> Item[MarkdownDoc] {
  item.bind(data => {
    let (meta, content) = parse_frontmatter(data.to_string())
    MarkdownDoc::new(content, meta)
  })
}

///|
// pub fn render_md(item : Item[MarkdownDoc]) -> Item[Html] {
//   ...
// }

///|
pub fn apply_template(
  content : Item[Html],
  template : @template.Template,
  vars : Vars,
) -> Item[Html] {
  vars["content"] = content.data.html |> String
  let rendered = template |> @template.apply_template(vars)
  content.bind(data => data.extend(rendered))
}

///|
pub fn apply_template_strict(
  content : Item[Html],
  template : @template.Template,
  vars : Vars,
) -> Item[Html] raise {
  vars["content"] = content.data.html |> String
  let rendered = template |> @template.apply_template_strict(vars)
  content.bind(data => data.extend(rendered))
}

///|
pub fn load_and_apply_template(
  content : Item[Html],
  template_path : String,
  vars : Vars,
  strict? : Bool = false,
) -> Item[Html] raise {
  let template = template_path
    |> @fs.read_file_to_string
    |> @template.parse_template
  if strict {
    apply_template_strict(content, template, vars)
  } else {
    apply_template(content, template, vars)
  }
}

///|
pub fn import_css(item : Item[Html], url : String) -> Item[Html] {
  item.bind(data => {
    data.extend(
      data.html |> inject_into_head("<link rel=\"stylesheet\" href=\"\{url}\">"),
    )
  })
}

///|
pub fn import_js(item : Item[Html], url : String) -> Item[Html] {
  item.bind(data => {
    data.extend(inject_before_body_end(data.html, "<script src=\{url}\">"))
  })
}

///|
pub fn use_css(item : Item[Html], code : String) -> Item[Html] {
  item.bind(data => {
    data.extend(inject_into_head(data.html, "<style>\{code}</style>"))
  })
}

///|
pub fn use_js(item : Item[Html], code : String) -> Item[Html] {
  item.bind(data => {
    data.extend(inject_before_body_end(data.html, "<script>\{code}</script>"))
  })
}

///|
pub fn[T : Thingable] identify(item : Item[T]) -> Item[Thing] {
  item.bind(x => x.to_thing())
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
