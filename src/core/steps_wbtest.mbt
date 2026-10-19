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

///|
test "thing: byte_size calculates correct sizes" {
  assert_eq(Thing::Doc("hello").byte_size(), 5)
  assert_eq(Thing::Asset(b"world!").byte_size(), 6)
  assert_eq(Thing::Empty.byte_size(), 0)
  let multi = Thing::Multiple([
    ("a.txt", Thing::Doc("abc")),
    ("b.bin", Thing::Asset(b"1234")),
    ("c.empty", Thing::Empty),
  ])
  assert_eq(multi.byte_size(), 7)
}

///|
test "render_markdown: populates toc variable in Item vars" {
  let md_content = "# Heading One\n\nSome text.\n\n## Sub Heading\n\nMore text.\n\n### Sub Sub\n"
  let item = Item::new(md_content, "page.md")
  let rendered = render_markdown(item)
  guard rendered.vars.get("toc") is Some(Array(toc_list)) else {
    fail("expected toc array in vars")
  }
  assert_eq(toc_list.length(), 3)
  guard toc_list[0] is Object(h1) else { fail("expected Object for h1") }
  assert_eq(h1.get("level"), Some(@template.Value::Number(1.0)))
  assert_eq(h1.get("title"), Some(@template.Value::String("Heading One")))
  assert_eq(h1.get("anchor"), Some(@template.Value::String("heading-one")))

  guard toc_list[1] is Object(h2) else { fail("expected Object for h2") }
  assert_eq(h2.get("level"), Some(@template.Value::Number(2.0)))
  assert_eq(h2.get("title"), Some(@template.Value::String("Sub Heading")))
  assert_eq(h2.get("anchor"), Some(@template.Value::String("sub-heading")))

  guard toc_list[2] is Object(h3) else { fail("expected Object for h3") }
  assert_eq(h3.get("level"), Some(@template.Value::Number(3.0)))
  assert_eq(h3.get("title"), Some(@template.Value::String("Sub Sub")))
  assert_eq(h3.get("anchor"), Some(@template.Value::String("sub-sub")))
}

///|
test "inject_canonical: injects canonical link tag into head" {
  let item = Item::new(
    "<head><title>Test</title></head><body>hi</body>", "test.html",
  )
  let res = inject_canonical(item, "https://example.com/test.html")
  assert_true(
    res.data.contains(
      "<link rel=\"canonical\" href=\"https://example.com/test.html\">",
    ),
  )
}

///|
test "inject_open_graph: injects og tags into head" {
  let item = Item::new("<head></head>", "test.html")
  let res = inject_open_graph(item, {
    title: Some("My Page"),
    description: Some("Description with \"quotes\""),
    url: Some("https://example.com/page"),
    image: Some("https://example.com/logo.png"),
    site_name: Some("My Site"),
    og_type: Some("article"),
    locale: Some("zh_CN"),
  })
  assert_true(
    res.data.contains("<meta property=\"og:title\" content=\"My Page\">"),
  )
  assert_true(
    res.data.contains(
      "<meta property=\"og:description\" content=\"Description with &quot;quotes&quot;\">",
    ),
  )
  assert_true(
    res.data.contains(
      "<meta property=\"og:url\" content=\"https://example.com/page\">",
    ),
  )
  assert_true(
    res.data.contains(
      "<meta property=\"og:image\" content=\"https://example.com/logo.png\">",
    ),
  )
  assert_true(
    res.data.contains("<meta property=\"og:site_name\" content=\"My Site\">"),
  )
  assert_true(
    res.data.contains("<meta property=\"og:type\" content=\"article\">"),
  )
  assert_true(
    res.data.contains("<meta property=\"og:locale\" content=\"zh_CN\">"),
  )
}

///|
test "inject_twitter_card: injects twitter tags into head" {
  let item = Item::new("<head></head>", "test.html")
  let res = inject_twitter_card(item, {
    card: Some("summary_large_image"),
    title: Some("Title"),
    description: Some("Desc"),
    image: Some("https://example.com/img.png"),
    creator: Some("@author"),
  })
  assert_true(
    res.data.contains(
      "<meta name=\"twitter:card\" content=\"summary_large_image\">",
    ),
  )
  assert_true(
    res.data.contains("<meta name=\"twitter:title\" content=\"Title\">"),
  )
  assert_true(
    res.data.contains("<meta name=\"twitter:description\" content=\"Desc\">"),
  )
  assert_true(
    res.data.contains(
      "<meta name=\"twitter:image\" content=\"https://example.com/img.png\">",
    ),
  )
  assert_true(
    res.data.contains("<meta name=\"twitter:creator\" content=\"@author\">"),
  )
}

///|
test "inject_feed_and_sitemap_discovery: injects discovery tags into head" {
  let item = Item::new("<head></head>", "test.html")
  let res = item
    |> inject_feed_discovery("https://example.com/feed.xml", title="My Feed")
    |> inject_sitemap_discovery("https://example.com/sitemap.xml")
  assert_true(
    res.data.contains(
      "<link rel=\"alternate\" type=\"application/atom+xml\" title=\"My Feed\" href=\"https://example.com/feed.xml\">",
    ),
  )
  assert_true(
    res.data.contains(
      "<link rel=\"sitemap\" type=\"application/xml\" title=\"Sitemap\" href=\"https://example.com/sitemap.xml\">",
    ),
  )
}

