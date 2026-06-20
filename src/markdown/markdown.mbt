///|
// pub(all) struct MarkdownAst {
//   blocks : Markdown
// } derive(Eq, Debug)
pub type Markdown = Array[Block]

///|
pub(all) struct ListBlock {
  ordered : Bool
  start : Int?
  items : Array[Markdown]
} derive(Eq, Debug)

///|
pub(all) enum Block {
  Heading(Int, Array[Inline])
  Paragraph(Array[Inline])
  ThematicBreak
  CodeBlock(String?, String)
  BlockQuote(Markdown)
  List(ListBlock)
  HtmlBlock(String)
} derive(Eq, Debug)

///|
pub(all) enum Inline {
  Text(String)
  Emphasis(Array[Inline])
  Strong(Array[Inline])
  Code(String)
  Link(Array[Inline], String)
  Image(String, String)
  Html(String)
  SoftBreak
  HardBreak
} derive(Eq, Debug)

///|
pub trait Plainable {
  fn to_plain(self : Self) -> String
}

///|
pub impl[T : Plainable] Plainable for Array[T] with fn to_plain(self : Array[T]) -> String {
  self.map(item => item.to_plain()).join(" ")
}

///|
pub impl Plainable for Block with fn to_plain(self : Block) -> String {
  match self {
    Heading(_, content) => Plainable::to_plain(content)
    Paragraph(content) => Plainable::to_plain(content)
    ThematicBreak => "---"
    CodeBlock(_, content) => content
    BlockQuote(blocks) => Plainable::to_plain(blocks)
    List(list) => list.to_plain()
    HtmlBlock(content) => content
  }
}

///|
pub impl Plainable for Inline with fn to_plain(self : Inline) -> String {
  match self {
    Text(text) => text
    Emphasis(content) => Plainable::to_plain(content)
    Strong(content) => Plainable::to_plain(content)
    Code(code) => code
    Link(content, _) => Plainable::to_plain(content)
    Image(_, alt) => alt
    Html(html) => html
    SoftBreak => " "
    HardBreak => "\n"
  }
}

///|
pub impl Plainable for ListBlock with fn to_plain(self : ListBlock) -> String {
  (if self.start is Some(start) { start.to_string() + " " } else { "" }) +
  Plainable::to_plain(self.items)
}

///|
pub fn[T : Show] parse_markdown(input : T) -> Markdown {
  parse_string(input.to_string())
}

///|
fn parse_string(input : String) -> Markdown {
  let lines = normalize_lines(input)
  parse_blocks(lines)
}

///|
fn parse_blocks(lines : Array[String]) -> Markdown {
  let blocks : Markdown = []
  let mut index = 0
  while index < lines.length() {
    let line = lines[index]
    let trimmed = line.trim().to_owned()
    if trimmed == "" {
      index = index + 1
    } else if is_fence_start(trimmed) {
      let (block, next) = parse_fenced_code(lines, index)
      blocks.push(block)
      index = next
    } else if is_atx_heading(trimmed) {
      blocks.push(parse_heading(trimmed))
      index = index + 1
    } else if is_thematic_break(trimmed) {
      blocks.push(ThematicBreak)
      index = index + 1
    } else if is_block_quote(trimmed) {
      let (block, next) = parse_block_quote(lines, index)
      blocks.push(block)
      index = next
    } else if is_list_item(trimmed) {
      let (block, next) = parse_list(lines, index)
      blocks.push(block)
      index = next
    } else if is_html_block_start(trimmed) {
      let (block, next) = parse_html_block(lines, index)
      blocks.push(block)
      index = next
    } else {
      let (block, next) = parse_paragraph(lines, index)
      blocks.push(block)
      index = next
    }
  }
  blocks
}

///|
fn parse_heading(line : String) -> Block {
  let mut level = 0
  while level < line.length() && char_at(line, level) == '#' && level < 6 {
    level = level + 1
  }
  let raw = substring(line, level, line.length()).trim().to_owned()
  let content = strip_closing_heading_marker(raw)
  Heading(level, parse_inlines(content))
}

///|
fn parse_fenced_code(lines : Array[String], start : Int) -> (Block, Int) {
  let opening = lines[start].trim().to_owned()
  let marker = char_at(opening, 0)
  let fence_len = count_prefix(opening, marker)
  let info = opening_suffix(opening, fence_len).trim().to_owned()
  let content = StringBuilder::new()
  let mut index = start + 1
  while index < lines.length() {
    let line = lines[index]
    let trimmed = line.trim().to_owned()
    if is_matching_fence(trimmed, marker, fence_len) {
      return (
        CodeBlock(
          if info == "" {
            None
          } else {
            Some(info)
          },
          content.to_string(),
        ),
        index + 1,
      )
    }
    content.write_string(line)
    if index + 1 < lines.length() {
      content.write_char('\n')
    }
    index = index + 1
  }
  (
    CodeBlock(if info == "" { None } else { Some(info) }, content.to_string()),
    index,
  )
}

