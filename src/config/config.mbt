///|
pub(all) struct BookConfig {
  title : String
  description : String
  keywords : String
  favicon : String
  logo : String
  authors : Array[String]
  language : String
  src : String
  dest : String
  repository : String?
  features : FeaturesConfig
  extension : ExtensionConfig
} derive(Eq, Debug, ToJson)

///|
pub(all) struct FeaturesConfig {
  highlight_enabled : Bool
  highlight_theme : String
  mathjax_enabled : Bool
} derive(Eq, Debug, ToJson)

///|
pub(all) struct ExtensionConfig {
  template : String
  assets : Array[String]
  inject_head : Array[String]
  inject_body : Array[String]
  use_js : Array[String]
  use_css : Array[String]
  import_css : Array[String]
  import_js : Array[String]
  preprocessors : Array[String]
  transformers : Array[String]
} derive(Eq, Debug, ToJson)

///|
pub suberror ConfigParseError {
  ConfigParseError(String)
} derive(Eq, Debug)

///|
pub let file_name = "sena.toml"

///|
pub fn BookConfig::extract_features(self : BookConfig) -> BookConfig {
  if self.features.highlight_enabled {
    self.extension.import_css.push(
      "https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.11.1/styles/\{self.features.highlight_theme}.min.css",
    )
    self.extension.import_js.push(
      "https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.11.1/highlight.min.js",
    )
    self.extension.use_js.push("hljs.highlightAll()")
  }
  if self.features.mathjax_enabled {
    self.extension.inject_head.push(
      (
        #|<script>MathJax={tex:{inlineMath:[['$','$']],displayMath:[['$$','$$']]}};</script>
        #|<script src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-chtml.min.js"></script>
      ),
    )
  }
  self
}

///|
pub fn BookConfig::to_toml(self : BookConfig) -> String {
  let b = StringBuilder::new()
  b.write_string("title = \{toml_string(self.title)}\n")
  b.write_string("description = \{toml_string(self.description)}\n")
  b.write_string("keywords = \{toml_string(self.keywords)}\n")
  b.write_string("favicon = \{toml_string(self.favicon)}\n")
  b.write_string("logo = \{toml_string(self.logo)}\n")
  b.write_string("authors = \{toml_string_array(self.authors)}\n")
  b.write_string("language = \{toml_string(self.language)}\n")
  b.write_string("src = \{toml_string(self.src)}\n")
  b.write_string("dest = \{toml_string(self.dest)}\n")
  match self.repository {
    Some(r) => b.write_string("repository = \{toml_string(r)}\n")
    None => ()
  }
  b.write_string("\n[features]\n")
  b.write_string("highlight-enabled = \{self.features.highlight_enabled}\n")
  b.write_string(
    "highlight-theme = \{toml_string(self.features.highlight_theme)}\n",
  )
  b.write_string("mathjax-enabled = \{self.features.mathjax_enabled}\n")
  b.write_string("\n[extension]\n")
  b.write_string("template = \{toml_string(self.extension.template)}\n")
  b.write_string("assets = \{toml_string_array(self.extension.assets)}\n")
  b.write_string(
    "inject-head = \{toml_string_array(self.extension.inject_head)}\n",
  )
  b.write_string(
    "inject-body = \{toml_string_array(self.extension.inject_body)}\n",
  )
  b.write_string("use-js = \{toml_string_array(self.extension.use_js)}\n")
  b.write_string("use-css = \{toml_string_array(self.extension.use_css)}\n")
  b.write_string(
    "import-css = \{toml_string_array(self.extension.import_css)}\n",
  )
  b.write_string("import-js = \{toml_string_array(self.extension.import_js)}\n")
  b.write_string(
    "preprocessors = \{toml_string_array(self.extension.preprocessors)}\n",
  )
  b.write_string(
    "transformers = \{toml_string_array(self.extension.transformers)}\n",
  )
  b.to_string()
}

///|
fn toml_string(s : String) -> String {
  "\"\{s.replace(old="\\",new= "\\\\").replace(old="\"", new="\\\"")}\""
}

