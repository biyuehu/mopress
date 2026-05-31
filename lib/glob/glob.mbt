///|
pub type Pattern = String

///|
pub fn glob_match(pattern : String, path : String) -> Bool {
  if pattern == "*" || pattern == "**" {
    true
  } else if pattern.contains("*") {
    let raw_parts = pattern.split("*").to_array()
    let parts : Array[String] = []
    for part in raw_parts {
      parts.push(part.to_owned())
    }
    let anchored_start = !pattern.has_prefix("*")
    let anchored_end = !pattern.has_suffix("*")
    match matches_parts(parts, path, 0, 0, true, anchored_start) {
      Some(end) => !anchored_end || end == path.length()
      None => false
    }
  } else {
    pattern == path
  }
}

///|
fn matches_parts(
  parts : Array[String],
  path : String,
  part_index : Int,
  from : Int,
  is_first_part : Bool,
  anchored_start : Bool,
) -> Int? {
  if part_index >= parts.length() {
    Some(from)
  } else {
    let part = parts[part_index]
    if part == "" {
      matches_parts(
        parts,
        path,
        part_index + 1,
        from,
        is_first_part,
        anchored_start,
      )
    } else if is_first_part && anchored_start {
      if slice_equals_at(path, part, 0) {
        matches_parts(
          parts,
          path,
          part_index + 1,
          part.length(),
          false,
          anchored_start,
        )
      } else {
        None
      }
    } else {
      match find_from(path, part, from) {
        Some(found) =>
          matches_parts(
            parts,
            path,
            part_index + 1,
            found + part.length(),
            false,
            anchored_start,
          )
        None => None
      }
    }
  }
}

///|
fn find_from(text : String, needle : String, from : Int) -> Int? {
  let text_length = text.length()
  let needle_length = needle.length()
  if needle_length == 0 {
    Some(from)
  } else {
    let mut index = from
    while index + needle_length <= text_length {
      if slice_equals_at(text, needle, index) {
        return Some(index)
      }
      index = index + 1
    }
    None
  }
}

///|
fn slice_equals_at(text : String, needle : String, start : Int) -> Bool {
  if start + needle.length() > text.length() {
    false
  } else {
    let mut index = 0
    while index < needle.length() {
      if text[start + index] != needle[index] {
        return false
      }
      index = index + 1
    }
    true
  }
}
