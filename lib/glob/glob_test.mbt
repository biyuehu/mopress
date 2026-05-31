///|
test "glob pattern matches exact and wildcard paths" {
  assert_true(glob_match("README.md", "README.md"))
  assert_false(glob_match("README.md", "src/README.md"))
  assert_true(glob_match("*.md", "chapter.md"))
  assert_false(glob_match("*.md", "chapter.md.bak"))
  assert_true(glob_match("src/*.md", "src/chapter.md"))
  assert_false(glob_match("src/*.md", "draft/src/chapter.md"))
  assert_true(glob_match("src/*/index.md", "src/guide/index.md"))
  assert_false(glob_match("src/*.md", "assets/style.css"))
}
