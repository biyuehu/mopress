///|
test "literal: exact match" {
  assert_eq(@glob.glob_match("foo.md", "foo.md"), true)
}

///|
test "literal: no match" {
  assert_eq(@glob.glob_match("foo.md", "bar.md"), false)
}

///|
test "star: matches single segment" {
  assert_eq(@glob.glob_match("*.md", "foo.md"), true)
}

///|
test "star: does not match across slash" {
  assert_eq(@glob.glob_match("*.md", "src/foo.md"), false)
}

///|
test "star: matches empty segment" {
  assert_eq(@glob.glob_match("*.md", ".md"), true)
}

///|
test "star: middle wildcard" {
  assert_eq(@glob.glob_match("foo*bar", "fooXXXbar"), true)
}

///|
test "star: middle wildcard no match across slash" {
  assert_eq(@glob.glob_match("foo*bar", "foo/bar"), false)
}

///|
test "doublestar: matches across directories" {
  assert_eq(@glob.glob_match("src/**/*.md", "src/a/b/c/foo.md"), true)
}

///|
test "doublestar: matches single level" {
  assert_eq(@glob.glob_match("src/**/*.md", "src/foo.md"), true)
}

///|
test "doublestar: matches zero levels" {
  assert_eq(@glob.glob_match("src/**.md", "src/foo.md"), true)
}

///|
test "doublestar: standalone matches everything" {
  assert_eq(@glob.glob_match("**", "a/b/c/d.md"), true)
}

///|
test "doublestar: no match wrong extension" {
  assert_eq(@glob.glob_match("src/**/*.md", "src/a/b/foo.txt"), false)
}

///|
test "question: matches single non-slash char" {
  assert_eq(@glob.glob_match("fo?.md", "foo.md"), true)
}

///|
test "question: does not match slash" {
  assert_eq(@glob.glob_match("fo?/bar", "fo//bar"), false)
}

///|
test "question: does not match empty" {
  assert_eq(@glob.glob_match("fo?.md", "fo.md"), false)
}

///|
test "question: multiple wildcards" {
  assert_eq(@glob.glob_match("?.md", "a.md"), true)
}

///|
test "combined: star and question" {
  assert_eq(@glob.glob_match("src/?.md", "src/a.md"), true)
}

///|
test "combined: star and question no match" {
  assert_eq(@glob.glob_match("src/?.md", "src/ab.md"), false)
}

///|
test "edge: empty pattern empty path" {
  assert_eq(@glob.glob_match("", ""), true)
}

///|
test "edge: empty pattern non-empty path" {
  assert_eq(@glob.glob_match("", "foo"), false)
}

///|
test "edge: pattern longer than path" {
  assert_eq(@glob.glob_match("foo/bar.md", "foo"), false)
}

///|
test "edge: pure doublestar slash" {
  assert_eq(@glob.glob_match("**/foo.md", "a/b/foo.md"), true)
}

///|
test "edge: pure doublestar slash root" {
  assert_eq(@glob.glob_match("**/foo.md", "foo.md"), true)
}

///|
/// The fixture directory shared by the scanning tests below. Its layout is:
/// ```
/// testdata/
///   a.md
///   b.md
///   c.txt
///   sub/
///     d.md
///     deep/
///       e.md
///       f.txt
/// ```
let scan_fixture : String = "src/glob/testdata"

///|
test "doublestar: middle zero levels" {
  assert_eq(@glob.glob_match("a/**/b", "a/b"), true)
}

///|
test "doublestar: middle multiple levels" {
  assert_eq(@glob.glob_match("a/**/b", "a/x/y/b"), true)
}

///|
test "doublestar: middle single level" {
  assert_eq(@glob.glob_match("a/**/b", "a/x/b"), true)
}

///|
test "doublestar: middle no match missing segment" {
  assert_eq(@glob.glob_match("a/**/b", "a/x/c"), false)
}

///|
test "doublestar: consecutive doublestars" {
  assert_eq(@glob.glob_match("**/**/*.md", "a/b/c.md"), true)
}

///|
test "doublestar: trailing as suffix of extension" {
  assert_eq(@glob.glob_match("**x.md", "a/b/x.md"), false)
}

///|
test "trailing slash pattern requires trailing slash path" {
  assert_eq(@glob.glob_match("foo/", "foo/"), true)
  assert_eq(@glob.glob_match("foo/", "foo"), false)
}

