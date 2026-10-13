///|
test "bridge: non zero exit to_string" {
  let err : ProcessorError = ProcessorError::NonZeroExit(
    command="x",
    exit_code=2,
    stderr="e",
  )
  assert_eq(
    err.to_string(),
    "ProcessorError: Command x failed with exit code 2 and stderr: e",
  )
}

///|
test "bridge: stderr reported to_string" {
  let err : ProcessorError = ProcessorError::StderrReported(
    command="x",
    message="m",
  )
  assert_eq(err.to_string(), "ProcessorError: Command x reported stderr: m")
}

///|
test "bridge: invalid stdout to_string" {
  let err : ProcessorError = ProcessorError::InvalidStdout(
    command="x",
    raw="r",
    reason="why",
  )
  assert_eq(
    err.to_string(),
    "ProcessorError: Command x produced invalid stdout: r (reason: why)",
  )
}
