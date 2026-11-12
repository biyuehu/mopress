///|
test "to_rfc3339: regression single digit day with slashes" {
  assert_eq(to_rfc3339("2026/11/6 15:34:36"), "2026-11-06T15:34:36Z")
}

///|
test "to_rfc3339: single digit month day and time components" {
  assert_eq(to_rfc3339("2026/1/5 9:8:7"), "2026-01-05T09:08:07Z")
}

///|
test "to_rfc3339: already compliant RFC3339 timestamp" {
  assert_eq(to_rfc3339("2026-11-12T00:00:00Z"), "2026-11-12T00:00:00Z")
}

///|
test "to_rfc3339: ISO date with single digit day and Z suffix" {
  assert_eq(to_rfc3339("2026-11-6T15:34:36Z"), "2026-11-06T15:34:36Z")
}

///|
test "to_rfc3339: date only input defaults to 00:00:00Z" {
  assert_eq(to_rfc3339("2026-11-6"), "2026-11-06T00:00:00Z")
}

///|
test "to_rfc3339: preserves timezone offset" {
  assert_eq(
    to_rfc3339("2026-11-06T15:34:36+08:00"),
    "2026-11-06T15:34:36+08:00",
  )
}
