///|
/// A single chapter link in a table of contents.
pub(all) struct SummaryLink {
  title : String
  location : String
  source : String
  /// Nested sub-chapters under this chapter, if any.
  nested_items : Array[SummaryItem]
} derive(Eq, Debug)

///|
pub extend SummaryLink with Eq::{not_equal, equal}

///|
pub extend SummaryLink with @debug.Debug::{to_repr}

///|
/// A single entry in a table of contents.
pub(all) enum SummaryItem {
  /// A link to a chapter.
  Link(SummaryLink)
  /// A part title, grouping subsequent chapters under a heading.
  PartTitle(String)
  /// A visual separator between groups of chapters.
  Separator
} derive(Eq, Debug)

///|
pub extend SummaryItem with Eq::{not_equal, equal}

///|
pub extend SummaryItem with @debug.Debug::{to_repr}

///|
pub(all) struct SummarySectionItem {
  item : SummaryItem
  numbered : Bool
} derive(Eq, Debug)

///|
pub extend SummarySectionItem with Eq::{not_equal, equal}

///|
pub extend SummarySectionItem with @debug.Debug::{to_repr}

///|
/// The parsed structure of a book's table of contents (`SUMMARY.md`),
/// split into an optional prefix section, the main numbered chapters, and
/// an optional suffix section — mirroring the conventional structure of
/// an mdBook-style summary file.
pub(all) struct Summary {
  title : String
  prefix_chapters : Array[SummaryItem]
  numbered_chapters : Array[SummaryItem]
  suffix_chapters : Array[SummaryItem]
  ordered_items : Array[SummarySectionItem]
} derive(Eq, Debug)

///|
pub extend Summary with Eq::{not_equal, equal}

///|
pub extend Summary with @debug.Debug::{to_repr}

///|
/// A single article's indexed content, e.g. for building a client-side
/// search index over the site's pages.
pub(all) struct ArticleIndex {
  title : String
  location : String
  content : String
} derive(Eq, Debug, ToJson)

///|
pub extend ArticleIndex with Eq::{not_equal, equal}

///|
pub extend ArticleIndex with @debug.Debug::{to_repr}

///|
pub extend ArticleIndex with ToJson::{to_json}

///|
fn flatten_items(
  items : Array[SummaryItem],
  depth : Int32,
  current : String,
  base_url : String,
  numbered~ : Bool = false,
  counter~ : Ref[Int32] = Ref(0),
  prefix~ : String = "",
) -> Array[Json] {
  let result : Array[Json] = []
  let mut local_counter = 0
  for item in items {
    match item {
      Separator => result.push({ "is_separator": Json(true) })
      PartTitle(title) => {
        counter.val = 0
        result.push({ "is_part_title": Json(true), "title": Json(title) })
      }
      Link(link) => {
        let number = if depth == 0 {
          counter.val += 1
          prefix + counter.val.to_string()
        } else {
          local_counter += 1
          prefix + local_counter.to_string()
        }
        let location = if base_url.has_suffix("/") {
          base_url[0:base_url.length() - 1] + link.location
        } else {
          base_url + link.location
        }
        if numbered {
          result.push({
            "is_link": Json(true),
            "title": Json(link.title),
            "location": location,
            "source": link.source,
            "depth": Json(depth),
            "is_current": Json(link.location == current),
            "number": Json(number),
          })
        } else {
          result.push({
            "is_link": Json(true),
            "title": Json(link.title),
            "location": location,
            "source": link.source,
            "depth": Json(depth),
            "is_current": Json(link.location == current),
          })
        }
        result.append(
          flatten_items(
            link.nested_items,
            depth + 1,
            current,
            base_url,
            numbered~,
            prefix=number + ".",
          ),
        )
      }
    }
  }
  result
}

