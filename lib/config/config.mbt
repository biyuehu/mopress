///|
pub(all) struct BookConfig {
  title : String?
  authors : Array[String]
  description : String?
  src : String
  language : String?
  text_direction : TextDirection
  build : BuildConfig
} derive(Eq, Debug)

///|
pub(all) struct BuildConfig {
  build_dir : String
  create_missing : Bool
} derive(Eq, Debug)

///|
pub(all) enum TextDirection {
  LeftToRight
  RightToLeft
} derive(Eq, Debug)

///|
pub suberror ConfigParseError {
  ConfigParseError(String)
} derive(Eq, Debug)

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
  let book = read_table(root, "book", true)
  let build = read_table(root, "build", true)
  let config = {
    title: read_optional_string(book, "title"),
    authors: read_string_array(book, "authors"),
    description: read_optional_string(book, "description"),
    src: read_string(book, "src", "src"),
    language: read_optional_string(book, "language"),
    text_direction: read_text_direction(book),
    build: {
      build_dir: read_string(build, "build-dir", "build"),
      create_missing: read_bool(build, "create-missing", true),
    },
  }
  config.validate()
  config
}

///|
pub fn BookConfig::validate(self : BookConfig) -> Unit raise ConfigParseError {
  validate_optional_non_empty("book.title", self.title)
  validate_string_array("book.authors", self.authors)
  validate_optional_non_empty("book.description", self.description)
  validate_non_empty("book.src", self.src)
  validate_optional_non_empty("book.language", self.language)
  validate_non_empty("build.build-dir", self.build.build_dir)
}

///|
pub impl Default for BookConfig with default() -> BookConfig {
  {
    title: None,
    authors: [],
    description: None,
    src: "src",
    language: Some("en"),
    text_direction: LeftToRight,
    build: BuildConfig::default(),
  }
}

///|
pub impl Default for BuildConfig with default() -> BuildConfig {
  { build_dir: "build", create_missing: true }
}

///|
fn read_table(
  root : Map[String, @toml.TomlValue],
  key : String,
  optional : Bool,
) -> Map[String, @toml.TomlValue] raise ConfigParseError {
  match root.get(key) {
    Some(@toml.TomlTable(t)) => t
    Some(_) => raise ConfigParseError("[" + key + "] must be a table")
    None =>
      if optional {
        Map([])
      } else {
        raise ConfigParseError("Missing required table [" + key + "]")
      }
  }
}

///|
fn read_optional_string(
  table : Map[String, @toml.TomlValue],
  key : String,
) -> String? raise ConfigParseError {
  match table.get(key) {
    Some(@toml.TomlString(s)) => Some(s)
    Some(_) => raise ConfigParseError("`" + key + "` must be a string")
    None => None
  }
}

///|
fn read_string(
  table : Map[String, @toml.TomlValue],
  key : String,
  default : String,
) -> String raise ConfigParseError {
  match read_optional_string(table, key) {
    Some(s) => s
    None => default
  }
}

///|
fn read_bool(
  table : Map[String, @toml.TomlValue],
  key : String,
  default : Bool,
) -> Bool raise ConfigParseError {
  match table.get(key) {
    Some(@toml.TomlBoolean(b)) => b
    Some(_) => raise ConfigParseError("`" + key + "` must be a boolean")
    None => default
  }
}

///|
fn read_string_array(
  table : Map[String, @toml.TomlValue],
  key : String,
) -> Array[String] raise ConfigParseError {
  match table.get(key) {
    Some(@toml.TomlArray(arr)) => {
      let result : Array[String] = []
      for item in arr {
        match item {
          @toml.TomlString(s) => result.push(s)
          _ =>
            raise ConfigParseError("`" + key + "` must be an array of strings")
        }
      }
      result
    }
    Some(_) => raise ConfigParseError("`" + key + "` must be an array")
    None => []
  }
}

///|
fn read_text_direction(
  book : Map[String, @toml.TomlValue],
) -> TextDirection raise ConfigParseError {
  match book.get("text-direction") {
    Some(@toml.TomlString("ltr")) | None => LeftToRight
    Some(@toml.TomlString("rtl")) => RightToLeft
    Some(@toml.TomlString(s)) =>
      raise ConfigParseError(
        "`text-direction` must be \"ltr\" or \"rtl\", got: " + s,
      )
    Some(_) => raise ConfigParseError("`text-direction` must be a string")
  }
}

///|
fn validate_optional_non_empty(
  key : String,
  value : String?,
) -> Unit raise ConfigParseError {
  match value {
    Some(s) => validate_non_empty(key, s)
    None => ()
  }
}

///|
fn validate_string_array(
  key : String,
  values : Array[String],
) -> Unit raise ConfigParseError {
  for value in values {
    validate_non_empty(key, value)
  }
}

///|
fn validate_non_empty(
  key : String,
  value : String,
) -> Unit raise ConfigParseError {
  if value.trim() == "" {
    raise ConfigParseError("`" + key + "` must not be empty")
  }
}
