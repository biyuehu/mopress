///|
/// The source and destination directories for a build, relative to the
/// project root.
pub(all) struct Options {
  src : String
  dest : String
} derive(Eq, Debug)

///|
/// The default build options.
pub impl Default for Options with fn default() -> Options {
  { src: "", dest: "dest" }
}

///|
/// Derives build `Options` (source/destination directories) from a
/// project's `BookConfig`.
pub fn Options::from_config(config : @config.BookConfig) -> Options {
  { src: config.src, dest: config.dest }
}

///|
/// A collection of build rules, as passed to `mo_build`/`mopress`.
pub type Rules = Array[Rule]

///|
/// A single rule describing how files matching a pattern should be
/// processed during a build.
pub(all) enum Rule {
  /// Matches files by glob pattern (see `@glob.glob_match`) alone.
  Glob(String, Handler)
  /// Matches files by glob pattern, further filtered by a user-supplied
  /// predicate: a file matches this rule only if it matches the glob
  /// pattern *and* the predicate returns `true` when called with the
  /// file's full relative path (consistent with `@glob.glob_match_with`).
  Guard(String, (String) -> Bool, Handler)
} derive(Debug)

///|
/// Reports whether `path` matches this rule (i.e. whether it should be
/// processed according to this rule's `Handler`).
pub fn Rule::check(self : Rule, path : String) -> Bool {
  match self {
    Glob(glob, _) => @glob.glob_match(glob, path)
    Guard(glob, f, _) => @glob.glob_match_with(glob, path, f)
  }
}

///|
/// Returns this rule's processing `Handler`.
pub fn Rule::handler(self : Rule) -> Handler {
  match self {
    Glob(_, handler) => handler
    Guard(_, _, handler) => handler
  }
}

///|
/// The core unit of data flowing through a mopress build pipeline.
///
/// An `Item[T]` carries a piece of data of type `T` (e.g. raw text,
/// a parsed Markdown AST, or rendered HTML), a set of template variables
/// (`vars`) that will be available when the item is eventually rendered
/// through a template, and a `target` path describing where the item's
/// output should be written.
///
/// Steps (functions of the shape `(Item[T]) -> Item[R]`, optionally
/// raising or async) transform an `Item` from one representation to
/// another while carrying its variables and target path forward, so that
/// a page's content can flow through a chain of transformations —
/// parsing, preprocessing, transforming, rendering, and templating — as a
/// pipeline of `Item` values.
pub struct Item[T] {
  data : T
  priv extension : String
  vars : Vars
  target : String
} derive(Eq, Debug)

