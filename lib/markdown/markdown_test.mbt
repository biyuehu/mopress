///|
struct MarkdownSource {
  text : String
}

///|
impl Show for MarkdownSource with output(self, logger) {
  logger.write_string(self.text)
}

///|
test "parse headings paragraphs and inline emphasis" {
  let source =
    #|# Title
    #|
    #|Hello **MoonBit** and *books*.
    #|
  let doc = parse_string(source)
  assert_eq(doc.blocks.length(), 2)
  guard doc.blocks[0] is Heading(1, [Text("Title")]) else {
    fail("expected level-1 heading")
  }
  guard doc.blocks[1]
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
  let doc = parse_string(source)
  assert_eq(doc.blocks.length(), 1)
  guard doc.blocks[0] is CodeBlock(Some("moonbit"), content) else {
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
  let doc = parse_string(source)
  assert_eq(doc.blocks.length(), 1)
  guard doc.blocks[0]
    is Paragraph(
      [
        Text("See "),
        Link([Text("docs")], "guide.md", None),
        SoftBreak,
        Text("and "),
        Image("logo", "logo.png", None),
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
  let doc = parse_string(source)
  assert_eq(doc.blocks.length(), 3)
  guard doc.blocks[0]
    is BlockQuote([Paragraph([Text("Quote"), SoftBreak, Text("continued")])]) else {
    fail("expected block quote")
  }
  guard doc.blocks[1] is List({ ordered: false, items, .. }) else {
    fail("expected unordered list")
  }
  assert_eq(items.length(), 2)
  assert_true(doc.blocks[2] is ThematicBreak)
}

///|
test "parse accepts any showable input" {
  let doc = parse(MarkdownSource::{ text: "## From Show" })
  guard doc.blocks[0] is Heading(2, [Text("From Show")]) else {
    fail("expected heading from showable input")
  }
}
