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
pub struct Runner[E](() -> E)

///|
pub(all) enum Matcher {
  Glob(String)
  Guard(String, (String) -> Bool)
}

///|
pub fn Matcher::check(self : Matcher, path : String) -> Bool {
  match self {
    Glob(glob) => @glob.glob_match(glob, path)
    Guard(glob, f) => @glob.glob_match_with(glob, path, f)
  }
}

///|
pub type Rules = Array[Rule]

///|
pub(all) enum Rule {
  One(Matcher, Mode)
  All(Matcher, Mode)
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
pub fn[T, R] Item::bind(self : Item[T], f : (T) -> R) -> Item[R] {
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
  handle_string? : (String, String) -> Unit raise = (path, data) => {
    @fs.write_string_to_file(path, data)
  },
  handle_bytes? : (String, Bytes) -> Unit raise = (path, data) => {
    @fs.write_bytes_to_file(path, data)
  },
) -> Unit raise {
  let path = @path.Path(dest).join(target).to_string()
  match self {
    Doc(doc) => handle_string(path, doc)
    Asset(asset) => handle_bytes(path, asset)
    Multiple(multiple) =>
      for info in multiple {
        info.1.write(dest, info.0, handle_string~, handle_bytes~)
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
pub type Step[T, R] = (Item[T]) -> Item[R]

///|
pub(all) enum Mode {
  Text(Step[String, Thing])
  Binary(Step[Bytes, Thing])
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
  match self {
    Text(f) => read_string(path) |> Item::new(extension) |> f
    Binary(f) => read_bytes(path) |> Item::new(extension) |> f
  }
}

///|
pub type Meta = Map[String, String]

///|
pub struct MarkdownDoc {
  source : String
  meta : Meta
}

///|
pub fn MarkdownDoc::new(source : String, meta : Meta) -> MarkdownDoc {
  { source, meta }
}

///|
pub struct Html {
  html : String
  meta : Meta
}

///|
pub fn Html::new(html : String, meta : Meta) -> Html {
  { html, meta }
}

///|
pub fn Html::extend(self : Html, html : String, meta? : Meta) -> Html {
  if meta is Some(meta) {
    Html::new(html, meta)
  } else {
    { ..self, html, }
  }
}

///|
pub type Vars = Map[String, @template.Value]
