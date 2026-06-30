///|
pub type Template = Array[TemplateNode]

///|
pub(all) enum TemplateNode {
  Text(String)
  Variable(String)
  If(String, Array[TemplateNode], Array[TemplateNode])
  For(String, Array[TemplateNode])
  Partial(String)
} derive(Eq, Debug)

///|
pub suberror TemplateParseError {
  TemplateParseError(String)
} derive(Eq, Debug)

///|
pub type Context = Map[String, Value]

///|
pub(all) enum Value {
  String(String)
  Number(Double)
  Bool(Bool)
  Array(Array[Value])
  Object(Map[String, Value])
} derive(Eq, Debug)

///|
pub impl Show for Value with fn to_string(self : Value) -> String {
  let to_string_spec = (v : Value) => {
    match v {
      String(s) => "\"\{s}\""
      _ => v.to_string()
    }
  }
  match self {
    String(s) => s
    Number(n) => n.to_string()
    Bool(b) => b.to_string()
    Array(a) => "[\{a.map(v => v |> to_string_spec).join(", ")}]"
    Object(x) => {
      let output = StringBuilder::new()
      output.write_string("{")
      let mut is_first = true
      for item in x {
        if is_first {
          is_first = false
        } else {
          output.write_string(", ")
        }
        output.write_string(item.0)
        output.write_string(": ")
        output.write_string(item.1 |> to_string_spec)
      }
      output.write_string("}")
      output.to_string()
    }
  }
}

///|
pub fn Value::from_json(json : Json) -> Value {
  match json {
    String(s) => String(s)
    Null => String("")
    Number(n, ..) => Number(n)
    True => Bool(true)
    False => Bool(false)
    Array(a) => Array(a.map(v => Value::from_json(v)))
    Object(o) => Object(o.map((_, v) => Value::from_json(v)))
  }
}

///|
pub fn[T : Show] parse_template(input : T) -> Template raise TemplateParseError {
  parse_string(input.to_string())
}

///|
fn parse_string(input : String) -> Template raise TemplateParseError {
  let (nodes, index, terminator) = parse_nodes(input, 0, [])
  match terminator {
    Some(name) =>
      raise TemplateParseError(
        "unexpected $\{name}$ at byte " + index.to_string(),
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
              let (then_children, next, found) = parse_nodes(input, close + 1, [
                "else", "endif",
              ])
              match found {
                Some("endif") => {
                  nodes.push(If(name, then_children, []))
                  index = next
                }
                Some("else") => {
                  let (else_children, else_next, else_found) = parse_nodes(
                    input,
                    next,
                    ["endif"],
                  )
                  match else_found {
                    Some(_) => {
                      nodes.push(If(name, then_children, else_children))
                      index = else_next
                    }
                    None =>
                      raise TemplateParseError(
                        "missing $endif$ for $if(" +
                        name +
                        ")$ at byte " +
                        open.to_string(),
                      )
                  }
                }
                Some(other) =>
                  raise TemplateParseError(
                    "unexpected $\{other}$ at byte " + open.to_string(),
                  )
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
            } else if tag == "else" || tag == "endif" || tag == "endfor" {
              raise TemplateParseError(
                "unexpected $\{tag}$ at byte " + open.to_string(),
              )
            } else if is_identifier(tag) {
              nodes.push(Variable(tag))
              index = close + 1
            } else {
              raise TemplateParseError(
                "invalid template tag $\{tag}$ at byte " + open.to_string(),
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
    raise TemplateParseError("invalid template identifier `\{name}`")
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
  UndefinedVariableError(String)
  NonArrayForLoopError(String)
  PartialLoadError(String)
  PartialParseError(String)
  RecursivePartialError(String)
} derive(Eq, Debug)

///|
pub fn apply_template(template : Template, context : Context) -> String {
  let output = StringBuilder::new()
  render_nodes(template, context, false, output, []) catch {
    _ => panic()
  }
  output.to_string()
}

///|
pub fn apply_template_strict(
  template : Template,
  context : Context,
) -> String raise TemplateRenderError {
  let output = StringBuilder::new()
  render_nodes(template, context, true, output, [])
  output.to_string()
}

///|
fn render_nodes(
  nodes : Array[TemplateNode],
  context : Context,
  strict : Bool,
  output : StringBuilder,
  partial_stack : Array[String],
) -> Unit raise TemplateRenderError {
  for node in nodes {
    match node {
      Text(text) => output.write_string(text)
      Variable(name) =>
        match lookup_value(name, context) {
          Some(value) => output.write_string(value.to_string())
          None =>
            if strict {
              raise UndefinedVariableError("missing variable: " + name)
            }
        }
      If(name, then_children, else_children) =>
        if lookup_value(name, context) is Some(value) && value.is_truthy() {
          render_nodes(then_children, context, strict, output, partial_stack)
        } else {
          render_nodes(else_children, context, strict, output, partial_stack)
        }
      For(name, children) =>
        match lookup_value(name, context) {
          Some(items) if items is Array(items) =>
            for item in items {
              let item_context = context.copy()
              item_context["item"] = item
              render_nodes(
                children, item_context, strict, output, partial_stack,
              )
            }
          _ =>
            if strict {
              raise NonArrayForLoopError("expected array for loop: " + name)
            }
        }
      Partial(path) =>
        render_partial(path, context, strict, output, partial_stack)
    }
  }
}

///|
fn Value::is_truthy(self : Value) -> Bool {
  match self {
    Bool(false) => false
    String("") => false
    Array(items) => items.length() > 0
    _ => true
  }
}

///|
fn lookup_value(path : String, context : Context) -> Value? {
  let parts = split_path(path)
  if parts.length() == 0 || parts[0] == "" {
    None
  } else {
    match context.get(parts[0]) {
      Some(value) => lookup_value_part(value, parts, 1)
      None => None
    }
  }
}

///|
fn lookup_value_part(
  value : Value,
  parts : Array[String],
  index : Int,
) -> Value? {
  if index >= parts.length() {
    Some(value)
  } else if parts[index] == "" {
    None
  } else {
    match value {
      Object(fields) =>
        match fields.get(parts[index]) {
          Some(next) => lookup_value_part(next, parts, index + 1)
          None => None
        }
      _ => None
    }
  }
}

///|
fn split_path(path : String) -> Array[String] {
  let parts : Array[String] = []
  for part in path.split(".").to_array() {
    parts.push(part.to_owned())
  }
  parts
}

///|
fn render_partial(
  path : String,
  context : Context,
  strict : Bool,
  output : StringBuilder,
  partial_stack : Array[String],
) -> Unit raise TemplateRenderError {
  if contains_string(partial_stack, path) {
    raise RecursivePartialError("recursive partial: " + path)
  }
  let source = @fs.read_file_to_string(path) catch {
    @fs.IOError(message) =>
      raise PartialLoadError("failed to read partial `\{path}`: " + message)
  }
  let template = parse_template(source) catch {
    TemplateParseError(message) =>
      raise PartialParseError("failed to parse partial `\{path}`: " + message)
  }
  let next_stack = partial_stack.copy()
  next_stack.push(path)
  render_nodes(template, context, strict, output, next_stack)
}
