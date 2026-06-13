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
    Paragraph([Link([Text("Preface")], "preface.md", None)]),
    ThematicBreak,
    Heading(1, [Text("Part One")]),
    List({
      ordered: false,
      start: None,
      items: [
        [
          Paragraph([Link([Text("Chapter 1")], "ch1.md", None)]),
          List({
            ordered: false,
            start: None,
            items: [[Paragraph([Link([Text("Sub 1.1")], "ch1/sub.md", None)])]],
          }),
        ],
        [Paragraph([Link([Text("Chapter 2")], "", None)])],
      ],
    }),
    ThematicBreak,
    Paragraph([Link([Text("Appendix")], "appendix.md", None)]),
  ]

  let summary = parse_summary(doc)

  // title
  @debug.assert_eq(summary.title, [Text("Summary")])

  // prefix
  @debug.assert_eq(summary.prefix_chapters, [
    { title: [Text("Preface")], url: "preface.md" },
  ])

  // parts
  assert_eq(summary.parts.length(), 1)
  @debug.assert_eq(summary.parts[0].title, Some([Text("Part One")]))
  assert_eq(summary.parts[0].items.length(), 2)

  // Chapter 1
  let ch1 = summary.parts[0].items[0]
  @debug.assert_eq(
    ch1.link,
    Some({ title: [Text("Chapter 1")], url: "ch1.md" }),
  )
  assert_eq(ch1.nested.length(), 1)
  @debug.assert_eq(
    ch1.nested[0].link,
    Some({ title: [Text("Sub 1.1")], url: "ch1/sub.md" }),
  )

  // Chapter 2
  let ch2 = summary.parts[0].items[1]
  @debug.assert_eq(ch2.link, Some({ title: [Text("Chapter 2")], url: "" }))
  assert_eq(ch2.nested.length(), 0)

  // suffix
  @debug.assert_eq(summary.suffix_chapters, [
    { title: [Text("Appendix")], url: "appendix.md" },
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
        [Paragraph([Link([Text("Intro")], "intro.md", None)])],
        [Paragraph([Link([Text("Guide")], "guide.md", None)])],
      ],
    }),
  ]

  let summary = parse_summary(doc)
  assert_eq(summary.prefix_chapters.length(), 0)
  assert_eq(summary.suffix_chapters.length(), 0)
  assert_eq(summary.parts.length(), 1)
  @debug.assert_eq(summary.parts[0].title, None)
  assert_eq(summary.parts[0].items.length(), 2)
}

///|
test "parse summary no title fallback" {
  let doc : @markdown.Markdown = [
    List({
      ordered: false,
      start: None,
      items: [[Paragraph([Link([Text("Page")], "page.md", None)])]],
    }),
  ]

  let summary = parse_summary(doc)
  @debug.assert_eq(summary.title, [Text("Summary")])
}
