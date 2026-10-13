///|
test "parse_frontmatter: CRLF line endings are normalized" {
  let (meta, body) = parse_frontmatter("---\r\ntitle: A\r\n---\r\nbody")
  assert_eq(meta["title"], "A")
  assert_eq(body, "body")
}

///|
test "parse_frontmatter: lines without colon are ignored" {
  let (meta, body) = parse_frontmatter("---\ntitle: A\nnocolon\n---\nbody")
  assert_eq(meta.length(), 1)
  assert_eq(meta["title"], "A")
  assert_eq(body, "body")
}

///|
test "parse_frontmatter: later duplicate key wins" {
  let (meta, _) = parse_frontmatter("---\na: 1\na: 2\n---\nbody")
  assert_eq(meta["a"], "2")
}

///|
test "parse_frontmatter: empty input" {
  let (meta, body) = parse_frontmatter("")
  assert_eq(meta.length(), 0)
  assert_eq(body, "")
}

///|
test "parse_frontmatter: multiline body preserved" {
  let (meta, body) = parse_frontmatter("---\na: 1\n---\nl1\nl2")
  assert_eq(meta["a"], "1")
  assert_eq(body, "l1\nl2")
}
