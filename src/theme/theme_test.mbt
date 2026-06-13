///|
test "default theme files load and parse" {
  let theme = load_default_theme()
  assert_true(@template.parse_template(theme.templates.layout).length() > 0)
  assert_true(@template.parse_template(theme.templates.sidebar).length() > 0)
  assert_true(@template.parse_template(theme.templates.page).length() > 0)
  assert_true(@template.parse_template(theme.templates.toc).length() > 0)
  assert_true(@template.parse_template(theme.templates.pager).length() > 0)
  assert_true(@template.parse_template(theme.templates.script).length() > 0)
  assert_true(
    theme.asset_content("layout.css").unwrap_or("").contains(".doc-root"),
  )
  assert_true(
    theme.asset_content("markdown.css").unwrap_or("").contains(".markdown-body"),
  )
}

///|
test "apply_theme renders default documentation shell" {
  let rendered : @renderer.RenderedMarkdown = {
    html: "<h2 id=\"overview\"><a class=\"heading-anchor\" href=\"#overview\" aria-hidden=\"true\">#</a>Overview</h2>\n<p>Body text.</p>\n",
    toc: [{ level: 2, title: "Overview", anchor: "overview" }],
  }
  let page : PageData = {
    title: "Modes & items",
    page_desc: "A page description",
    page_badge: Some("stable"),
    breadcrumb: ["Core concepts", "Modes & items"],
    sidebar_sections: [
      SidebarSection::new("Getting started", [
        NavItem::new("Introduction", "index.html"),
        NavItem::new("Modes & items", "modes.html").active(),
      ]),
    ],
    prev_title: Some("Rules"),
    prev_url: Some("rules.html"),
    next_title: Some("Output"),
    next_url: Some("output.html"),
  }
  let html = apply_theme(rendered, page, load_default_theme())
  assert_true(html.contains("<!doctype html>"))
  assert_true(html.contains("class=\"nav-item active\""))
  assert_true(html.contains("href=\"#overview\""))
  assert_true(html.contains("class=\"page-nav-btn next\""))
}
