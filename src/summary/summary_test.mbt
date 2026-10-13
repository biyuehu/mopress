///|
test "parse simple summary" {
  // # Summary
  // [Preface](preface.md)
  // ---
  // # Part One
  // - [Chapter 1](ch1.md)
  //   - [Sub 1.1](ch1/sub.md)
  // - [Chapter 2]()
  // ---
  // [Appendix](appendix.md)

  let doc : @markdown.Markdown = [
    @markdown.Heading(1, [@markdown.Text("Summary")]),
    @markdown.Paragraph([
      @markdown.Link([@markdown.Text("Preface")], "preface.md"),
    ]),
    @markdown.ThematicBreak,
    @markdown.Heading(1, [@markdown.Text("Part One")]),
    @markdown.List({
      ordered: false,
      start: None,
      items: [
        [
          @markdown.Paragraph([
            @markdown.Link([@markdown.Text("Chapter 1")], "ch1.md"),
          ]),
          @markdown.List({
            ordered: false,
            start: None,
            items: [
              [
                @markdown.Paragraph([
                  @markdown.Link([@markdown.Text("Sub 1.1")], "ch1/sub.md"),
                ]),
              ],
            ],
          }),
        ],
        [
          @markdown.Paragraph([
            @markdown.Link([@markdown.Text("Chapter 2")], "ch2.md"),
          ]),
        ],
      ],
    }),
    @markdown.ThematicBreak,
    @markdown.Paragraph([
      @markdown.Link([@markdown.Text("Appendix")], "appendix.md"),
    ]),
  ]

  let summary = @summary.parse_summary(doc)

  @debug.assert_eq(summary.title, "Summary")

  @debug.assert_eq(summary.prefix_chapters, [
    @summary.SummaryItem::Link({
      title: "Preface",
      location: "/preface.html",
      source: "preface.md",
      nested_items: [],
    }),
    @summary.SummaryItem::Separator,
  ])

  @debug.assert_eq(summary.numbered_chapters.length(), 4)

  @debug.assert_eq(
    summary.numbered_chapters[0],
    @summary.SummaryItem::PartTitle("Part One"),
  )

  match summary.numbered_chapters[1] {
    @summary.SummaryItem::Link(ch1) => {
      @debug.assert_eq(ch1.title, "Chapter 1")
      @debug.assert_eq(ch1.location, "/ch1.html")
      @debug.assert_eq(ch1.nested_items.length(), 1)

      match ch1.nested_items[0] {
        @summary.SummaryItem::Link(sub) => {
          @debug.assert_eq(sub.title, "Sub 1.1")
          @debug.assert_eq(sub.location, "/ch1/sub.html")
          @debug.assert_eq(sub.nested_items.length(), 0)
        }
        _ => panic()
      }
    }
    _ => panic()
  }

  match summary.numbered_chapters[2] {
    @summary.SummaryItem::Link(ch2) => {
      @debug.assert_eq(ch2.title, "Chapter 2")
      @debug.assert_eq(ch2.location, "/ch2.html")
      @debug.assert_eq(ch2.nested_items.length(), 0)
    }
    _ => panic()
  }

  @debug.assert_eq(
    summary.numbered_chapters[3],
    @summary.SummaryItem::Separator,
  )

  @debug.assert_eq(summary.suffix_chapters, [
    @summary.SummaryItem::Link({
      title: "Appendix",
      location: "/appendix.html",
      source: "appendix.md",
      nested_items: [],
    }),
  ])
}

