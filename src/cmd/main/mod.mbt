///|
fn load_config() -> @config.BookConfig raise {
  @config.file_name |> @fs.read_file_to_string |> @config.BookConfig::parse()
}

///|
fn handle_init() -> Unit raise {
  if @fs.path_exists(@config.file_name) {
    println("Config file already exists, skipping initialization.")
    return
  }
  @fs.write_string_to_file(
    @config.file_name,
    @config.BookConfig::default().to_toml(),
  )
  if !@fs.path_exists("templates") {
    @fs.create_dir("templates")
  }
  if !@fs.path_exists("styles") {
    @fs.create_dir("styles")
  }
  if !@fs.path_exists("scripts") {
    @fs.create_dir("scripts")
  }
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
fn handle_build() -> Unit raise {
  load_config() |> run
}

///|
async fn handle_serve() -> Unit {
  @core.mo_serve(load_config() |> @core.Options::from_config)
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
pub fn step_markdown_raw(
  raw : @core.Item[String],
  config : @config.BookConfig,
  summary : @summary.Summary,
) -> @core.Item[@core.Thing] raise {
  raw
  |> @core.set_extension(".html")
  |> @core.render_markdown_and_frontmatter
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
pub fn run(config : @config.BookConfig) -> Unit raise {
  let summary = @fs.read_file_to_string(
      @path.Path(config.src).join("SUMMARY.md").to_string(),
    )
    |> @markdown.parse_markdown
    |> @summary.parse_summary

  @core.mo_build(
    { src: config.src, dest: config.dest },
    [
      Glob(
        "SUMMARY.md",
        Text(raw => {
          raw
          |> @core.set_extension(".json")
          |> x => {
            x.map_with_eff(_ => {
              @core.Multiple([
                (
                  "index.json",
                  summary.index_articles(config.src).to_json().stringify()
                  |> @core.Doc,
                ),
                (
                  "404.html",
                  step_markdown_raw(
                    @core.Item::new(
                      "---\ntitle: 404\n---\nYour page can not be found...",
                      "404",
                      extension=".md",
                    ),
                    config,
                    summary,
                  ).data,
                ),
              ])
            })
          }
        }),
      ),
      Glob("*.markdown", Text(raw => raw |> step_markdown_raw(config, summary))),
      ..config.extension.assets.map(glob => @core.Glob(glob, Copy)),
    ],
  )
}