///|
fn parse_block_quote(lines : Array[String], start : Int) -> (Block, Int) {
  let quote_lines : Array[String] = []
  let mut index = start
  while index < lines.length() {
    let trimmed = lines[index].trim().to_owned()
    if trimmed == "" {
      quote_lines.push("")
      index = index + 1
    } else if is_block_quote(trimmed) {
      quote_lines.push(strip_block_quote_marker(trimmed))
      index = index + 1
    } else {
      break
    }
  }
  (BlockQuote(parse_blocks(quote_lines)), index)
}

///|
fn parse_list(lines : Array[String], start : Int) -> (Block, Int) {
  let first = parse_list_marker(lines[start].trim().to_owned()).unwrap()
  let items : Array[Markdown] = []
  let mut index = start
  while index < lines.length() {
    let trimmed = lines[index].trim().to_owned()
    match parse_list_marker(trimmed) {
      Some(marker) if marker.ordered == first.ordered => {
        let item_lines : Array[String] = [marker.rest]
        index = index + 1
        while index < lines.length() {
          let next = lines[index]
          let next_trimmed = next.trim().to_owned()
          if next_trimmed == "" {
            item_lines.push("")
            index = index + 1
          } else if count_leading_spaces(next) >= 2 {
            item_lines.push(strip_leading_spaces(next, 2))
            index = index + 1
          } else if is_list_item(next_trimmed) {
            break
          } else {
            break
          }
        }
        items.push(parse_blocks(item_lines))
      }
      _ => break
    }
  }
  (List({ ordered: first.ordered, start: first.start, items }), index)
}

///|
fn parse_html_block(lines : Array[String], start : Int) -> (Block, Int) {
  let content = StringBuilder::new()
  let mut index = start
  while index < lines.length() {
    let line = lines[index]
    if line.trim().to_owned() == "" {
      break
    }
    if index > start {
      content.write_char('\n')
    }
    content.write_string(line)
    index = index + 1
  }
  (HtmlBlock(content.to_string()), index)
}

///|
fn parse_paragraph(lines : Array[String], start : Int) -> (Block, Int) {
  let content = StringBuilder::new()
  let mut index = start
  while index < lines.length() {
    let line = lines[index]
    let trimmed = line.trim().to_owned()
    if trimmed == "" || is_block_start(trimmed) {
      break
    }
    if index > start {
      content.write_char('\n')
    }
    content.write_string(trimmed)
    index = index + 1
  }
  (Paragraph(parse_inlines(content.to_string())), index)
}

///|
fn parse_inlines(input : String) -> Array[Inline] {
  let nodes : Array[Inline] = []
  let mut text = StringBuilder::new()
  let mut index = 0
  while index < input.length() {
    if starts_at(input, index, "  \n") {
      text = flush_text(text, nodes)
      nodes.push(HardBreak)
      index = index + 3
    } else if char_at(input, index) == '\n' {
      text = flush_text(text, nodes)
      nodes.push(SoftBreak)
      index = index + 1
    } else if char_at(input, index) == '`' {
      match find_char(input, '`', index + 1) {
        Some(end) => {
          text = flush_text(text, nodes)
          nodes.push(Code(substring(input, index + 1, end)))
          index = end + 1
        }
        None => {
          text.write_char(char_at(input, index))
          index = index + 1
        }
      }
    } else if starts_at(input, index, "![") {
      match parse_image(input, index) {
        Some((node, next)) => {
          text = flush_text(text, nodes)
          nodes.push(node)
          index = next
        }
        None => {
          text.write_char(char_at(input, index))
          index = index + 1
        }
      }
    } else if char_at(input, index) == '[' {
      match parse_link(input, index) {
        Some((node, next)) => {
          text = flush_text(text, nodes)
          nodes.push(node)
          index = next
        }
        None => {
          text.write_char(char_at(input, index))
          index = index + 1
        }
      }
    } else if starts_at(input, index, "**") {
      match parse_delimited(input, index, "**", true) {
        Some((node, next)) => {
          text = flush_text(text, nodes)
          nodes.push(node)
          index = next
        }
        None => {
          text.write_char(char_at(input, index))
          index = index + 1
        }
      }
    } else if char_at(input, index) == '*' {
      match parse_delimited(input, index, "*", false) {
        Some((node, next)) => {
          text = flush_text(text, nodes)
          nodes.push(node)
          index = next
        }
        None => {
          text.write_char(char_at(input, index))
          index = index + 1
        }
      }
    } else if char_at(input, index) == '<' {
      match find_char(input, '>', index + 1) {
        Some(end) => {
          text = flush_text(text, nodes)
          nodes.push(Html(substring(input, index, end + 1)))
          index = end + 1
        }
        None => {
          text.write_char(char_at(input, index))
          index = index + 1
        }
      }
    } else {
      text.write_char(char_at(input, index))
      index = index + 1
    }
  }
  let _ = flush_text(text, nodes)
  nodes
}

