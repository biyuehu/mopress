///|
fn inject_into_head(html : String, tag : String) -> String {
  match html.find("</head>") {
    Some(idx) =>
      Show::to_string(html[0:idx]) + tag + Show::to_string(html[idx:])
    None => tag + html
  }
}

///|
fn inject_before_body_end(html : String, tag : String) -> String {
  match html.find("</body>") {
    Some(idx) =>
      Show::to_string(html[0:idx]) + tag + Show::to_string(html[idx:])
    None => html + tag
  }
}

///|
fn parse_frontmatter(content : String) -> (Frontmatter, String) {
  let content = content.replace_all(old="\r\n", new="\n")
  if !content.has_prefix("---\n") {
    (Map([]), content)
  } else {
    let rest = Show::to_string(content[4:])
    let (end_idx, skip) = if rest.has_prefix("---\n") {
      (0, 4)
    } else {
      match rest.find("\n---\n") {
        None => return (Map([]), content)
        Some(i) => (i, i + 5)
      }
    }
    let fm_str = content[4:4 + end_idx]
    let body = Show::to_string(content[4 + skip:])
    let data : Map[String, String] = Map([])
    for line in fm_str.split("\n") {
      match line.find(":") {
        None => ()
        Some(colon) => {
          let key = Show::to_string(line[:colon].trim())
          let val = Show::to_string(line[colon + 1:].trim())
          data[key] = val
        }
      }
    }
    (data, body)
  }
}

///|
fn ensure_dir(path : String) -> Unit raise @fs.IOError {
  let normalized = path.replace_all(old="\\", new="/")
  if ["", ".", "/"].contains(normalized) {
    return
  }

  let parts = normalized.split("/")
  let mut current = ""

  for p in parts {
    if p == "" || p == "." {
      continue
    }
    current = if current == "" {
      Show::to_string(p)
    } else {
      current + "/" + Show::to_string(p)
    }

    if !@fs.path_exists(current) {
      @fs.create_dir(current)
    } else if !@fs.is_dir(current) {
      raise @fs.IOError("path exists but is not a directory: " + current)
    }
  }
}

///|
fn ensure_dir_for_file(filepath : String) -> Unit raise @fs.IOError {
  let dir = (filepath |> @path.Path).dirname().to_string()
  if !["", ".", "/", "\\"].contains(dir) && !@fs.path_exists(dir) {
    ensure_dir(dir)
  }
}

///|

///|
fn compute_bytes_hash(bytes : Bytes) -> String {
  let hash = @crypto.sha256(bytes)
  @crypto.bytes_to_hex_string(hash)
}

///|
/// Writes this `Thing` to disk under `dest`, but only if the target file does
/// not exist or its existing content hash differs from the new content.
/// Returns `true` if a write actually occurred, or `false` if skipped.
pub fn Thing::write_if_changed(
  self : Thing,
  dest : String,
  target : String,
) -> Bool raise @fs.IOError {
  let path = @path.Path(dest).join(target).to_string()
  ensure_dir_for_file(path)
  match self {
    Doc(doc) => {
      if @fs.path_exists(path) && @fs.is_file(path) {
        try {
          let existing = @fs.read_file_to_string(path)
          if existing == doc {
            return false
          }
        } catch {
          _ => ()
        }
      }
      @fs.write_string_to_file(path, doc)
      true
    }
    Asset(asset) => {
      if @fs.path_exists(path) && @fs.is_file(path) {
        try {
          let existing = @fs.read_file_to_bytes(path)
          if compute_bytes_hash(existing) == compute_bytes_hash(asset) {
            return false
          }
        } catch {
          _ => ()
        }
      }
      @fs.write_bytes_to_file(path, asset)
      true
    }
    Multiple(multiple) => {
      let mut written = false
      for info in multiple {
        let res = info.1.write_if_changed(dest, info.0)
        if res {
          written = true
        }
      }
      written
    }
    Empty => false
  }
}

///|
/// Marker to keep `moonbitlang/async` as a declared dependency of this
/// package: the package is only referenced by whitebox tests (`async test`
/// in `steps_wbtest.mbt`), which the `unused_package` lint does not scan.
fn _mopress_async_import_guard() -> Unit {
  ignore(@async.is_being_cancelled())
}
