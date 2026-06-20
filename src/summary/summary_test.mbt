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
    Paragraph([Link([Text("Preface")], "preface.md")]),
    ThematicBreak,
    Heading(1, [Text("Part One")]),
    List({
      ordered: false,
      start: None,
      items: [
        [
          Paragraph([Link([Text("Chapter 1")], "ch1.md")]),
          List({
            ordered: false,
            start: None,
            items: [[Paragraph([Link([Text("Sub 1.1")], "ch1/sub.md")])]],
          }),
        ],
        [Paragraph([Link([Text("Chapter 2")], "")])],
      ],
    }),
    ThematicBreak,
    Paragraph([Link([Text("Appendix")], "appendix.md")]),
  ]

  let summary = parse_summary(doc)

  @debug.assert_eq(summary.title, "Summary")

  @debug.assert_eq(summary.prefix_chapters, [
    Link({ title: "Preface", location: Some("preface.md"), nested_items: [] }),
  ])

  @debug.assert_eq(summary.numbered_chapters.length(), 5)

  @debug.assert_eq(summary.numbered_chapters[1], PartTitle("Part One"))

  match summary.numbered_chapters[2] {
    Link(ch1) => {
      @debug.assert_eq(ch1.title, "Chapter 1")
      @debug.assert_eq(ch1.location, Some("ch1.md"))
      @debug.assert_eq(ch1.nested_items.length(), 1)

      match ch1.nested_items[0] {
        Link(sub) => {
          @debug.assert_eq(sub.title, "Sub 1.1")
          @debug.assert_eq(sub.location, Some("ch1/sub.md"))
          @debug.assert_eq(sub.nested_items.length(), 0)
        }
        _ => panic()
      }
    }
    _ => panic()
  }

  match summary.numbered_chapters[3] {
    Link(ch2) => {
      @debug.assert_eq(ch2.title, "Chapter 2")
      @debug.assert_eq(ch2.location, Some(""))
      @debug.assert_eq(ch2.nested_items.length(), 0)
    }
    _ => panic()
  }

  @debug.assert_eq(summary.numbered_chapters[4], Separator)

  @debug.assert_eq(summary.suffix_chapters, [
    Link({ title: "Appendix", location: Some("appendix.md"), nested_items: [] }),
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
        [Paragraph([Link([Text("Intro")], "intro.md")])],
        [Paragraph([Link([Text("Guide")], "guide.md")])],
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
      @debug.assert_eq(item.location, Some("intro.md"))
      @debug.assert_eq(item.nested_items.length(), 0)
    }
    _ => panic()
  }

  match summary.numbered_chapters[1] {
    Link(item) => {
      @debug.assert_eq(item.title, "Guide")
      @debug.assert_eq(item.location, Some("guide.md"))
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
      items: [[Paragraph([Link([Text("Page")], "page.md")])]],
    }),
  ]

  let summary = parse_summary(doc)
  @debug.assert_eq(summary.title, "Summary")
}
