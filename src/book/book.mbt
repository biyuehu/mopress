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

// ///|
// fn Chapter::display_title(self : Chapter) -> String {
//   match self.number {
//     Some(number) => "\{number.to_string()} \{self.name}"
//     None => self.name
//   }
// }

// ///|
// fn Chapter::output_path(self : Chapter) -> String {
//   match self.path {
//     Some(path) => path.replace(old=".md", new=".html")
//     None => self.name.to_lower() + ".html"
//   }
// }

// ///|
// fn build_demo_sidebar(
//   chapters : Array[Chapter],
//   current_title : String,
// ) -> Array[@theme.NavItem] {
//   let items : Array[@theme.NavItem] = []
//   for chapter in chapters {
//     let item = if chapter.name == current_title {
//       @theme.NavItem::new(chapter.display_title(), chapter.output_path()).active()
//     } else {
//       @theme.NavItem::new(chapter.display_title(), chapter.output_path())
//     }
//     items.push(item)
//   }
//   items
// }

// fn render_demo_page(book : Book, current_index : Int) -> String raise {
//   let chapters = book.chapters()
//   let chapter = chapters[current_index]
//   let rendered = @renderer.render_markdown(
//     @markdown.parse_markdown(chapter.content),
//   )
//   let page : @theme.PageData = {
//     title: chapter.name,
//     page_desc: "Generated from the book model",
//     page_badge: Some("demo"),
//     breadcrumb: ["Demo book", chapter.name],
//     sidebar_sections: [
//       @theme.SidebarSection::new(
//         "Chapters",
//         build_demo_sidebar(chapters, chapter.name),
//       ),
//     ],
//     prev_title: if current_index > 0 {
//       Some(chapters[current_index - 1].name)
//     } else {
//       None
//     },
//     prev_url: if current_index > 0 {
//       Some(chapters[current_index - 1].output_path())
//     } else {
//       None
//     },
//     next_title: if current_index + 1 < chapters.length() {
//       Some(chapters[current_index + 1].name)
//     } else {
//       None
//     },
//     next_url: if current_index + 1 < chapters.length() {
//       Some(chapters[current_index + 1].output_path())
//     } else {
//       None
//     },
//   }
//   @theme.apply_theme(rendered, page, @theme.load_default_theme())
// }

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