///|
fn flatten_ordered_items(
  items : Array[SummarySectionItem],
  current : String,
  base_url : String,
) -> Array[Json] {
  let result : Array[Json] = []
  let counter : Ref[Int32] = Ref(0)
  for sec in items {
    match sec.item {
      Separator => result.push({ "is_separator": Json(true) })
      PartTitle(title) => {
        counter.val = 0
        result.push({ "is_part_title": Json(true), "title": Json(title) })
      }
      Link(link) => {
        let number = if sec.numbered {
          counter.val += 1
          counter.val.to_string()
        } else {
          ""
        }
        let location = if base_url.has_suffix("/") {
          base_url[0:base_url.length() - 1] + link.location
        } else {
          base_url + link.location
        }
        if sec.numbered {
          result.push({
            "is_link": Json(true),
            "title": Json(link.title),
            "location": location,
            "source": link.source,
            "depth": Json(0),
            "is_current": Json(link.location == current),
            "number": Json(number),
          })
        } else {
          result.push({
            "is_link": Json(true),
            "title": Json(link.title),
            "location": location,
            "source": link.source,
            "depth": Json(0),
            "is_current": Json(link.location == current),
          })
        }
        if link.nested_items.length() > 0 {
          result.append(
            flatten_items(
              link.nested_items,
              1,
              current,
              base_url,
              numbered=sec.numbered,
              prefix=if sec.numbered { number + "." } else { "" },
            ),
          )
        }
      }
    }
  }
  result
}

///|
/// Returns a JSON representation of this summary, rooted at `location`,
/// e.g. for use as a template variable describing the current section's
/// navigation structure.
pub fn Summary::flatten(
  self : Summary,
  current : String,
  base_url : String,
) -> Json {
  let current = unify_url(current)
  let prefix_flat = flatten_items(self.prefix_chapters, 0, current, base_url)
  let numbered_flat = flatten_items(
    self.numbered_chapters,
    0,
    current,
    base_url,
    numbered=true,
  )
  let suffix_flat = flatten_items(self.suffix_chapters, 0, current, base_url)
  let chapters_flat = if self.ordered_items.length() > 0 {
    flatten_ordered_items(self.ordered_items, current, base_url)
  } else {
    let flat : Array[Json] = []
    flat.append(prefix_flat)
    flat.append(numbered_flat)
    flat.append(suffix_flat)
    flat
  }

  {
    "title": Json(self.title),
    "chapters": Json::array(chapters_flat),
    "prefix_chapters": Json::array(prefix_flat),
    "numbered_chapters": Json::array(numbered_flat),
    "suffix_chapters": Json::array(suffix_flat),
  }
}

///|
fn parse_summary_item(item : Array[@markdown.Block]) -> SummaryItem? {
  let link : SummaryLink? = extract_item_link(item)
  let nested : Array[SummaryItem] = extract_nested_items(item)

  link.map(link => {
    Link({
      title: link.title,
      location: link.location,
      source: link.source,
      nested_items: nested,
    })
  })
}

///|
fn extract_item_link(item : Array[@markdown.Block]) -> SummaryLink? {
  match item {
    [Paragraph(inlines), ..] =>
      match inlines {
        [Link(title, url), ..] =>
          Some({
            title: @markdown.Plainable::to_plain(title),
            location: unify_url(url),
            source: url,
            nested_items: [],
          })
        _ => None
      }
    _ => None
  }
}

///|
fn extract_nested_items(item : Array[@markdown.Block]) -> Array[SummaryItem] {
  for block in item {
    match block {
      List(lb) => return parse_list_items(lb.items)
      _ => continue
    }
  } nobreak {
    []
  }
}

///|
fn parse_list_items(
  items : Array[Array[@markdown.Block]],
) -> Array[SummaryItem] {
  let result : Array[SummaryItem] = []
  for item in items {
    match parse_summary_item(item) {
      Some(si) => result.push(si)
      None => continue
    }
  }
  result
}