///|
test "case sensitivity" {
  assert_eq(@glob.glob_match("*.MD", "foo.md"), false)
  assert_eq(@glob.glob_match("*.md", "foo.MD"), false)
  assert_eq(@glob.glob_match("*.md", "foo.md"), true)
}

///|
test "dotfiles are matched by star" {
  assert_eq(@glob.glob_match("*", ".gitignore"), true)
  assert_eq(@glob.glob_match("*.md", ".hidden.md"), true)
}

///|
test "special regex-like characters are literal" {
  assert_eq(@glob.glob_match("a.b.md", "a.b.md"), true)
  assert_eq(@glob.glob_match("a.b.md", "axb.md"), false)
  assert_eq(@glob.glob_match("a[b].md", "a[b].md"), true)
  assert_eq(@glob.glob_match("a{1,2}.md", "a{1,2}.md"), true)
}

///|
test "backslash path separator is normalized" {
  assert_eq(@glob.glob_match("a/b.md", "a\\b.md"), true)
  assert_eq(@glob.glob_match("**/*.md", "a\\b\\c.md"), true)
}

///|
test "glob_match_with: predicate receives original path" {
  let mut received : String = ""
  let result = @glob.glob_match_with("*.md", "foo.md", p => {
    received = p
    true
  })
  assert_eq(result, true)
  assert_eq(received, "foo.md")
}

///|
test "glob_match_with: predicate can reject a glob match" {
  assert_eq(
    @glob.glob_match_with("*.md", "skip.md", p => p != "skip.md"),
    false,
  )
  assert_eq(@glob.glob_match_with("*.md", "keep.md", p => p != "skip.md"), true)
}

///|
test "glob_match_with: predicate not called when glob fails" {
  let mut called = false
  let result = @glob.glob_match_with("*.md", "foo.txt", _ => {
    called = true
    true
  })
  assert_eq(result, false)
  assert_eq(called, false)
}

///|
test "scan_files: single segment pattern" {
  let files = @glob.scan_files(scan_fixture, "*.md")
  assert_eq(files.length(), 2)
  assert_true(files.any(p => p.has_suffix("a.md")))
  assert_true(files.any(p => p.has_suffix("b.md")))
  assert_false(files.any(p => p.has_suffix("d.md")))
}

///|
test "scan_files: recursive doublestar pattern" {
  let files = @glob.scan_files(scan_fixture, "**/*.md")
  assert_eq(files.length(), 4)
  assert_true(files.any(p => p.has_suffix("a.md")))
  assert_true(files.any(p => p.has_suffix("b.md")))
  assert_true(files.any(p => p.has_suffix("d.md")))
  assert_true(files.any(p => p.has_suffix("e.md")))
}

///|
test "scan_files: recursive non-markdown" {
  let files = @glob.scan_files(scan_fixture, "**/*.txt")
  assert_eq(files.length(), 2)
  assert_true(files.any(p => p.has_suffix("c.txt")))
  assert_true(files.any(p => p.has_suffix("f.txt")))
}

///|
test "scan_files: subdirectory pattern" {
  let files = @glob.scan_files(scan_fixture, "sub/**/*.md")
  assert_eq(files.length(), 2)
  assert_true(files.any(p => p.has_suffix("d.md")))
  assert_true(files.any(p => p.has_suffix("e.md")))
}

///|
test "scan_files: unmatched pattern yields empty" {
  let files = @glob.scan_files(scan_fixture, "*.rs")
  assert_eq(files.length(), 0)
}

///|
test "scan_files_with: predicate filters results" {
  let files = @glob.scan_files_with(scan_fixture, "**/*.md", p => {
    !p.has_suffix("b.md")
  })
  assert_eq(files.length(), 3)
  assert_false(files.any(p => p.has_suffix("b.md")))
}

///|
test "scan_files_with: predicate receives full joined path" {
  let received : Array[String] = []
  let _ = @glob.scan_files_with(scan_fixture, "*.md", p => {
    received.push(p)
    true
  })
  assert_eq(received.length(), 2)
  // Each received path should contain the fixture prefix, since
  // scan_recursive passes the joined full path (not the relative one).
  // Normalize separators to make this assertion portable.
  let prefix = scan_fixture.replace_all(old="\\", new="/")
  for path in received {
    assert_true(path.replace_all(old="\\", new="/").contains(prefix))
  }
}

///|
test "scan_files: nonexistent directory raises" {
  let raised = try {
    let _ = @glob.scan_files("src/glob/testdata_nonexistent", "*.md")
    false
  } catch {
    _ => true
  }
  assert_true(raised)
}

