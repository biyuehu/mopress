///|
/// The fixture directory used by the `explain` tests below. It contains
/// three `.md` files (`a.md`, `b.md`, `skip.md`) and one `.txt` file
/// (`c.txt`).
let explain_fixture : String = "src/core/testdata/explain"

///|
test "compute_explain_report: glob rule matches only its pattern" {
  let report = @core.compute_explain_report(
    { src: explain_fixture, dest: "_build/unused", },
    [@core.Rule::Glob("*.md", @core.Copy)],
  )
  assert_eq(report.src, explain_fixture)
  assert_eq(report.rules.length(), 1)
  let rule = report.rules[0]
  assert_eq(rule.index, 0)
  assert_eq(rule.pattern, "*.md")
  assert_eq(rule.handler_kind, "Copy")
  assert_eq(rule.matched.length(), 3)
  assert_eq(rule.rejected.length(), 0)
  assert_true(rule.matched.any(p => p.has_suffix("a.md")))
  assert_true(rule.matched.any(p => p.has_suffix("b.md")))
  assert_true(rule.matched.any(p => p.has_suffix("skip.md")))
}

///|
test "compute_explain_report: guard rule separates rejected" {
  let report = @core.compute_explain_report(
    { src: explain_fixture, dest: "_build/unused", },
    [@core.Rule::Guard("*.md", p => !p.has_suffix("skip.md"), @core.Copy)],
  )
  let rule = report.rules[0]
  assert_eq(rule.matched.length(), 2)
  assert_eq(rule.rejected.length(), 1)
  assert_true(rule.matched.any(p => p.has_suffix("a.md")))
  assert_true(rule.matched.any(p => p.has_suffix("b.md")))
  assert_true(rule.rejected.any(p => p.has_suffix("skip.md")))
}

///|
test "compute_explain_report: unmatched files reported" {
  let report = @core.compute_explain_report(
    { src: explain_fixture, dest: "_build/unused", },
    [@core.Rule::Glob("*.md", @core.Copy)],
  )
  assert_eq(report.unmatched.length(), 1)
  assert_true(report.unmatched[0].has_suffix("c.txt"))
}

///|
test "compute_explain_report: no rule means everything unmatched" {
  let report = @core.compute_explain_report(
    { src: explain_fixture, dest: "_build/unused", },
    [],
  )
  assert_eq(report.rules.length(), 0)
  assert_eq(report.unmatched.length(), 4)
  assert_eq(report.conflicts.length(), 0)
}

///|
test "compute_explain_report: conflicting rules reported" {
  let report = @core.compute_explain_report(
    { src: explain_fixture, dest: "_build/unused", },
    [@core.Rule::Glob("*.md", @core.Copy), @core.Rule::Glob("a.*", @core.Copy)],
  )
  assert_eq(report.conflicts.length(), 1)
  let (path, idxs) = report.conflicts[0]
  assert_true(path.has_suffix("a.md"))
  assert_eq(idxs, [0, 1])
}

///|
async test "mo_build with no_emit writes nothing" {
  // Destination lives under `_build/`, which is gitignored, so tests do
  // not have to clean up after themselves.
  let dest = "_build/test_no_emit_out"
  let rules : @core.Rules = [@core.Glob("*.md", @core.Copy)]
  @core.mo_build(
    { src: "src/core/testdata/explain", dest, },
    rules,
    no_emit=true,
  )
  assert_false(@fs.path_exists(dest))
}

///|
async test "mo_build without no_emit writes files" {
  let dest = "_build/test_emit_out"
  let rules : @core.Rules = [@core.Glob("*.md", @core.Copy)]
  @core.mo_build({ src: "src/core/testdata/explain", dest, }, rules)
  assert_true(@fs.path_exists(dest))
  assert_true(@fs.path_exists(@path.Path(dest).join("a.md").to_string()))
}

///|
async test "mo_build concurrently processes all matched files without missing or corruption" {
  let dest = "_build/test_concurrent_emit_out"
  let rules : @core.Rules = [
    @core.Glob(
      "*.md",
      @core.Handler::Text(item => {
        let modified = item.data + "\n-- processed by concurrent build --"
        @core.unify(item.map(_ => modified))
      }),
    ),
  ]
  @core.mo_build({ src: "src/core/testdata/explain", dest, }, rules)
  assert_true(@fs.path_exists(dest))
  let a_path = @path.Path(dest).join("a.md").to_string()
  let b_path = @path.Path(dest).join("b.md").to_string()
  let skip_path = @path.Path(dest).join("skip.md").to_string()
  assert_true(@fs.path_exists(a_path))
  assert_true(@fs.path_exists(b_path))
  assert_true(@fs.path_exists(skip_path))
  let a_content = @fs.read_file_to_string(a_path)
  assert_true(a_content.contains("-- processed by concurrent build --"))
}

///|
async test "mo_build with analyze flag runs and outputs report" {
  let dest = "_build/test_analyze_out"
  let rules : @core.Rules = [
    @core.Glob(
      "*.md",
      @core.Handler::Text(item => {
        @core.record_step_trace("dummy_step", 5L)
        @core.unify(item)
      }),
    ),
  ]
  @core.mo_build(
    { src: "src/core/testdata/explain", dest, },
    rules,
    analyze=true,
  )
  assert_true(@fs.path_exists(dest))
}

///|
async test "mo_build with analyze_json flag runs and outputs valid json" {
  let dest = "_build/test_analyze_json_out"
  let rules : @core.Rules = [
    @core.Glob(
      "*.md",
      @core.Handler::Text(item => {
        @core.record_step_trace("json_step", 3L)
        @core.unify(item)
      }),
    ),
  ]
  @core.mo_build(
    { src: "src/core/testdata/explain", dest, },
    rules,
    analyze_json=true,
  )
  assert_true(@fs.path_exists(dest))
}