///|
/// Parses a book's `SUMMARY.md` (already parsed into a Markdown AST) into
/// its structured `Summary` representation.
pub fn parse_summary(doc : @markdown.Markdown) -> Summary {
  let title : String = find_title(doc)

  let prefix_chapters : Array[SummaryItem] = []
  let numbered_chapters : Array[SummaryItem] = []
  let suffix_chapters : Array[SummaryItem] = []
  let ordered_items : Array[SummarySectionItem] = []

  let blocks = skip_title(doc)

  let mut phase = 0 // 0=prefix, 1=numbered, 2=suffix
  let pending_headings : Array[String] = []

  fn target() -> Array[SummaryItem] {
    if phase == 0 {
      prefix_chapters
    } else if phase == 1 {
      numbered_chapters
    } else {
      suffix_chapters
    }
  }

  fn flush_headings() -> Unit {
    for h in pending_headings {
      target().push(PartTitle(h))
      ordered_items.push({ item: PartTitle(h), numbered: false, })
    }
    pending_headings.clear()
  }

  for block in blocks {
    match block {
      Heading(_, inlines) =>
        pending_headings.push(@markdown.Plainable::to_plain(inlines))
      ThematicBreak => {
        flush_headings()
        target().push(Separator)
        ordered_items.push({ item: Separator, numbered: false, })
      }
      List(lb) => {
        if phase == 0 {
          phase = 1
        }
        flush_headings()
        for item in parse_list_items(lb.items) {
          numbered_chapters.push(item)
          ordered_items.push({ item, numbered: true, })
        }
      }
      Paragraph(inlines) => {
        flush_headings()
        if phase == 1 {
          phase = 2
        }
        for item in extract_root_link_items(inlines) {
          target().push(item)
          ordered_items.push({ item, numbered: false, })
        }
      }
      _ => ()
    }
  }

  { title, prefix_chapters, numbered_chapters, suffix_chapters, ordered_items, }
}

///|
fn unify_url(url : String) -> String {
  let url = url.replace_all(old="\\", new="/")
  let path = @path.Path(url)
  let basename = Show::to_string(path.basename())
  let result = path
    .dirname()
    .join(
      basename
      .rev_find(".")
      .map(index => Show::to_string(basename[:index]))
      .unwrap_or(basename) +
      ".html",
    )
    |> Show::to_string
    |> s => { s.replace_all(old="\\", new="/") }
  if result[0:2] == "./" {
    "/" + (result[2:] |> Show::to_string)
  } else if result[0:1] == "/" {
    result
  } else {
    "/" + result
  }
}

///|
fn find_title(doc : @markdown.Markdown) -> String {
  for block in doc {
    match block {
      Heading(1, inlines) => return @markdown.Plainable::to_plain(inlines)
      _ => continue
    }
  } nobreak {
    "Summary"
  }
}

///|
fn skip_title(doc : @markdown.Markdown) -> Array[@markdown.Block] {
  let mut found = false
  let result : Array[@markdown.Block] = []

  for block in doc {
    if !found {
      match block {
        Heading(1, _) => {
          found = true
          continue
        }
        _ => result.push(block)
      }
    } else {
      result.push(block)
    }
  }

  result
}

///|
fn extract_root_link_items(
  inlines : Array[@markdown.Inline],
) -> Array[SummaryItem] {
  let result : Array[SummaryItem] = []
  for inline in inlines {
    match inline {
      Link(title, url) =>
        result.push(
          Link({
            title: @markdown.Plainable::to_plain(title),
            location: unify_url(url),
            source: url,
            nested_items: [],
          }),
        )
      _ => continue
    }
  }
  result
}