///|
fn toml_string_array(arr : Array[String]) -> String {
  "[\{arr.map(toml_string).join(", ")}]"
}

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
  let features = read_table(root, "features", true)
  let extension = read_table(root, "extension", true)
  let default = BookConfig::default()
  {
    title: read_string_nonempty(root, "title"),
    authors: read_string_array(root, "authors"),
    description: read_string(root, "description", default.description),
    keywords: read_string(root, "keywords", default.keywords),
    favicon: read_string(root, "favicon", default.favicon),
    logo: read_string(root, "logo", default.logo),
    language: read_string(root, "language", default.language),
    src: read_string(root, "src", default.src),
    dest: read_string(root, "dest", default.dest),
    repository: read_optional_string(root, "repository"),
    features: {
      highlight_enabled: read_bool(features, "highlight-enabled"),
      highlight_theme: read_string(
        features,
        "highlight-theme",
        default.features.highlight_theme,
      ),
      mathjax_enabled: read_bool(features, "mathjax-enabled"),
    },
    extension: {
      template: read_string(extension, "template", default.extension.template),
      assets: read_string_array(extension, "assets"),
      inject_head: read_string_array(extension, "inject-head"),
      inject_body: read_string_array(extension, "inject-body"),
      use_js: read_string_array(extension, "use-js"),
      use_css: read_string_array(extension, "use-css"),
      import_css: read_string_array(extension, "import-css"),
      import_js: read_string_array(extension, "import-js"),
      preprocessors: read_string_array(extension, "preprocessors"),
      transformers: read_string_array(extension, "transformers"),
    },
  }.extract_features()
}

///|
pub impl Default for BookConfig with fn default() -> BookConfig {
  {
    title: "MoPress Doc",
    description: "A modern documentation and static site generator for the MoonBit ecosystem, inspired by mdBook and Hakyll",
    keywords: "Documentation,Static Site Generator,SSG,MoonBit,MoonLang,Moon,Functional,Haskell,mdBook,Hakyll",
    favicon: "https://himeno-sena.com/favicon.ico",
    logo: "https://himeno-sena.com/favicon.ico",
    authors: ["Himeno Sena"],
    language: "en",
    src: "./",
    dest: "./dest",
    repository: Some("https://github.com/biyuehu/mopress"),
    features: FeaturesConfig::default(),
    extension: ExtensionConfig::default(),
  }
}

///|
pub impl Default for FeaturesConfig with fn default() -> FeaturesConfig {
  {
    highlight_enabled: false,
    highlight_theme: "github",
    mathjax_enabled: false,
  }
}

///|
pub impl Default for ExtensionConfig with fn default() -> ExtensionConfig {
  {
    template: "templates/default.html",
    assets: ["images/*", "styles/*", "scripts/*"],
    inject_head: [],
    inject_body: [],
    use_js: ["console.log('Hello, MoPress!');"],
    use_css: [],
    import_css: [],
    import_js: [],
    preprocessors: [],
    transformers: [],
  }
}

///|
fn read_table(
  root : Map[String, @toml.TomlValue],
  key : String,
  optional : Bool,
) -> Map[String, @toml.TomlValue] raise ConfigParseError {
  match root.get(key) {
    Some(@toml.TomlTable(t)) => t
    Some(_) => raise ConfigParseError("[\{key}] must be a table")
    None =>
      if optional {
        Map([])
      } else {
        raise ConfigParseError("Missing required table [\{key}]")
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
    Some(_) => raise ConfigParseError("`\{key}` must be a string")
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
) -> Bool raise ConfigParseError {
  match table.get(key) {
    Some(@toml.TomlBoolean(b)) => b
    Some(_) => raise ConfigParseError("`\{key}` must be a boolean")
    _ => false
  }
}

///|
fn read_string_nonempty(
  table : Map[String, @toml.TomlValue],
  key : String,
) -> String raise ConfigParseError {
  match read_optional_string(table, key) {
    Some(s) =>
      if s == "" {
        raise ConfigParseError("`\{key}` must be a non-empty string")
      } else {
        s
      }
    None => raise ConfigParseError("Missing required string `\{key}`")
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
          _ => raise ConfigParseError("`\{key}` must be an array of strings")
        }
      }
      result
    }
    Some(_) => raise ConfigParseError("`\{key}` must be an array")
    None => []
  }
}
