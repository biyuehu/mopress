///|
/// Converts a `@toml.TomlValue` into a `@template.Value`.
pub fn value_from_toml(toml : @toml.TomlValue) -> @template.Value {
  match toml {
    TomlString(s) => @template.Value::String(s)
    TomlInteger(i) => @template.Value::Number(i.to_double())
    TomlFloat(f) => @template.Value::Number(f)
    TomlBoolean(b) => @template.Value::Bool(b)
    TomlArray(arr) => @template.Value::Array(arr.map(value_from_toml))
    TomlTable(table) => {
      let m : Map[String, @template.Value] = Map([])
      for k, v in table {
        // Skip internal TOML marker keys
        if !k.has_prefix("\u0000") {
          m[k] = value_from_toml(v)
        }
      }
      @template.Value::Object(m)
    }
    TomlDateTime(dt) => {
      let str = match dt {
        OffsetDateTime(s) | LocalDateTime(s) | LocalDate(s) | LocalTime(s) => s
      }
      @template.Value::String(str)
    }
  }
}

///|
/// Loads every structured file under `dir` into a single `Value::Object`,
/// keyed by each file's basename without extension. Subdirectories are
/// ignored. Unsupported extensions or unparseable files are skipped silently.
///
/// If `dir` does not exist or is not a directory, returns an empty Object.
pub fn load_data_dir(dir : String) -> @template.Value {
  let empty = @template.Value::Object(Map([]))
  if !@fs.path_exists(dir) {
    return empty
  }
  let is_directory = @fs.is_dir(dir) catch { _ => false }
  if !is_directory {
    return empty
  }
  let entries = @fs.read_dir(dir) catch { _ => return empty }
  let result : Map[String, @template.Value] = Map([])
  for entry in entries {
    let full_path = @path.Path(dir).join(entry).to_string()
    let is_sub_dir = @fs.is_dir(full_path) catch { _ => true }
    if is_sub_dir {
      continue
    }
    let p = @path.Path(entry)
    let ext = Show::to_string(p.extname()).to_lower()
    let basename = Show::to_string(p.basename())
    let stem = match basename.rev_find(".") {
      Some(idx) => Show::to_string(basename[:idx])
      None => basename
    }
    if stem.is_empty() {
      continue
    }
    if ext == ".json" {
      try {
        let content = @fs.read_file_to_string(full_path)
        let json = @json.parse(content)
        result[stem] = @template.Value::from_json(json)
      } catch {
        _ => ()
      }
    } else if ext == ".toml" {
      try {
        let content = @fs.read_file_to_string(full_path)
        let toml = @toml.parse(content)
        result[stem] = value_from_toml(toml)
      } catch {
        _ => ()
      }
    } else if ext == ".yaml" || ext == ".yml" {
      try {
        let content = @fs.read_file_to_string(full_path)
        let docs = @yaml.Yaml::load_from_string(content)
        if docs.length() > 0 {
          result[stem] = value_from_yaml(docs[0])
        }
      } catch {
        _ => ()
      }
    }
  }
  @template.Value::Object(result)
}

///|
let data_cache : Map[String, @template.Value] = Map([])

///|
/// Returns cached data for `dir` if available, or loads and caches it.
pub fn load_data_dir_cached(dir : String) -> @template.Value {
  match data_cache.get(dir) {
    Some(val) => val
    None => {
      let val = load_data_dir(dir)
      data_cache[dir] = val
      val
    }
  }
}

///|
/// Clears the in-memory cache of loaded data directories.
pub fn clear_data_cache() -> Unit {
  data_cache.clear()
}

///|
/// Site mode step that loads structured data from `dir` and attaches it
/// to the item under variable name `"data"`.
pub fn[T] load_data(
  item : @core.Item[T],
  dir : String,
  cached~ : Bool = true,
) -> @core.Item[T] {
  let data = if cached { load_data_dir_cached(dir) } else { load_data_dir(dir) }
  item.set_var("data", data)
}

///|
/// Converts a `@yaml.Yaml` value into a `@template.Value`.
pub fn value_from_yaml(yaml : @yaml.Yaml) -> @template.Value {
  match yaml {
    Null => @template.Value::Object(Map([]))
    Boolean(b) => @template.Value::Bool(b)
    Integer(i) => @template.Value::Number(i.to_double())
    Real(f, ..) => @template.Value::Number(f)
    String(s) => @template.Value::String(s)
    Array(arr) => @template.Value::Array(arr.map(value_from_yaml))
    Map(m) => {
      let res : Map[String, @template.Value] = Map([])
      for k, v in m {
        res[k] = value_from_yaml(v)
      }
      @template.Value::Object(res)
    }
    BadValue => @template.Value::Object(Map([]))
  }
}
