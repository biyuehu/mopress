///|
pub type Template = Array[TemplateNode]

///|
pub(all) enum TemplateNode {
  Text(String)
  Variable(String)
  If(String, Array[TemplateNode])
  For(String, Array[TemplateNode])
  Partial(String)
} derive(Eq, Debug)

///|
pub suberror TemplateParseError {
  TemplateParseError(String)
} derive(Eq, Debug)

///|
pub fn parse_template(input : String) -> Template raise TemplateParseError {
  let (nodes, index, terminator) = parse_nodes(input, 0, [])
  match terminator {
    Some(name) =>
      raise TemplateParseError(
        "unexpected $" + name + "$ at byte " + index.to_string(),
      )
    None => nodes
  }
}

///|
fn parse_nodes(
  input : String,
  start : Int,
  terminators : Array[String],
) -> (Array[TemplateNode], Int, String?) raise TemplateParseError {
  let nodes : Array[TemplateNode] = []
  let mut index = start
  while index < input.length() {
    match find_char(input, '$', index) {
      Some(open) => {
        if open > index {
          nodes.push(Text(substring(input, index, open)))
        }
        match find_char(input, '$', open + 1) {
          Some(close) => {
            let tag = substring(input, open + 1, close).trim().to_owned()
            if contains_string(terminators, tag) {
              return (nodes, close + 1, Some(tag))
            } else if tag.has_prefix("if(") && tag.has_suffix(")") {
              let name = trim_tag_argument(tag, "if(")
              let (children, next, found) = parse_nodes(input, close + 1, [
                "endif",
              ])
              match found {
                Some(_) => {
                  nodes.push(If(name, children))
                  index = next
                }
                None =>
                  raise TemplateParseError(
                    "missing $endif$ for $if(" +
                    name +
                    ")$ at byte " +
                    open.to_string(),
                  )
              }
            } else if tag.has_prefix("for(") && tag.has_suffix(")") {
              let name = trim_tag_argument(tag, "for(")
              let (children, next, found) = parse_nodes(input, close + 1, [
                "endfor",
              ])
              match found {
                Some(_) => {
                  nodes.push(For(name, children))
                  index = next
                }
                None =>
                  raise TemplateParseError(
                    "missing $endfor$ for $for(" +
                    name +
                    ")$ at byte " +
                    open.to_string(),
                  )
              }
            } else if tag.has_prefix("partial(") && tag.has_suffix(")") {
              nodes.push(Partial(parse_partial_path(tag, open)))
              index = close + 1
            } else if tag == "endif" || tag == "endfor" {
              raise TemplateParseError(
                "unexpected $" + tag + "$ at byte " + open.to_string(),
              )
            } else if is_identifier(tag) {
              nodes.push(Variable(tag))
              index = close + 1
            } else {
              raise TemplateParseError(
                "invalid template tag $" + tag + "$ at byte " + open.to_string(),
              )
            }
          }
          None =>
            raise TemplateParseError(
              "unterminated template tag at byte " + open.to_string(),
            )
        }
      }
      None => {
        nodes.push(Text(substring(input, index, input.length())))
        index = input.length()
      }
    }
  }
  (nodes, index, None)
}

///|
fn trim_tag_argument(
  tag : String,
  prefix : String,
) -> String raise TemplateParseError {
  let name = substring(tag, prefix.length(), tag.length() - 1).trim().to_owned()
  if is_identifier(name) {
    name
  } else {
    raise TemplateParseError("invalid template identifier `" + name + "`")
  }
}

///|
fn parse_partial_path(
  tag : String,
  offset : Int,
) -> String raise TemplateParseError {
  let raw = substring(tag, "partial(".length(), tag.length() - 1)
    .trim()
    .to_owned()
  if raw.length() >= 2 &&
    char_at(raw, 0) == '"' &&
    char_at(raw, raw.length() - 1) == '"' {
    substring(raw, 1, raw.length() - 1)
  } else {
    raise TemplateParseError(
      "partial expects a quoted path at byte " + offset.to_string(),
    )
  }
}

///|
fn is_identifier(input : String) -> Bool {
  if input == "" {
    false
  } else {
    let first = char_at(input, 0)
    if !is_identifier_start(first) {
      false
    } else {
      let mut index = 1
      while index < input.length() {
        if !is_identifier_continue(char_at(input, index)) {
          return false
        }
        index = index + 1
      }
      true
    }
  }
}

///|
fn is_identifier_start(ch : Char) -> Bool {
  (ch >= 'A' && ch <= 'Z') || (ch >= 'a' && ch <= 'z') || ch == '_'
}

///|
fn is_identifier_continue(ch : Char) -> Bool {
  is_identifier_start(ch) || (ch >= '0' && ch <= '9') || ch == '-' || ch == '.'
}

///|
fn contains_string(items : Array[String], target : String) -> Bool {
  for item in items {
    if item == target {
      return true
    }
  }
  false
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
pub suberror TemplateRenderError {
  TemplateRenderError(String)
  MissingVariableError(String)
  PartialNotImplementedError(String)
} derive(Eq, Debug)

///|
pub fn render_template(
  template : Template,
  context : Map[String, String],
) -> String raise TemplateRenderError {
  let output = StringBuilder::new()
  render_nodes(template, context, output)
  output.to_string()
}

///|
fn render_nodes(
  nodes : Array[TemplateNode],
  context : Map[String, String],
  output : StringBuilder,
) -> Unit raise TemplateRenderError {
  for node in nodes {
    match node {
      Text(text) => output.write_string(text)
      Variable(name) =>
        match context.get(name) {
          Some(value) => output.write_string(value.to_string())
          None => raise MissingVariableError("missing variable: " + name)
        }
      If(name, children) => {
        guard context.get(name) is Some(value) && value != ""
        render_nodes(children, context, output)
      }
      For(name, children) =>
        match context.get(name) {
          Some(items) =>
            for item in items {
              let item_context = context
              item_context["item"] = item.to_string()
              render_nodes(children, item_context, output)
            }
          _ => raise TemplateRenderError("expected array for loop: " + name)
        }
      Partial(path) =>
        raise PartialNotImplementedError("partial not implemented: " + path)
    }
  }
}
