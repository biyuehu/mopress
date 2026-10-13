///|
test "item: new infers extension from target" {
  let item = Item::new("x", "a/b.md")
  assert_eq(item.extension, ".md")
  assert_eq(item.target, "a/b.md")
}

///|
test "item: new explicit extension overrides inferred one" {
  assert_eq(Item::new("x", "a/b.md", extension=".html").extension, ".html")
}

///|
test "item: new empty extension falls back to inferred one" {
  assert_eq(Item::new("x", "a/b.md", extension="").extension, ".md")
}

///|
test "item: location keeps directory and basename" {
  let item = Item::new("x", "a/b.md")
  assert_eq(item.location(), @path.Path("a").join("b.md").to_string())
}

///|
test "item: set_extension changes location extension only" {
  let item = Item::new("x", "a/b.md") |> set_extension(".html")
  assert_eq(item.data, "x")
  assert_eq(item.target, "a/b.md")
  assert_eq(item.location(), @path.Path("a").join("b.html").to_string())
}

///|
test "item: map keeps target and vars" {
  let item = Item::new("abc", "a.md", vars={ "k": @template.String("v") })
  let mapped = item.map(s => s.length())
  assert_eq(mapped.data, 3)
  assert_eq(mapped.target, "a.md")
  @debug.assert_eq(mapped.vars.get("k"), Some(@template.String("v")))
}

///|
test "item: map can override target" {
  let mapped = Item::new("abc", "a.md").map(s => s, target="b.md")
  assert_eq(mapped.target, "b.md")
}

///|
test "item: base overrides only given fields" {
  let item = Item::new("abc", "a.md").base(target="z.md")
  assert_eq(item.data, "abc")
  assert_eq(item.target, "z.md")
  assert_eq(item.extension, ".md")
}

///|
test "item: set_var add_vars clear_var" {
  let item = Item::new("x", "a.md")
  let item = item.set_var("k", @template.String("v"))
  @debug.assert_eq(item.vars.get("k"), Some(@template.String("v")))
  let item = item.add_vars({
    "k": @template.String("w"),
    "n": @template.Bool(true),
  })
  @debug.assert_eq(item.vars.get("k"), Some(@template.String("w")))
  @debug.assert_eq(item.vars.get("n"), Some(@template.Bool(true)))
  let item = item.clear_var("k")
  @debug.assert_eq(item.vars.get("k"), Some(@template.String("")))
}

///|
test "rule: glob rule check and handler" {
  let rule = Rule::Glob("*.md", Handler::Copy)
  assert_true(rule.check("a.md"))
  assert_false(rule.check("a.txt"))
  assert_false(rule.check("dir/a.md"))
  assert_true(rule.handler() is Copy)
}

///|
test "rule: guard rule requires glob and predicate" {
  let rule = Rule::Guard("*.md", p => p == "a.md", Handler::Copy)
  assert_true(rule.check("a.md"))
  assert_false(rule.check("b.md"))
  assert_false(rule.check("a.txt"))
  assert_true(rule.handler() is Copy)
}

///|
test "options: default and from_config" {
  @debug.assert_eq(Options::default(), { src: "./", dest: "./dest", })
  let config = { ..@config.BookConfig::default(), src: "docs", dest: "out", }
  @debug.assert_eq(Options::from_config(config), { src: "docs", dest: "out", })
}

///|
test "thingable: string and bytes" {
  @debug.assert_eq(Thingable::to_thing("x"), Doc("x"))
  @debug.assert_eq(Thingable::to_thing(b"ab"), Asset(b"ab"))
}

///|
test "unify: converts item data to thing" {
  @debug.assert_eq(unify(Item::new("x", "a.md")).data, Doc("x"))
}

///|
test "extract_markdown: splits frontmatter and body" {
  let item = Item::new("---\ntitle: T\n---\nbody", "a.md")
  let (fm, body) = extract_markdown(item).data
  assert_eq(fm["title"], "T")
  assert_eq(body, "body")
}

///|
test "separate_frontmatter: splits frontmatter and body" {
  let item = Item::new("---\ntitle: T\n---\nbody", "a.md")
  let (fm, body) = separate_frontmatter(item).data
  assert_eq(fm["title"], "T")
  assert_eq(body, "body")
}

///|
test "parse_markdown step: yields ast" {
  let item = parse_markdown(Item::new("# Hi", "a.md"))
  assert_eq(item.data.length(), 1)
  assert_true(item.data[0] is @markdown.Heading(1, _))
}

///|
test "render_markdown step: renders heading" {
  let item = render_markdown(Item::new("# Hi", "a.md"))
  assert_true(item.data.contains("<h1 id=\"hi\">"))
}

///|
test "render_markdown_and_frontmatter: strips frontmatter and sets vars" {
  let item = render_markdown_and_frontmatter(
    Item::new("---\ntitle: T\n---\nbody", "a.md"),
  )
  assert_true(item.data.contains("<p>body</p>"))
  assert_false(item.data.contains("title: T"))
  @debug.assert_eq(item.vars.get("title"), Some(@template.String("T")))
}

