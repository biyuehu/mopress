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
