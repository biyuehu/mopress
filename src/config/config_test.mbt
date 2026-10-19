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
    #|[extensions]
    #|template = "template.html"
    #|use-css = ["// ..."]
    #|use-js = ["console.log('hello')"]
    #|import-css = ["style.css", "custom.css"]
    #|import-js = ["app.js"]
    #|preprocessors = ["katex"]
    #|transformers = ["highlight"]
  let config = @config.BookConfig::parse(toml)
  assert_eq(config.title, "MyBook")
  @debug.assert_eq(config.authors, ["Alice", "Bob"])
  assert_eq(config.description, "A test book")
  assert_eq(config.keywords, "test,moonbit")
  assert_eq(config.language, "zh")
  assert_eq(config.src, "src")
  assert_eq(config.dest, "public")
  assert_eq(config.extensions.template, "template.html")
  @debug.assert_eq(config.extensions.use_css, ["// ..."])
  @debug.assert_eq(config.extensions.use_js, ["console.log('hello')"])
  @debug.assert_eq(config.extensions.import_css, ["style.css", "custom.css"])
  @debug.assert_eq(config.extensions.import_js, ["app.js"])
  @debug.assert_eq(config.extensions.preprocessors, ["katex"])
}

///|
test "parse only title" {
  let config = @config.BookConfig::parse(
    (
      #|title = "OnlyTitle"
    ),
  )
  assert_eq(config.title, "OnlyTitle")
  assert_eq(config.language, "en")
  assert_eq(config.dest, "./dest")
}

///|
test "parse missing extension section" {
  let config = @config.BookConfig::parse(
    (
      #|title = "NoExt"
      #|language = "ja"
    ),
  )
  @debug.assert_eq(config.title, "NoExt")
  @debug.assert_eq(config.extensions.import_css, [])
  @debug.assert_eq(config.extensions.import_js, [])
  @debug.assert_eq(config.extensions.preprocessors, [])
  @debug.assert_eq(config.extensions.transformers, [])
}

///|
test "parse invalid toml syntax" {
  let result : Result[@config.BookConfig, @config.ConfigParseError] = Ok(
    @config.BookConfig::parse("title = "),
  ) catch {
    e => Err(e)
  }
  match result {
    Err(@config.ConfigParseError(msg)) =>
      @debug.assert_eq(msg.has_prefix("Parse config error:"), true)
    Ok(_) => fail("Expected parse error")
  }
}

