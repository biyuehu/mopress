///|
pub(all) struct Options {
  src : String
  dest : String
} derive(Eq, Debug)

///|
pub impl Default for Options with fn default() -> Options {
  { src: "", dest: "dest" }
}

///|
pub fn Options::from_config(config : @config.BookConfig) -> Options {
  { src: config.src, dest: config.dest }
}

///|
pub type Rules = Array[Rule]

///|
pub(all) enum Rule {
  Glob(String, Mode)
  Guard(String, (String) -> Bool, Mode)
}

///|
pub fn Rule::check(self : Rule, path : String) -> Bool {
  match self {
    Glob(glob, _) => @glob.glob_match(glob, path)
    Guard(glob, f, _) => @glob.glob_match_with(glob, path, f)
  }
}

///|
pub fn Rule::mode(self : Rule) -> Mode {
  match self {
    Glob(_, mode) => mode
    Guard(_, _, mode) => mode
  }
}

///|
pub struct Item[T] {
  data : T
  priv extension : String
  vars : Vars
  target : String
} derive(Eq, Debug)

///|
pub fn[T] Item::new(
  data : T,
  target : String,
  extension? : String,
  vars? : Vars = Map([]),
) -> Item[T] {
  {
    data,
    extension: if extension is Some(extension) && !extension.is_empty() {
      extension
    } else {
      @path.Path(target).extname() |> Show::to_string
    },
    vars,
    target,
  }
}

///|
pub fn[T] Item::location(self : Item[T]) -> String {
  let path = @path.Path(self.target)
  let basename = Show::to_string(path.basename())
  path
  .dirname()
  .join(
    basename
    .rev_find(".")
    .map(index => Show::to_string(basename[:index]))
    .unwrap_or(basename) +
    self.extension,
  )
  .to_string()
}

///|
pub fn[T, R] Item::map(
  self : Item[T],
  f : (T) -> R,
  target? : String,
  extension? : String,
  vars? : Vars,
) -> Item[R] {
  Item::new(
    f(self.data),
    if target is Some(target) {
      target
    } else {
      self.target
    },
    extension=if extension is Some(extension) {
      extension
    } else {
      self.extension
    },
    vars=if vars is Some(vars) { vars } else { self.vars },
  )
}

///|
pub fn[T, R] Item::map_with_eff(
  self : Item[T],
  f : (T) -> R raise,
  target? : String,
  extension? : String,
  vars? : Vars,
) -> Item[R] raise {
  Item::new(
    f(self.data),
    if target is Some(target) {
      target
    } else {
      self.target
    },
    extension=if extension is Some(extension) {
      extension
    } else {
      self.extension
    },
    vars=if vars is Some(vars) { vars } else { self.vars },
  )
}

///|
pub fn[T] Item::extend(
  self : Item[T],
  target? : String,
  extension? : String,
  vars? : Vars,
) -> Item[T] {
  Item::new(
    self.data,
    if target is Some(target) {
      target
    } else {
      self.target
    },
    extension=if extension is Some(extension) {
      extension
    } else {
      self.extension
    },
    vars=if vars is Some(vars) { vars } else { self.vars },
  )
}

///|
pub fn[T] Item::add_vars(self : Item[T], vars : Vars) -> Item[T] {
  self.extend(vars=self.vars.merge(vars))
}

///|
pub fn[T] Item::set_var(
  self : Item[T],
  key : String,
  value : @template.Value,
) -> Item[T] {
  self.extend(vars=self.vars.merge(Map([(key, value)])))
}

///|
pub fn[T] Item::clear_var(self : Item[T], key : String) -> Item[T] {
  self.set_var(key, "" |> String)
}

///|
pub(all) enum Thing {
  Doc(String)
  Asset(Bytes)
  Multiple(Array[(String, Thing)])
  Empty
}

///|
pub fn Thing::write(
  self : Thing,
  dest : String,
  target : String,
) -> Unit raise @fs.IOError {
  let path = @path.Path(dest).join(target).to_string()
  ensure_dir_for_file(path)
  match self {
    Doc(doc) => @fs.write_string_to_file(path, doc)
    Asset(asset) => @fs.write_bytes_to_file(path, asset)
    Multiple(multiple) =>
      for info in multiple {
        info.1.write(dest, info.0)
      }
    Empty => ()
  }
}

///|
pub trait Thingable {
  fn to_thing(self : Self) -> Thing
}

///|
pub impl Thingable for String with fn to_thing(self : String) -> Thing {
  Doc(self)
}

///|
pub impl Thingable for Bytes with fn to_thing(self : Bytes) -> Thing {
  Asset(self)
}

///|
pub impl Thingable for Json with fn to_thing(self : Json) -> Thing {
  Doc(self.stringify())
}

///|
pub type Step[T, R] = async (Item[T]) -> Item[R]

///|
pub(all) enum Mode {
  Text(Step[String, Thing])
  Binary(Step[Bytes, Thing])
  Copy
}

///|
pub async fn Mode::run(
  self : Mode,
  options : Options,
  path : String,
  read_string? : (String) -> String raise = path => {
    @fs.read_file_to_string(path)
  },
  read_bytes? : (String) -> Bytes raise = path => @fs.read_file_to_bytes(path),
) -> Item[Thing] {
  let extension = @path.Path(path).extname() |> Show::to_string
  let target = path[options.src.length() + 1:] |> Show::to_string
  match self {
    Text(f) => read_string(path) |> Item::new(target, extension~) |> f
    Binary(f) => read_bytes(path) |> Item::new(target, extension~) |> f
    Copy => read_bytes(path) |> Item::new(target, extension~) |> identify
  }
}

///|
pub type Frontmatter = Map[String, String]

///|
pub type Html = String

///|
pub type Vars = Map[String, @template.Value]
