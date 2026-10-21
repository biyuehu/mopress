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

///|
test "docs/index.html: metadata and SEO tags integrity" {
  let content = @fs.read_file_to_string("docs/index.html")
  // 1. Basic meta tags
  assert_true(content.contains("<meta charset=\"UTF-8\">"))
  assert_true(
    content.contains(
      "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">",
    ),
  )
  assert_true(
    content.contains(
      "<title>MoPress — 面向 MoonBit 生态的文档与静态站点生成器</title>",
    ),
  )
  assert_true(content.contains("<meta name=\"description\""))
  assert_true(content.contains("<meta name=\"keywords\""))
  assert_true(
    content.contains("<meta name=\"author\" content=\"Himeno Sena\">"),
  )
  assert_true(
    content.contains("<meta name=\"robots\" content=\"index, follow\">"),
  )
  assert_true(
    content.contains("<meta name=\"theme-color\" content=\"#0b0d12\">"),
  )
  assert_true(content.contains("<meta name=\"color-scheme\" content=\"dark\">"))

  // 2. Open Graph tags
  assert_true(
    content.contains("<meta property=\"og:type\" content=\"website\">"),
  )
  assert_true(
    content.contains(
      "<meta property=\"og:url\" content=\"https://mo.himeno-sena.com/\">",
    ),
  )
  assert_true(content.contains("<meta property=\"og:title\""))
  assert_true(content.contains("<meta property=\"og:description\""))
  assert_true(
    content.contains(
      "<meta property=\"og:image\" content=\"https://himeno-sena.com/favicon.ico\">",
    ),
  )
  assert_true(
    content.contains("<meta property=\"og:site_name\" content=\"MoPress\">"),
  )
  assert_true(
    content.contains("<meta property=\"og:locale\" content=\"zh_CN\">"),
  )

  // 3. Twitter Card tags
  assert_true(
    content.contains("<meta name=\"twitter:card\" content=\"summary\">"),
  )
  assert_true(
    content.contains(
      "<meta name=\"twitter:url\" content=\"https://mo.himeno-sena.com/\">",
    ),
  )
  assert_true(content.contains("<meta name=\"twitter:title\""))
  assert_true(content.contains("<meta name=\"twitter:description\""))
  assert_true(
    content.contains(
      "<meta name=\"twitter:image\" content=\"https://himeno-sena.com/favicon.ico\">",
    ),
  )
  assert_true(
    content.contains("<meta name=\"twitter:creator\" content=\"@HimenoSena\">"),
  )

  // 4. Canonical and icon
  assert_true(
    content.contains(
      "<link rel=\"canonical\" href=\"https://mo.himeno-sena.com/\">",
    ),
  )
  assert_true(
    content.contains(
      "<link rel=\"icon\" href=\"https://himeno-sena.com/favicon.ico\" type=\"image/x-icon\">",
    ),
  )
}

///|
test "sidebar client assets: responsive CSS drawer and mobile sidebar integrity" {
  // 1. Template contains sidebarBackdrop element for mobile drawer
  assert_true(book_templates_default_html.contains("id=\"sidebarBackdrop\""))
  assert_true(
    book_templates_default_html.contains("class=\"sidebar-backdrop\""),
  )

  // 2. CSS contains responsive drawer styles and backdrop
  assert_true(book_styles_index_css.contains("@media (max-width: 768px)"))
  assert_true(book_styles_index_css.contains(".doc-root.nav-open .sidebar"))
  assert_true(book_styles_index_css.contains(".sidebar-backdrop"))
  assert_true(book_styles_index_css.contains("@media (min-width: 769px)"))
  assert_true(
    book_styles_index_css.contains(".doc-root.nav-collapsed .sidebar"),
  )

  // 3. Scripts contain initSidebar without initial DOM mutation (no FOUC / stutter)
  assert_true(book_scripts_main_js.contains("function initSidebar()"))
  assert_true(book_scripts_main_js.contains("sidebarBackdrop"))
  assert_true(book_scripts_main_js.contains("nav-open"))
  assert_true(book_scripts_main_js.contains("nav-collapsed"))
  assert_false(book_scripts_main_js.contains("function initMobileSidebar()"))
}

