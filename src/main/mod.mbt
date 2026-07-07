///|
fn load_config() -> @config.BookConfig raise {
  @config.file_name |> @fs.read_file_to_string |> @config.BookConfig::parse()
}

///|
fn handle_init() -> Unit raise {
  if @fs.path_exists(@config.file_name) {
    println("Configuration already exists, skipping initialization.")
    return
  }
  println("Generating configuration: " + @config.file_name)
  @fs.write_string_to_file(
    @config.file_name,
    @config.BookConfig::default().to_toml(),
  )
  if !@fs.path_exists("templates") {
    println("Creating templates/")
    @fs.create_dir("templates")
  }
  if !@fs.path_exists("styles") {
    println("Creating styles/")
    @fs.create_dir("styles")
  }
  if !@fs.path_exists("scripts") {
    println("Creating scripts/")
    @fs.create_dir("scripts")
  }
  if !@fs.path_exists("plugins") {
    println("Creating plugins/")
    @fs.create_dir("plugins")
  }
  if !@fs.path_exists("plugins/preprocessers") {
    @fs.create_dir("plugins/preprocessers")
  }
  if !@fs.path_exists("plugins/transformers") {
    @fs.create_dir("plugins/transformers")
  }
  if !@fs.path_exists("plugins/external") {
    @fs.create_dir("plugins/external")
  }
  if !@fs.path_exists("plugins/preprocessors/github-alert.ts") {
    @fs.write_string_to_file(
      "plugins/preprocessers/github-alert.ts", plugins_preprocessers_github_alert_ts,
    )
  }
  println("Scaffolding default assets.")
  @fs.write_string_to_file("templates/default.html", templates_default_html)
  @fs.write_string_to_file("styles/index.css", styles_index_css)
  @fs.write_string_to_file("scripts/main.js", scripts_main_js)
  println("Initialization complete.")
}

///|
fn handle_help() -> Unit {
  println(
    (
      #|Usage: mopress <command>
      #|
      #|Commands:
      #|  build    Build the site
      #|  init     Initialize a new project
      #|  serve    Serve the site locally
      #|  help     Print this help message
    ),
  )
}

///|
async fn handle_build() -> Unit {
  println("Building site.")
  load_config() |> build_book
}

///|
async fn handle_serve() -> Unit {
  let config = load_config()
  @core.mo_serve(config |> @core.Options::from_config)
}

///|
async fn command_handler() -> Unit {
  let args = @env.args()
  match (if args.length() > 1 { args[1] } else { "" }) {
    "init" => handle_init()
    "build" => handle_build()
    "serve" => handle_serve()
    _ => handle_help()
  }
}