///|
test "import_css: injects link before head end" {
  let item = Item::new("<head></head><body></body>", "a.html")
  assert_eq(
    import_css(item, ["a.css"]).data,
    "<head><link rel=\"stylesheet\" href=\"a.css\">\n</head><body></body>",
  )
}

///|
test "import_js: injects script before body end" {
  let item = Item::new("<head></head><body></body>", "a.html")
  assert_eq(
    import_js(item, ["a.js"]).data,
    "<head></head><body><script src=\"a.js\"></script>\n</body>",
  )
}

///|
test "use_css and use_js: inline code injection" {
  let item = Item::new("<head></head><body></body>", "a.html")
  assert_eq(
    use_css(item, ["a{}"]).data,
    "<head><style>a{}</style>\n</head><body></body>",
  )
  assert_eq(
    use_js(item, ["x()"]).data,
    "<head></head><body><script>x()</script>\n</body>",
  )
}

///|
test "import_css: empty list leaves item unchanged" {
  let item = Item::new("<head></head>", "a.html")
  assert_eq(import_css(item, []).data, "<head></head>")
  assert_eq(import_js(item, []).data, "<head></head>")
  assert_eq(use_css(item, []).data, "<head></head>")
  assert_eq(use_js(item, []).data, "<head></head>")
}

///|
test "inject_head and inject_body steps" {
  let item = Item::new("<head></head><body></body>", "a.html")
  assert_eq(inject_head(item, "<m>").data, "<head><m></head><body></body>")
  assert_eq(inject_body(item, "<s>").data, "<head></head><body><s></body>")
}

///|
test "apply_template: substitutes vars and body" {
  let template = @template.parse_template("<h1>$title$</h1>$body$")
  let item = Item::new("<p>x</p>", "a.html", vars={
    "title": @template.String("T"),
  })
  assert_eq(apply_template(item, template).data, "<h1>T</h1><p>x</p>")
}

///|
test "apply_template: tolerates undefined variable" {
  let template = @template.parse_template("a$missing$b")
  assert_eq(apply_template(Item::new("x", "a.html"), template).data, "ab")
}

///|
test "apply_template_strict: raises on undefined variable" {
  let template = @template.parse_template("a$missing$b")
  try apply_template_strict(Item::new("x", "a.html"), template) catch {
    _ => ()
  } noraise {
    _ => fail("expected strict template error")
  }
}

///|
test "load_and_apply_template: raises when file missing" {
  try
    load_and_apply_template(
      Item::new("x", "a.html"),
      "src/core/__missing__.html",
    )
  catch {
    _ => ()
  } noraise {
    _ => fail("expected read error")
  }
}

///|
test "load_and_apply_template: renders partial-free template file" {
  let item = Item::new("x", "a.html", vars={ "title": @template.String("T") })
  let result = load_and_apply_template(
    item, "src/template/testdata/footer.html",
  )
  assert_true(result.data.contains("<footer>T</footer>"))
}

///|
test "use_preprocessor: runs handlers in order" {
  let item = Item::new("s", "a.md")
  let result = use_preprocessor(item, [
    i => i.map(s => s + "a"),
    i => i.map(s => s + "b"),
  ])
  assert_eq(result.data, "sab")
}

///|
test "use_preprocessor: empty handlers is identity" {
  assert_eq(use_preprocessor(Item::new("s", "a.md"), []).data, "s")
}

///|
test "use_preprocessor: propagates raised error" {
  try use_preprocessor(Item::new("s", "a.md"), [_ => fail("boom")]) catch {
    _ => ()
  } noraise {
    _ => fail("expected error")
  }
}

///|
test "use_transformer: empty handlers is identity" {
  let doc : @markdown.Markdown = [@markdown.ThematicBreak]
  assert_eq(use_transformer(Item::new(doc, "a.md"), []).data.length(), 1)
}

///|
async test "handler: text handler uses custom reader" {
  let handler = Handler::Text(item => unify(item))
  let result = handler.run({ src: "docs", dest: "out", }, "docs/a.md", read_string=_ => {
    "hello"
  })
  @debug.assert_eq(result.data, Doc("hello"))
  assert_eq(result.extension, ".md")
}

///|
async test "handler: binary and copy handlers use bytes reader" {
  let binary = Handler::Binary(item => unify(item))
  let r1 = binary.run({ src: "docs", dest: "out", }, "docs/a.bin", read_bytes=_ => {
    b"ab"
  })
  @debug.assert_eq(r1.data, Asset(b"ab"))
  let r2 = Handler::Copy.run({ src: "docs", dest: "out", }, "docs/a.bin", read_bytes=_ => {
    b"cd"
  })
  @debug.assert_eq(r2.data, Asset(b"cd"))
}
