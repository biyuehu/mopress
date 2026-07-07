///|
/// Top-level configuration for a mopress site/book.
///
/// This is the structure serialized to and parsed from the project's
/// configuration file (see `file_name`), and is threaded through the
/// entire build pipeline (see `mopress/main`'s `run` and
/// `process_markdown_page`, and `mopress/bridge`'s processor-running
/// functions) as shared, read-only context.
pub(all) struct BookConfig {
  /// The site's title, used both for `<title>`/template variables and as
  /// the default display name of the book.
  title : String
  /// A short description of the site, typically surfaced in template
  /// variables and metadata (e.g. an HTML `<meta name="description">` tag).
  description : String
  /// A comma- or space-separated (format defined by consuming templates)
  /// list of keywords for the site, surfaced via the `site_keywords`
  /// template variable.
  keywords : String
  /// Path (relative to the site root) to the favicon asset.
  favicon : String
  /// Path (relative to the site root) to the site's logo asset.
  logo : String
  /// The list of author names credited for the site's content.
  authors : Array[String]
  /// The site's primary language, e.g. as an HTML `lang` attribute value.
  language : String
  /// Path to the directory containing the site's source Markdown content
  /// and its `SUMMARY.md` table of contents, relative to the project root.
  repository : String?
  /// Feature toggles controlling optional built-in behavior such as
  /// syntax highlighting and MathJax support.
  src : String
  /// Path to the directory where the built site is written, relative to
  /// the project root.
  dest : String
  /// The base URL of the site, used to generate absolute URLs for
  /// links and assets. This is typically the site's domain name, defaulting
  /// to `/`.
  base_url : String
  /// Optional URL to the site's source repository, surfaced via the
  /// `repository` template variable when present (defaults to an empty
  /// string in templates when absent).
  features : FeaturesConfig
  /// Extension points for customizing the build: templates, asset
  /// injection, and the external preprocessor/transformer command
  /// pipelines.
  extension : ExtensionConfig
} derive(Eq, ToJson, @debug.Debug)

///|
/// Toggles for optional, built-in rendering features.
pub(all) struct FeaturesConfig {
  /// Whether syntax highlighting of fenced code blocks is enabled.
  highlight_enabled : Bool
  /// The name of the syntax highlighting theme to use when
  /// `highlight_enabled` is `true`.
  highlight_theme : String
  /// Whether MathJax rendering of mathematical notation is enabled.
  mathjax_enabled : Bool
} derive(Eq, ToJson, @debug.Debug)

///|
/// Configuration for extension points that customize how a site is built:
/// which template to render pages with, which static assets to copy
/// verbatim, which CSS/JS to inject or import, and which external
/// preprocessor/transformer commands to run over Markdown content.
pub(all) struct ExtensionConfig {
  /// Path to the HTML template file used to render every page (see
  /// `@core.load_and_apply_template` as used by `process_markdown_page`).
  template : String
  /// Glob patterns (relative to `BookConfig.src`) identifying additional
  /// static asset files/directories to copy into the output verbatim,
  /// alongside the rendered Markdown pages.
  assets : Array[String]
  /// Raw HTML snippets injected into the `<head>` of every rendered page.
  inject_head : Array[String]
  /// Raw HTML snippets injected at the end of the `<body>` of every
  /// rendered page.
  inject_body : Array[String]
  /// Raw JavaScript code to be injected as inline `<script>` blocks just
  /// before `</body>` on every page (see `@core.use_js`), one `<script>`
  /// tag per array element.
  use_js : Array[String]
  /// Raw CSS code to be injected as inline `<style>` blocks just before
  /// `</head>` on every page (see `@core.use_css`), one `<style>` tag per
  /// array element.
  use_css : Array[String]
  /// Paths/URLs to external CSS files to be imported via `<link>` (see
  /// `@core.import_css`) on every page, rather than inlined.
  import_css : Array[String]
  /// Paths/URLs to external JavaScript files to be imported via
  /// `<script src>` (see `@core.import_js`) on every page, rather than
  /// inlined.
  import_js : Array[String]
  /// Commands (see `@bridge.run_markdown_preprocessors`) to run, in order,
  /// over each page's raw Markdown text before it is parsed into an AST.
  preprocessors : Array[String]
  /// Commands (see `@bridge.run_markdown_transformers`) to run, in order,
  /// over each page's parsed Markdown AST before it is rendered to HTML.
  transformers : Array[String]
} derive(Eq, ToJson, @debug.Debug)

