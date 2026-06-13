///|
pub(all) struct Book {
  config : @config.BookConfig
  sections : Array[BookItem]
} derive(Eq, Debug)

///|
pub(all) struct Chapter {
  name : String
  content : String
  number : SectionNumber?
  path : String?
  source_path : String?
  parent_names : Array[String]
  sub_items : Array[BookItem]
} derive(Eq, Debug)

///|
pub(all) struct SectionNumber {
  parts : Array[Int]
} derive(Eq, Debug)

///|
pub(all) enum BookItem {
  Chapter(Chapter)
  Separator
  PartTitle(String)
} derive(Eq, Debug)

///|
pub fn Book::new(config : @config.BookConfig) -> Book {
  { config, sections: [] }
}

///|
pub fn Book::with_sections(
  config : @config.BookConfig,
  sections : Array[BookItem],
) -> Book {
  { config, sections }
}

///|
pub fn Book::chapter_count(self : Book) -> Int {
  count_chapters(self.sections)
}

///|
pub fn Book::chapters(self : Book) -> Array[Chapter] {
  let chapters : Array[Chapter] = []
  collect_chapters(self.sections, chapters)
  chapters
}

///|
pub fn Chapter::new(name : String, content : String) -> Chapter {
  {
    name,
    content,
    number: None,
    path: None,
    source_path: None,
    parent_names: [],
    sub_items: [],
  }
}

///|
pub fn Chapter::with_path(
  name : String,
  content : String,
  path : String,
) -> Chapter {
  {
    name,
    content,
    number: None,
    path: Some(path),
    source_path: None,
    parent_names: [],
    sub_items: [],
  }
}

///|
pub fn Chapter::with_sub_items(
  self : Chapter,
  sub_items : Array[BookItem],
) -> Chapter {
  { ..self, sub_items, }
}

///|
pub fn Chapter::with_number(self : Chapter, number : SectionNumber) -> Chapter {
  { ..self, number: Some(number) }
}

///|
pub fn Chapter::with_source_path(
  self : Chapter,
  source_path : String,
) -> Chapter {
  { ..self, source_path: Some(source_path) }
}

///|
pub fn Chapter::with_parent_names(
  self : Chapter,
  parent_names : Array[String],
) -> Chapter {
  { ..self, parent_names, }
}

///|
pub fn SectionNumber::new(parts : Array[Int]) -> SectionNumber {
  { parts, }
}

///|
pub fn SectionNumber::append(self : SectionNumber, part : Int) -> SectionNumber {
  let parts = self.parts.copy()
  parts.push(part)
  { parts, }
}

///|
pub fn SectionNumber::to_string(self : SectionNumber) -> String {
  let mut result = ""
  for index = 0; index < self.parts.length(); index = index + 1 {
    if index > 0 {
      result = result + "."
    }
    result = result + self.parts[index].to_string()
  }
  result
}

///|
fn count_chapters(items : Array[BookItem]) -> Int {
  let mut count = 0
  for item in items {
    match item {
      Chapter(chapter) => count = count + 1 + count_chapters(chapter.sub_items)
      Separator | PartTitle(_) => ()
    }
  }
  count
}

///|
fn collect_chapters(items : Array[BookItem], output : Array[Chapter]) -> Unit {
  for item in items {
    match item {
      Chapter(chapter) => {
        output.push(chapter)
        collect_chapters(chapter.sub_items, output)
      }
      Separator | PartTitle(_) => ()
    }
  }
}
