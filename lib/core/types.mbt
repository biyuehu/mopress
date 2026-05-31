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
pub(all) struct Item[T] {
  data : T
  extension : String
}

///|
pub(all) enum Output {
  Text(String, String)
  Binary(String, Bytes)
  Multiple(Array[(String, Output)])
  Empty
}

///|
pub type Step[T, R] = (Item[T]) -> Item[R]

///|
pub(all) enum Mode {
  Text(Step[String, Output])
  Binary(Step[Bytes, Output])
}