///|
/// Renders a Markdown string to its plain-text representation (stripping
/// all Markdown/HTML markup), e.g. for use in generating search indexes
/// or previews from summary/article content.
pub fn md_to_plain(input : String) -> String {
  let input = input
    .replace_all(old="\r\n", new="\n")
    .replace_all(old="\r", new="\n")
  let out = StringBuilder()
  let mut i = 0
  while i < input.length() {
    let ch = input[i]
    if ch == '#' {
      while i < input.length() && input[i] == '#' {
        i = i + 1
      }
      while i < input.length() && input[i] == ' ' {
        i = i + 1
      }
    } else if ch == '*' || ch == '_' {
      let marker = ch
      if i + 1 < input.length() && input[i + 1] == marker {
        i = i + 2
      } else {
        i = i + 1
      }
    } else if ch == '`' {
      i = i + 1
    } else if ch == '!' && i + 1 < input.length() && input[i + 1] == '[' {
      i = i + 2
      while i < input.length() && input[i] != ']' {
        i = i + 1
      }
      i = i + 1
      if i < input.length() && input[i] == '(' {
        while i < input.length() && input[i] != ')' {
          i = i + 1
        }
        i = i + 1
      }
    } else if ch == '[' {
      i = i + 1
      while i < input.length() && input[i] != ']' {
        if input[i].to_char() is Some(ch) {
          out.write_char(ch)
        }
        i = i + 1
      }
      i = i + 1
      if i < input.length() && input[i] == '(' {
        while i < input.length() && input[i] != ')' {
          i = i + 1
        }
        i = i + 1
      }
    } else if ch == '<' {
      while i < input.length() && input[i] != '>' {
        i = i + 1
      }
      i = i + 1
    } else if ch == '>' && (i == 0 || input[i - 1] == '\n') {
      i = i + 1
      if i < input.length() && input[i] == ' ' {
        i = i + 1
      }
    } else if ch == '|' {
      out.write_char(' ')
      i = i + 1
    } else {
      if ch.to_char() is Some(ch) {
        out.write_char(ch)
      }
      i = i + 1
    }
  }
  out
  .to_string()
  .replace_all(old="\n", new=" ")
  .replace_all(old="---", new=" ")
  .to_lower()
  .trim()
  .to_owned()
}

///|
/// Builds a search/content index over all articles reachable from this
/// summary, reading each article's source file from `src`.
///
/// Raises if any referenced article's source file cannot be read.
pub fn Summary::index_articles(
  self : Summary,
  src : String,
) -> Array[ArticleIndex] raise {
  let articles : Array[ArticleIndex] = []

  fn collect(items : Array[SummaryItem]) -> Unit raise {
    for item in items {
      match item {
        SummaryItem::Link(link) => {
          let path = @path.Path(src).join(link.source) |> Show::to_string
          articles.push({
            title: link.title,
            location: link.location,
            content: path |> @fs.read_file_to_string |> md_to_plain,
          })
          collect(link.nested_items)
        }
        _ => ()
      }
    }
  }

  collect(
    [..self.prefix_chapters, ..self.numbered_chapters, ..self.suffix_chapters],
  )
  articles
}

///|
/// Returns a breadcrumb string describing the path from the root of the
/// table of contents down to the chapter located at `location`.
pub fn Summary::breadcrumb(self : Summary, current : String) -> String {
  let current = unify_url(current)
  fn find(items : Array[SummaryItem], path : Array[String]) -> Array[String]? {
    for item in items {
      match item {
        SummaryItem::Link(link) => {
          let new_path = path + [link.title]
          if link.location == current {
            return Some(new_path)
          }
          match find(link.nested_items, new_path) {
            Some(p) => return Some(p)
            None => ()
          }
        }
        _ => ()
      }
    }
    None
  }

  let path = match find(self.prefix_chapters, []) {
    Some(p) => p
    None =>
      match find(self.numbered_chapters, []) {
        Some(p) => p
        None =>
          match find(self.suffix_chapters, []) {
            Some(p) => p
            None => return "/ ???"
          }
      }
  }
  "/ " + path.join(" / ")
}

