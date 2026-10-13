///|
test "template: parse error to_string" {
  assert_eq(TemplateParseError("x").to_string(), "TemplateParseError: x")
}

///|
test "template: render error to_string" {
  assert_eq(
    UndefinedVariableError("x").to_string(),
    "UndefinedVariableError: missing variable: x",
  )
  assert_eq(
    NonArrayForLoopError("x").to_string(),
    "NonArrayForLoopError: expected array for loop: x",
  )
}