///|
test "generate_robots_txt: outputs valid robots.txt" {
  // 1. Without sitemap
  let r1 = @summary.generate_robots_txt()
  assert_true(r1.contains("User-agent: *\nAllow: /\n"))
  assert_false(r1.contains("Sitemap:"))

  // 2. With sitemap and disallow
  let r2 = @summary.generate_robots_txt(
    sitemap_url=Some("https://example.com/sitemap.xml"),
    disallow=["/private/"],
  )
  assert_true(r2.contains("Disallow: /private/\n"))
  assert_true(r2.contains("Sitemap: https://example.com/sitemap.xml\n"))
}

///|
async test "process_markdown_page: injects fine-grained SEO tags in Book mode" {
  let base = @config.BookConfig::default()
  let config = {
    ..base,
    title: "My Doc",
    description: "Doc description",
    site_url: Some("https://example.com"),
    logo: "https://example.com/logo.png",
    feed_enabled: true,
    sitemap_enabled: true,
    extensions: { ..base.extensions, template: "src/testdata/template.html", },
  }

  // Case 1: Standard page with auto-derived SEO tags
  let raw1 = @core.Item::new(
    "---\ntitle: Guide\nimage: https://example.com/guide.png\n---\nBody", "guide.md",
  )
  let res1 = process_markdown_page(raw1, config, empty_summary())
  guard res1.data is @core.Doc(html1) else { fail("expected Doc") }
  assert_true(
    html1.contains(
      "<link rel=\"canonical\" href=\"https://example.com/guide.html\">",
    ),
  )
  assert_true(html1.contains("<meta property=\"og:title\" content=\"Guide\">"))
  assert_true(
    html1.contains(
      "<meta property=\"og:image\" content=\"https://example.com/guide.png\">",
    ),
  )
  assert_true(
    html1.contains("<meta property=\"og:site_name\" content=\"My Doc\">"),
  )
  assert_true(
    html1.contains("<meta name=\"twitter:card\" content=\"summary\">"),
  )
  assert_true(
    html1.contains(
      "<link rel=\"alternate\" type=\"application/atom+xml\" title=\"My Doc\" href=\"https://example.com/feed.xml\">",
    ),
  )
  assert_true(
    html1.contains(
      "<link rel=\"sitemap\" type=\"application/xml\" title=\"Sitemap\" href=\"https://example.com/sitemap.xml\">",
    ),
  )

  // Case 2: Frontmatter disables open_graph and twitter_card
  let raw2 = @core.Item::new(
    "---\ntitle: Secret\nopen_graph: false\ntwitter_card: false\n---\nBody", "secret.md",
  )
  let res2 = process_markdown_page(raw2, config, empty_summary())
  guard res2.data is @core.Doc(html2) else { fail("expected Doc") }
  assert_false(html2.contains("<meta property=\"og:"))
  assert_false(html2.contains("<meta name=\"twitter:"))
}

///|
async test "build_book_rules: generates robots.txt when enabled" {
  let base = @config.BookConfig::default()
  let config = {
    ..base,
    src: feed_fixture,
    sitemap_enabled: true,
    site_url: Some("https://example.com"),
    features: { ..base.features, robots_txt_enabled: true, },
  }
  let summary = feed_summary()
  let dummy_404 = @core.Item::new(@core.Doc("404"), "404.html")
  let rules = build_book_rules(config, summary, dummy_404, silent=true)
  guard rules[0] is Glob(_, Text(handler)) else {
    fail("expected summary glob")
  }
  let item = @core.Item::new("SUMMARY", "SUMMARY.md")
  let result = handler(item)
  guard result.data is @core.Multiple(outputs) else {
    fail("expected multiple outputs")
  }
  let mut found_robots = false
  for out in outputs {
    if out.0 == "robots.txt" {
      found_robots = true
      guard out.1 is @core.Doc(content) else {
        fail("expected Doc for robots.txt")
      }
      assert_true(content.contains("User-agent: *\nAllow: /\n"))
      assert_true(
        content.contains("Sitemap: https://example.com/sitemap.xml\n"),
      )
    }
  }
  assert_true(found_robots)
}

