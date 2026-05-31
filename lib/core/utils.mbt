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
fn parse_frontmatter(content : String) -> (Meta, String) {
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