///|
fn parse_link(input : String, start : Int) -> (Inline, Int)? {
  match find_char(input, ']', start + 1) {
    Some(label_end) if label_end + 1 < input.length() &&
      char_at(input, label_end + 1) == '(' =>
      match find_char(input, ')', label_end + 2) {
        Some(dest_end) => {
          let label = substring(input, start + 1, label_end)
          let destination = substring(input, label_end + 2, dest_end)
            .trim()
            .to_owned()
          Some((Link(parse_inlines(label), destination), dest_end + 1))
        }
        None => None
      }
    _ => None
  }
}

///|
fn parse_image(input : String, start : Int) -> (Inline, Int)? {
  match find_char(input, ']', start + 2) {
    Some(label_end) if label_end + 1 < input.length() &&
      char_at(input, label_end + 1) == '(' =>
      match find_char(input, ')', label_end + 2) {
        Some(dest_end) => {
          let alt = substring(input, start + 2, label_end)
          let destination = substring(input, label_end + 2, dest_end)
            .trim()
            .to_owned()
          Some((Image(alt, destination), dest_end + 1))
        }
        None => None
      }
    _ => None
  }
}

///|
fn parse_delimited(
  input : String,
  start : Int,
  delimiter : String,
  strong : Bool,
) -> (Inline, Int)? {
  match find_string(input, delimiter, start + delimiter.length()) {
    Some(end) => {
      let content = substring(input, start + delimiter.length(), end)
      let parsed = parse_inlines(content)
      if strong {
        Some((Strong(parsed), end + delimiter.length()))
      } else {
        Some((Emphasis(parsed), end + delimiter.length()))
      }
    }
    None => None
  }
}

///|
fn flush_text(buffer : StringBuilder, output : Array[Inline]) -> StringBuilder {
  let text = buffer.to_string()
  if text != "" {
    output.push(Text(text))
  }
  StringBuilder::new()
}

///|
fn is_block_start(trimmed : String) -> Bool {
  is_fence_start(trimmed) ||
  is_atx_heading(trimmed) ||
  is_thematic_break(trimmed) ||
  is_block_quote(trimmed) ||
  is_list_item(trimmed) ||
  is_html_block_start(trimmed)
}

///|
fn is_atx_heading(line : String) -> Bool {
  let mut level = 0
  while level < line.length() && char_at(line, level) == '#' && level < 7 {
    level = level + 1
  }
  level > 0 &&
  level <= 6 &&
  (
    level == line.length() ||
    char_at(line, level) == ' ' ||
    char_at(line, level) == '\t'
  )
}

///|
fn is_fence_start(line : String) -> Bool {
  (line.has_prefix("```") && count_prefix(line, '`') >= 3) ||
  (line.has_prefix("~~~") && count_prefix(line, '~') >= 3)
}

///|
fn is_matching_fence(line : String, marker : Char, minimum : Int) -> Bool {
  line.length() >= minimum &&
  char_at(line, 0) == marker &&
  count_prefix(line, marker) >= minimum &&
  substring(line, count_prefix(line, marker), line.length()).trim() == ""
}

///|
fn is_thematic_break(line : String) -> Bool {
  let compact = remove_spaces(line)
  if compact.length() < 3 {
    false
  } else {
    let marker = char_at(compact, 0)
    (marker == '-' || marker == '*' || marker == '_') &&
    all_chars_are(compact, marker)
  }
}

///|
fn is_block_quote(line : String) -> Bool {
  line.has_prefix(">")
}

///|
fn is_list_item(line : String) -> Bool {
  parse_list_marker(line) is Some(_)
}

///|
fn is_html_block_start(line : String) -> Bool {
  line.has_prefix("<") && line.contains(">")
}

///|
fn strip_closing_heading_marker(input : String) -> String {
  let trimmed = input.trim().to_owned()
  let mut end = trimmed.length()
  while end > 0 && char_at(trimmed, end - 1) == '#' {
    end = end - 1
  }
  if end < trimmed.length() && (end == 0 || char_at(trimmed, end - 1) == ' ') {
    substring(trimmed, 0, end).trim().to_owned()
  } else {
    trimmed
  }
}

