///|
pub(all) struct BookConfig {
  title : String?
  authors : Array[String]
  description : String?
  src : String
  output : String
  language : String?
  text_direction : TextDirection
}

///|
pub enum TextDirection {
  LeftToRight
  RightToLeft
}

///|
pub suberror ConfigParseError {
  ConfigParseError(String)
}

///|

///|
pub fn BookConfig::parse(
  config_str : String,
) -> BookConfig raise ConfigParseError {
  guard (@toml.parse(config_str) catch {
      s => raise ConfigParseError("Parse config error: " + s.to_string())
    })
    is @toml.TomlTable(root) else {
    raise ConfigParseError("Config root must be a TOML table")
  }

  let book : Map[String, @toml.TomlValue] = match root.get("book") {
    Some(@toml.TomlTable(t)) => t
    Some(_) => raise ConfigParseError("[book] must be a table")
    None => Map([])
  }

  {
    title: match book.get("title") {
      Some(@toml.TomlString(s)) => Some(s)
      Some(_) => raise ConfigParseError("`title` must be a string")
      None => None
    },
    authors: match book.get("authors") {
      Some(@toml.TomlArray(arr)) => {
        let result : Array[String] = []
        for item in arr {
          match item {
            @toml.TomlString(s) => result.push(s)
            _ => raise ConfigParseError("`authors` must be an array of strings")
          }
        }
        result
      }
      Some(_) => raise ConfigParseError("`authors` must be an array")
      None => []
    },
    description: match book.get("description") {
      Some(@toml.TomlString(s)) => Some(s)
      Some(_) => raise ConfigParseError("`description` must be a string")
      None => None
    },
    src: match book.get("src") {
      Some(@toml.TomlString(s)) => s
      Some(_) => raise ConfigParseError("`src` must be a string")
      None => "src"
    },
    output: match book.get("output") {
      Some(@toml.TomlString(s)) => s
      Some(_) => raise ConfigParseError("`output` must be a string")
      None => "build"
    },
    language: match book.get("language") {
      Some(@toml.TomlString(s)) => Some(s)
      Some(_) => raise ConfigParseError("`language` must be a string")
      None => None
    },
    text_direction: match book.get("text-direction") {
      Some(@toml.TomlString("ltr")) | None => LeftToRight
      Some(@toml.TomlString("rtl")) => RightToLeft
      Some(@toml.TomlString(s)) =>
        raise ConfigParseError(
          "`text-direction` must be \"ltr\" or \"rtl\", got: " + s,
        )
      Some(_) => raise ConfigParseError("`text-direction` must be a string")
    },
  }
}

///|
pub impl Default for BookConfig with default() -> BookConfig {
  {
    title: None,
    authors: [],
    description: None,
    src: "src",
    output: "build",
    language: Some("en"),
    text_direction: LeftToRight,
  }
}