///|
/// Returns the previous and next chapter (as `(title, location)` pairs),
/// relative to the chapter located at `location`, according to this
/// summary's chapter ordering. Either value is `None` if there is no
/// previous/next chapter (e.g. at the start or end of the book).
pub fn Summary::prev_next(
  self : Summary,
  current : String,
) -> ((String, String)?, (String, String)?) {
  let current = unify_url(current)
  let flat : Array[SummaryLink] = []
  fn collect(items : Array[SummaryItem]) -> Unit {
    for item in items {
      match item {
        SummaryItem::Link(link) => {
          flat.push(link)
          collect(link.nested_items)
        }
        _ => ()
      }
    }
  }
  collect(self.prefix_chapters)
  collect(self.numbered_chapters)
  collect(self.suffix_chapters)

  fn to_val(link : SummaryLink) -> (String, String) {
    (link.title, link.location)
  }

  match flat.search_by(link => link.location == current) {
    None => (None, None)
    Some(i) =>
      (
        if i > 0 {
          Some(to_val(flat[i - 1]))
        } else {
          None
        },
        if i < flat.length() - 1 {
          Some(to_val(flat[i + 1]))
        } else {
          None
        },
      )
  }
}

// @block page-meta

///|
/// Per-page metadata collected from a `Summary` plus each source file's
/// frontmatter, used for feed and sitemap generation.
///
/// Every frontmatter field is optional: missing values are either omitted
/// from the generated output or fall back to site-level config. The
/// recognized fields are `description`, `keywords`, `authors`, `language`
/// and `date`; `title` is taken from the summary link's own title.
pub(all) struct PageMeta {
  title : String
  location : String
  description : String?
  keywords : String?
  authors : String?
  language : String?
  date : String?
} derive(Eq, Debug)

///|
pub extend PageMeta with Eq::{not_equal, equal}

///|
pub extend PageMeta with @debug.Debug::{to_repr}
// @end

///|
/// Collects per-page metadata for every link reachable from this summary,
/// reading each article's source file under `src` to extract frontmatter
/// fields.
///
/// Raises if any referenced source file cannot be read.
pub fn Summary::collect_page_meta(
  self : Summary,
  src : String,
) -> Array[PageMeta] raise {
  let metas : Array[PageMeta] = []
  fn collect(items : Array[SummaryItem]) -> Unit raise {
    for item in items {
      match item {
        SummaryItem::Link(link) => {
          let path = @path.Path(src).join(link.source) |> Show::to_string
          let raw = @fs.read_file_to_string(path)
          let (fm, _) = @core.separate_frontmatter(
              @core.Item::new(raw, link.source),
            ).data
          metas.push({
            title: link.title,
            location: link.location,
            description: fm.get("description"),
            keywords: fm.get("keywords"),
            authors: fm.get("authors"),
            language: fm.get("language"),
            date: fm.get("date"),
          })
          collect(link.nested_items)
        }
        _ => ()
      }
    }
  }
  collect(
    [..self.prefix_chapters, ..self.numbered_chapters, ..self.suffix_chapters],
  )
  metas
}

///|
fn xml_escape(s : String) -> String {
  let out = StringBuilder()
  for ch in s {
    match ch {
      '&' => out.write_string("&amp;")
      '<' => out.write_string("&lt;")
      '>' => out.write_string("&gt;")
      '"' => out.write_string("&quot;")
      '\'' => out.write_string("&apos;")
      _ => out.write_char(ch)
    }
  }
  out.to_string()
}

///|
/// Converts a `YYYY/MM/DD HH:MM:SS` timestamp into RFC 3339 by
/// substituting separators and appending `Z`.
fn to_rfc3339(build_time : String) -> String {
  build_time.replace_all(old="/", new="-").replace_all(old=" ", new="T") + "Z"
}

