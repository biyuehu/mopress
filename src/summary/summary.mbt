///|
pub(all) struct SummaryLink {
  title : String
  location : String?
  nested_items : Array[SummaryItem]
} derive(Eq, Debug, ToJson)

///|
pub(all) enum SummaryItem {
  Link(SummaryLink)
  PartTitle(String)
  Separator
} derive(Eq, Debug, ToJson)

///|
pub(all) struct Summary {
  title : String
  prefix_chapters : Array[SummaryItem]
  numbered_chapters : Array[SummaryItem]
  suffix_chapters : Array[SummaryItem]
} derive(Eq, Debug, ToJson)

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
            location: Some(url),
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

  for block in blocks {
    match (phase, block) {
      (0, Paragraph(inlines)) =>
        match extract_root_link_item(inlines) {
          Some(item) => prefix_chapters.push(item)
          None => ()
        }

      // 保持旧行为：这里仅切换到 numbered。
      // 如果你想把开头的 --- 也保留下来，可以改成：
      // numbered_chapters.push(Separator)
      // phase = 1
      (0, ThematicBreak) => phase = 1
      (0, Heading(1, inlines)) => {
        phase = 1
        numbered_chapters.push(
          PartTitle(@markdown.Plainable::to_plain(inlines)),
        )
      }
      (0, List(lb)) => {
        phase = 1
        for item in parse_list_items(lb.items) {
          numbered_chapters.push(item)
        }
      }
      (1, Heading(1, inlines)) =>
        numbered_chapters.push(
          PartTitle(@markdown.Plainable::to_plain(inlines)),
        )
      (1, List(lb)) =>
        for item in parse_list_items(lb.items) {
          numbered_chapters.push(item)
        }
      (1, ThematicBreak) => {
        numbered_chapters.push(Separator)
        phase = 2
      }
      (2, Paragraph(inlines)) =>
        match extract_root_link_item(inlines) {
          Some(item) => suffix_chapters.push(item)
          None => ()
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
fn extract_root_link_item(inlines : Array[@markdown.Inline]) -> SummaryItem? {
  for inline in inlines {
    match inline {
      Link(title, url) =>
        return Some(
          Link({
            title: @markdown.Plainable::to_plain(title),
            location: Some(url),
            nested_items: [],
          }),
        )
      _ => continue
    }
  } nobreak {
    None
  }
}
