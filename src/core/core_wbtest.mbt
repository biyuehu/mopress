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
      |> import_js("./custom.js")
      |> import_css("./custom.css")
      |> use_js("console.log('hi, moonbit! hi, mopress!')")
      |> use_css("some css code")
      |> identify
    }),
  ),
  Glob("images/*", Copy),
  Glob("css/*", Copy),
]

///|
test {
  // mo_build(options, rules)
}

///|
async test {
  // mo_serve(options, rules)
}

///|
test {
  guard @fs.is_file("test/src/SUMMARY.md")
  let json = (@fs.read_file_to_string("test/src/SUMMARY.md")
  |> @markdown.parse_markdown
  |> @summary.parse_summary).to_json()

  debug(json.stringify())
  let section = json |> @template.Value::from_json

  // mo_build(options, [
  //   Glob(
  //     "*.markdown",
  //     Text(raw => {
  //       raw
  //       |> set_extension("html")
  //       |> render_markdown_and_frontmatter
  //       |> x => {
  //         x.map(html => {
  //           html
  //           .set_var("section", section)
  //           .set_var(
  //             "percious",
  //             Object(
  //               Map([
  //                 ("title", String("before")),
  //                 ("location", String("./before.html")),
  //               ]),
  //             ),
  //           )
  //           .set_var(
  //             "next",
  //             Object(
  //               Map([
  //                 ("title", String("after")),
  //                 ("location", String("./after.html")),
  //               ]),
  //             ),
  //           )
  //           .set_var("current", "chapter_1.html" |> String)
  //         })
  //       }
  //       |> load_and_apply_template("test/src/templates/default.html")
  //       |> identify
  //     }),
  //   ),
  //   Glob("images/*", Copy),
  //   Glob("css/*", Copy),
  //   Glob("js/*", Copy),
  // ])
}
