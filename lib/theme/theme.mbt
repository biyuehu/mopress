///|
pub(all) struct Theme {
  templates : TemplateSet
  assets : Array[ThemeAsset]
} derive(Eq, Debug)

///|
pub(all) struct TemplateSet {
  layout : String
  sidebar : String
  page : String
  toc : String
  pager : String
  script : String
} derive(Eq, Debug)

///|
pub(all) struct ThemeAsset {
  path : String
  content : String
} derive(Eq, Debug)

///|
pub(all) struct PageData {
  title : String
  page_desc : String
  page_badge : String?
  breadcrumb : Array[String]
  sidebar_sections : Array[SidebarSection]
  prev_title : String?
  prev_url : String?
  next_title : String?
  next_url : String?
} derive(Eq, Debug)

///|
pub(all) struct SidebarSection {
  label : String
  items : Array[NavItem]
} derive(Eq, Debug)

///|
pub(all) struct NavItem {
  title : String
  url : String
  active : Bool
  sub : Bool
} derive(Eq, Debug)

///|
let default_templates_dir = "lib/renderer/templates"

///|
let default_assets_dir = "lib/renderer/styles"

///|
pub fn PageData::new(title : String) -> PageData {
  {
    title,
    page_desc: "",
    page_badge: None,
    breadcrumb: [],
    sidebar_sections: [],
    prev_title: None,
    prev_url: None,
    next_title: None,
    next_url: None,
  }
}

///|
pub fn SidebarSection::new(
  label : String,
  items : Array[NavItem],
) -> SidebarSection {
  { label, items }
}

///|
pub fn NavItem::new(title : String, url : String) -> NavItem {
  { title, url, active: false, sub: false }
}

///|
pub fn NavItem::active(self : NavItem) -> NavItem {
  { ..self, active: true }
}

///|
pub fn NavItem::sub(self : NavItem) -> NavItem {
  { ..self, sub: true }
}

///|
pub fn Theme::asset_content(self : Theme, path : String) -> String? {
  for asset in self.assets {
    if asset.path == path {
      return Some(asset.content)
    }
  }
  None
}

///|
pub fn load_default_theme() -> Theme raise {
  load_theme(default_templates_dir, default_assets_dir)
}

///|
pub fn load_theme(templates_dir : String, assets_dir : String) -> Theme raise {
  {
    templates: load_template_set(templates_dir),
    assets: load_theme_assets(assets_dir),
  }
}

///|
pub fn load_template_set(base_dir : String) -> TemplateSet raise {
  {
    layout: read_theme_file(base_dir, "layout.html"),
    sidebar: read_theme_file(base_dir, "sidebar.html"),
    page: read_theme_file(base_dir, "page.html"),
    toc: read_theme_file(base_dir, "toc.html"),
    pager: read_theme_file(base_dir, "pager.html"),
    script: read_theme_file(base_dir, "script.html"),
  }
}

///|
pub fn load_theme_assets(base_dir : String) -> Array[ThemeAsset] raise {
  [
    { path: "layout.css", content: read_theme_file(base_dir, "layout.css") },
    { path: "markdown.css", content: read_theme_file(base_dir, "markdown.css") },
  ]
}

///|
pub fn apply_theme(
  rendered : @renderer.RenderedMarkdown,
  page : PageData,
  theme : Theme,
) -> String raise {
  let context = page_context(page, rendered)
  let sidebar_html = render_template_source(theme.templates.sidebar, context)
  let toc_html = render_template_source(theme.templates.toc, context)
  let pager_html = render_template_source(theme.templates.pager, context)
  let page_context = context.copy()
  page_context["content_html"] = @template.String(rendered.html)
  page_context["pager_html"] = @template.String(pager_html)
  let page_html = render_template_source(theme.templates.page, page_context)
  let layout_context = page_context.copy()
  layout_context["sidebar_html"] = @template.String(sidebar_html)
  layout_context["toc_html"] = @template.String(toc_html)
  layout_context["page_html"] = @template.String(page_html)
  layout_context["script_html"] = @template.String(
    render_template_source(theme.templates.script, context),
  )
  layout_context["layout_css"] = @template.String(
    theme.asset_content("layout.css").unwrap_or(""),
  )
  layout_context["markdown_css"] = @template.String(
    theme.asset_content("markdown.css").unwrap_or(""),
  )
  render_template_source(theme.templates.layout, layout_context)
}