///|
/// Processes a single raw content item (typically a Markdown file, but also
/// used for synthetic pages such as the 404 fallback) into its final
/// rendered `Thing`, ready to be written to disk.
///
/// The pipeline performed here is:
/// 1. Separate YAML frontmatter from the raw Markdown body.
/// 2. Run all configured `markdown-text` preprocessors on the raw text
///    (see `@bridge.run_markdown_preprocessors`).
/// 3. Parse the preprocessed text into a Markdown AST.
/// 4. Run all configured `markdown-ast` transformers on the AST
///    (see `@bridge.run_markdown_transformers`).
/// 5. Render the transformed AST (together with the original frontmatter)
///    into HTML, and switch the item's extension to `.html`.
/// 6. Inject a standard set of template variables derived from `config` and
///    `summary` (site metadata, breadcrumb, prev/next navigation, etc.).
/// 7. Apply the configured HTML template, then inject/import the configured
///    CSS and JS assets and head/body snippets.
///
/// `summary` is used to resolve the item's position within the site's
/// table of contents, in order to compute breadcrumbs and previous/next
/// links; it is expected to have already been parsed from the book's
/// `SUMMARY.md` before calling this function.
pub async fn process_markdown_page(
  raw : @core.Item[String],
  config : @config.BookConfig,
  summary : @summary.Summary,
) -> @core.Item[@core.Thing] {
  let seprated = raw |> @core.separate_frontmatter
  let text = @bridge.run_markdown_preprocessors(config, seprated.data.1)
  let ast = @bridge.run_markdown_transformers(
    config,
    (seprated.map(_ => text) |> @core.parse_markdown).data,
  )
  @core.render_markdown_and_frontmatter_from_ast(
    seprated.map(_ => ast),
    seprated.data.0,
  )
  |> @core.set_extension(".html")
  |> x => {
    let (prev, next) = summary.prev_next(x.location())
    x.add_vars(
      Map([
        ("section", summary.flatten(x.location()) |> @template.Value::from_json),
        ("site_title", config.title |> String),
        ("site_description", config.description |> String),
        ("site_keywords", config.keywords |> String),
        ("site_authors", config.authors.join(",") |> String),
        ("site_language", config.language |> String),
        ("favicon", config.favicon |> String),
        ("logo", config.logo |> String),
        ("repository", config.repository.unwrap_or("") |> String),
        ("breadcrumb", summary.breadcrumb(x.location()) |> String),
        ("version", "v1.0.0" |> String),
        (
          "prev",
          prev
          .map(prev => {
            @template.Object(
              Map([("title", prev.0 |> String), ("location", prev.1 |> String)]),
            )
          })
          .unwrap_or(String("")),
        ),
        (
          "next",
          next
          .map(next => {
            @template.Object(
              Map([("title", next.0 |> String), ("location", next.1 |> String)]),
            )
          })
          .unwrap_or(String("")),
        ),
      ]),
    )
  }
  |> @core.load_and_apply_template(config.extension.template)
  |> @core.import_css(config.extension.import_css)
  |> @core.import_js(config.extension.import_js)
  |> @core.use_css(config.extension.use_css)
  |> @core.use_js(config.extension.use_js)
  |> @core.inject_head(config.extension.inject_head.join("\n"))
  |> @core.inject_body(config.extension.inject_body.join("\n"))
  |> @core.identify
}

///|
/// Runs the full site build pipeline for the given book configuration.
///
/// This orchestrates the entire build process: it parses `SUMMARY.md` under
/// `config.src` to build the site's navigation structure, renders a 404
/// fallback page, and then walks the source directory to render every
/// Markdown article (`*.markdown`) into its final HTML output alongside any
/// configured static assets. All output is written under `config.dest`.
///
/// This function does not return a value; build failures are expected to
/// surface as raised errors from the underlying steps (config loading,
/// file I/O, markdown processing, or templating) rather than through a
/// return value.
pub async fn build_book(config : @config.BookConfig) -> Unit {
  println("Parsing SUMMARY.md")
  let summary = @fs.read_file_to_string(
      @path.Path(config.src).join("SUMMARY.md").to_string(),
    )
    |> @markdown.parse_markdown
    |> @summary.parse_summary

  println("Rendering 404 page")
  let not_found_page = process_markdown_page(
    @core.Item::new(
      "---\ntitle: 404\n---\nYour page can not be found...",
      "404",
      extension=".md",
    ),
    config,
    summary,
  )

  @core.mo_build(
    { src: config.src, dest: config.dest },
    [
      Glob(
        "SUMMARY.md",
        Text(raw => {
          raw
          |> @core.set_extension(".json")
          |> x => {
            x.map_with_raise(_ => {
              @core.Multiple([
                (
                  "index.json",
                  summary.index_articles(config.src).to_json().stringify()
                  |> @core.Doc,
                ),
                ("404.html", not_found_page.data),
              ])
            })
          }
        }),
      ),
      Glob("*.md", Text(raw => raw |> process_markdown_page(config, summary))),
      Glob(
        "*.markdown",
        Text(raw => raw |> process_markdown_page(config, summary)),
      ),
      ..config.extension.assets.map(glob => @core.Glob(glob, Copy)),
    ],
  )
}
