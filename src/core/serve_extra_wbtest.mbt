///|
test "strip_query_and_fragment: handles query fragment and neither" {
  assert_eq(strip_query_and_fragment("/a?x=1"), "/a")
  assert_eq(strip_query_and_fragment("/a#f"), "/a")
  assert_eq(strip_query_and_fragment("/a?x#f"), "/a")
  assert_eq(strip_query_and_fragment("/a#f?x"), "/a")
  assert_eq(strip_query_and_fragment("/a"), "/a")
}

///|
test "hex_value: digits letters and invalid" {
  @debug.assert_eq(hex_value('0'), Some(0))
  @debug.assert_eq(hex_value('9'), Some(9))
  @debug.assert_eq(hex_value('a'), Some(10))
  @debug.assert_eq(hex_value('F'), Some(15))
  @debug.assert_eq(hex_value('G'), None)
}

///|
test "is_unreserved_url_unit: classification" {
  assert_true(is_unreserved_url_unit('a'))
  assert_true(is_unreserved_url_unit('Z'))
  assert_true(is_unreserved_url_unit('5'))
  assert_true(is_unreserved_url_unit('-'))
  assert_true(is_unreserved_url_unit('~'))
  assert_false(is_unreserved_url_unit('/'))
  assert_false(is_unreserved_url_unit(' '))
}

///|
test "request_target_to_relative_path: dot and empty segments" {
  let expected = Some(@path.Path("a").join("b").to_string())
  @debug.assert_eq(request_target_to_relative_path("/a/./b"), expected)
  @debug.assert_eq(request_target_to_relative_path("/a//b"), expected)
  @debug.assert_eq(request_target_to_relative_path("/?x=1"), Some("index.html"))
}

///|
test "request_target_to_relative_path: percent decoding edge cases" {
  @debug.assert_eq(request_target_to_relative_path("/%41"), Some("A"))
  @debug.assert_eq(request_target_to_relative_path("/%zz"), Some("%zz"))
  @debug.assert_eq(request_target_to_relative_path("/a%2"), Some("a%2"))
  @debug.assert_eq(request_target_to_relative_path("/a\u0000b"), None)
}

///|
test "content_type: case insensitive and fallback" {
  assert_eq(content_type("A.HTML"), "text/html; charset=utf-8")
  assert_eq(content_type("a.htm"), "text/html; charset=utf-8")
  assert_eq(content_type("a.md"), "text/plain; charset=utf-8")
  assert_eq(content_type("a.json"), "application/json; charset=utf-8")
  assert_eq(content_type("a.svg"), "image/svg+xml")
  assert_eq(content_type("a.jpeg"), "image/jpeg")
  assert_eq(content_type("a.wasm"), "application/wasm")
  assert_eq(content_type("a.bin"), "application/octet-stream")
  assert_eq(content_type("noext"), "application/octet-stream")
}
