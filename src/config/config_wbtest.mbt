///|
test "config: parse error to_string" {
  assert_eq(ConfigParseError("x").to_string(), "ConfigParseError: x")
}