///|
test "parse title is not string" {
  let result : Result[@config.BookConfig, @config.ConfigParseError] = Ok(
    @config.BookConfig::parse("title = 123"),
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
  let result : Result[@config.BookConfig, @config.ConfigParseError] = Ok(
    @config.BookConfig::parse("extensions = \"not_a_table\""),
  ) catch {
    e => Err(e)
  }
  match result {
    Err(@config.ConfigParseError(msg)) =>
      @debug.assert_eq(msg.has_prefix("[extensions] must be a table"), true)
    Ok(_) => fail("Expected error for non-table extension")
  }
}

///|
test "parse import-css is not array" {
  let result : Result[@config.BookConfig, @config.ConfigParseError] = Ok(
    @config.BookConfig::parse(
      (
        #|title = "sena!"
        #|[extensions]
        #|template = ""
        #|import-css = "not_an_array"
      ),
    ),
  ) catch {
    e => Err(e)
  }
  match result {
    Err(@config.ConfigParseError(msg)) =>
      @debug.assert_eq(msg.has_prefix("`import-css` must be an array"), true)
    Ok(_) => fail("Expected error for non-array import-css")
  }
}

///|
test "parse import-js array contains non-string" {
  let result : Result[@config.BookConfig, @config.ConfigParseError] = Ok(
    @config.BookConfig::parse(
      (
        #|title = "sena!"
        #|[extensions]
        #|template = ""
        #|import-js = ["ok.js", 42]
      ),
    ),
  ) catch {
    e => Err(e)
  }
  match result {
    Err(@config.ConfigParseError(msg)) =>
      @debug.assert_eq(
        msg.has_prefix("`import-js` must be an array of strings"),
        true,
      )
    Ok(_) => fail("Expected error for non-string in import-js")
  }
}

///|
test "parse preprocessors array contains non-string" {
  let result : Result[@config.BookConfig, @config.ConfigParseError] = Ok(
    @config.BookConfig::parse(
      (
        #|title = "sena!"
        #|[extensions]
        #|template = ""
        #|preprocessors = [true, false]
      ),
    ),
  ) catch {
    e => Err(e)
  }
  match result {
    Err(@config.ConfigParseError(msg)) =>
      @debug.assert_eq(
        msg.has_prefix("`preprocessors` must be an array of strings"),
        true,
      )
    Ok(_) => fail("Expected error for non-string in preprocessors")
  }
}

///|
test "parse transformers is not array" {
  let result : Result[@config.BookConfig, @config.ConfigParseError] = Ok(
    @config.BookConfig::parse(
      (
        #|title = "sena!"
        #|[extensions]
        #|template = ""
        #|transformers = 999
      ),
    ),
  ) catch {
    e => Err(e)
  }
  match result {
    Err(@config.ConfigParseError(msg)) =>
      assert_eq(msg.has_prefix("`transformers` must be an array"), true)
    Ok(_) => fail("Expected error for non-array transformers")
  }
}

///|
test "default values" {
  let config = @config.BookConfig::default()
  assert_eq(config.title, "MoPress Doc")
  assert_eq(config.language, "en")
  assert_eq(config.src, "./")
  assert_eq(config.dest, "./dest")
  assert_eq(config.base_url, "/")
  assert_eq(config.extensions.template, "templates/default.html")
  assert_eq(config.features.highlight_enabled, false)
  assert_eq(config.features.mathjax_enabled, false)
}

///|
test "file name constant" {
  assert_eq(@config.file_name, "sena.toml")
}

///|
test "to_toml and parse round trip" {
  let config = @config.BookConfig::default()
  let parsed = @config.BookConfig::parse(config.to_toml())
  assert_true(parsed == config)
}

///|
test "to_toml escapes quotes and backslashes" {
  let config = { ..@config.BookConfig::default(), title: "a\"b\\c", }
  assert_true(config.to_toml().contains("title = \"a\\\"b\\\\c\""))
  let parsed = @config.BookConfig::parse(config.to_toml())
  assert_eq(parsed.title, "a\"b\\c")
}

///|
test "to_toml omits repository when none" {
  let config = { ..@config.BookConfig::default(), repository: None, }
  assert_false(config.to_toml().contains("repository"))
  let parsed = @config.BookConfig::parse(config.to_toml())
  assert_true(parsed.repository is None)
}

///|
test "parse repository and base_url" {
  let config = @config.BookConfig::parse(
    (
      #|title = "T"
      #|repository = "https://example.com/repo"
      #|base_url = "/docs/"
    ),
  )
  assert_true(config.repository == Some("https://example.com/repo"))
  assert_eq(config.base_url, "/docs/")
}

///|
test "missing title is rejected" {
  let message = try @config.BookConfig::parse("language = \"en\"") catch {
    @config.ConfigParseError(msg) => msg
  } noraise {
    _ => abort("expected error")
  }
  assert_eq(message, "Missing required string `title`")
}

///|
test "empty title is rejected" {
  let message = try @config.BookConfig::parse("title = \"\"") catch {
    @config.ConfigParseError(msg) => msg
  } noraise {
    _ => abort("expected error")
  }
  assert_eq(message, "`title` must be a non-empty string")
}

///|
test "features must be a table" {
  let message = try
    @config.BookConfig::parse("title = \"T\"\nfeatures = 1")
  catch {
    @config.ConfigParseError(msg) => msg
  } noraise {
    _ => abort("expected error")
  }
  assert_eq(message, "[features] must be a table")
}

///|
test "boolean feature flag must be boolean" {
  let message = try
    @config.BookConfig::parse(
      "title = \"T\"\n[features]\nhighlight-enabled = \"yes\"",
    )
  catch {
    @config.ConfigParseError(msg) => msg
  } noraise {
    _ => abort("expected error")
  }
  assert_eq(message, "`highlight-enabled` must be a boolean")
}

///|
test "string fields must be strings" {
  let message = try
    @config.BookConfig::parse("title = \"T\"\ndescription = 5")
  catch {
    @config.ConfigParseError(msg) => msg
  } noraise {
    _ => abort("expected error")
  }
  assert_eq(message, "`description` must be a string")
}

///|
test "authors must be array" {
  let message = try
    @config.BookConfig::parse("title = \"T\"\nauthors = \"me\"")
  catch {
    @config.ConfigParseError(msg) => msg
  } noraise {
    _ => abort("expected error")
  }
  assert_eq(message, "`authors` must be an array")
}

///|
test "parse enables highlight preset" {
  let config = @config.BookConfig::parse(
    (
      #|title = "T"
      #|[features]
      #|highlight-enabled = true
      #|highlight-theme = "dark"
    ),
  )
  assert_eq(config.features.highlight_theme, "dark")
  @debug.assert_eq(config.extensions.import_css, [
    "https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.11.1/styles/dark.min.css",
  ])
  assert_eq(config.extensions.import_js.length(), 3)
  assert_true(config.extensions.use_js.contains("hljs.highlightAll()"))
}

///|
test "parse enables mathjax preset" {
  let config = @config.BookConfig::parse(
    (
      #|title = "T"
      #|[features]
      #|mathjax-enabled = true
    ),
  )
  assert_eq(config.extensions.inject_head.length(), 1)
  assert_true(config.extensions.inject_head[0].contains("MathJax"))
}

///|
test "apply_feature_presets is no-op when disabled" {
  let config = @config.BookConfig::default()
  let applied = config.apply_feature_presets()
  assert_eq(applied.extensions.import_css.length(), 0)
  assert_eq(applied.extensions.import_js.length(), 0)
  assert_eq(applied.extensions.inject_head.length(), 0)
}

///|
test "apply_feature_presets on constructed config" {
  let base = @config.BookConfig::default()
  let config = {
    ..base,
    features: {
      ..base.features,
      highlight_enabled: true,
      highlight_theme: "monokai",
      mathjax_enabled: true,
    },
  }.apply_feature_presets()
  assert_true(config.extensions.import_css[0].has_suffix("monokai.min.css"))
  assert_eq(config.extensions.inject_head.length(), 1)
}

///|
test "parse SEO features configuration" {
  // 1. Defaults are true
  let default_cfg = @config.BookConfig::parse("title = \"Test\"")
  assert_true(default_cfg.features.open_graph_enabled)
  assert_true(default_cfg.features.twitter_card_enabled)
  assert_true(default_cfg.features.robots_txt_enabled)

  // 2. Explicitly disabled
  let disabled_toml =
    #|title = "Test"
    #|[features]
    #|open-graph = false
    #|twitter-card = false
    #|robots-txt = false
  let disabled_cfg = @config.BookConfig::parse(disabled_toml)
  assert_false(disabled_cfg.features.open_graph_enabled)
  assert_false(disabled_cfg.features.twitter_card_enabled)
  assert_false(disabled_cfg.features.robots_txt_enabled)

  // 3. Serialized to toml contains SEO flags
  let toml = disabled_cfg.to_toml()
  assert_true(toml.contains("open-graph = false"))
  assert_true(toml.contains("twitter-card = false"))
  assert_true(toml.contains("robots-txt = false"))
}
