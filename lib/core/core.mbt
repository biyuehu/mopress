///|
pub fn mopress(options : Options, rules : Rules) -> Unit raise {
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
pub fn[E] mopress_with(
  options : Options,
  init : (Options) -> E,
  rules : (Options, E) -> Rules,
) -> Unit raise {
  options |> mopress(options |> rules(options |> init))
}

///|
fn mo_init(options : Options) -> Unit raise {
  ...
}

///|
fn mo_serve(options : Options, rules : Rules) -> Unit raise {
  ...
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
    let (paths, mode) = match rule {
      One(Glob(glob), mode) => (@glob.scan_files(glob, options.src)[0:1], mode)
      One(Guard(glob, f), mode) =>
        (@glob.scan_files_with(glob, options.src, f)[0:1], mode)
      All(Glob(glob), mode) => (@glob.scan_files(glob, options.src), mode)
      All(Guard(glob, f), mode) =>
        (@glob.scan_files_with(glob, options.src, f), mode)
    }
    for path in paths {
      let { data, extension } = mode.run(path)
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
test {
  mopress({ src: "lib", dest: "build" }, [])
}
