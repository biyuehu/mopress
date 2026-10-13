///|
test "render_markdown emits escaped content anchors and toc" {
  let source =
    #|## Hello & World
    #|
    #|Use `code` and [docs](guide.html).
    #|
    #|## Hello & World
    #|
  let md = @markdown.parse_markdown(source)
  let rendered = @renderer.render_markdown(md)
  assert_true(rendered.html.contains("id=\"hello-world\""))
  assert_true(rendered.html.contains("id=\"hello-world-2\""))
  assert_true(rendered.html.contains("Hello &amp; World"))
  assert_true(rendered.html.contains("<code>code</code>"))
  assert_eq(rendered.toc.length(), 2)
  assert_eq(rendered.toc[0].anchor, "hello-world")
  assert_eq(rendered.toc[1].anchor, "hello-world-2")
}

///|
test "render_markdown can escape raw html" {
  let source =
    #|<script>alert(1)</script>
    #|
  let md = @markdown.parse_markdown(source)
  let rendered = @renderer.render_markdown(md, opt={
    heading_anchor_prefix: "",
    allow_raw_html: false,
  })
  assert_true(rendered.html.contains("&lt;script&gt;alert(1)&lt;/script&gt;"))
}

///|
fn render(source : String) -> @renderer.RenderedMarkdown {
  @renderer.render_markdown(@markdown.parse_markdown(source))
}

///|
test "paragraph and thematic break" {
  let html = render("hello\n\n---").html
  assert_true(html.contains("<p>hello</p>"))
  assert_true(html.contains("<hr>"))
}

///|
test "heading anchor prefix" {
  let md = @markdown.parse_markdown("# A")
  let rendered = @renderer.render_markdown(md, opt={
    heading_anchor_prefix: "x-",
    allow_raw_html: true,
  })
  assert_true(rendered.html.contains("id=\"x-a\""))
  assert_eq(rendered.toc[0].anchor, "x-a")
}

///|
test "toc entries carry level and title" {
  let rendered = render("## Hello")
  @debug.assert_eq(rendered.toc, [
    { level: 2, title: "Hello", anchor: "hello", },
  ])
}

///|
test "repeated headings get numbered anchors" {
  let rendered = render("# A\n\n# A\n\n# A")
  assert_eq(rendered.toc[0].anchor, "a")
  assert_eq(rendered.toc[1].anchor, "a-2")
  assert_eq(rendered.toc[2].anchor, "a-3")
}

///|
test "heading without slug characters falls back" {
  let rendered = render("# !!!")
  assert_eq(rendered.toc[0].anchor, "section")
}

///|
test "code block language class and escaping" {
  let html = render("```Moonbit\na < b\n```").html
  assert_true(
    html.contains("<pre><code class=\"language-moonbit\">a &lt; b</code></pre>"),
  )
}

///|
test "code block without language" {
  let html = render("```\nx\n```").html
  assert_true(html.contains("<pre><code>x</code></pre>"))
}

///|
test "ordered list start attribute" {
  assert_true(render("3. a\n4. b").html.contains("<ol start=\"3\">"))
  assert_true(render("- a\n- b").html.contains("<ul><li>"))
}

///|
test "external link opens in new tab" {
  let html = render("[x](https://a.com)").html
  assert_true(html.contains("target=\"_blank\""))
  assert_true(html.contains("href=\"https://a.com\""))
  assert_true(html.contains("rel=\"noopener noreferrer\""))
}

///|
test "local link has no target" {
  let html = render("[x](a.md)").html
  assert_true(html.contains("href=\"a.md\""))
  assert_false(html.contains("_blank"))
}

///|
test "image is lazy loaded" {
  let html = render("![alt](a.png)").html
  assert_true(html.contains("<img src=\"a.png\" alt=\"alt\""))
  assert_true(html.contains("loading=\"lazy\""))
}

///|
test "table" {
  let html = render("| A | B |\n| - | - |\n| 1 | 2 |").html
  assert_true(html.contains("<th>A</th>"))
  assert_true(html.contains("<td>2</td>"))
  assert_true(html.contains("<table>"))
}

///|
test "block quote" {
  let html = render("> q").html
  assert_true(html.contains("<blockquote>"))
  assert_true(html.contains("<p>q</p>"))
}

///|
test "raw html allowed by default" {
  assert_true(render("<div>x</div>").html.contains("<div>x</div>"))
}

///|
test "inline html escaped when disallowed" {
  let md = @markdown.parse_markdown("a <b>x</b>")
  let rendered = @renderer.render_markdown(md, opt={
    heading_anchor_prefix: "",
    allow_raw_html: false,
  })
  assert_true(rendered.html.contains("&lt;b&gt;"))
}

///|
test "emphasis and strong" {
  let html = render("*a* **b**").html
  assert_true(html.contains("<em>a</em>"))
  assert_true(html.contains("<strong>b</strong>"))
}

///|
test "text escaping" {
  assert_true(render("a & b \"q\"").html.contains("a &amp; b &quot;q&quot;"))
}

///|
test "default options" {
  @debug.assert_eq(@renderer.RenderOptions::default(), {
    heading_anchor_prefix: "",
    allow_raw_html: true,
  })
}
