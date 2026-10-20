///|
test "load_data_dir: loads json and toml files, ignores subdirs and unsupported extensions" {
  let val = @data.load_data_dir("src/data/testdata")
  guard val is Object(map) else { fail("expected Object") }
  assert_true(map.contains("authors"))
  assert_true(map.contains("sponsors"))
  assert_false(map.contains("ignore"))
  assert_false(map.contains("nested"))
  assert_false(map.contains("subdir"))

  // Verify authors content
  guard map.get("authors") is Some(Array(authors)) else {
    fail("expected authors Array")
  }
  assert_eq(authors.length(), 2)
  guard authors[0] is Object(author0) else {
    fail("expected Object for author0")
  }
  assert_eq(author0.get("name"), Some(@template.Value::String("Alice")))
  assert_eq(author0.get("role"), Some(@template.Value::String("Author")))

  // Verify sponsors content
  guard map.get("sponsors") is Some(Object(sponsors)) else {
    fail("expected sponsors Object")
  }
  assert_eq(sponsors.get("tier"), Some(@template.Value::String("gold")))
  assert_eq(sponsors.get("amount"), Some(@template.Value::Number(100.0)))
  assert_eq(sponsors.get("active"), Some(@template.Value::Bool(true)))
  guard sponsors.get("members") is Some(Array(members)) else {
    fail("expected members Array")
  }
  assert_eq(members.length(), 2)
  assert_eq(members[0], @template.Value::String("Carol"))
  assert_eq(members[1], @template.Value::String("Dave"))
}

///|
test "load_data_dir: non-existent directory returns empty Object" {
  let val = @data.load_data_dir("src/data/testdata/non_existent_dir_12345")
  guard val is Object(map) else { fail("expected Object") }
  assert_eq(map.length(), 0)
}

///|
test "load_data_dir: passing a file path instead of directory returns empty Object" {
  let val = @data.load_data_dir("src/data/testdata/authors.json")
  guard val is Object(map) else { fail("expected Object") }
  assert_eq(map.length(), 0)
}

///|
test "load_data: step attaches data variable to Item" {
  let item = @core.Item::new("hello", "index.md")
  let result = @data.load_data(item, "src/data/testdata")
  guard result.vars.get("data") is Some(Object(map)) else {
    fail("expected data Object in vars")
  }
  assert_true(map.contains("authors"))
  assert_true(map.contains("sponsors"))
}

///|
test "load_data_dir_cached: caches result and can be cleared" {
  @data.clear_data_cache()
  let val1 = @data.load_data_dir_cached("src/data/testdata")
  guard val1 is Object(map1) else { fail("expected Object") }
  assert_true(map1.contains("authors"))

  let val2 = @data.load_data_dir_cached("src/data/testdata")
  guard val2 is Object(map2) else { fail("expected Object") }
  assert_true(map2.contains("authors"))

  @data.clear_data_cache()
  let val3 = @data.load_data_dir_cached("src/data/testdata")
  guard val3 is Object(map3) else { fail("expected Object") }
  assert_true(map3.contains("authors"))
}

///|
test "load_data_dir: loads yaml and yml files" {
  let val = @data.load_data_dir("src/data/testdata")
  guard val is Object(map) else { fail("expected Object") }
  assert_true(map.contains("team"))

  guard map.get("team") is Some(Object(team_obj)) else {
    fail("expected team Object")
  }
  guard team_obj.get("team") is Some(Object(team_info)) else {
    fail("expected team property Object")
  }
  assert_eq(team_info.get("name"), Some(@template.Value::String("Core Team")))
  assert_eq(team_info.get("lead"), Some(@template.Value::String("Alice")))
  assert_eq(team_info.get("count"), Some(@template.Value::Number(5.0)))
  guard team_info.get("tags") is Some(Array(tags)) else {
    fail("expected tags Array")
  }
  assert_eq(tags.length(), 3)
  assert_eq(tags[0], @template.Value::String("moonbit"))
}
