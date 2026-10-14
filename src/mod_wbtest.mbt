///|
fn page_config() -> @config.BookConfig {
  let base = @config.BookConfig::default()
  {
    ..base,
    extensions: { ..base.extensions, template: "src/testdata/template.html", },
  }
}

///|
fn empty_summary() -> @summary.Summary {
  {
    title: "S",
    prefix_chapters: [],
    numbered_chapters: [],
    suffix_chapters: [],
  }
}

///|
async test "process_markdown_page: renders markdown through template" {
  let raw = @core.Item::new(
    "---\ntitle: Hello\n---\n# Hi\n\nBody text.", "page.md",
  )
  let result = process_markdown_page(raw, page_config(), empty_summary())
  guard result.data is @core.Doc(html) else { fail("expected Doc") }
  assert_true(html.contains("<h1 id=\"hi\">"))
  assert_true(html.contains("Body text"))
  assert_true(html.contains("<title>Hello</title>"))
  assert_true(result.location().has_suffix(".html"))
}

///|
async test "process_markdown_page: frontmatter title reaches template" {
  let raw = @core.Item::new("---\ntitle: Custom Title\n---\nbody", "page.md")
  let result = process_markdown_page(raw, page_config(), empty_summary())
  guard result.data is @core.Doc(html) else { fail("expected Doc") }
  assert_true(html.contains("<title>Custom Title</title>"))
}

///|
async test "process_markdown_page: site title fallback when no frontmatter" {
  let raw = @core.Item::new("body only", "page.md")
  let result = process_markdown_page(raw, page_config(), empty_summary())
  guard result.data is @core.Doc(html) else { fail("expected Doc") }
  assert_true(html.contains("<title>MoPress Doc</title>"))
}
