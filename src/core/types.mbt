///|
pub(all) struct Options {
  // title : String
  // authors : Array[String]
  // description : String
  // language : String
  src : String
  dest : String
} derive(Eq, Debug)

///|
pub impl Default for Options with fn default() -> Options {
  { src: "", dest: "dest" }
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
  extension : String
}

///|
pub fn[T] Item::new(data : T, extension : String) -> Item[T] {
  { data, extension }
}

///|
pub fn[T, R] Item::map(self : Item[T], f : (T) -> R) -> Item[R] {
  Item::new(f(self.data), self.extension)
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
  println("path:" + path)
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
  Thing::Doc(self)
}

///|
pub impl Thingable for Bytes with fn to_thing(self : Bytes) -> Thing {
  Thing::Asset(self)
}

///|
pub impl Thingable for Html with fn to_thing(self : Html) -> Thing {
  Thing::Doc(self.html)
}

///|
pub type Step[T, R] = (Item[T]) -> Item[R] raise

///|
pub(all) enum Mode {
  Text(Step[String, Thing])
  Binary(Step[Bytes, Thing])
  Copy
}

///|
pub fn Mode::run(
  self : Mode,
  path : String,
  read_string? : (String) -> String raise = path => {
    @fs.read_file_to_string(path)
  },
  read_bytes? : (String) -> Bytes raise = path => @fs.read_file_to_bytes(path),
) -> Item[Thing] raise {
  let extension = @path.Path(path).extname() |> Show::to_string
  println("path:" + path + " extension:" + extension)
  match self {
    Text(f) => read_string(path) |> Item::new(extension) |> f
    Binary(f) => read_bytes(path) |> Item::new(extension) |> f
    Copy => read_bytes(path) |> Item::new(extension) |> identify
  }
}

///|
pub type Frontmatter = Map[String, String]

///|
pub struct Html {
  html : String
  vars : Vars
}

///|
pub fn Html::new(html : String, vars : Vars) -> Html {
  { html, vars }
}

///|
pub fn Html::extend(self : Html, html : String, vars? : Vars) -> Html {
  if vars is Some(vars) {
    Html::new(html, vars)
  } else {
    { ..self, html, }
  }
}

///|
pub fn Html::add_vars(self : Html, vars : Vars) -> Html {
  { ..self, vars: self.vars.merge(vars) }
}

///|
pub fn Html::set_var(
  self : Html,
  key : String,
  value : @template.Value,
) -> Html {
  let vars = self.vars.merge(Map([(key, value)]))
  Html::new(self.html, vars)
}

///|
pub fn Html::clear_var(self : Html, key : String) -> Html {
  self.set_var(key, "" |> String)
}

//|

///|
pub type Vars = Map[String, @template.Value]
