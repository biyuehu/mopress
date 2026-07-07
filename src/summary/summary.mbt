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
/// The parsed structure of a book's table of contents (`SUMMARY.md`),
/// split into an optional prefix section, the main numbered chapters, and
/// an optional suffix section — mirroring the conventional structure of
/// an mdBook-style summary file.
pub(all) struct Summary {
  title : String
  prefix_chapters : Array[SummaryItem]
  numbered_chapters : Array[SummaryItem]
  suffix_chapters : Array[SummaryItem]
} derive(Eq, Debug)

///|
/// A single article's indexed content, e.g. for building a client-side
/// search index over the site's pages.
pub(all) struct ArticleIndex {
  title : String
  location : String
  content : String
} derive(Eq, Debug, ToJson)

///|
fn flatten_items(
  items : Array[SummaryItem],
  depth : Int,
  current : String,
  base_url : String,
  numbered? : Bool = false,
  prefix? : String = "",
) -> Array[Json] {
  let result : Array[Json] = []
  let mut counter = 0
  for item in items {
    match item {
      Separator => result.push({ "is_separator": true.to_json() })
      PartTitle(title) =>
        result.push({
          "is_part_title": true.to_json(),
          "title": title.to_json(),
        })
      Link(link) => {
        counter += 1
        let number = prefix + counter.to_string()
        let location = if base_url[-1:] == "/" {
          base_url[0:base_url.length() - 1] + link.location
        } else {
          base_url + link.location
        }
        if numbered {
          result.push({
            "is_link": true.to_json(),
            "title": link.title.to_json(),
            "location": location,
            "source": link.source,
            "depth": depth.to_json(),
            "is_current": (link.location == current).to_json(),
            "number": number.to_json(),
          })
        } else {
          result.push({
            "is_link": true.to_json(),
            "title": link.title.to_json(),
            "location": location,
            "source": link.source,
            "depth": depth.to_json(),
            "is_current": (link.location == current).to_json(),
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
/// Returns a JSON representation of this summary, rooted at `location`,
/// e.g. for use as a template variable describing the current section's
/// navigation structure.
pub fn Summary::flatten(
  self : Summary,
  current : String,
  base_url : String,
) -> Json {
  let current = unify_url(current)
  {
    "title": self.title.to_json(),
    "prefix_chapters": Json::array(
      flatten_items(self.prefix_chapters, 0, current, base_url),
    ),
    "numbered_chapters": Json::array(
      flatten_items(self.numbered_chapters, 0, current, base_url, numbered=true),
    ),
    "suffix_chapters": Json::array(
      flatten_items(self.suffix_chapters, 0, current, base_url),
    ),
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
      }
      List(lb) => {
        if phase == 0 {
          phase = 1
        }
        flush_headings()
        for item in parse_list_items(lb.items) {
          numbered_chapters.push(item)
        }
      }
      Paragraph(inlines) => {
        flush_headings()
        if phase == 1 {
          phase = 2
        }
        for item in extract_root_link_items(inlines) {
          target().push(item)
        }
      }
      _ => ()
    }
  }

  { title, prefix_chapters, numbered_chapters, suffix_chapters }
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
  let out = StringBuilder::new()
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
