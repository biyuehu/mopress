///|
async test "bridge: preprocessors with empty chain return data unchanged" {
  let config = @config.BookConfig::default()
  let result = @bridge.run_markdown_preprocessors(config, "# hi", "a.md")
  assert_eq(result, "# hi")
}

///|
async test "bridge: transformers with empty chain return ast unchanged" {
  let config = @config.BookConfig::default()
  let doc = @markdown.parse_markdown("# hi")
  let result = @bridge.run_markdown_transformers(config, doc, "a.md")
  @debug.assert_eq(result, doc)
}

///|
let fixture : String = "src/bridge/testdata/echo.js"

///|
fn text_config(scripts : Array[String]) -> @config.BookConfig {
  let base = @config.BookConfig::default()
  { ..base, extensions: { ..base.extensions, preprocessors: scripts, }, }
}

///|
fn ast_config(scripts : Array[String]) -> @config.BookConfig {
  let base = @config.BookConfig::default()
  { ..base, extensions: { ..base.extensions, transformers: scripts, }, }
}

///|
async test "bridge: preprocessor echo transforms data" {
  let config = text_config(["bun " + fixture])
  let result = @bridge.run_markdown_preprocessors(config, "hello", "a.md")
  assert_eq(result, "hello [echo]")
}

///|
async test "bridge: preprocessor empty stdout passes through" {
  let config = text_config(["bun " + fixture + " empty"])
  let result = @bridge.run_markdown_preprocessors(config, "hello", "a.md")
  assert_eq(result, "hello")
}

///|
async test "bridge: preprocessor chain runs in order" {
  let config = text_config(["bun " + fixture, "bun " + fixture])
  let result = @bridge.run_markdown_preprocessors(config, "x", "a.md")
  assert_eq(result, "x [echo] [echo]")
}

///|
async test "bridge: preprocessor non-zero exit raises" {
  let config = text_config(["bun " + fixture + " fail"])
  let caught = try {
    let _ = @bridge.run_markdown_preprocessors(config, "x", "a.md")
    ""
  } catch {
    e => e.to_string()
  }
  assert_true(caught.contains("failed with exit code"))
}

///|
async test "bridge: preprocessor stderr raises" {
  let config = text_config(["bun " + fixture + " stderr"])
  let caught = try {
    let _ = @bridge.run_markdown_preprocessors(config, "x", "a.md")
    ""
  } catch {
    e => e.to_string()
  }
  assert_true(caught.contains("reported stderr"))
}

///|
async test "bridge: preprocessor invalid json raises" {
  let config = text_config(["bun " + fixture + " badjson"])
  let caught = try {
    let _ = @bridge.run_markdown_preprocessors(config, "x", "a.md")
    ""
  } catch {
    e => e.to_string()
  }
  assert_true(caught.contains("produced invalid stdout"))
}

///|
async test "bridge: transformer echo passes ast through" {
  let config = ast_config(["bun " + fixture])
  let doc = @markdown.parse_markdown("# hi")
  let result = @bridge.run_markdown_transformers(config, doc, "a.md")
  @debug.assert_eq(result, doc)
}

///|
async test "bridge: script is split into command and arguments" {
  let config = text_config(["bun " + fixture + " inspect alpha beta"])
  let result = @bridge.run_markdown_preprocessors(config, "x", "a.md")
  // The `inspect` mode returns the request data unchanged; the important
  // thing here is that the extra arguments (`alpha`, `beta`) reach the
  // process without being treated as part of the command name.
  assert_eq(result, "x")
}

///|
async test "bridge: request type is markdown-text for preprocessor" {
  let config = text_config(["bun " + fixture + " inspect"])
  let result = @bridge.run_markdown_preprocessors(config, "body", "doc.md")
  assert_eq(result, "body")
}

///|
async test "bridge: transformer non-zero exit raises" {
  let config = ast_config(["bun " + fixture + " fail"])
  let doc = @markdown.parse_markdown("# hi")
  let caught = try {
    let _ = @bridge.run_markdown_transformers(config, doc, "a.md")
    ""
  } catch {
    e => e.to_string()
  }
  assert_true(caught.contains("failed with exit code"))
}

///|
async test "bridge: transformer stderr raises" {
  let config = ast_config(["bun " + fixture + " stderr"])
  let doc = @markdown.parse_markdown("# hi")
  let caught = try {
    let _ = @bridge.run_markdown_transformers(config, doc, "a.md")
    ""
  } catch {
    e => e.to_string()
  }
  assert_true(caught.contains("reported stderr"))
}

///|
async test "bridge: transformer invalid json raises" {
  let config = ast_config(["bun " + fixture + " badjson"])
  let doc = @markdown.parse_markdown("# hi")
  let caught = try {
    let _ = @bridge.run_markdown_transformers(config, doc, "a.md")
    ""
  } catch {
    e => e.to_string()
  }
  assert_true(caught.contains("produced invalid stdout"))
}

///|
async test "bridge: transformer empty stdout passes ast through" {
  let config = ast_config(["bun " + fixture + " empty"])
  let doc = @markdown.parse_markdown("# hi")
  let result = @bridge.run_markdown_transformers(config, doc, "a.md")
  @debug.assert_eq(result, doc)
}

///|
async test "bridge: preprocessor sends markdown-text type and target" {
  let config = text_config(["bun " + fixture + " inspect-text doc.md"])
  let result = @bridge.run_markdown_preprocessors(config, "body", "doc.md")
  // `inspect-text` fills `data` with a JSON string describing the protocol
  // fields it observed, so we can assert on those fields without depending
  // on the `Json` type's concrete constructors.
  assert_true(result.contains("\"type\":\"markdown-text\""))
  assert_true(result.contains("\"target\":\"doc.md\""))
  assert_true(result.contains("\"hasConfig\":true"))
}

///|
async test "bridge: transformer sends markdown-ast type and target" {
  let config = ast_config(["bun " + fixture + " check-ast doc.md"])
  let doc = @markdown.parse_markdown("# hi")
  let result = @bridge.run_markdown_transformers(config, doc, "doc.md")
  @debug.assert_eq(result, doc)
}