///|
/// Renders an Atom feed for the given pages.
///
/// Returns an empty string when `config.site_url` is unset, since Atom
/// requires absolute entry URLs and the site has no way to construct them.
///
/// `build_time` (a `YYYY/MM/DD HH:MM:SS` string) is used as the feed-level
/// `<updated>` timestamp and as the fallback for entries whose source file
/// has no `date` frontmatter field.
pub fn generate_feed_xml(
  config : @config.BookConfig,
  metas : Array[PageMeta],
  build_time : String,
) -> String {
  guard config.site_url is Some(site_url) else { "" }
  let ts = to_rfc3339(build_time)
  let author = if config.authors.length() > 0 { config.authors[0] } else { "" }
  let out = StringBuilder()
  out.write_string("<?xml version=\"1.0\" encoding=\"utf-8\"?>\n")
  out.write_string("<feed xmlns=\"http://www.w3.org/2005/Atom\">\n")
  out.write_string("  <title>\{xml_escape(config.title)}</title>\n")
  out.write_string("  <id>\{xml_escape(site_url)}</id>\n")
  out.write_string("  <link href=\"\{xml_escape(site_url)}\"/>\n")
  out.write_string("  <updated>\{ts}</updated>\n")
  if author != "" {
    out.write_string("  <author><name>\{xml_escape(author)}</name></author>\n")
  }
  let limit = if config.feed_limit > metas.length() {
    metas.length()
  } else {
    config.feed_limit
  }
  for i = 0; i < limit; i = i + 1 {
    let m = metas[i]
    let url = site_url + m.location
    out.write_string("  <entry")
    match m.language {
      Some(lang) => out.write_string(" xml:lang=\"\{xml_escape(lang)}\"")
      None => ()
    }
    out.write_string(">\n")
    out.write_string("    <title>\{xml_escape(m.title)}</title>\n")
    out.write_string("    <id>\{xml_escape(url)}</id>\n")
    out.write_string("    <link href=\"\{xml_escape(url)}\"/>\n")
    out.write_string("    <updated>\{m.date.unwrap_or(ts)}</updated>\n")
    let entry_authors : Array[String] = match m.authors {
      Some(a) => a.split(",").map(s => s.trim().to_owned()).to_array()
      None => config.authors
    }
    for a in entry_authors {
      if a != "" {
        out.write_string("    <author><name>\{xml_escape(a)}</name></author>\n")
      }
    }
    match m.description {
      Some(d) => out.write_string("    <summary>\{xml_escape(d)}</summary>\n")
      None => ()
    }
    match m.keywords {
      Some(k) =>
        for kw in k.split(",") {
          let t = kw.trim().to_owned()
          if t != "" {
            out.write_string("    <category term=\"\{xml_escape(t)}\"/>\n")
          }
        }
      None => ()
    }
    out.write_string("  </entry>\n")
  }
  out.write_string("</feed>\n")
  out.to_string()
}

///|
/// Renders a sitemap for the given pages, using absolute URLs when
/// `config.site_url` is set and `base_url`-relative URLs otherwise.
pub fn generate_sitemap_xml(
  config : @config.BookConfig,
  metas : Array[PageMeta],
) -> String {
  let out = StringBuilder()
  out.write_string("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n")
  out.write_string(
    "<urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\">\n",
  )
  for m in metas {
    let url = match config.site_url {
      Some(s) => s + m.location
      None =>
        if config.base_url.has_suffix("/") {
          Show::to_string(config.base_url[0:config.base_url.length() - 1]) +
          m.location
        } else {
          config.base_url + m.location
        }
    }
    out.write_string("  <url>\n")
    out.write_string("    <loc>\{xml_escape(url)}</loc>\n")
    match m.date {
      Some(d) => out.write_string("    <lastmod>\{xml_escape(d)}</lastmod>\n")
      None => ()
    }
    out.write_string("  </url>\n")
  }
  out.write_string("</urlset>\n")
  out.to_string()
}

///|
/// Renders standard `robots.txt` content, optionally including a reference
/// to the site's `sitemap.xml`.
pub fn generate_robots_txt(
  sitemap_url~ : String? = None,
  allow~ : Array[String] = ["/"],
  disallow~ : Array[String] = [],
) -> String {
  let b = StringBuilder()
  b.write_string("User-agent: *\n")
  for a in allow {
    b.write_string("Allow: \{a}\n")
  }
  for d in disallow {
    b.write_string("Disallow: \{d}\n")
  }
  match sitemap_url {
    Some(url) => b.write_string("\nSitemap: \{url}\n")
    None => ()
  }
  b.to_string()
}
