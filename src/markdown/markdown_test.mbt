///|
test "parse headings paragraphs and inline emphasis" {
  let source =
    #|# Title
    #|
    #|Hello **MoonBit** and *books*.
    #|
  let doc = @markdown.parse_markdown(source)
  assert_eq(doc.length(), 2)
  guard doc[0] is @markdown.Heading(1, [@markdown.Text("Title")]) else {
    fail("expected level-1 heading")
  }
  guard doc[1]
    is @markdown.Paragraph(
      [
        @markdown.Text("Hello "),
        @markdown.Strong([@markdown.Text("MoonBit")]),
        @markdown.Text(" and "),
        @markdown.Emphasis([@markdown.Text("books")]),
        @markdown.Text("."),
      ]
    ) else {
    fail("expected paragraph with strong and emphasis")
  }
}

///|
test "parse fenced code and preserve info string" {
  let source =
    #|```moonbit
    #|fn main {
    #|  println("hi")
    #|}
    #|```
    #|
  let doc = @markdown.parse_markdown(source)
  assert_eq(doc.length(), 1)
  guard doc[0] is @markdown.CodeBlock(Some("moonbit"), content) else {
    fail("expected fenced moonbit code block")
  }
  assert_true(content.contains("println"))
}

///|
test "parse links images html and soft breaks" {
  let source =
    #|See [docs](guide.md)
    #|and ![logo](logo.png) <x-demo enabled></x-demo>
    #|
  let doc = @markdown.parse_markdown(source)
  assert_eq(doc.length(), 1)
  guard doc[0]
    is @markdown.Paragraph(
      [
        @markdown.Text("See "),
        @markdown.Link([@markdown.Text("docs")], "guide.md"),
        @markdown.SoftBreak,
        @markdown.Text("and "),
        @markdown.Image("logo", "logo.png"),
        @markdown.Text(" "),
        @markdown.Html("<x-demo enabled>"),
        @markdown.Html("</x-demo>"),
      ]
    ) else {
    fail("expected paragraph with link image html and soft break")
  }
}

///|
test "parse block quotes lists and thematic breaks" {
  let source =
    #|> Quote
    #|> continued
    #|
    #|- one
    #|- two
    #|
    #|---
    #|
  let doc = @markdown.parse_markdown(source)
  assert_eq(doc.length(), 3)
  guard doc[0]
    is @markdown.BlockQuote(
      [
        @markdown.Paragraph(
          [
            @markdown.Text("Quote"),
            @markdown.SoftBreak,
            @markdown.Text("continued"),
          ]
        ),
      ]
    ) else {
    fail("expected block quote")
  }
  guard doc[1] is @markdown.List({ ordered: false, items, .. }) else {
    fail("expected unordered list")
  }
  assert_eq(items.length(), 2)
  assert_true(doc[2] is @markdown.ThematicBreak)
}

///|
test "parse table" {
  let basic = @markdown.parse_markdown(
    (
      #|| A | B |
      #|| - | - |
      #|| 1 | 2 |
      #|| 3 | 4 |
    ),
  )
  @debug.assert_eq(basic, [
    @markdown.Block::Table({
      headers: [[@markdown.Inline::Text("A")], [@markdown.Inline::Text("B")]],
      rows: [
        [[@markdown.Inline::Text("1")], [@markdown.Inline::Text("2")]],
        [[@markdown.Inline::Text("3")], [@markdown.Inline::Text("4")]],
      ],
    }),
  ])

  let inline_content = @markdown.parse_markdown(
    (
      #|| **bold** | `code` |
      #|| -------- | ------ |
      #|| normal   | *em*   |
    ),
  )
  @debug.assert_eq(inline_content, [
    @markdown.Block::Table({
      headers: [
        [@markdown.Inline::Strong([@markdown.Inline::Text("bold")])],
        [@markdown.Inline::Code("code")],
      ],
      rows: [
        [
          [@markdown.Inline::Text("normal")],
          [@markdown.Inline::Emphasis([@markdown.Inline::Text("em")])],
        ],
      ],
    }),
  ])

  let no_body = @markdown.parse_markdown(
    (
      #|| H1 | H2 |
      #||:--:|:--:|
    ),
  )
  @debug.assert_eq(no_body, [
    @markdown.Block::Table({
      headers: [[@markdown.Inline::Text("H1")], [@markdown.Inline::Text("H2")]],
      rows: [],
    }),
  ])
}
