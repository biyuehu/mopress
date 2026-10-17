///|
test "inject_into_head: injects tag before </head>" {
  let html = "<html><head><title>Test</title></head><body></body></html>"
  let result = inject_into_head(
    html, "<link rel=\"stylesheet\" href=\"style.css\">",
  )
  assert_eq(
    result, "<html><head><title>Test</title><link rel=\"stylesheet\" href=\"style.css\"></head><body></body></html>",
  )
}

///|
test "inject_into_head: no </head> tag appends to front" {
  let html = "<body>hello</body>"
  let result = inject_into_head(html, "<style>body{}</style>")
  assert_eq(result, "<style>body{}</style><body>hello</body>")
}

///|
test "inject_into_head: empty html" {
  let result = inject_into_head("", "<style></style>")
  assert_eq(result, "<style></style>")
}

///|
test "inject_into_head: multiple </head> uses first occurrence" {
  let html = "<head></head><head></head>"
  let result = inject_into_head(html, "<meta>")
  assert_eq(result, "<head><meta></head><head></head>")
}

///|
test "inject_before_body_end: injects tag before </body>" {
  let html = "<html><head></head><body><p>hello</p></body></html>"
  let result = inject_before_body_end(html, "<script src=\"app.js\"></script>")
  assert_eq(
    result, "<html><head></head><body><p>hello</p><script src=\"app.js\"></script></body></html>",
  )
}

///|
test "inject_before_body_end: no </body> tag appends to end" {
  let html = "<p>hello</p>"
  let result = inject_before_body_end(html, "<script></script>")
  assert_eq(result, "<p>hello</p><script></script>")
}

///|
test "inject_before_body_end: empty html" {
  let result = inject_before_body_end("", "<script></script>")
  assert_eq(result, "<script></script>")
}

///|
test "inject_before_body_end: multiple </body> uses first occurrence" {
  let html = "<body>a</body><body>b</body>"
  let result = inject_before_body_end(html, "<script></script>")
  assert_eq(result, "<body>a<script></script></body><body>b</body>")
}

///|
test "parse_frontmatter: basic key-value" {
  let content =
    #|---
    #|title: Hello
    #|author: himeno
    #|---
    #|# Body content
  let (meta, body) = parse_frontmatter(content)
  assert_eq(meta["title"], "Hello")
  assert_eq(meta["author"], "himeno")
  assert_eq(body, "# Body content")
}

///|
test "parse_frontmatter: no frontmatter returns empty meta" {
  let content = "# Just a heading\n\nSome paragraph."
  let (meta, body) = parse_frontmatter(content)
  assert_eq(meta.length(), 0)
  assert_eq(body, content)
}

///|
test "parse_frontmatter: empty frontmatter block" {
  let content =
    #|---
    #|---
    #|body here
  let (meta, body) = parse_frontmatter(content)
  assert_eq(meta.length(), 0)
  assert_eq(body, "body here")
}

///|
test "parse_frontmatter: unclosed frontmatter treated as no frontmatter" {
  let content =
    #|---
    #|title: Hello
    #|body here
  let (meta, body) = parse_frontmatter(content)
  assert_eq(meta.length(), 0)
  assert_eq(body, content)
}

///|
test "parse_frontmatter: value with colon in it" {
  let content =
    #|---
    #|url: https://example.com
    #|---
    #|body
  let (meta, body) = parse_frontmatter(content)
  assert_eq(meta["url"], "https://example.com")
  assert_eq(body, "body")
}

///|
test "parse_frontmatter: whitespace trimmed from key and value" {
  let content =
    #|---
    #|  title  :   Hello World  
    #|---
    #|body
  let (meta, body) = parse_frontmatter(content)
  assert_eq(meta["title"], "Hello World")
  assert_eq(body, "body")
}

///|
test "Thing::write_if_changed: skips rewrite when content is identical" {
  let temp_dir = "_build/test_write_if_changed"
  let doc = Thing::Doc("Hello World")

  // First write should write and return true
  let first = doc.write_if_changed(temp_dir, "test.txt")
  assert_true(first)
  assert_eq(@fs.read_file_to_string(temp_dir + "/test.txt"), "Hello World")

  // Second write with identical content should skip and return false
  let second = doc.write_if_changed(temp_dir, "test.txt")
  assert_false(second)

  // Third write with modified content should write and return true
  let modified = Thing::Doc("Hello New World")
  let third = modified.write_if_changed(temp_dir, "test.txt")
  assert_true(third)
  assert_eq(@fs.read_file_to_string(temp_dir + "/test.txt"), "Hello New World")
}
