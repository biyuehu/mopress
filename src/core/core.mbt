///|
/// Convenience entry point that runs `mo_build` with the given `rules`
/// against `options` (defaulting to `Options::default()` if not
/// provided).
pub async fn mopress(
  rules : Rules,
  options~ : Options = Options::default(),
) -> Unit {
  let args = @env.args()
  let cmd = if args.length() > 1 { args[1] } else { "" }
  let no_emit = args.length() > 2 && args[2] == "--no-emit"
  match cmd {
    "build" => options |> mo_build(rules, no_emit~)
    "serve" => options |> mo_serve
    "explain" => options |> explain(rules)
    opts =>
      @c.chalk().modifier(Bold).color(Red).render("Unknown command: \{opts}")
      |> println
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
  options~ : Options = Options::default(),
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
pub async fn mo_build(
  options : Options,
  rules : Rules,
  no_emit~ : Bool = false,
) -> Unit {
  if no_emit {
    println("Dry-run (no emit) from \{options.src}")
  } else {
    println("Emitting files from \{options.src} to \{options.dest}")
  }
  for rule in rules {
    for path in rule.match_paths(options.src).0 {
      let item = rule.handler().run(options, path)
      if no_emit {
        println("  would write: \{item.location()}")
      } else {
        item.data.write(options.dest, item.location())
      }
    }
  }
  if no_emit {
    println("Dry-run complete (no files written).")
  } else {
    @c.chalk().modifier(Bold).color(Green).render("√ Build finished.")
    |> println
  }
}

///|
/// Computes how `rules` match against files under `options.src`, without
/// executing any handler and without writing any file.
///
/// This is the pure computation behind `explain`; it is exposed so that
/// callers (e.g. CI checks, tests, custom reporting tools) can inspect the
/// result structurally instead of parsing printed output.
///
/// It runs the same matching logic (`Rule::match_paths`) that `mo_build`
/// uses, so the report never diverges from what a build would actually do.
///
/// Raises `@fs.IOError` if `options.src` (or any subdirectory of it)
/// cannot be read.
pub fn compute_explain_report(
  options : Options,
  rules : Rules,
) -> ExplainReport raise @fs.IOError {
  let matches : Array[RuleMatch] = []
  let all_matched : Map[String, Array[Int32]] = Map([])
  for i, rule in rules {
    let (matched, rejected) = rule.match_paths(options.src)
    for path in matched {
      match all_matched.get(path) {
        Some(idxs) => idxs.push(i)
        None => all_matched[path] = [i]
      }
    }
    matches.push({
      index: i,
      pattern: rule.pattern(),
      handler_kind: rule.handler_kind(),
      matched,
      rejected,
    })
  }

  let all_files = @glob.scan_files(options.src, "**")
  let unmatched : Array[String] = []
  for path in all_files {
    if all_matched.get(path) is None {
      unmatched.push(path)
    }
  }

  let conflicts : Array[(String, Array[Int32])] = []
  for entry in all_matched {
    if entry.1.length() > 1 {
      conflicts.push(entry)
    }
  }

  { src: options.src, rules: matches, unmatched, conflicts, }
}

///|
/// Prints a report of how `rules` match against files under `options.src`,
/// without executing any handler and without writing any file.
///
/// Reports, for each rule, the files it matches (and, for `Guard` rules,
/// the files rejected by their predicate), followed by any files under
/// `src` matched by no rule at all, and any files matched by more than one
/// rule (a potential conflict).
///
/// The report content comes from `compute_explain_report`, so it never
/// diverges from what a build would actually do.
pub fn explain(options : Options, rules : Rules) -> Unit raise @fs.IOError {
  let report = compute_explain_report(options, rules)
  println("Explaining \{report.rules.length()} rule(s) against \{report.src}")
  for rule in report.rules {
    println("\nRule \{rule.index}: \{rule.pattern} (\{rule.handler_kind})")
    for path in rule.matched {
      println("  → \{path}")
    }
    for path in rule.rejected {
      println("  ✗ \{path} (predicate returned false)")
    }
  }
  if report.unmatched.length() > 0 {
    println("\nUnmatched files (\{report.unmatched.length()}):")
    for path in report.unmatched {
      println("  ! \{path}")
    }
  }
  if report.conflicts.length() > 0 {
    println("\nConflicts (\{report.conflicts.length()}):")
    for entry in report.conflicts {
      println(
        "  ⚠ \{entry.0} matched by rules \{entry.1.map(i => i.to_string()).join(", ")}",
      )
    }
  }
}
