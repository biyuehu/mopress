///|
test "glob extra: star matches empty" {
  assert_eq(@glob.glob_match("*", ""), true)
}

///|
test "glob extra: question does not match two chars" {
  assert_eq(@glob.glob_match("?", "ab"), false)
}

///|
test "glob extra: trailing doublestar" {
  assert_eq(@glob.glob_match("a/**", "a/b/c"), true)
  assert_eq(@glob.glob_match("a/**", "b/c"), false)
}

///|
test "glob extra: doublestar in the middle" {
  assert_eq(@glob.glob_match("a/**/z.md", "a/b/c/z.md"), true)
  assert_eq(@glob.glob_match("a/**/z.md", "a/z.md"), true)
  assert_eq(@glob.glob_match("a/**/z.md", "a/b/y.md"), false)
}

///|
test "glob extra: multiple stars in one segment" {
  assert_eq(@glob.glob_match("*-*.md", "a-b.md"), true)
  assert_eq(@glob.glob_match("*-*.md", "ab.md"), false)
}

///|
test "glob extra: literal is case sensitive" {
  assert_eq(@glob.glob_match("Foo.md", "foo.md"), false)
}

///|
test "glob extra: glob_match_with requires both glob and predicate" {
  assert_eq(@glob.glob_match_with("*.md", "a.md", p => p.has_prefix("a")), true)
  assert_eq(
    @glob.glob_match_with("*.md", "a.md", p => p.has_prefix("b")),
    false,
  )
  assert_eq(@glob.glob_match_with("*.md", "a.txt", _ => true), false)
}

///|
test "glob extra: scan_files finds files in directory" {
  let results = @glob.scan_files("src/template/testdata", "*.html")
  assert_true(results.length() >= 3)
  assert_true(results.any(p => p.has_suffix("footer.html")))
  assert_true(results.any(p => p.has_suffix("recursive.html")))
}

///|
test "glob extra: scan_files with non matching pattern is empty" {
  let results = @glob.scan_files("src/template/testdata", "*.nomatch")
  assert_eq(results.length(), 0)
}

///|
test "glob extra: scan_files_with filters by predicate" {
  let all = @glob.scan_files_with("src/template/testdata", "*.html", _ => true)
  assert_true(all.length() >= 3)
  let none = @glob.scan_files_with("src/template/testdata", "*.html", _ => false)
  assert_eq(none.length(), 0)
  let one = @glob.scan_files_with("src/template/testdata", "*.html", p => {
    p.has_suffix("footer.html")
  })
  assert_eq(one.length(), 1)
}

///|
test "glob extra: scan_files raises for missing directory" {
  try @glob.scan_files("src/__definitely_missing__", "*") catch {
    _ => ()
  } noraise {
    _ => fail("expected IOError")
  }
}
