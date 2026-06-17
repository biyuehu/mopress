///|
test "chapter constructor sets stable defaults" {
  let chapter = Chapter::with_path("Intro", "# Intro", "intro.md")
  assert_eq(chapter.name, "Intro")
  assert_eq(chapter.content, "# Intro")
  assert_true(chapter.path is Some("intro.md"))
  assert_true(chapter.source_path is None)
  assert_true(chapter.number is None)
  assert_eq(chapter.parent_names.length(), 0)
  assert_eq(chapter.sub_items.length(), 0)
}

///|
test "book flattens nested chapters in reading order" {
  let install = Chapter::with_path("Install", "install", "guide/install.md")
  let guide = Chapter::with_path("Guide", "guide", "guide.md").with_sub_items([
    Chapter(install),
  ])
  let intro = Chapter::with_path("Intro", "intro", "intro.md")
  let book = Book::with_sections(@config.BookConfig::default(), [
    PartTitle("Getting Started"),
    Chapter(intro),
    Separator,
    Chapter(guide),
  ])
  let chapters = book.chapters()
  assert_eq(book.chapter_count(), 3)
  assert_eq(chapters.length(), 3)
  assert_eq(chapters[0].name, "Intro")
  assert_eq(chapters[1].name, "Guide")
  assert_eq(chapters[2].name, "Install")
}

///|
test "section number appends without mutating original" {
  let first = SectionNumber::new([1])
  let nested = first.append(2).append(3)
  assert_eq(first.to_string(), "1")
  assert_eq(nested.to_string(), "1.2.3")
}

///|
// fn make_demo_book() -> Book {
//   let intro = Chapter::with_path(
//     "Introduction",
//     (
//       #|# Introduction
//       #|
//       #|Welcome to **mopress**.
//       #|
//       #|## Quick start
//       #|
//       #|Write Markdown and render it into a themed page.
//     ),
//     "intro.md",
//   ).with_number(SectionNumber::new([1]))
//   let guide = Chapter::with_path(
//     "Guide",
//     (
//       #|# Guide
//       #|
//       #|This chapter links the book model with the renderer.
//       #|
//       #|## Rendering
//       #|
//       #|Themes provide layout, navigation and assets.
//     ),
//     "guide.md",
//   ).with_number(SectionNumber::new([2]))
//   Book::with_sections(@config.BookConfig::default(), [
//     Chapter(intro),
//     Chapter(guide),
//   ])
// }

///|
// test "book demo renders themed documentation pages" {
//   let book = make_demo_book()
//   let intro_html = render_demo_page(book, 0)
//   let guide_html = render_demo_page(book, 1)

//   assert_true(intro_html.contains("<!doctype html>"))
//   assert_true(intro_html.contains("Introduction"))
//   assert_true(intro_html.contains("Welcome to <strong>mopress</strong>."))
//   assert_true(intro_html.contains("class=\"nav-item active\""))
//   assert_true(intro_html.contains("href=\"#quick-start\""))
//   assert_true(intro_html.contains("Guide"))
//   assert_true(intro_html.contains("guide.html"))

//   assert_true(guide_html.contains("<!doctype html>"))
//   assert_true(
//     guide_html.contains("Themes provide layout, navigation and assets."),
//   )
//   assert_true(guide_html.contains("href=\"#rendering\""))
//   assert_true(guide_html.contains("intro.html"))
// }
