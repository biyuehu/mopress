///|
pub async fn mopress(
  rules : Rules,
  options? : Options = Options::default(),
) -> Unit {
  let args = @env.args()
  let cmd = if args.length() > 1 { args[1] } else { "help" }
  match cmd {
    "build" => options |> mo_build(rules)
    "init" => options |> mo_init()
    "serve" => options |> mo_serve(rules)
    "help" | _ => mo_help()
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
fn mo_init(options : Options) -> Unit raise {
  ignore(options)
  fail("`mopress init` is not implemented yet")
}

///|
async fn mo_serve(options : Options, rules : Rules) -> Unit {
  options |> mo_build(rules)
  serve_static_dir(options.dest)
}

///|
fn mo_help() -> Unit {
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
fn mo_build(options : Options, rules : Rules) -> Unit raise {
  for rule in rules {
    for
      path in (match rule {
        Glob(glob, _) => @glob.scan_files(options.src, glob)
        Guard(glob, f, _) => @glob.scan_files_with(options.src, glob, f)
      }) {
      let { data, extension } = rule.mode().run(path)
      let target = path[options.src.length() + 1:] |> Show::to_string
      data.write(
        options.dest,
        target
        .rev_find(".")
        .map(index => Show::to_string(target[0:index]) + extension)
        .unwrap_or_else(() => target + extension),
      )
    }
  }
}

///|
async test {
  // Test mopress
}