///|
/// Creates a new item with the given `data` and `target` path, optionally
/// overriding its extension and/or providing an initial set of template
/// variables.
///
/// `extension`, when provided, should include its leading dot (e.g.
/// `.html`), consistent with `set_extension`.
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
/// Returns this item's target path, e.g. for use in resolving relative
/// links, breadcrumbs, or previous/next navigation (see
/// `@summary.Summary::breadcrumb` and `@summary.Summary::prev_next`).
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
/// Applies `f` to this item's data to produce a new item with data of
/// type `R`, optionally overriding `target`, `extension`, and/or `vars` in
/// the same way as `Item::base`.
///
/// `extension`, when provided, should include its leading dot (e.g.
/// `.html`), consistent with `set_extension`.
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
/// Like `Item::map`, but `f` may raise; the resulting error propagates out
/// of this call rather than being caught.
///
/// `extension`, when provided, should include its leading dot (e.g.
/// `.html`), consistent with `set_extension`.
pub fn[T, R] Item::map_with_raise(
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
/// Returns a copy of `self` with `target`, `extension`, and/or `vars`
/// overridden by the given optional arguments, leaving `data` and any
/// unspecified fields unchanged.
///
/// `extension`, when provided, should include its leading dot (e.g.
/// `.html`), consistent with `set_extension`.
pub fn[T] Item::base(
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
/// Returns a copy of `self` with the given variables merged into its
/// existing `vars`, overwriting any existing entries with the same key.
pub fn[T] Item::add_vars(self : Item[T], vars : Vars) -> Item[T] {
  self.base(vars=self.vars.merge(vars))
}

///|
/// Returns a copy of `self` with the variable named `key` set to `value`
/// in its `vars`, overwriting any existing entry with the same key.
pub fn[T] Item::set_var(
  self : Item[T],
  key : String,
  value : @template.Value,
) -> Item[T] {
  self.base(vars=self.vars.merge(Map([(key, value)])))
}

///|
/// Returns a copy of `self` with the variable named `key` removed from
/// its `vars`, if present.
pub fn[T] Item::clear_var(self : Item[T], key : String) -> Item[T] {
  self.set_var(key, "" |> String)
}

///|
/// The final, writable output produced for a build item.
pub(all) enum Thing {
  /// A text document, e.g. rendered HTML.
  Doc(String)
  /// A binary asset, e.g. an image or other file copied/produced as raw
  /// bytes.
  Asset(Bytes)
  /// Several named outputs produced from a single build item; each tuple
  /// pairs a file name (including its extension) with the `Thing` to be
  /// written under that name.
  Multiple(Array[(String, Thing)])
  /// No output should be written for this item.
  Empty
} derive(Eq, Debug)

///|
/// Writes this `Thing` to disk under `dest`, using `name` as the output
/// file name (including extension) — or, for `Multiple`, as the base
/// directory under which each named sub-output is written.
///
/// This is a thin wrapper around the underlying filesystem write
/// operations (see `@fs`); no additional processing (e.g. templating or
/// transformation) is applied here.
///
/// Raises `@fs.IOError` if writing fails.
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
/// Types that can be converted into a `Thing`, the common output
/// representation written to disk at the end of a build pipeline.
pub trait Thingable {
  fn to_thing(self : Self) -> Thing
}

///|
/// Converts a `String` into a `Thing::Doc`.
pub impl Thingable for String with fn to_thing(self : String) -> Thing {
  Doc(self)
}

///|
/// Converts `Bytes` into a `Thing::Asset`.
pub impl Thingable for Bytes with fn to_thing(self : Bytes) -> Thing {
  Asset(self)
}

///|
/// Converts a `Json` value into a `Thing::Doc` by converting it to a JSON string.
pub impl Thingable for Json with fn to_thing(self : Json) -> Thing {
  Doc(self.stringify())
}

///|
/// A pipeline step transforming an `Item[T]` into an `Item[R]`.
pub type Step[T, R] = async (Item[T]) -> Item[R]

///|
/// The processing handler applied to files matched by a `Rule`.
pub(all) enum Handler {
  /// Reads the matched file as text and processes it with the given
  /// step, producing the final `Item[Thing]` to be written to disk.
  Text(async (Item[String]) -> Item[Thing])
  /// Reads the matched file as raw bytes and processes it with the given
  /// step, producing the final `Item[Thing]` to be written to disk.
  Binary(async (Item[Bytes]) -> Item[Thing])
  /// Copies the matched file to the output directory unchanged, without
  /// any processing.
  Copy
} derive(Debug)

///|
/// Executes this handler against the file at `path` (relative to
/// `options.src`), returning the resulting `Item[Thing]`.
///
/// `read_string` and `read_bytes` allow overriding how the file's
/// contents are read for `Text` and `Binary` handlers respectively
/// (defaulting to ordinary filesystem reads), which is primarily useful
/// for testing or for sourcing content from something other than the
/// local filesystem.
pub async fn Handler::run(
  self : Handler,
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
    Copy => read_bytes(path) |> Item::new(target, extension~) |> unify
  }
}

///|
/// A YAML frontmatter block, parsed as a map of string keys to string
/// values.
pub type Frontmatter = Map[String, String]

///|
/// A rendered HTML string.
pub type Html = String

///|
/// A set of named template variables, as carried by `Item.vars`.
pub type Vars = Map[String, @template.Value]
