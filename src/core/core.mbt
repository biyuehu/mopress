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
  let no_emit = args.contains("--no-emit")
  let analyze = args.contains("--analyze")
  match cmd {
    "build" => options |> mo_build(rules, no_emit~, analyze~)
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
  analyze~ : Bool = false,
  analyze_json~ : Bool = false,
) -> Unit {
  let is_analyze = analyze || analyze_json
  let build_start = @async.now()
  if !analyze_json {
    if no_emit {
      println("Dry-run (no emit) from \{options.src}")
    } else {
      println("Emitting files from \{options.src} to \{options.dest}")
    }
  }
  let page_analyses : Array[PageAnalysis] = []
  let step_map : Map[String, (Ref[Int64], Ref[Int32], Ref[Int64])] = Map([])
  for rule in rules {
    let paths = rule.match_paths(options.src).0
    let mut outputs : Array[String] = []
    let page_reports : Array[PageAnalysis?] = Array::make(paths.length(), None)
    @async.with_task_group(group => {
      outputs = Array::make(paths.length(), "")
      for i, path in paths {
        group.spawn_bg(() => {
          let t0 = @async.now()
          let tpl_counter = Ref(0)
          let collected_traces : Array[StepTrace] = []
          let item = if is_analyze {
            with_page_trace(collected_traces, () => {
              @template.with_render_counter(tpl_counter, () => {
                rule.handler().run(options, path)
              })
            })
          } else {
            rule.handler().run(options, path)
          }
          let t_run = @async.now() - t0
          if no_emit {
            outputs[i] = item.location()
          } else {
            item.data.write(options.dest, item.location())
          }
          if is_analyze {
            let size = item.data.byte_size()
            let mut slowest_name = rule.handler_kind()
            let mut slowest_ms = t_run
            if collected_traces.length() > 0 {
              slowest_name = collected_traces[0].name
              slowest_ms = collected_traces[0].duration_ms
              for tr in collected_traces {
                if tr.duration_ms > slowest_ms {
                  slowest_name = tr.name
                  slowest_ms = tr.duration_ms
                }
              }
            } else {
              collected_traces.push({
                name: rule.handler_kind(),
                duration_ms: t_run,
              })
            }
            let page_rep : PageAnalysis = {
              path: item.location(),
              size_bytes: size,
              total_duration_ms: t_run,
              template_renders: tpl_counter.val,
              slowest_step: slowest_name,
              slowest_step_ms: slowest_ms,
              step_traces: collected_traces,
            }
            page_reports[i] = Some(page_rep)
          }
        })
      }
    })
    if no_emit && !analyze_json {
      for loc in outputs {
        if !loc.is_empty() {
          println("  would write: \{loc}")
        }
      }
    }
    if is_analyze {
      for rep in page_reports {
        match rep {
          Some(p) => {
            page_analyses.push(p)
            for trace in p.step_traces {
              match step_map.get(trace.name) {
                Some(entry) => {
                  entry.0.val += trace.duration_ms
                  entry.1.val += 1
                  if trace.duration_ms > entry.2.val {
                    entry.2.val = trace.duration_ms
                  }
                }
                None =>
                  step_map[trace.name] = (
                    Ref(trace.duration_ms),
                    Ref(1),
                    Ref(trace.duration_ms),
                  )
              }
            }
          }
          None => ()
        }
      }
    }
  }
  let total_build_ms = @async.now() - build_start
  if !analyze_json {
    if no_emit {
      println("Dry-run complete (no files written).")
    } else {
      @c.chalk().modifier(Bold).color(Green).render("√ Build finished.")
      |> println
    }
  }
  if is_analyze {
    let mut total_size = 0
    for p in page_analyses {
      total_size += p.size_bytes
    }
    let step_summaries : Array[StepSummary] = []
    for entry in step_map {
      step_summaries.push({
        name: entry.0,
        total_ms: entry.1.0.val,
        call_count: entry.1.1.val,
        max_ms: entry.1.2.val,
      })
    }
    let report : BuildAnalysisReport = {
      pages: page_analyses,
      steps: step_summaries,
      total_pages: page_analyses.length(),
      total_size_bytes: total_size,
      total_build_ms,
    }
    if analyze_json {
      println(report.to_json().stringify())
    } else {
      print_analysis_report(report)
    }
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
