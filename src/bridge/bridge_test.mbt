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