///|
test "count_words and calculate_reading_time" {
  // English text
  assert_eq(count_words("Hello world this is a test"), 6)
  // Chinese text (each CJK char is 1 word)
  assert_eq(count_words("你好世界，这是一个测试"), 10)
  // Mixed text
  assert_eq(count_words("MoonBit 编程语言 is awesome!"), 7)
  // Ignored code blocks and HTML tags
  assert_eq(count_words("<div>Hello</div> ```fn main() {}``` world"), 2)

  // Reading time
  assert_eq(calculate_reading_time("", words_per_minute=300), 0)
  assert_eq(calculate_reading_time("Short text", words_per_minute=300), 1)
  // 600 words with 300 wpm = 2 mins
  let mut long_text = ""
  for i = 0; i < 600; i = i + 1 {
    long_text = long_text + "字"
  }
  assert_eq(calculate_reading_time(long_text, words_per_minute=300), 2)
}

///|
test "add_reading_time: sets template variables" {
  let item = Item::new("Hello world from MoonBit! 你好世界！", "post.md")
  let result = add_reading_time(item, words_per_minute=300)
  guard result.vars.get("word_count") is Some(Number(count)) else {
    fail("expected word_count number")
  }
  assert_eq(count, 8.0)
  guard result.vars.get("reading_time") is Some(Number(mins)) else {
    fail("expected reading_time number")
  }
  assert_eq(mins, 1.0)
}

///|
test "extract_excerpt and add_excerpt" {
  // 1. Explicit separator <!--more-->
  let content1 = "# Title\n\nIntroductory summary.\n<!--more-->\nDeep content."
  assert_eq(extract_excerpt(content1), "Introductory summary.")

  // 2. Explicit separator with space <!-- more -->
  let content2 = "First part.\n<!-- more -->\nSecond part."
  assert_eq(extract_excerpt(content2), "First part.")

  // 3. Fallback to first non-empty paragraph (skipping frontmatter and H1)
  let content3 =
    #|---
    #|title: Post
    #|---
    #|
    #|# Welcome
    #|
    #|This is the first real paragraph of the article.
    #|
    #|This is the second paragraph.
  assert_eq(
    extract_excerpt(content3),
    "This is the first real paragraph of the article.",
  )

  // 4. Max length truncation
  let long_p = "12345678901234567890"
  assert_eq(extract_excerpt(long_p, max_length=10), "1234567890...")

  // 5. add_excerpt step
  let item = Item::new(content1, "post.md")
  let res_item = add_excerpt(item)
  guard res_item.vars.get("excerpt") is Some(String(ex)) else {
    fail("expected excerpt var")
  }
  assert_eq(ex, "Introductory summary.")
}

///|
test "paginate: splits items into pages and renders templates" {
  // Create dummy archive template
  let tpl_src =
    #|Page: $page_number$/$total_pages$
    #|$for(posts)$
    #|- $item.title$ ($item.url$)
    #|$endfor$
    #|prev: $prev_url$ next: $next_url$
  let template_file = "src/core/testdata/pagination_template.html"
  @fs.write_string_to_file(template_file, tpl_src)

  let items : Array[PaginatedItem] = [
    { ..PaginatedItem::default(), title: "Post 1", url: "/posts/1.html", },
    { ..PaginatedItem::default(), title: "Post 2", url: "/posts/2.html", },
    { ..PaginatedItem::default(), title: "Post 3", url: "/posts/3.html", },
  ]

  let thing = generate_pagination(
    items,
    page_size=2,
    base_path="blog",
    template_path=template_file,
  )
  guard thing is Multiple(pages) else { fail("expected Multiple pages") }
  assert_eq(pages.length(), 2)

  // Page 1: blog/index.html with Post 1 & Post 2
  assert_eq(pages[0].0, "blog/index.html")
  guard pages[0].1 is Doc(p1_html) else { fail("expected Doc") }
  assert_true(p1_html.contains("Page: 1/2"))
  assert_true(p1_html.contains("Post 1 (/posts/1.html)"))
  assert_true(p1_html.contains("Post 2 (/posts/2.html)"))
  assert_false(p1_html.contains("Post 3"))
  assert_true(p1_html.contains("next: /blog/page-2.html"))

  // Page 2: blog/page-2.html with Post 3
  assert_eq(pages[1].0, "blog/page-2.html")
  guard pages[1].1 is Doc(p2_html) else { fail("expected Doc") }
  assert_true(p2_html.contains("Page: 2/2"))
  assert_true(p2_html.contains("Post 3 (/posts/3.html)"))
  assert_true(p2_html.contains("prev: /blog/index.html"))

  // Cleanup
  @fs.remove_file(template_file) catch {
    _ => ()
  }
}
