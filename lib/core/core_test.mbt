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
