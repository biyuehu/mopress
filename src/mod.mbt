///|
fn load_config(silent~ : Bool = false) -> @config.BookConfig raise {
  let config = @config.file_name
    |> @fs.read_file_to_string
    |> @config.BookConfig::parse()
  if !silent {
    @c.chalk().color(Magenta).render("✝ Handing site: \{config.title}")
    |> println
    @c.chalk()
    .color(BlueBright)
    .render(
      "? Total preprocessors: \{config.extensions.preprocessors.length()} | Total transformers: \{config.extensions.transformers.length()} | Total import_css: \{config.extensions.import_css.length()} | Total import_js: \{config.extensions.import_js.length()} | Total use_css: \{config.extensions.use_css.length()} | Total use_js: \{config.extensions.use_js.length()} | Total inject_head: \{config.extensions.inject_head.length()} | Total inject_body: \{config.extensions.inject_body.length()}",
    )
    |> println
  }
  config
}

///|
fn handle_init() -> Unit raise {
  if @fs.path_exists(@config.file_name) {
    @c.chalk()
    .modifier(Bold)
    .color(Red)
    .render("Configuration already exists, skipping initialization.")
    |> println
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
  if !@fs.path_exists("plugins/preprocessors") {
    @fs.create_dir("plugins/preprocessors")
  }
  if !@fs.path_exists("plugins/transformers") {
    @fs.create_dir("plugins/transformers")
  }
  if !@fs.path_exists("plugins/runtime") {
    @fs.create_dir("plugins/runtime")
  }
  if !@fs.path_exists("plugins/preprocessors/github-alert.ts") {
    @fs.write_string_to_file(
      "plugins/preprocessors/github-alert.ts", book_plugins_preprocessers_github_alert_ts,
    )
  }
  println("Scaffolding default assets.")
  @fs.write_string_to_file(
    "templates/default.html", book_templates_default_html,
  )
  @fs.write_string_to_file("styles/index.css", book_styles_index_css)
  @fs.write_string_to_file("scripts/main.js", book_scripts_main_js)
  @fs.write_string_to_file("index.md", book_index_md)
  @fs.write_string_to_file("SUMMARY.md", book_summary_md)
  @c.chalk().modifier(Bold).color(Green).render("Initialization complete.")
  |> println
}

///|
fn handle_new(dir : String) -> Unit raise {
  println("Creating site-mode project: \{dir}")
  if @fs.path_exists(dir) {
    @c.chalk()
    .modifier(Bold)
    .color(Red)
    .render("Directory has already existed: \{dir}")
    |> println
    return
  }
  @fs.create_dir(dir)
  let path = @path.Path(dir)
  @fs.write_string_to_file(
    path.join("index.md") |> Show::to_string,
    site_index_md,
  )
  @fs.write_string_to_file(
    path.join("about.md") |> Show::to_string,
    site_about_md,
  )
  @fs.write_string_to_file(
    path.join("contact.md") |> Show::to_string,
    site_contact_md,
  )
  @fs.create_dir(path.join("styles") |> Show::to_string)
  @fs.write_string_to_file(
    path.join("styles/default.css") |> Show::to_string,
    site_styles_default_css,
  )
  @fs.create_dir(path.join("templates") |> Show::to_string)
  @fs.write_string_to_file(
    path.join("templates/default.html") |> Show::to_string,
    site_templates_default_html,
  )
  @fs.write_string_to_file(
    path.join("site.mbtx") |> Show::to_string,
    site_site_mbtx,
  )
  @c.chalk().modifier(Bold).color(Green).render("Creation complete.") |> println
}

///|
fn handle_help() -> Unit {
  println(
    (
      #|Usage: mopress <command>
      #|
      #|Commands:
      #|  build              Build the site
      #|  build --no-emit    Build without writing files to disk
      #|  build --analyze    Build and output performance breakdown analysis
      #|  build --analyze-json  Build and output analysis report in JSON format
      #|  explain            Print which files each rule matches
      #|  init               Initialize a new book-mode project
      #|  new                Create a new site-mode project
      #|  serve              Serve the site locally
      #|  version            Print the version number
      #|  help               Print this help message
    ),
  )
}

///|
async fn handle_build(
  no_emit~ : Bool = false,
  analyze~ : Bool = false,
  analyze_json~ : Bool = false,
) -> Unit {
  let config = load_config(silent=analyze_json)
  build_book(config, no_emit~, analyze~, analyze_json~)
}

///|
fn handle_explain() -> Unit raise {
  let config = load_config()
  explain_book(config)
}

///|
async fn handle_serve() -> Unit {
  let config = load_config()
  @core.mo_serve(config |> @core.Options::from_config)
}

///|
fn handle_version() -> Unit {
  @c.chalk()
  .modifier(Bold)
  .color(MagentaBright)
  .render("MoPress version: \{version} (\{build_time})")
  |> println
}

///|
async fn command_handler() -> Unit {
  let args = @env.args()
  match (if args.length() > 1 { args[1] } else { "" }) {
    "init" => handle_init()
    "new" =>
      if args.length() > 2 {
        handle_new(args[2])
      } else {
        @c.chalk().modifier(Bold).color(Red).render("Usage: mopress new <dir>")
        |> println
      }
    "build" =>
      handle_build(
        no_emit=args.contains("--no-emit"),
        analyze=args.contains("--analyze"),
        analyze_json=args.contains("--analyze-json"),
      )
    "serve" => handle_serve()
    "explain" => handle_explain()
    "version" => handle_version()
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
  silent~ : Bool = false,
) -> @core.Item[@core.Thing] {
  if !silent {
    "Rendering page \{raw.target}" |> println
  }
  let t_sep_0 = @async.now()
  let seprated = raw |> @core.separate_frontmatter
  @core.record_step_trace("separate_frontmatter", @async.now() - t_sep_0)

  let t_prep_0 = @async.now()
  let text = @bridge.run_markdown_preprocessors(
    config,
    seprated.data.1,
    raw.target,
  )
  @core.record_step_trace("run_preprocessors", @async.now() - t_prep_0)

  let t_parse_0 = @async.now()
  let parsed_md = (seprated.map(_ => text) |> @core.parse_markdown).data
  @core.record_step_trace("parse_markdown", @async.now() - t_parse_0)

  let t_trans_0 = @async.now()
  let ast = @bridge.run_markdown_transformers(config, parsed_md, raw.target)
  @core.record_step_trace("run_transformers", @async.now() - t_trans_0)

  // @block steps
  let t_render_0 = @async.now()
  let rendered_html = @core.render_markdown_and_frontmatter_from_ast(
    seprated.map(_ => ast),
    seprated.data.0,
  )
  @core.record_step_trace("render_markdown", @async.now() - t_render_0)

  let t_tpl_0 = @async.now()
  let item_with_vars = rendered_html
    |> @core.set_extension(".html")
    |> x => {
      let (prev, next) = summary.prev_next(x.location())
      x.add_vars(
        Map([
          (
            "section",
            summary.flatten(x.location(), config.base_url)
            |> @template.Value::from_json,
          ),
          ("site_title", config.title |> String),
          ("site_description", config.description |> String),
          ("site_keywords", config.keywords |> String),
          ("site_authors", config.authors.join(",") |> String),
          ("site_language", config.language |> String),
          ("favicon", config.favicon |> String),
          ("logo", config.logo |> String),
          ("repository", config.repository.unwrap_or("") |> String),
          ("src", config.src |> String),
          ("dest", config.dest |> String),
          ("base_url", config.base_url |> String),
          ("build_time", build_time |> String),
          ("version", version |> String),
          ("breadcrumb", summary.breadcrumb(x.location()) |> String),
          ("current", x.location() |> String),
          (
            "prev",
            prev
            .map(prev => {
              @template.Object(
                Map([
                  ("title", prev.0 |> String),
                  ("location", prev.1 |> String),
                ]),
              )
            })
            .unwrap_or(String("")),
          ),
          (
            "next",
            next
            .map(next => {
              @template.Object(
                Map([
                  ("title", next.0 |> String),
                  ("location", next.1 |> String),
                ]),
              )
            })
            .unwrap_or(String("")),
          ),
        ]),
      )
    }
  let templated = item_with_vars
    |> @core.load_and_apply_template(config.extensions.template)
  @core.record_step_trace("apply_template", @async.now() - t_tpl_0)

  let t_assets_0 = @async.now()
  let final_item = templated
    |> @core.import_css(config.extensions.import_css)
    |> @core.import_js(config.extensions.import_js)
    |> @core.use_css(config.extensions.use_css)
    |> @core.use_js(config.extensions.use_js)
    |> @core.inject_head(config.extensions.inject_head.join("\n"))
    |> @core.inject_body(config.extensions.inject_body.join("\n"))
    |> @core.unify
  @core.record_step_trace("inject_assets", @async.now() - t_assets_0)
  // @end
  final_item
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

///|
/// Builds the set of rules used by Book-mode builds. Extracted so that both
/// `build_book` and `explain_book` share the exact same rule set — the
/// `explain` report therefore never diverges from what a build would do.
fn build_book_rules(
  config : @config.BookConfig,
  summary : @summary.Summary,
  not_found_page : @core.Item[@core.Thing],
  silent~ : Bool = false,
) -> @core.Rules {
  [
    Glob(
      "SUMMARY.md",
      Text(raw => {
        raw
        |> @core.set_extension(".json")
        |> x => {
          x.map_with_raise(_ => {
            let metas = summary.collect_page_meta(config.src)
            let outputs : Array[(String, @core.Thing)] = [
              (
                "index.json",
                Json(summary.index_articles(config.src)).stringify()
                |> @core.Doc,
              ),
              ("404.html", not_found_page.data),
            ]
            if config.feed_enabled && config.site_url is Some(_) {
              outputs.push(
                (
                  "feed.xml",
                  @core.Doc(
                    @summary.generate_feed_xml(config, metas, build_time),
                  ),
                ),
              )
            }
            if config.sitemap_enabled {
              outputs.push(
                (
                  "sitemap.xml",
                  @core.Doc(@summary.generate_sitemap_xml(config, metas)),
                ),
              )
            }
            @core.Multiple(outputs)
          })
        }
      }),
    ),
    Glob(
      "**/*.md",
      Text(raw => raw |> process_markdown_page(config, summary, silent~)),
    ),
    Glob(
      "**/*.markdown",
      Text(raw => raw |> process_markdown_page(config, summary, silent~)),
    ),
    ..config.extensions.assets.map(glob => @core.Glob(glob, Copy)),
  ]
}

///|
/// Prints a report of how Book-mode rules match against files under
/// `config.src`, without building anything. The set of rules reported is
/// exactly what `build_book` would use.
pub fn explain_book(config : @config.BookConfig) -> Unit raise {
  println("Parsing SUMMARY.md")
  let summary = @fs.read_file_to_string(
      @path.Path(config.src).join("SUMMARY.md").to_string(),
    )
    |> @markdown.parse_markdown
    |> @summary.parse_summary()

  let stub = @core.Item::new(@core.Empty, "404.html")
  @core.explain(
    { src: config.src, dest: config.dest, },
    build_book_rules(config, summary, stub),
  )
}

///|
pub async fn build_book(
  config : @config.BookConfig,
  no_emit~ : Bool = false,
  analyze~ : Bool = false,
  analyze_json~ : Bool = false,
) -> Unit {
  if !analyze_json {
    println("Parsing SUMMARY.md")
  }
  let summary = @fs.read_file_to_string(
      @path.Path(config.src).join("SUMMARY.md").to_string(),
    )
    |> @markdown.parse_markdown
    |> @summary.parse_summary()

  let not_found_page = process_markdown_page(
    @core.Item::new(book_404_md, "404", extension=".md"),
    config,
    summary,
    silent=analyze_json,
  )

  @core.mo_build(
    { src: config.src, dest: config.dest, },
    build_book_rules(config, summary, not_found_page, silent=analyze_json),
    no_emit~,
    analyze~,
    analyze_json~,
  )
}
