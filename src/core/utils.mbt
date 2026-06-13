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
  if ["", ".", @path.sep.to_string()].contains(path) {
    return
  }

  let parts = path.split(@path.sep.to_string())
  let mut current = ""

  for p in parts {
    if p == "" || p == "." {
      continue
    }
    current = if current == "" {
      Show::to_string(p)
    } else {
      current + @path.sep.to_string() + Show::to_string(p)
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
  println("Ensuring dir for file: " + dir + " || file:  " + filepath)
  if !["", ".", @path.sep.to_string()].contains(dir) && !@fs.path_exists(dir) {
    ensure_dir(dir)
  }
}