///|
test "parse summary no parts just flat list" {
  // # Summary
  // - [Intro](intro.md)
  // - [Guide](guide.md)

  let doc : @markdown.Markdown = [
    @markdown.Heading(1, [@markdown.Text("Summary")]),
    @markdown.List({
      ordered: false,
      start: None,
      items: [
        [
          @markdown.Paragraph([
            @markdown.Link([@markdown.Text("Intro")], "intro.md"),
          ]),
        ],
        [
          @markdown.Paragraph([
            @markdown.Link([@markdown.Text("Guide")], "guide.md"),
          ]),
        ],
      ],
    }),
  ]

  let summary = @summary.parse_summary(doc)

  @debug.assert_eq(summary.prefix_chapters.length(), 0)
  @debug.assert_eq(summary.suffix_chapters.length(), 0)
  @debug.assert_eq(summary.numbered_chapters.length(), 2)

  match summary.numbered_chapters[0] {
    @summary.SummaryItem::Link(item) => {
      @debug.assert_eq(item.title, "Intro")
      @debug.assert_eq(item.location, "/intro.html")
      @debug.assert_eq(item.nested_items.length(), 0)
    }
    _ => panic()
  }

  match summary.numbered_chapters[1] {
    @summary.SummaryItem::Link(item) => {
      @debug.assert_eq(item.title, "Guide")
      @debug.assert_eq(item.location, "/guide.html")
      @debug.assert_eq(item.nested_items.length(), 0)
    }
    _ => panic()
  }
}

///|
test "parse summary no title fallback" {
  let doc : @markdown.Markdown = [
    @markdown.List({
      ordered: false,
      start: None,
      items: [
        [
          @markdown.Paragraph([
            @markdown.Link([@markdown.Text("Page")], "page.html"),
          ]),
        ],
      ],
    }),
  ]

  let summary = @summary.parse_summary(doc)
  @debug.assert_eq(summary.title, "Summary")
}

///|
test "breadcrumb" {
  let s : @summary.Summary = {
    title: "",
    prefix_chapters: [
      @summary.SummaryItem::Link({
        title: "说明",
        location: "/intro.html",
        source: "./intro.md",
        nested_items: [],
      }),
    ],
    numbered_chapters: [
      @summary.SummaryItem::Link({
        title: "指南",
        location: "/guide.html",
        source: "./guide.md",
        nested_items: [
          @summary.SummaryItem::Link({
            title: "命令",
            location: "/cmd.html",
            source: "./cmd.md",
            nested_items: [],
          }),
        ],
      }),
    ],
    suffix_chapters: [],
  }
  assert_eq(s.breadcrumb("./intro.html"), "/ 说明")
  assert_eq(s.breadcrumb("./guide.html"), "/ 指南")
  assert_eq(s.breadcrumb("./cmd.html"), "/ 指南 / 命令")
  assert_eq(s.breadcrumb("./ghost.html"), "/ ???")
}

///|
test "prev_next" {
  let s : @summary.Summary = {
    title: "",
    prefix_chapters: [
      @summary.SummaryItem::Link({
        title: "A",
        location: "./a.html",
        source: "./a.md",
        nested_items: [],
      }),
    ],
    numbered_chapters: [
      @summary.SummaryItem::PartTitle("x"),
      @summary.SummaryItem::Link({
        title: "B",
        location: "/b.html",
        source: "./b.md",
        nested_items: [],
      }),
      @summary.SummaryItem::Link({
        title: "C",
        location: "/c.html",
        source: "./c.md",
        nested_items: [],
      }),
    ],
    suffix_chapters: [],
  }
  @debug.assert_eq(s.prev_next("./ghost.html"), (None, None))
  let (p, n) = s.prev_next("./b.html")
  match (p, n) {
    (Some((prev, _)), Some((next, _))) => {
      assert_eq(prev, "A")
      assert_eq(next, "C")
    }
    _ => fail("expected prev=A next=C")
  }
}

///|
fn sample_summary() -> @summary.Summary {
  {
    title: "S",
    prefix_chapters: [],
    numbered_chapters: [
      @summary.SummaryItem::Link({
        title: "A",
        location: "/a.html",
        source: "a.md",
        nested_items: [
          @summary.SummaryItem::Link({
            title: "A1",
            location: "/a1.html",
            source: "a1.md",
            nested_items: [],
          }),
        ],
      }),
      @summary.SummaryItem::Link({
        title: "B",
        location: "/b.html",
        source: "b.md",
        nested_items: [],
      }),
    ],
    suffix_chapters: [],
  }
}

