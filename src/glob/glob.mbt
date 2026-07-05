///|
priv enum GlobToken {
  Literal(String)
  Star
  DoubleStar
  Question
}

///|
fn tokenize(pattern : String) -> Array[GlobToken] {
  let tokens : Array[GlobToken] = []
  let chars = pattern.to_array()
  let len = chars.length()
  let mut i = 0
  while i < len {
    if chars[i] == '*' {
      if i + 1 < len && chars[i + 1] == '*' {
        tokens.push(DoubleStar)
        i = i + 2
        // skip trailing slash after **
        if i < len && chars[i] == '/' {
          i = i + 1
        }
      } else {
        tokens.push(Star)
        i = i + 1
      }
    } else if chars[i] == '?' {
      tokens.push(Question)
      i = i + 1
    } else {
      let mut j = i
      while j < len && chars[j] != '*' && chars[j] != '?' {
        j = j + 1
      }
      let literal = pattern[i:j]
      tokens.push(Literal(literal.to_owned()))
      i = j
    }
  }
  tokens
}

///|
fn match_tokens(
  tokens : Array[GlobToken],
  ti : Int,
  path : String,
  pi : Int,
) -> Bool {
  if ti >= tokens.length() {
    return pi >= path.length()
  }
  let chars = path.to_array()
  let path_len = path.length()
  match tokens[ti] {
    Literal(s) => {
      let slen = s.length()
      if pi + slen > path_len {
        false
      } else if path[pi:pi + slen].to_owned() != s {
        false
      } else {
        match_tokens(tokens, ti + 1, path, pi + slen)
      }
    }
    Question =>
      if pi >= path_len || chars[pi] == '/' {
        false
      } else {
        match_tokens(tokens, ti + 1, path, pi + 1)
      }
    Star => {
      let mut p = pi
      if match_tokens(tokens, ti + 1, path, p) {
        return true
      }
      while p < path_len && chars[p] != '/' {
        p = p + 1
        if match_tokens(tokens, ti + 1, path, p) {
          return true
        }
      }
      false
    }
    DoubleStar => {
      let mut p = pi
      if match_tokens(tokens, ti + 1, path, p) {
        return true
      }
      while p < path_len {
        p = p + 1
        if match_tokens(tokens, ti + 1, path, p) {
          return true
        }
      }
      false
    }
  }
}

///|
/// Reports whether `path` matches the given glob `pattern`.
///
/// Supports `*` (matching any sequence of characters within a path
/// segment) and `?` (matching any single character), including `**` for
/// matching across path segment boundaries (e.g. `./**/*.js`) and mixed
/// patterns like `src/?.md`. No other glob syntax (such as brace
/// expansion or character classes) is supported.
pub fn glob_match(pattern : String, path : String) -> Bool {
  match_tokens(
    tokenize(pattern),
    0,
    path.replace_all(old=@path.sep.to_string(), new="/"),
    0,
  )
}

///|
/// Like `glob_match`, but delegates to `f` instead of standard glob
/// semantics: `f` receives the full relative path (matching the same
/// candidate path `glob_match` would test against `pattern`) and its
/// return value determines whether that path is considered a match.
///
/// `pattern` follows the same glob syntax as `glob_match` (`*`, `?`, and
/// `**` across path segments).
pub fn glob_match_with(
  pattern : String,
  path : String,
  f : (String) -> Bool,
) -> Bool {
  glob_match(pattern, path) && f(path)
}

//|

///|
/// Recursively scans the directory at `root` and returns the paths of all
/// files matching the glob `pattern` (see `glob_match` for supported
/// syntax: `*`, `?`, and `**` across path segments).
///
/// Raises `@fs.IOError` if `root` cannot be read (e.g. it does not exist,
/// or the process lacks permission to list its contents).
pub fn scan_files(
  dir : String,
  pattern : String,
) -> Array[String] raise @fs.IOError {
  let results = []
  scan_recursive(dir, dir, pattern, results)
  results
}

///|
/// Like `scan_files`, but uses `f` instead of standard glob matching to
/// decide which files to include: for each candidate file, `f` is called
/// with its full relative path (relative to `root`), and the file is
/// included in the result only if `f` returns `true`.
///
/// Raises `@fs.IOError` under the same conditions as `scan_files`.
pub fn scan_files_with(
  dir : String,
  pattern : String,
  f : (String) -> Bool,
) -> Array[String] raise @fs.IOError {
  let results = []
  scan_recursive(dir, dir, pattern, results, f~)
  results
}

///|
fn scan_recursive(
  base : String,
  current : String,
  pattern : String,
  results : Array[String],
  f? : (String) -> Bool,
) -> Unit raise @fs.IOError {
  for entry in @fs.read_dir(current) {
    let full_path = (current |> @path.Path).join(entry).to_string()
    if @fs.is_dir(full_path) {
      if @fs.path_exists(full_path + @path.sep.to_string()) {
        scan_recursive(base, full_path, pattern, results)
      }
    } else if glob_match(
        pattern,
        Show::to_string(full_path[base.length() + 1:]),
      ) &&
      ((f is Some(f) && f(full_path)) || f is None) {
      results.push(full_path)
    }
  }
}
