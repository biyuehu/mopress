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

///|
let feed_fixture : String = "src/testdata/pages"

///|
fn feed_summary() -> @summary.Summary {
  {
    title: "S",
    prefix_chapters: [],
    numbered_chapters: [
      @summary.SummaryItem::Link({
        title: "Intro",
        location: "/intro.html",
        source: "intro.md",
        nested_items: [],
      }),
      @summary.SummaryItem::Link({
        title: "Guide",
        location: "/guide.html",
        source: "guide.md",
        nested_items: [],
      }),
    ],
    suffix_chapters: [],
  }
}

///|
fn feed_config(site_url : String?) -> @config.BookConfig {
  { ..@config.BookConfig::default(), site_url, }
}

///|
test "generate_feed_xml returns empty when site_url unset" {
  let metas = feed_summary().collect_page_meta(feed_fixture)
  assert_eq(
    @summary.generate_feed_xml(feed_config(None), metas, build_time),
    "",
  )
}

///|
test "generate_feed_xml emits Atom structure with entries" {
  let config = { ..feed_config(Some("https://example.com")), feed_limit: 20, }
  let metas = feed_summary().collect_page_meta(feed_fixture)
  let xml = @summary.generate_feed_xml(config, metas, build_time)
  assert_true(xml.contains("<?xml version=\"1.0\" encoding=\"utf-8\"?>"))
  assert_true(xml.contains("xmlns=\"http://www.w3.org/2005/Atom\""))
  assert_true(xml.contains("<title>MoPress Doc</title>"))
  assert_true(xml.contains("<id>https://example.com</id>"))
  assert_true(xml.contains("<title>Intro</title>"))
  assert_true(xml.contains("<id>https://example.com/intro.html</id>"))
  assert_true(xml.contains("<summary>An introduction</summary>"))
  assert_true(xml.contains("<category term=\"intro\"/>"))
  assert_true(xml.contains("<category term=\"welcome\"/>"))
  assert_true(xml.contains("<updated>2026-10-01</updated>"))
}

///|
test "generate_feed_xml respects feed_limit" {
  let config = { ..feed_config(Some("https://example.com")), feed_limit: 1, }
  let metas = feed_summary().collect_page_meta(feed_fixture)
  let xml = @summary.generate_feed_xml(config, metas, build_time)
  assert_true(xml.contains("<title>Intro</title>"))
  assert_false(xml.contains("<title>Guide</title>"))
}

///|
test "generate_sitemap_xml emits urlset with both pages" {
  let metas = feed_summary().collect_page_meta(feed_fixture)
  let xml = @summary.generate_sitemap_xml(
    feed_config(Some("https://example.com")),
    metas,
  )
  assert_true(xml.contains("<?xml version=\"1.0\" encoding=\"UTF-8\"?>"))
  assert_true(xml.contains("http://www.sitemaps.org/schemas/sitemap/0.9"))
  assert_true(xml.contains("<loc>https://example.com/intro.html</loc>"))
  assert_true(xml.contains("<loc>https://example.com/guide.html</loc>"))
  assert_true(xml.contains("<lastmod>2026-10-01</lastmod>"))
}

///|
test "generate_sitemap_xml uses base_url when site_url unset" {
  let metas = feed_summary().collect_page_meta(feed_fixture)
  let base = { ..feed_config(None), base_url: "/docs/", }
  let xml = @summary.generate_sitemap_xml(base, metas)
  assert_true(xml.contains("<loc>/docs/intro.html</loc>"))
}

///|
test "collect_page_meta reads frontmatter fields" {
  let metas = feed_summary().collect_page_meta(feed_fixture)
  assert_eq(metas.length(), 2)
  let intro = metas[0]
  assert_eq(intro.title, "Intro")
  assert_eq(intro.location, "/intro.html")
  assert_eq(intro.description, Some("An introduction"))
  assert_eq(intro.keywords, Some("intro, welcome"))
  assert_eq(intro.authors, Some("Alice, Bob"))
  assert_eq(intro.language, Some("en"))
  assert_eq(intro.date, Some("2026-10-01"))
}

///|
test "collect_page_meta leaves absent fields as None" {
  let metas = feed_summary().collect_page_meta(feed_fixture)
  let guide = metas[1]
  assert_eq(guide.description, None)
  assert_eq(guide.keywords, None)
  assert_eq(guide.authors, None)
  assert_eq(guide.language, None)
  assert_eq(guide.date, None)
}

