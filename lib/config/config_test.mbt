///|
test "default config uses mdbook-compatible paths" {
  let config = BookConfig::default()
  assert_true(config.title is None)
  assert_eq(config.authors.length(), 0)
  assert_eq(config.src, "src")
  assert_true(config.language is Some("en"))
  assert_true(config.text_direction is LeftToRight)
  assert_eq(config.build.build_dir, "build")
  assert_eq(config.build.create_missing, true)
}

///|
test "parse book and build sections" {
  let source =
    #|[book]
    #|title = "MoBook"
    #|authors = ["MoonBit Team", "Contributors"]
    #|description = "A reliable book generator"
    #|src = "docs"
    #|language = "zh-CN"
    #|text-direction = "rtl"
    #|
    #|[build]
    #|build-dir = "public"
    #|create-missing = false
    #|
  let config = BookConfig::parse(source)
  assert_true(config.title is Some("MoBook"))
  assert_eq(config.authors.length(), 2)
  assert_eq(config.authors[0], "MoonBit Team")
  assert_eq(config.authors[1], "Contributors")
  assert_true(config.description is Some("A reliable book generator"))
  assert_eq(config.src, "docs")
  assert_true(config.language is Some("zh-CN"))
  assert_true(config.text_direction is RightToLeft)
  assert_eq(config.build.build_dir, "public")
  assert_eq(config.build.create_missing, false)
}

///|
test "parse rejects wrong field type" {
  let source =
    #|[book]
    #|authors = "nobody"
    #|
  let message = try BookConfig::parse(source) catch {
    ConfigParseError(message) => message
  } noraise {
    _ => abort("expected config parsing to fail")
  }
  assert_eq(message, "`authors` must be an array")
}

///|
test "parse rejects empty path values" {
  let source =
    #|[book]
    #|src = " "
    #|
  let message = try BookConfig::parse(source) catch {
    ConfigParseError(message) => message
  } noraise {
    _ => abort("expected config validation to fail")
  }
  assert_eq(message, "`book.src` must not be empty")
}
