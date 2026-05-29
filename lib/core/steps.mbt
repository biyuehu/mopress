///|
pub(all) struct Meta {
  data : Map[String, String]
}

///|
pub(all) struct Md {
  ast : @markdown.Markdown
  meta : Meta
}

///|
pub(all) struct Html {
  html : String
  meta : Meta
}

///|
pub type Vars = Map[String, String]

///|
pub fn[T : Show] parse_markdown(item : Item[T]) -> @markdown.Markdown {
  let x = item.data
  @markdown.parse_markdown(x)
}

///|
pub fn to_string(item : Item[Bytes]) -> Item[String] {
  ...
}

///|
// pub fn to_md(item : Item[String]) -> Item[Md] raise ParseError {
//   ...
// }

// ///|
// pub fn bytes_to_md(item : Item[Bytes]) -> Item[Md] raise ParseError {
//   item |> to_string |> to_md
// }

///|
pub fn render_md(item : Item[Md]) -> Item[Html] {
  ...
}

///|
pub fn apply_template(
  template_name : String,
  vars : Vars,
) -> (Item[Html]) -> Item[Html] raise @template.TemplateParseError {
  ...
}

///|
pub fn import_css(url : String) -> (Item[Html]) -> Item[Html] {
  ...
}

///|
pub fn import_js(url : String) -> (Item[Html]) -> Item[Html] {
  ...
}

///|
pub fn use_css(code : String) -> (Item[Html]) -> Item[Html] {
  ...
}

///|
pub fn use_js(code : String) -> (Item[Html]) -> Item[Html] {
  ...
}

///|
pub fn copy_asset(item : Item[Bytes]) -> Item[Output] {
  ...
}

///|
pub fn to_output(item : Item[Html]) -> Item[Output] {
  ...
}

///|
pub fn[T] discard(item : Item[T]) -> Item[Output] {
  ...
}

///|
pub fn use_preprocessor(
  handlers : Array[(Item[Md]) -> Item[Md] raise Error],
) -> (Item[Md]) -> Item[Md] raise Error {
  ...
}

///|
// pub fn generate_tocs(item : Item[Md]) -> Item[Tocs] {
//   ...
// }

///|
pub fn minify_css(item : Item[String]) -> Item[String] {
  ...
}

///|
pub fn minify_js(item : Item[String]) -> Item[String] {
  ...
}

///|
pub fn optimize_image(item : Item[Bytes]) -> Item[Bytes] {
  ...
}
