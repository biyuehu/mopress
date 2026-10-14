///|
/// Renders a `GlobToken` as a short string, so tests can compare token
/// sequences with `assert_eq` (`GlobToken` itself does not derive `Eq`).
fn token_repr(t : GlobToken) -> String {
  match t {
    Literal(s) => "L(" + s + ")"
    Star => "*"
    DoubleStar => "**"
    Question => "?"
  }
}

///|
fn tokens_repr(ts : Array[GlobToken]) -> Array[String] {
  ts.map(token_repr)
}

///|
test "tokenize: empty pattern" {
  let expected : Array[String] = []
  assert_eq(tokens_repr(tokenize("")), expected)
}

///|
test "tokenize: single literal" {
  assert_eq(tokens_repr(tokenize("a")), ["L(a)"])
}

///|
test "tokenize: single star" {
  assert_eq(tokens_repr(tokenize("*")), ["*"])
}

///|
test "tokenize: single question" {
  assert_eq(tokens_repr(tokenize("?")), ["?"])
}

///|
test "tokenize: single doublestar" {
  assert_eq(tokens_repr(tokenize("**")), ["**"])
}

///|
test "tokenize: star plus extension" {
  assert_eq(tokens_repr(tokenize("*.md")), ["*", "L(.md)"])
}

///|
test "tokenize: alternating star question" {
  assert_eq(tokens_repr(tokenize("a*b?c")), ["L(a)", "*", "L(b)", "?", "L(c)"])
}

///|
test "tokenize: doublestar absorbs following slash" {
  assert_eq(tokens_repr(tokenize("**/")), ["**"])
  assert_eq(tokens_repr(tokenize("**/b")), ["**", "L(b)"])
}

///|
test "tokenize: slash before doublestar stays in literal" {
  assert_eq(tokens_repr(tokenize("a/**")), ["L(a/)", "**"])
  assert_eq(tokens_repr(tokenize("a/**/b")), ["L(a/)", "**", "L(b)"])
}

///|
test "tokenize: leading doublestar with directory suffix" {
  // `**/*.md` is `DoubleStar` (with its trailing slash absorbed) followed
  // by `Star` (the `*` in `*.md`) followed by the literal `.md`.
  assert_eq(tokens_repr(tokenize("**/*.md")), ["**", "*", "L(.md)"])
  assert_eq(tokens_repr(tokenize("src/**/*.md")), [
    "L(src/)", "**", "*", "L(.md)",
  ])
}

///|
test "tokenize: three stars at segment boundary" {
  // `***` forms its own segment: the whole run collapses into `DoubleStar`.
  assert_eq(tokens_repr(tokenize("***")), ["**"])
  // `***.md` has a non-segment boundary after the stars, so the run
  // degrades to a single-segment `Star`.
  assert_eq(tokens_repr(tokenize("***.md")), ["*", "L(.md)"])
}

///|
test "tokenize: mid-segment doublestar degrades to star" {
  assert_eq(tokens_repr(tokenize("**x.md")), ["*", "L(x.md)"])
  assert_eq(tokens_repr(tokenize("a**b")), ["L(a)", "*", "L(b)"])
}

///|
test "match_tokens: empty tokens match only empty path" {
  let tokens : Array[GlobToken] = []
  assert_eq(match_tokens(tokens, 0, "", 0), true)
  assert_eq(match_tokens(tokens, 0, "a", 0), false)
}

///|
test "match_tokens: literal match and mismatch" {
  let tokens = tokenize("ab")
  assert_eq(match_tokens(tokens, 0, "ab", 0), true)
  assert_eq(match_tokens(tokens, 0, "ax", 0), false)
  assert_eq(match_tokens(tokens, 0, "a", 0), false)
}

///|
test "match_tokens: star zero-width and mid-segment" {
  let tokens = tokenize("a*b")
  assert_eq(match_tokens(tokens, 0, "ab", 0), true)
  assert_eq(match_tokens(tokens, 0, "axb", 0), true)
  assert_eq(match_tokens(tokens, 0, "a/x/b", 0), false)
}

///|
test "match_tokens: doublestar zero-width and cross-segment" {
  let tokens = tokenize("a/**/b")
  assert_eq(match_tokens(tokens, 0, "a/b", 0), true)
  assert_eq(match_tokens(tokens, 0, "a/x/b", 0), true)
  assert_eq(match_tokens(tokens, 0, "a/x/y/z/b", 0), true)
  assert_eq(match_tokens(tokens, 0, "a/x/c", 0), false)
}
