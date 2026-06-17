///|
test "parse headings paragraphs and inline emphasis" {
  let source =
    #|# Title
    #|
    #|Hello **MoonBit** and *books*.
    #|
  let doc = parse_markdown(source)
  assert_eq(doc.length(), 2)
  guard doc[0] is Heading(1, [Text("Title")]) else {
    fail("expected level-1 heading")
  }
  guard doc[1]
    is Paragraph(
      [
        Text("Hello "),
        Strong([Text("MoonBit")]),
        Text(" and "),
        Emphasis([Text("books")]),
        Text("."),
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
  let doc = parse_markdown(source)
  assert_eq(doc.length(), 1)
  guard doc[0] is CodeBlock(Some("moonbit"), content) else {
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
  let doc = parse_markdown(source)
  assert_eq(doc.length(), 1)
  guard doc[0]
    is Paragraph(
      [
        Text("See "),
        Link([Text("docs")], "guide.md"),
        SoftBreak,
        Text("and "),
        Image("logo", "logo.png"),
        Text(" "),
        Html("<x-demo enabled>"),
        Html("</x-demo>"),
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
  let doc = parse_markdown(source)
  assert_eq(doc.length(), 3)
  guard doc[0]
    is BlockQuote([Paragraph([Text("Quote"), SoftBreak, Text("continued")])]) else {
    fail("expected block quote")
  }
  guard doc[1] is List({ ordered: false, items, .. }) else {
    fail("expected unordered list")
  }
  assert_eq(items.length(), 2)
  assert_true(doc[2] is ThematicBreak)
}
