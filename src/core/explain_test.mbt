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
