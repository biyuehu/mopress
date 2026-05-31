///|
test "literal: exact match" {
  assert_eq(glob_match("foo.md", "foo.md"), true)
}

///|
test "literal: no match" {
  assert_eq(glob_match("foo.md", "bar.md"), false)
}

///|
test "star: matches single segment" {
  assert_eq(glob_match("*.md", "foo.md"), true)
}

///|
test "star: does not match across slash" {
  assert_eq(glob_match("*.md", "src/foo.md"), false)
}

///|
test "star: matches empty segment" {
  assert_eq(glob_match("*.md", ".md"), true)
}

///|
test "star: middle wildcard" {
  assert_eq(glob_match("foo*bar", "fooXXXbar"), true)
}

///|
test "star: middle wildcard no match across slash" {
  assert_eq(glob_match("foo*bar", "foo/bar"), false)
}

///|
test "doublestar: matches across directories" {
  assert_eq(glob_match("src/**/*.md", "src/a/b/c/foo.md"), true)
}

///|
test "doublestar: matches single level" {
  assert_eq(glob_match("src/**/*.md", "src/foo.md"), true)
}

///|
test "doublestar: matches zero levels" {
  assert_eq(glob_match("src/**.md", "src/foo.md"), true)
}

///|
test "doublestar: standalone matches everything" {
  assert_eq(glob_match("**", "a/b/c/d.md"), true)
}

///|
test "doublestar: no match wrong extension" {
  assert_eq(glob_match("src/**/*.md", "src/a/b/foo.txt"), false)
}

///|
test "question: matches single non-slash char" {
  assert_eq(glob_match("fo?.md", "foo.md"), true)
}

///|
test "question: does not match slash" {
  assert_eq(glob_match("fo?/bar", "fo//bar"), false)
}

///|
test "question: does not match empty" {
  assert_eq(glob_match("fo?.md", "fo.md"), false)
}

///|
test "question: multiple wildcards" {
  assert_eq(glob_match("?.md", "a.md"), true)
}

///|
test "combined: star and question" {
  assert_eq(glob_match("src/?.md", "src/a.md"), true)
}

///|
test "combined: star and question no match" {
  assert_eq(glob_match("src/?.md", "src/ab.md"), false)
}

///|
test "edge: empty pattern empty path" {
  assert_eq(glob_match("", ""), true)
}

///|
test "edge: empty pattern non-empty path" {
  assert_eq(glob_match("", "foo"), false)
}

///|
test "edge: pattern longer than path" {
  assert_eq(glob_match("foo/bar.md", "foo"), false)
}

///|
test "edge: pure doublestar slash" {
  assert_eq(glob_match("**/foo.md", "a/b/foo.md"), true)
}

///|
test "edge: pure doublestar slash root" {
  assert_eq(glob_match("**/foo.md", "foo.md"), true)
}