///|
fn strip_block_quote_marker(line : String) -> String {
  if line.length() == 1 {
    ""
  } else if char_at(line, 1) == ' ' {
    substring(line, 2, line.length())
  } else {
    substring(line, 1, line.length())
  }
}

///|
priv struct ListMarker {
  ordered : Bool
  start : Int?
  rest : String
}

///|
fn parse_list_marker(line : String) -> ListMarker? {
  if line.length() >= 2 &&
    (
      char_at(line, 0) == '-' ||
      char_at(line, 0) == '+' ||
      char_at(line, 0) == '*'
    ) &&
    (char_at(line, 1) == ' ' || char_at(line, 1) == '\t') {
    Some({
      ordered: false,
      start: None,
      rest: substring(line, 2, line.length()),
    })
  } else {
    let mut index = 0
    while index < line.length() && is_digit(char_at(line, index)) {
      index = index + 1
    }
    if index > 0 &&
      index + 1 < line.length() &&
      (char_at(line, index) == '.' || char_at(line, index) == ')') &&
      (char_at(line, index + 1) == ' ' || char_at(line, index + 1) == '\t') {
      Some({
        ordered: true,
        start: Some(parse_positive_int(substring(line, 0, index))),
        rest: substring(line, index + 2, line.length()),
      })
    } else {
      None
    }
  }
}

///|
fn normalize_lines(input : String) -> Array[String] {
  let normalized = replace_crlf(input)
  let views = normalized.split("\n").to_array()
  let lines : Array[String] = []
  for view in views {
    lines.push(view.to_owned())
  }
  lines
}

///|
fn replace_crlf(input : String) -> String {
  let output = StringBuilder::new()
  let mut index = 0
  while index < input.length() {
    if char_at(input, index) == '\r' {
      if index + 1 < input.length() && char_at(input, index + 1) == '\n' {
        output.write_char('\n')
        index = index + 2
      } else {
        output.write_char('\n')
        index = index + 1
      }
    } else {
      output.write_char(char_at(input, index))
      index = index + 1
    }
  }
  output.to_string()
}

///|
fn remove_spaces(input : String) -> String {
  let output = StringBuilder::new()
  for ch in input {
    if ch != ' ' && ch != '\t' {
      output.write_char(ch)
    }
  }
  output.to_string()
}

///|
fn all_chars_are(input : String, expected : Char) -> Bool {
  for ch in input {
    if ch != expected {
      return false
    }
  }
  true
}

///|
fn count_prefix(input : String, expected : Char) -> Int {
  let mut count = 0
  while count < input.length() && char_at(input, count) == expected {
    count = count + 1
  }
  count
}

///|
fn count_leading_spaces(input : String) -> Int {
  let mut count = 0
  while count < input.length() && char_at(input, count) == ' ' {
    count = count + 1
  }
  count
}

///|
fn strip_leading_spaces(input : String, max : Int) -> String {
  let mut count = 0
  while count < input.length() && count < max && char_at(input, count) == ' ' {
    count = count + 1
  }
  substring(input, count, input.length())
}

///|
fn opening_suffix(input : String, start : Int) -> String {
  substring(input, start, input.length())
}

///|
fn starts_at(input : String, start : Int, needle : String) -> Bool {
  if start + needle.length() > input.length() {
    false
  } else {
    let mut index = 0
    while index < needle.length() {
      if char_at(input, start + index) != char_at(needle, index) {
        return false
      }
      index = index + 1
    }
    true
  }
}

///|
fn find_char(input : String, needle : Char, start : Int) -> Int? {
  let mut index = start
  while index < input.length() {
    if char_at(input, index) == needle {
      return Some(index)
    }
    index = index + 1
  }
  None
}

///|
fn find_string(input : String, needle : String, start : Int) -> Int? {
  let mut index = start
  while index + needle.length() <= input.length() {
    if starts_at(input, index, needle) {
      return Some(index)
    }
    index = index + 1
  }
  None
}

///|
fn substring(input : String, start : Int, end : Int) -> String {
  let output = StringBuilder::new()
  let mut index = start
  while index < end && index < input.length() {
    output.write_char(char_at(input, index))
    index = index + 1
  }
  output.to_string()
}

///|
fn char_at(input : String, index : Int) -> Char {
  input.code_unit_at(index).unsafe_to_char()
}

///|
fn is_digit(ch : Char) -> Bool {
  ch >= '0' && ch <= '9'
}

///|
fn parse_positive_int(input : String) -> Int {
  let mut value = 0
  for ch in input {
    value = value * 10 + (ch.to_int() - '0'.to_int())
  }
  value
}
