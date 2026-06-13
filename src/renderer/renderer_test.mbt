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
  let rendered = render_markdown(md)
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
  let rendered = render_markdown(md, opt={
    heading_anchor_prefix: "",
    allow_raw_html: false,
  })
  assert_true(rendered.html.contains("&lt;script&gt;alert(1)&lt;/script&gt;"))
}