///|
pub fn apply_default_theme(
  rendered : @renderer.RenderedMarkdown,
  page : PageData,
) -> String raise {
  apply_theme(rendered, page, load_default_theme())
}

///|
fn read_theme_file(base_dir : String, name : String) -> String raise {
  @fs.read_file_to_string(join_path(base_dir, name))
}

///|
fn join_path(base_dir : String, name : String) -> String {
  if base_dir.has_suffix("/") || base_dir.has_suffix("\\") {
    base_dir + name
  } else {
    base_dir + "/" + name
  }
}

///|
fn render_template_source(
  source : String,
  context : @template.Context,
) -> String raise {
  let template = @template.parse_template(source)
  @template.apply_template(template, context)
}

///|
fn page_context(
  page : PageData,
  rendered : @renderer.RenderedMarkdown,
) -> @template.Context {
  {
    "title": html_value(page.title),
    "page_desc": html_value(page.page_desc),
    "page_badge": option_html_value(page.page_badge),
    "breadcrumb": breadcrumb_value(page.breadcrumb),
    "sidebar_sections": sidebar_sections_value(page.sidebar_sections),
    "toc_items": toc_items_value(rendered.toc),
    "prev_title": option_html_value(page.prev_title),
    "prev_url": option_attr_value(page.prev_url),
    "next_title": option_html_value(page.next_title),
    "next_url": option_attr_value(page.next_url),
  }
}

///|
fn breadcrumb_value(items : Array[String]) -> @template.Value {
  let values : Array[@template.Value] = []
  for index = 0; index < items.length(); index = index + 1 {
    let is_last = index + 1 == items.length()
    values.push(
      @template.Object({
        "label": html_value(items[index]),
        "class": @template.String(if is_last { "current" } else { "" }),
        "sep": @template.Bool(!is_last),
      }),
    )
  }
  @template.Array(values)
}

///|
fn sidebar_sections_value(sections : Array[SidebarSection]) -> @template.Value {
  let values : Array[@template.Value] = []
  for section in sections {
    values.push(
      @template.Object({
        "label": html_value(section.label),
        "items": nav_items_value(section.items),
      }),
    )
  }
  @template.Array(values)
}

///|
fn nav_items_value(items : Array[NavItem]) -> @template.Value {
  let values : Array[@template.Value] = []
  for item in items {
    values.push(
      @template.Object({
        "title": html_value(item.title),
        "url": @template.String(escape_attr(item.url)),
        "class": @template.String(nav_item_class(item)),
      }),
    )
  }
  @template.Array(values)
}

///|
fn toc_items_value(items : Array[@renderer.TocItem]) -> @template.Value {
  let values : Array[@template.Value] = []
  for item in items {
    values.push(
      @template.Object({
        "title": html_value(item.title),
        "url": @template.String("#" + escape_attr(item.anchor)),
        "class": @template.String(toc_item_class(item.level)),
      }),
    )
  }
  @template.Array(values)
}

///|
fn nav_item_class(item : NavItem) -> String {
  let mut klass = "nav-item"
  if item.active {
    klass = klass + " active"
  }
  if item.sub {
    klass = klass + " sub"
  }
  klass
}

///|
fn toc_item_class(level : Int) -> String {
  if level >= 3 {
    "toc-item sub"
  } else {
    "toc-item"
  }
}

///|
fn option_html_value(value : String?) -> @template.Value {
  match value {
    Some(s) => html_value(s)
    None => @template.String("")
  }
}

///|
fn option_attr_value(value : String?) -> @template.Value {
  match value {
    Some(s) => @template.String(escape_attr(s))
    None => @template.String("")
  }
}

///|
fn html_value(value : String) -> @template.Value {
  @template.String(escape_html(value))
}

///|
fn escape_html(input : String) -> String {
  let out = StringBuilder::new()
  for ch in input {
    match ch {
      '<' => out.write_string("&lt;")
      '>' => out.write_string("&gt;")
      '&' => out.write_string("&amp;")
      '"' => out.write_string("&quot;")
      '\'' => out.write_string("&#39;")
      _ => out.write_char(ch)
    }
  }
  out.to_string()
}

///|
fn escape_attr(input : String) -> String {
  escape_html(input)
}
