///|
pub type Glob = String

///|
pub(all) enum Matcher {
  Glob(Glob)
  Guard(Glob, (String) -> Bool)
}

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
