///|
test "parse full config" {
  let toml =
    #|title = "MyBook"
    #|authors = ["Alice", "Bob"]
    #|description = "A test book"
    #|keywords = "test,moonbit"
    #|language = "zh"
    #|src = "src"
    #|dest = "public"
    #|
    #|[extension]
    #|extra-css = ["style.css", "custom.css"]
    #|extra-js = ["app.js"]
    #|preprocessors = ["katex"]
    #|transformers = ["highlight"]
  let config = BookConfig::parse(toml)
  assert_eq(config.title, "MyBook")
  @debug.assert_eq(config.authors, ["Alice", "Bob"])
  assert_eq(config.description, "A test book")
  assert_eq(config.keywords, "test,moonbit")
  assert_eq(config.language, "zh")
  assert_eq(config.src, "src")
  assert_eq(config.dest, "public")
  @debug.assert_eq(config.extension.extra_css, ["style.css", "custom.css"])
  @debug.assert_eq(config.extension.extra_js, ["app.js"])
  @debug.assert_eq(config.extension.preprocessors, ["katex"])
}

///|
test "parse only title" {
  let config = BookConfig::parse(
    (
      #|title = "OnlyTitle"
    ),
  )
  assert_eq(config.title, "OnlyTitle")
  assert_eq(config.language, "en")
  assert_eq(config.dest, "dest")
}

///|
test "parse missing extension section" {
  let config = BookConfig::parse(
    (
      #|title = "NoExt"
      #|language = "ja"
    ),
  )
  @debug.assert_eq(config.title, "NoExt")
  @debug.assert_eq(config.extension.extra_css, [])
  @debug.assert_eq(config.extension.extra_js, [])
  @debug.assert_eq(config.extension.preprocessors, [])
  @debug.assert_eq(config.extension.transformers, [])
}

///|
test "parse invalid toml syntax" {
  let result : Result[BookConfig, ConfigParseError] = Ok(
    BookConfig::parse("title = "),
  ) catch {
    e => Err(e)
  }
  match result {
    Err(ConfigParseError(msg)) =>
      @debug.assert_eq(msg.has_prefix("Parse config error:"), true)
    Ok(_) => fail("Expected parse error")
  }
}

///|
test "parse title is not string" {
  let result : Result[BookConfig, ConfigParseError] = Ok(
    BookConfig::parse("title = 123"),
  ) catch {
    e => Err(e)
  }
  match result {
    Ok(cfg) => assert_eq(cfg.title, "MoPress")
    Err(_) => ()
  }
}

///|
test "parse extension is not table" {
  let result : Result[BookConfig, ConfigParseError] = Ok(
    BookConfig::parse("extension = \"not_a_table\""),
  ) catch {
    e => Err(e)
  }
  match result {
    Err(ConfigParseError(msg)) =>
      @debug.assert_eq(msg.has_prefix("[extension] must be a table"), true)
    Ok(_) => fail("Expected error for non-table extension")
  }
}

///|
test "parse extra-css is not array" {
  let result : Result[BookConfig, ConfigParseError] = Ok(
    BookConfig::parse(
      (
        #|title = "sena!"
        #|[extension]
        #|template = ""
        #|extra-css = "not_an_array"
      ),
    ),
  ) catch {
    e => Err(e)
  }
  match result {
    Err(ConfigParseError(msg)) =>
      @debug.assert_eq(msg.has_prefix("`extra-css` must be an array"), true)
    Ok(_) => fail("Expected error for non-array extra-css")
  }
}

///|
test "parse extra-js array contains non-string" {
  let result : Result[BookConfig, ConfigParseError] = Ok(
    BookConfig::parse(
      (
        #|title = "sena!"
        #|[extension]
        #|template = ""
        #|extra-js = ["ok.js", 42]
      ),
    ),
  ) catch {
    e => Err(e)
  }
  match result {
    Err(ConfigParseError(msg)) =>
      @debug.assert_eq(
        msg.has_prefix("`extra-js` must be an array of strings"),
        true,
      )
    Ok(_) => fail("Expected error for non-string in extra-js")
  }
}

///|
test "parse preprocessors array contains non-string" {
  let result : Result[BookConfig, ConfigParseError] = Ok(
    BookConfig::parse(
      (
        #|title = "sena!"
        #|[extension]
        #|template = ""
        #|preprocessors = [true, false]
      ),
    ),
  ) catch {
    e => Err(e)
  }
  match result {
    Err(ConfigParseError(msg)) =>
      @debug.assert_eq(
        msg.has_prefix("`preprocessors` must be an array of strings"),
        true,
      )
    Ok(_) => fail("Expected error for non-string in preprocessors")
  }
}

///|
test "parse transformers is not array" {
  let result : Result[BookConfig, ConfigParseError] = Ok(
    BookConfig::parse(
      (
        #|title = "sena!"
        #|[extension]
        #|template = ""
        #|transformers = 999
      ),
    ),
  ) catch {
    e => Err(e)
  }
  match result {
    Err(ConfigParseError(msg)) =>
      assert_eq(msg.has_prefix("`transformers` must be an array"), true)
    Ok(_) => fail("Expected error for non-array transformers")
  }
}
