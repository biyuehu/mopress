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

///|
test "empty input yields no blocks" {
  assert_eq(@markdown.parse_markdown("").length(), 0)
  assert_eq(@markdown.parse_markdown("\n\n").length(), 0)
}

///|
test "heading levels and closing marker" {
  @debug.assert_eq(@markdown.parse_markdown("## Hi ##"), [
    @markdown.Heading(2, [@markdown.Text("Hi")]),
  ])
  @debug.assert_eq(@markdown.parse_markdown("###### Six"), [
    @markdown.Heading(6, [@markdown.Text("Six")]),
  ])
}

///|
test "seven hashes is not a heading" {
  let doc = @markdown.parse_markdown("####### x")
  assert_true(doc[0] is @markdown.Paragraph(_))
}

///|
test "hash without space is not a heading" {
  let doc = @markdown.parse_markdown("#tag")
  assert_true(doc[0] is @markdown.Paragraph(_))
}

///|
test "thematic break variants" {
  @debug.assert_eq(@markdown.parse_markdown("***"), [@markdown.ThematicBreak])
  @debug.assert_eq(@markdown.parse_markdown("___"), [@markdown.ThematicBreak])
  @debug.assert_eq(@markdown.parse_markdown("- - -"), [@markdown.ThematicBreak])
}

///|
test "tilde fence and unclosed fence" {
  @debug.assert_eq(@markdown.parse_markdown("~~~\ncode\n~~~"), [
    @markdown.CodeBlock(None, "code"),
  ])
  @debug.assert_eq(@markdown.parse_markdown("```\nabc"), [
    @markdown.CodeBlock(None, "abc"),
  ])
}

///|
test "fence preserves blank lines inside" {
  @debug.assert_eq(@markdown.parse_markdown("```rs\na\n\nb\n```"), [
    @markdown.CodeBlock(Some("rs"), "a\n\nb"),
  ])
}

///|
test "ordered list keeps start number" {
  let doc = @markdown.parse_markdown("3. a\n4. b")
  guard doc[0] is @markdown.List({ ordered: true, start: Some(3), items, }) else {
    fail("expected ordered list starting at 3")
  }
  assert_eq(items.length(), 2)
}

///|
test "nested list via indentation" {
  let doc = @markdown.parse_markdown("- a\n  - b\n- c")
  guard doc[0] is @markdown.List({ items, .. }) else { fail("expected list") }
  assert_eq(items.length(), 2)
  assert_eq(items[0].length(), 2)
  assert_true(items[0][1] is @markdown.List(_))
}

///|
test "CRLF input becomes soft break" {
  @debug.assert_eq(@markdown.parse_markdown("a\r\nb"), [
    @markdown.Paragraph([
      @markdown.Text("a"),
      @markdown.SoftBreak,
      @markdown.Text("b"),
    ]),
  ])
}

///|
test "inline code and unmatched delimiters" {
  @debug.assert_eq(@markdown.parse_markdown("a `b` c"), [
    @markdown.Paragraph([
      @markdown.Text("a "),
      @markdown.Code("b"),
      @markdown.Text(" c"),
    ]),
  ])
  @debug.assert_eq(@markdown.parse_markdown("*a"), [
    @markdown.Paragraph([@markdown.Text("*a")]),
  ])
  @debug.assert_eq(@markdown.parse_markdown("`a"), [
    @markdown.Paragraph([@markdown.Text("`a")]),
  ])
}

///|
test "html block" {
  @debug.assert_eq(@markdown.parse_markdown("<div>\nx\n</div>"), [
    @markdown.HtmlBlock("<div>\nx\n</div>"),
  ])
}

///|
test "link with nested emphasis" {
  @debug.assert_eq(@markdown.parse_markdown("[**a**](u.md)"), [
    @markdown.Paragraph([
      @markdown.Link([@markdown.Strong([@markdown.Text("a")])], "u.md"),
    ]),
  ])
}

///|
test "bracket without destination stays text" {
  @debug.assert_eq(@markdown.parse_markdown("[a] b"), [
    @markdown.Paragraph([@markdown.Text("[a] b")]),
  ])
}

///|
test "to_plain for inlines" {
  assert_eq(@markdown.Plainable::to_plain(@markdown.Text("a")), "a")
  assert_eq(
    @markdown.Plainable::to_plain(@markdown.Strong([@markdown.Text("b")])),
    "b",
  )
  assert_eq(@markdown.Plainable::to_plain(@markdown.Code("c")), "c")
  assert_eq(
    @markdown.Plainable::to_plain(@markdown.Link([@markdown.Text("l")], "u.md")),
    "l",
  )
  assert_eq(@markdown.Plainable::to_plain(@markdown.SoftBreak), " ")
  assert_eq(@markdown.Plainable::to_plain(@markdown.HardBreak), "\n")
  assert_eq(@markdown.Plainable::to_plain(@markdown.Html("<b>")), "<b>")
}

///|
test "to_plain for blocks" {
  assert_eq(
    @markdown.Plainable::to_plain(@markdown.Heading(1, [@markdown.Text("T")])),
    "T",
  )
  assert_eq(
    @markdown.Plainable::to_plain(
      @markdown.Paragraph([
        @markdown.Text("a"),
        @markdown.Strong([@markdown.Text("b")]),
      ]),
    ),
    "a b",
  )
  assert_eq(@markdown.Plainable::to_plain(@markdown.ThematicBreak), "")
  assert_eq(@markdown.Plainable::to_plain(@markdown.CodeBlock(None, "x")), "x")
}

///|
test "block json round trip" {
  let block : @markdown.Block = @markdown.Paragraph([
    @markdown.Text("a"),
    @markdown.Emphasis([@markdown.Text("b")]),
  ])
  let back : @markdown.Block = @json.from_json(block.to_json())
  assert_true(back == block)
}