///|
test "scan_files: empty pattern matches nothing" {
  let files = @glob.scan_files(scan_fixture, "")
  assert_eq(files.length(), 0)
}

///|
test "scan_files: doublestar alone matches all files" {
  let files = @glob.scan_files(scan_fixture, "**")
  assert_eq(files.length(), 6)
  for f in files {
    assert_false(f.has_suffix("sub"))
    assert_false(f.has_suffix("deep"))
  }
}

///|
test "scan_files: scanning a regular file path raises" {
  let file_path = @path.Path(scan_fixture).join("a.md").to_string()
  let raised = try {
    let _ = @glob.scan_files(file_path, "*")
    false
  } catch {
    _ => true
  }
  assert_true(raised)
}

///|
test "doublestar: three stars adjacent degrade to star" {
  // `***.md` is not a standalone segment, so the star run degrades to a
  // single-segment `*`.
  assert_eq(@glob.glob_match("***.md", "a/b/c.md"), false)
  assert_eq(@glob.glob_match("***.md", "c.md"), true)
}

///|
test "consecutive slashes in path do not match single slash pattern" {
  // Pins current behavior: `a/b` does not match `a//b`.
  assert_eq(@glob.glob_match("a/b", "a//b"), false)
}

///|
test "scan_files_with: predicate receives src-prefixed path" {
  let received : Array[String] = []
  let _ = @glob.scan_files_with(scan_fixture, "a.md", p => {
    received.push(p)
    true
  })
  assert_eq(received.length(), 1)
  let normalized = received[0].replace_all(old="\\", new="/")
  assert_true(normalized.has_suffix("a.md"))
  assert_true(normalized.contains("testdata/"))
}

///|
test "trailing doublestar slash matches zero or more levels" {
  assert_eq(@glob.glob_match("src/**/", "src/"), true)
  assert_eq(@glob.glob_match("src/**/", "src/a/"), true)
  assert_eq(@glob.glob_match("src/**/", "src/a/b/"), true)
  // `src/**/` tokenizes identically to `src/**` (the trailing slash after
  // `**` is consumed by the tokenizer), so it also matches paths without a
  // trailing slash.
  assert_eq(@glob.glob_match("src/**/", "src/a/b"), true)
}

///|
test "leading slash pattern requires leading slash path" {
  assert_eq(@glob.glob_match("/foo.md", "/foo.md"), true)
  assert_eq(@glob.glob_match("/foo.md", "foo.md"), false)
}

///|
test "unicode filename literal match" {
  assert_eq(@glob.glob_match("字符.md", "字符.md"), true)
  assert_eq(@glob.glob_match("字符.md", "别的.md"), false)
}

///|
test "unicode filename with star" {
  assert_eq(@glob.glob_match("*.md", "字符.md"), true)
  assert_eq(@glob.glob_match("字*.md", "字符.md"), true)
  assert_eq(@glob.glob_match("?.md", "字.md"), true)
  assert_eq(@glob.glob_match("?.md", "字符.md"), false)
}

///|
test "unicode filename with doublestar" {
  assert_eq(@glob.glob_match("**/*.md", "目录/字符.md"), true)
  assert_eq(@glob.glob_match("目录/**/*.md", "目录/子/字符.md"), true)
}

///|
test "star matches empty segment" {
  assert_eq(@glob.glob_match("*", ""), true)
  assert_eq(@glob.glob_match("*.md", ".md"), true)
  assert_eq(@glob.glob_match("a*b", "ab"), true)
  assert_eq(@glob.glob_match("a**b", "ab"), true)
}

///|
test "star does not match slash even when empty on both sides" {
  assert_eq(@glob.glob_match("*", "/"), false)
  assert_eq(@glob.glob_match("a*/b", "a/b"), true)
  assert_eq(@glob.glob_match("a*/*b", "a/b"), true)
}

///|
test "doublestar matches empty" {
  assert_eq(@glob.glob_match("**", ""), true)
  assert_eq(@glob.glob_match("a/**/b", "a/b"), true)
  assert_eq(@glob.glob_match("a/**", "a/"), true)
}

///|
test "doublestar matches single empty segment" {
  assert_eq(@glob.glob_match("**/b", "b"), true)
  // `a/**` tokenizes as `Literal("a/") + DoubleStar`, so the `a/` prefix
  // must be present in the path; a bare `a` does not match.
  assert_eq(@glob.glob_match("a/**", "a"), false)
  assert_eq(@glob.glob_match("a/**", "a/"), true)
  assert_eq(@glob.glob_match("a/**", "a/b"), true)
}
