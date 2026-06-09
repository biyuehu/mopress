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
pub type Frontmatter = Map[String, String]

///|
pub struct MarkdownDoc {
  source : String
  frontmatter : Frontmatter
}

///|
pub fn MarkdownDoc::new(
  source : String,
  frontmatter : Frontmatter,
) -> MarkdownDoc {
  { source, frontmatter }
}

///|
pub struct Html {
  html : String
  frontmatter : Frontmatter
}

///|
pub fn Html::new(html : String, frontmatter : Frontmatter) -> Html {
  { html, frontmatter }
}

///|
pub fn Html::extend(
  self : Html,
  html : String,
  frontmatter? : Frontmatter,
) -> Html {
  if frontmatter is Some(frontmatter) {
    Html::new(html, frontmatter)
  } else {
    { ..self, html, }
  }
}

///|
pub type Vars = Map[String, @template.Value]
