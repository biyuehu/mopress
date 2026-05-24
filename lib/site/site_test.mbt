///|
test "glob pattern matches exact and wildcard paths" {
  assert_true(Pattern::glob("README.md").matches("README.md"))
  assert_false(Pattern::glob("README.md").matches("src/README.md"))
  assert_true(Pattern::glob("*.md").matches("chapter.md"))
  assert_false(Pattern::glob("*.md").matches("chapter.md.bak"))
  assert_true(Pattern::glob("src/*.md").matches("src/chapter.md"))
  assert_false(Pattern::glob("src/*.md").matches("draft/src/chapter.md"))
  assert_true(Pattern::glob("src/*/index.md").matches("src/guide/index.md"))
  assert_false(Pattern::glob("src/*.md").matches("assets/style.css"))
}

///|
test "resource helpers keep transformations explicit" {
  let resource = Resource::new("src/index.md", "# Home")
    .with_metadata("title", "Home")
    .with_path("index.html")
  assert_eq(resource.path, "index.html")
  assert_eq(resource.content, "# Home")
  assert_true(resource.metadata.get("title") is Some("Home"))
}

///|
test "site rules can model one and all operations" {
  let site = Site::new()
    .add_rule(
      one("**/*.md", fn(resource) {
        [map_content(resource, fn(s) { s + "\n" })]
      }),
    )
    .add_rule(all("assets/*", fn(resources) { resources }))
  assert_eq(site.rules.length(), 2)
}
