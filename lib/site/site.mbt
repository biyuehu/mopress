///|
pub(all) struct Pattern {
  raw : String
} derive(Eq, Debug)

///|
pub(all) struct Resource {
  path : String
  content : String
  metadata : Map[String, String]
} derive(Eq, Debug)

///|
pub(all) struct Site {
  rules : Array[SiteRule]
}

///|
pub(all) enum SiteRule {
  One(Pattern, (Resource) -> Array[Resource])
  All(Pattern, (Array[Resource]) -> Array[Resource])
}

///|
pub fn Pattern::glob(raw : String) -> Pattern {
  { raw, }
}

///|
pub fn Pattern::matches(self : Pattern, path : String) -> Bool {
  glob_matches(self.raw, path)
}

///|
pub fn Resource::new(path : String, content : String) -> Resource {
  { path, content, metadata: Map([]) }
}

///|
pub fn Resource::with_metadata(
  self : Resource,
  key : String,
  value : String,
) -> Resource {
  let metadata = self.metadata.copy()
  metadata[key] = value
  { ..self, metadata, }
}

///|
pub fn Resource::with_path(self : Resource, path : String) -> Resource {
  { ..self, path, }
}

///|
pub fn Resource::with_content(self : Resource, content : String) -> Resource {
  { ..self, content, }
}

///|
pub fn Site::new() -> Site {
  { rules: [] }
}

///|
pub fn Site::with_rules(rules : Array[SiteRule]) -> Site {
  { rules, }
}

///|
pub fn Site::add_rule(self : Site, rule : SiteRule) -> Site {
  let rules = self.rules.copy()
  rules.push(rule)
  { rules, }
}

///|
pub fn one(glob : String, action : (Resource) -> Array[Resource]) -> SiteRule {
  One(Pattern::glob(glob), action)
}

///|
pub fn all(
  glob : String,
  action : (Array[Resource]) -> Array[Resource],
) -> SiteRule {
  All(Pattern::glob(glob), action)
}

///|
pub fn copy_resource(resource : Resource) -> Array[Resource] {
  [resource]
}

///|
pub fn drop_resource(_resource : Resource) -> Array[Resource] {
  []
}

///|
pub fn map_content(
  resource : Resource,
  transform : (String) -> String,
) -> Resource {
  resource.with_content(transform(resource.content))
}

///|
fn glob_matches(pattern : String, path : String) -> Bool {
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
