///|
/// Convenience entry point that runs `mo_build` with the given `rules`
/// against `options` (defaulting to `Options::default()` if not
/// provided).
pub async fn mopress(
  rules : Rules,
  options? : Options = Options::default(),
) -> Unit {
  let args = @env.args()
  let cmd = if args.length() > 1 { args[1] } else { "" }
  match cmd {
    "build" => options |> mo_build(rules)
    "serve" => options |> mo_serve
    opts => println("Unknown command: \{opts}")
  }
}

///|
/// Like `mopress`, but allows deriving the set of rules from some
/// intermediate value `E` computed from `options`: `setup` is called with
/// `options` to produce a value of type `E`, which is then passed
/// (together with `options`) to `build_rules` to produce the final list of
/// rules to run.
///
/// This is useful when the rule set itself depends on some computation or
/// resource derived from `options` (e.g. parsed configuration or a parsed
/// summary/table of contents) that would otherwise need to be recomputed
/// independently by the caller before constructing `rules`.
pub async fn[E] mopress_with(
  options? : Options = Options::default(),
  init : (Options) -> E,
  rules : (Options, E) -> Rules,
) -> Unit {
  mopress(options |> rules(options |> init), options~)
}

///|
/// Serves the site described by `options` locally, e.g. for development
/// and live preview, rather than writing output to disk.
pub async fn mo_serve(options : Options) -> Unit {
  serve_static_dir(options.dest)
}

///|
/// Runs the build pipeline described by `rules` against the given
/// `options` (source/destination directories), writing all resulting
/// output to `options.dest`.
///
/// Each rule's glob pattern (and, for `Guard` rules, its predicate) is
/// matched against files discovered under `options.src`; matching files
/// are processed according to the rule's `Mode` and the result is written
/// to disk via `Thing::write`.
pub async fn mo_build(options : Options, rules : Rules) -> Unit {
  println("Emitting files from \{options.src} to \{options.dest}")
  for rule in rules {
    for
      path in (match rule {
        Glob(glob, _) => @glob.scan_files(options.src, glob)
        Guard(glob, f, _) => @glob.scan_files_with(options.src, glob, f)
      }) {
      let item = rule.mode().run(options, path)
      item.data.write(options.dest, item.location())
    }
  }
  println("Build finished.")
}