///|
async test "process_markdown_page: data directory variables injected into template" {
  let base = @config.BookConfig::default()
  let config = {
    ..base,
    extensions: {
      ..base.extensions,
      template: "src/testdata/data_template.html",
      data_dir: "src/data/testdata",
    },
  }
  let raw = @core.Item::new(
    "---\ntitle: Data Page\n---\nPage content", "data_page.md",
  )
  let result = process_markdown_page(raw, config, empty_summary())
  guard result.data is @core.Doc(html) else { fail("expected Doc") }
  assert_true(html.contains("<div class=\"author\">Alice - Author</div>"))
  assert_true(html.contains("<div class=\"author\">Bob - Editor</div>"))
  assert_true(html.contains("<div class=\"tier\">gold</div>"))
  assert_true(html.contains("Page content"))
}

///|
async test "process_markdown_page: priority frontmatter > data > builtin vars" {
  let base = @config.BookConfig::default()
  let config = {
    ..base,
    title: "Default Site Title",
    extensions: {
      ..base.extensions,
      template: "src/testdata/data_priority_template.html",
      data_dir: "src/data/testdata",
    },
  }
  // Case 1: Page provides its own site_title in frontmatter to override builtin site_title
  let raw1 = @core.Item::new(
    "---\nsite_title: Overridden Site Title\n---\nbody", "p1.md",
  )
  let res1 = process_markdown_page(raw1, config, empty_summary())
  guard res1.data is @core.Doc(html1) else { fail("expected Doc") }
  assert_true(html1.contains("title: Overridden Site Title"))

  // Case 2: Page without override uses default site_title
  let raw2 = @core.Item::new("body", "p2.md")
  let res2 = process_markdown_page(raw2, config, empty_summary())
  guard res2.data is @core.Doc(html2) else { fail("expected Doc") }
  assert_true(html2.contains("title: Default Site Title"))
}

///|
test "search client assets: embedded template and scripts integrity" {
  // 1. Verify default book template contains all necessary search dialog elements
  assert_true(book_templates_default_html.contains("id=\"searchOverlay\""))
  assert_true(book_templates_default_html.contains("id=\"searchInput\""))
  assert_true(book_templates_default_html.contains("id=\"searchResults\""))
  assert_true(book_templates_default_html.contains("id=\"searchOpen\""))
  assert_true(book_templates_default_html.contains("id=\"searchClose\""))

  // 2. Verify embedded main.js contains the enhanced search logic
  assert_true(book_scripts_main_js.contains("function initSearch()"))
  assert_true(book_scripts_main_js.contains("highlightMatches"))
  assert_true(book_scripts_main_js.contains("getSnippet"))
  assert_true(book_scripts_main_js.contains("scored.sort"))
  assert_true(book_scripts_main_js.contains("is-active"))
  assert_true(book_scripts_main_js.contains("fetch('/index.json')"))

  // 3. Verify styles contain active and highlight mark styles
  assert_true(book_styles_index_css.contains(".search-result.is-active"))
  assert_true(book_styles_index_css.contains(".search-result mark"))
}

///|
async test "process_markdown_page: exposes toc template variable" {
  let base = @config.BookConfig::default()
  let config = {
    ..base,
    extensions: {
      ..base.extensions,
      template: "src/testdata/toc_template.html",
    },
  }
  let md =
    #|# Introduction
    #|
    #|First section.
    #|
    #|## Background
    #|
    #|Some background info.
    #|
    #|## Architecture Details
    #|
    #|More deep details.
  let raw = @core.Item::new(md, "toc_page.md")
  let result = process_markdown_page(raw, config, empty_summary())
  guard result.data is @core.Doc(html) else { fail("expected Doc") }
  assert_true(
    html.contains(
      "<a class=\"toc-link depth-1\" href=\"#introduction\">Introduction</a>",
    ),
  )
  assert_true(
    html.contains(
      "<a class=\"toc-link depth-2\" href=\"#background\">Background</a>",
    ),
  )
  assert_true(
    html.contains(
      "<a class=\"toc-link depth-2\" href=\"#architecture-details\">Architecture Details</a>",
    ),
  )
  assert_true(html.contains("<h1 id=\"introduction\">"))
}