///|
test "prev_next at both ends" {
  let s = sample_summary()
  @debug.assert_eq(s.prev_next("/a.html"), (None, Some(("A1", "/a1.html"))))
  @debug.assert_eq(s.prev_next("/b.html"), (Some(("A1", "/a1.html")), None))
}

///|
test "prev_next follows nested order" {
  let s = sample_summary()
  @debug.assert_eq(
    s.prev_next("/a1.html"),
    (Some(("A", "/a.html")), Some(("B", "/b.html"))),
  )
}

///|
test "breadcrumb nested" {
  let s = sample_summary()
  assert_eq(s.breadcrumb("/a1.html"), "/ A / A1")
  assert_eq(s.breadcrumb("./b.md"), "/ B")
}

///|
test "flatten marks numbers and current" {
  let json = sample_summary().flatten("./a.html", "/").stringify()
  assert_true(json.contains("\"title\":\"S\""))
  assert_true(json.contains("\"number\":\"1\""))
  assert_true(json.contains("\"number\":\"1.1\""))
  assert_true(json.contains("\"number\":\"2\""))
  assert_true(json.contains("\"location\":\"/a.html\""))
  assert_true(json.contains("\"is_current\":true"))
}

///|
test "flatten applies base url" {
  let json = sample_summary().flatten("./a.html", "/docs/").stringify()
  assert_true(json.contains("\"location\":\"/docs/a.html\""))
  let json2 = sample_summary().flatten("./a.html", "/docs").stringify()
  assert_true(json2.contains("\"location\":\"/docs/a.html\""))
}

///|
test "flatten includes separator and part title" {
  let s : @summary.Summary = {
    title: "S",
    prefix_chapters: [@summary.SummaryItem::Separator],
    numbered_chapters: [@summary.SummaryItem::PartTitle("P")],
    suffix_chapters: [],
  }
  let json = s.flatten("/x.html", "/").stringify()
  assert_true(json.contains("\"is_separator\":true"))
  assert_true(json.contains("\"is_part_title\":true"))
  assert_true(json.contains("\"title\":\"P\""))
}

///|
test "md_to_plain strips markup" {
  assert_eq(
    @summary.md_to_plain("# Title\n\n**bold** and `code`"),
    "title  bold and code",
  )
  assert_eq(@summary.md_to_plain("[Docs](a.md)"), "docs")
  assert_eq(@summary.md_to_plain("![alt](x.png) hi"), "hi")
  assert_eq(@summary.md_to_plain("a<b>c</b>d"), "acd")
  assert_eq(@summary.md_to_plain("|a|b|"), "a b")
  assert_eq(@summary.md_to_plain(""), "")
}

///|
test "parse_summary ignores items without link" {
  let doc : @markdown.Markdown = [
    @markdown.List({
      ordered: false,
      start: None,
      items: [
        [@markdown.Paragraph([@markdown.Text("plain")])],
        [@markdown.Paragraph([@markdown.Link([@markdown.Text("L")], "l.md")])],
      ],
    }),
  ]
  let summary = @summary.parse_summary(doc)
  assert_eq(summary.numbered_chapters.length(), 1)
}

///|
test "parse_summary normalizes backslash and dot paths" {
  let doc : @markdown.Markdown = [
    @markdown.Paragraph([@markdown.Link([@markdown.Text("P")], "./dir/p.md")]),
  ]
  let summary = @summary.parse_summary(doc)
  guard summary.prefix_chapters[0] is @summary.SummaryItem::Link(link) else {
    fail("expected link")
  }
  assert_eq(link.location, "/dir/p.html")
  assert_eq(link.source, "./dir/p.md")
}