///|
/// Error raised when a configuration file's contents cannot be parsed into
/// a `BookConfig`. The associated `String` carries a human-readable
/// description of the parse failure.
pub suberror ConfigParseError {
  ConfigParseError(String)
} derive(Eq, Debug)

///|
/// The file name (relative to the current working directory) that mopress
/// looks for, reads, and writes as the project's configuration file, e.g.
/// when running `mopress init` or when loading configuration before a
/// `build`/`serve` command.
pub let file_name = "sena.toml"

///|
/// Desugars the `features` preset into their corresponding low-level
/// `extension` fields (`use_js`, `use_css`, `inject_head`, `inject_body`,
/// `import_css`, `import_js`, etc.), returning a new `BookConfig` with
/// those `extension` fields populated accordingly.
///
/// This is automatically invoked at the end of `BookConfig::parse`, so
/// callers loading configuration through `parse` do not need to call this
/// separately; it is exposed primarily for cases where a `BookConfig` is
/// constructed or mutated by other means and needs the same desugaring
/// applied afterwards.
pub fn BookConfig::apply_feature_presets(self : BookConfig) -> BookConfig {
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
/// Serializes this configuration to its TOML string representation, e.g.
/// for writing out to the project's configuration file (see `file_name`)
/// during `mopress init` or when persisting configuration changes.
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
/// Parses a `BookConfig` from its serialized (TOML) string representation.
///
/// Raises `ConfigParseError` if `input` is not valid TOML, or is valid TOML
/// that does not match the expected `BookConfig` shape (e.g. missing
/// required fields or fields of the wrong type).
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
    repository: read_optional_string(root, "repository"),
    src: read_string(root, "src", default.src),
    dest: read_string(root, "dest", default.dest),
    base_url: read_string(root, "base_url", default.base_url),
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
  }.apply_feature_presets()
}

///|
/// The default configuration used to scaffold a new project, e.g. when
/// running `mopress init` and no configuration file yet exists.
pub impl Default for BookConfig with fn default() -> BookConfig {
  {
    title: "MoPress Doc",
    description: "A modern documentation and static site generator for the MoonBit ecosystem, inspired by mdBook and Hakyll",
    keywords: "Documentation,Static Site Generator,SSG,MoonBit,MoonLang,Moon,Functional,Haskell,mdBook,Hakyll",
    favicon: "https://himeno-sena.com/favicon.ico",
    logo: "https://himeno-sena.com/favicon.ico",
    authors: ["Himeno Sena"],
    language: "en",
    repository: Some("https://github.com/biyuehu/mopress"),
    src: "./",
    dest: "./dest",
    base_url: "/",
    features: FeaturesConfig::default(),
    extension: ExtensionConfig::default(),
  }
}

///|
/// The default feature configuration used to scaffold a new project.
///
/// # Uncertainty
/// I don't know the exact default values (e.g. whether highlighting/MathJax
/// are on or off by default, or what the default theme name is) without
/// seeing the implementation, so I haven't asserted specific defaults in
/// this comment.
pub impl Default for FeaturesConfig with fn default() -> FeaturesConfig {
  {
    highlight_enabled: false,
    highlight_theme: "github",
    mathjax_enabled: false,
  }
}

///|
/// The default extension configuration used to scaffold a new project,
/// with no custom preprocessors/transformers and no injected assets beyond
/// the default template.
pub impl Default for ExtensionConfig with fn default() -> ExtensionConfig {
  {
    template: "templates/default.html",
    assets: ["images/**/*", "styles/**/*", "scripts/**/*"],
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
