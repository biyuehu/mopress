///|
test "request_target_to_relative_path normalizes index and rejects traversal" {
  @debug.assert_eq(request_target_to_relative_path("/"), Some("index.html"))
  @debug.assert_eq(request_target_to_relative_path("/guide/"), Some("guide"))
  @debug.assert_eq(
    request_target_to_relative_path("/a/b.html?x=1"),
    Some(@path.Path("a").join("b.html").to_string()),
  )
  @debug.assert_eq(request_target_to_relative_path("/../secret"), None)
  @debug.assert_eq(request_target_to_relative_path("/a\\b"), None)
}

///|
test "percent_decode_unreserved keeps reserved separators encoded" {
  @debug.assert_eq(
    request_target_to_relative_path("/hello%20world"),
    Some("hello%20world"),
  )
  @debug.assert_eq(
    request_target_to_relative_path("/hello%2Dworld"),
    Some("hello-world"),
  )
  @debug.assert_eq(request_target_to_relative_path("/a%2Fb"), Some("a%2Fb"))
}

///|
test "content_type covers common static assets" {
  assert_eq(content_type("index.html"), "text/html; charset=utf-8")
  assert_eq(content_type("main.css"), "text/css; charset=utf-8")
  assert_eq(content_type("app.js"), "text/javascript; charset=utf-8")
  assert_eq(content_type("image.png"), "image/png")
  assert_eq(content_type("font.woff2"), "font/woff2")
}
