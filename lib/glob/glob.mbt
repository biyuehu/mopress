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
      // 匹配单个非/字符
      if pi >= path_len || chars[pi] == '/' {
        false
      } else {
        match_tokens(tokens, ti + 1, path, pi + 1)
      }
    Star => {
      // 贪心尝试所有不含/的位置
      let mut p = pi
      // 先尝试匹配空字符串
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
pub fn glob_match(pattern : String, path : String) -> Bool {
  let tokens = tokenize(pattern)
  match_tokens(tokens, 0, path, 0)
}

///|
pub fn scan_files(
  dir : String,
  pattern : String,
) -> Array[String] raise @fs.IOError {
  let results = []
  scan_recursive(dir, dir, pattern, results)
  results
}

///|
fn scan_recursive(
  base : String,
  current : String,
  pattern : String,
  results : Array[String],
) -> Unit raise @fs.IOError {
  for entry in @fs.read_dir(current) {
    let full_path = current + "/" + entry
    if @fs.path_exists(full_path + "/") {
      scan_recursive(base, full_path, pattern, results)
    } else if glob_match(
        pattern,
        Show::to_string(full_path[base.length() + 1:]),
      ) {
      results.push(full_path)
    }
  }
}
