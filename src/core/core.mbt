///|
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
pub async fn[E] mopress_with(
  options? : Options = Options::default(),
  init : (Options) -> E,
  rules : (Options, E) -> Rules,
) -> Unit {
  mopress(options |> rules(options |> init), options~)
}

///|
pub async fn mo_serve(options : Options) -> Unit {
  serve_static_dir(options.dest)
}

///|
pub async fn mo_build(options : Options, rules : Rules) -> Unit {
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
}
