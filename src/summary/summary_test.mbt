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
    Heading(1, [Text("Summary")]),
    Paragraph([Link([Text("Preface")], "preface.html")]),
    ThematicBreak,
    Heading(1, [Text("Part One")]),
    List({
      ordered: false,
      start: None,
      items: [
        [
          Paragraph([Link([Text("Chapter 1")], "ch1.html")]),
          List({
            ordered: false,
            start: None,
            items: [[Paragraph([Link([Text("Sub 1.1")], "ch1/sub.html")])]],
          }),
        ],
        [Paragraph([Link([Text("Chapter 2")], "ch2.html")])],
      ],
    }),
    ThematicBreak,
    Paragraph([Link([Text("Appendix")], "appendix.html")]),
  ]

  let summary = parse_summary(doc)

  @debug.assert_eq(summary.title, "Summary")

  @debug.assert_eq(summary.prefix_chapters, [
    Link({ title: "Preface", location: "preface.html", nested_items: [] }),
    Separator,
  ])

  @debug.assert_eq(summary.numbered_chapters.length(), 4)

  @debug.assert_eq(summary.numbered_chapters[0], PartTitle("Part One"))

  match summary.numbered_chapters[1] {
    Link(ch1) => {
      @debug.assert_eq(ch1.title, "Chapter 1")
      @debug.assert_eq(ch1.location, "ch1.html")
      @debug.assert_eq(ch1.nested_items.length(), 1)

      match ch1.nested_items[0] {
        Link(sub) => {
          @debug.assert_eq(sub.title, "Sub 1.1")
          @debug.assert_eq(sub.location, "ch1/sub.html")
          @debug.assert_eq(sub.nested_items.length(), 0)
        }
        _ => panic()
      }
    }
    _ => panic()
  }

  match summary.numbered_chapters[2] {
    Link(ch2) => {
      @debug.assert_eq(ch2.title, "Chapter 2")
      @debug.assert_eq(ch2.location, "ch2.html")
      @debug.assert_eq(ch2.nested_items.length(), 0)
    }
    _ => panic()
  }

  @debug.assert_eq(summary.numbered_chapters[3], Separator)

  @debug.assert_eq(summary.suffix_chapters, [
    Link({ title: "Appendix", location: "appendix.html", nested_items: [] }),
  ])
}

///|
test "parse summary no parts just flat list" {
  // # Summary
  // - [Intro](intro.md)
  // - [Guide](guide.md)

  let doc : @markdown.Markdown = [
    Heading(1, [Text("Summary")]),
    List({
      ordered: false,
      start: None,
      items: [
        [Paragraph([Link([Text("Intro")], "intro.html")])],
        [Paragraph([Link([Text("Guide")], "guide.html")])],
      ],
    }),
  ]

  let summary = parse_summary(doc)

  @debug.assert_eq(summary.prefix_chapters.length(), 0)
  @debug.assert_eq(summary.suffix_chapters.length(), 0)
  @debug.assert_eq(summary.numbered_chapters.length(), 2)

  match summary.numbered_chapters[0] {
    Link(item) => {
      @debug.assert_eq(item.title, "Intro")
      @debug.assert_eq(item.location, "intro.html")
      @debug.assert_eq(item.nested_items.length(), 0)
    }
    _ => panic()
  }

  match summary.numbered_chapters[1] {
    Link(item) => {
      @debug.assert_eq(item.title, "Guide")
      @debug.assert_eq(item.location, "guide.html")
      @debug.assert_eq(item.nested_items.length(), 0)
    }
    _ => panic()
  }
}

///|
test "parse summary no title fallback" {
  let doc : @markdown.Markdown = [
    List({
      ordered: false,
      start: None,
      items: [[Paragraph([Link([Text("Page")], "page.html")])]],
    }),
  ]

  let summary = parse_summary(doc)
  @debug.assert_eq(summary.title, "Summary")
}

///|
test "breadcrumb" {
  let s : Summary = {
    title: "",
    prefix_chapters: [
      SummaryItem::Link({
        title: "说明",
        location: "./intro.html",
        nested_items: [],
      }),
    ],
    numbered_chapters: [
      SummaryItem::Link({
        title: "指南",
        location: "./guide.html",
        nested_items: [
          SummaryItem::Link({
            title: "命令",
            location: "./cmd.html",
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
  assert_eq(s.breadcrumb("./ghost.html"), "/")
}

///|
test "prev_next" {
  let s : Summary = {
    title: "",
    prefix_chapters: [
      SummaryItem::Link({ title: "A", location: "./a.html", nested_items: [] }),
    ],
    numbered_chapters: [
      SummaryItem::PartTitle("x"),
      SummaryItem::Link({ title: "B", location: "./b.html", nested_items: [] }),
      SummaryItem::Link({ title: "C", location: "./c.html", nested_items: [] }),
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
