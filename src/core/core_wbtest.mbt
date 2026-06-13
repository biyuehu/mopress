///|
let options : Options = { src: "test/src", dest: "test/dest" }

///|
let rules : Rules = [
  Glob(
    "*.markdown",
    Text(raw => {
      raw
      |> set_extension("html")
      |> render_markdown_and_frontmatter
      |> load_and_apply_template("test/src/templates/default.html")
      |> identify
    }),
  ),
  Glob("images/*", Binary(raw => raw |> identify)),
  Glob("css/*", Copy),
]

///|
test {
  mo_build(options, rules)
}

///|
async test {
  // mo_serve(options, rules)
}