///|
test "handle_new scaffold: embedded site assets contain expected content" {
  // site.mbtx should reference the new SEO steps and excerpt/reading_time combinators
  assert_true(site_site_mbtx.contains("add_excerpt"))
  assert_true(site_site_mbtx.contains("add_reading_time"))
  assert_true(site_site_mbtx.contains("inject_open_graph"))
  assert_true(site_site_mbtx.contains("inject_twitter_card"))
  assert_true(site_site_mbtx.contains("load_and_apply_template"))

  // template should use $reading_time$ and $word_count$
  assert_true(site_templates_default_html.contains("reading_time"))
  assert_true(site_templates_default_html.contains("word_count"))

  // default CSS should style .post-meta
  assert_true(site_styles_default_css.contains(".post-meta"))

  // example post should contain the <!--more--> excerpt separator
  assert_true(site_posts_hello_world_md.contains("<!--more-->"))
  assert_true(site_posts_hello_world_md.contains("title:"))

  // index page should exist
  assert_false(site_index_md.is_empty())
}

///|
test "handle_new: supports blog and minimal templates" {
  let tmp_blog = "_build/test_scaffold_blog_unique"
  let tmp_minimal = "_build/test_scaffold_minimal_unique"

  if @fs.path_exists(tmp_blog) {
    // cleanup in case prior run left it
    @fs.remove_dir(tmp_blog) catch {
      _ => ()
    }
  }
  if @fs.path_exists(tmp_minimal) {
    @fs.remove_dir(tmp_minimal) catch {
      _ => ()
    }
  }

  handle_new(tmp_blog, template="blog")
  assert_true(@fs.path_exists(tmp_blog + "/index.md"))
  assert_true(@fs.path_exists(tmp_blog + "/posts/hello-world.md"))
  assert_true(@fs.path_exists(tmp_blog + "/site.mbtx"))

  handle_new(tmp_minimal, template="minimal")
  assert_true(@fs.path_exists(tmp_minimal + "/index.md"))
  assert_true(@fs.path_exists(tmp_minimal + "/contact.md"))
  assert_false(@fs.path_exists(tmp_minimal + "/posts"))

  // clean up
  @fs.remove_dir(tmp_blog) catch {
    _ => ()
  }
  @fs.remove_dir(tmp_minimal) catch {
    _ => ()
  }
}

///|
test "handle_init: supports custom directory" {
  let tmp_book = "_build/test_init_book_unique"
  if @fs.path_exists(tmp_book) {
    @fs.remove_dir(tmp_book) catch {
      _ => ()
    }
  }

  handle_init(target_dir=tmp_book)
  assert_true(@fs.path_exists(tmp_book + "/sena.toml"))
  assert_true(@fs.path_exists(tmp_book + "/SUMMARY.md"))
  assert_true(@fs.path_exists(tmp_book + "/index.md"))
  assert_true(@fs.path_exists(tmp_book + "/templates/default.html"))

  @fs.remove_dir(tmp_book) catch {
    _ => ()
  }
}

///|
async test "process_markdown_page: injects i18n variables and hreflang links when configured" {
  let base = @config.BookConfig::default()
  let config = {
    ..base,
    title: "Multi Doc",
    language: "en",
    languages: ["en", "zh"],
    site_url: Some("https://example.com"),
    extensions: { ..base.extensions, template: "src/testdata/template.html", },
  }

  let raw = @core.Item::new("---\ntitle: Page\n---\nHello", "guide.md")
  let res = process_markdown_page(raw, config, empty_summary())
  guard res.data is @core.Doc(html) else { fail("expected Doc") }

  assert_true(
    html.contains(
      "<link rel=\"alternate\" hreflang=\"en\" href=\"https://example.com/guide.html\">",
    ),
  )
  assert_true(
    html.contains(
      "<link rel=\"alternate\" hreflang=\"zh\" href=\"https://example.com/zh/guide.html\">",
    ),
  )
}
