///|
pub(all) struct SummaryLink {
  title : String
  location : String
  nested_items : Array[SummaryItem]
} derive(Eq, Debug)

///|
pub(all) enum SummaryItem {
  Link(SummaryLink)
  PartTitle(String)
  Separator
} derive(Eq, Debug)

///|
pub(all) struct Summary {
  title : String
  prefix_chapters : Array[SummaryItem]
  numbered_chapters : Array[SummaryItem]
  suffix_chapters : Array[SummaryItem]
} derive(Eq, Debug)

///|
fn flatten_items(
  items : Array[SummaryItem],
  depth : Int,
  current : String,
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
        let path = @path.Path(link.location)
        let basename = Show::to_string(path.basename())
        let location = {
          let location = path
            .dirname()
            .join(
              basename
              .rev_find(".")
              .map(index => Show::to_string(basename[:index]))
              .unwrap_or(basename) +
              ".html",
            )
            .to_string()
          if location.length() > 2 && location[0:2] == "./" {
            location[2:]
          } else {
            location
          }
        }
        let number = prefix + counter.to_string()
        if numbered {
          result.push({
            "is_link": true.to_json(),
            "title": link.title.to_json(),
            "location": location,
            "depth": depth.to_json(),
            "is_current": (location == current).to_json(),
            "number": number.to_json(),
          })
        } else {
          result.push({
            "is_link": true.to_json(),
            "title": link.title.to_json(),
            "location": location,
            "depth": depth.to_json(),
            "is_current": (location == current).to_json(),
          })
        }
        result.append(
          flatten_items(
            link.nested_items,
            depth + 1,
            current,
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
pub fn Summary::flatten(self : Summary, current : String) -> Json {
  {
    "title": self.title.to_json(),
    "prefix_chapters": Json::array(
      flatten_items(self.prefix_chapters, 0, current),
    ),
    "numbered_chapters": Json::array(
      flatten_items(self.numbered_chapters, 0, current, numbered=true),
    ),
    "suffix_chapters": Json::array(
      flatten_items(self.suffix_chapters, 0, current),
    ),
  }
}

///|
fn parse_summary_item(item : Array[@markdown.Block]) -> SummaryItem? {
  let link : SummaryLink? = extract_item_link(item)
  let nested : Array[SummaryItem] = extract_nested_items(item)

  match link {
    Some(lnk) =>
      Some(
        Link({ title: lnk.title, location: lnk.location, nested_items: nested }),
      )
    None => None
  }
}

///|
fn extract_item_link(item : Array[@markdown.Block]) -> SummaryLink? {
  match item {
    [Paragraph(inlines), ..] =>
      match inlines {
        [Link(title, url), ..] =>
          Some({
            title: @markdown.Plainable::to_plain(title),
            location: url,
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
            location: url,
            nested_items: [],
          }),
        )
      _ => continue
    }
  }
  result
}

///|
pub fn Summary::breadcrumb(self : Summary, current : String) -> String {
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
            None => return "/"
          }
      }
  }
  "/ " + path.join(" / ")
}

///|
pub fn Summary::prev_next(
  self : Summary,
  current : String,
) -> ((String, String)?, (String, String)?) {
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

  match flat.search_by(fn(link) { link.location == current }) {
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
