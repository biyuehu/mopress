///|
pub(all) struct SummaryLink {
  title : String
  url : String
} derive(Eq, Debug)

///|
pub(all) struct SummaryItem {
  link : SummaryLink?
  nested : Array[SummaryItem]
} derive(Eq, Debug)

///|
pub(all) struct SummaryPart {
  title : String?
  items : Array[SummaryItem]
} derive(Eq, Debug)

///|
pub(all) struct Summary {
  title : String
  prefix_chapters : Array[SummaryLink]
  parts : Array[SummaryPart]
  suffix_chapters : Array[SummaryLink]
} derive(Eq, Debug)

///|
fn parse_summary_item(item : Array[@markdown.Block]) -> SummaryItem {
  let link : SummaryLink? = extract_item_link(item)
  let nested : Array[SummaryItem] = extract_nested_items(item)
  { link, nested }
}

///|
fn extract_item_link(item : Array[@markdown.Block]) -> SummaryLink? {
  match item {
    [Paragraph(inlines), ..] =>
      match inlines {
        [Link(title, url), ..] =>
          Some({ title: @markdown.Plainable::to_plain(title), url })
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
  items.map(fn(item) { parse_summary_item(item) })
}

///|
pub fn parse_summary(doc : @markdown.Markdown) -> Summary {
  let title : String = find_title(doc)

  let prefix_chapters : Array[SummaryLink] = []
  let parts : Array[SummaryPart] = []
  let suffix_chapters : Array[SummaryLink] = []

  let blocks = skip_title(doc)

  let mut phase = 0 // 0=prefix, 1=in_parts, 2=suffix
  let mut current_part_title : String? = None
  let mut current_part_items : Array[SummaryItem] = []

  fn flush_part() {
    if current_part_items.length() > 0 || current_part_title is Some(_) {
      parts.push({ title: current_part_title, items: current_part_items })
      current_part_title = None
      current_part_items = []
    }
  }

  for block in blocks {
    match (phase, block) {
      (0, Paragraph(inlines)) =>
        match extract_link_from_inlines(inlines) {
          Some(lnk) => prefix_chapters.push(lnk)
          None => ()
        }
      (0, ThematicBreak) => phase = 1
      (0, Heading(1, inlines)) => {
        phase = 1
        current_part_title = Some(@markdown.Plainable::to_plain(inlines))
      }
      (0, List(lb)) => {
        phase = 1
        current_part_items = parse_list_items(lb.items)
      }
      (1, Heading(1, inlines)) => {
        flush_part()
        current_part_title = Some(@markdown.Plainable::to_plain(inlines))
      }
      (1, List(lb)) => current_part_items = parse_list_items(lb.items)
      (1, ThematicBreak) => {
        flush_part()
        phase = 2
      }
      (2, Paragraph(inlines)) =>
        match extract_link_from_inlines(inlines) {
          Some(lnk) => suffix_chapters.push(lnk)
          None => ()
        }
      _ => ()
    }
  }

  // 别忘了 flush 最后一个 part
  flush_part()

  { title, prefix_chapters, parts, suffix_chapters }
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
/// 跳过第一个 Heading(1)
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
fn extract_link_from_inlines(inlines : Array[@markdown.Inline]) -> SummaryLink? {
  for inline in inlines {
    match inline {
      Link(title, url) =>
        return Some({ title: @markdown.Plainable::to_plain(title), url })
      _ => continue
    }
  } nobreak {
    None
  }
}
