///|
pub(all) struct RenderOptions {
  heading_anchor_prefix : String
  allow_raw_html : Bool
}

///|
pub(all) struct TocItem {
  level : Int
  title : String
  anchor : String
} derive(Eq, Debug)

///|
priv struct RenderContext {
  slug_counts : Map[String, Int]
  toc : Array[TocItem]
  opt : RenderOptions
}

///|
pub(all) struct RenderedMarkdown {
  html : String
  toc : Array[TocItem]
}

///|
pub impl Default for RenderOptions with fn default() -> RenderOptions {
  { heading_anchor_prefix: "", allow_raw_html: true }
}

///|
pub fn render_markdown(
  md : @markdown.Markdown,
  opt? : RenderOptions = RenderOptions::default(),
) -> RenderedMarkdown {
  let ctx = { slug_counts: Map([]), toc: [], opt }
  { html: render_blocks(md, ctx), toc: ctx.toc }
}

///|
fn render_blocks(blocks : @markdown.Markdown, ctx : RenderContext) -> String {
  let out = StringBuilder::new()
  for block in blocks {
    out.write_string(render_block(block, ctx))
    out.write_char('\n')
  }
  out.to_string()
}

///|
fn render_block(block : @markdown.Block, ctx : RenderContext) -> String {
  match block {
    @markdown.Heading(level, inlines) => render_heading(level, inlines, ctx)
    @markdown.Paragraph(inlines) =>
      "<p>" + render_inlines(inlines, ctx) + "</p>"
    @markdown.ThematicBreak => "<hr>"
    @markdown.CodeBlock(lang, code) => render_code_block(lang, code)
    @markdown.BlockQuote(inner) =>
      "<blockquote>\n" + render_blocks(inner, ctx) + "</blockquote>"
    @markdown.List(list) => render_list(list, ctx)
    @markdown.HtmlBlock(raw) =>
      if ctx.opt.allow_raw_html {
        raw
      } else {
        "<pre class=\"html-block-escaped\"><code>" +
        escape_html(raw) +
        "</code></pre>"
      }
  }
}

///|
fn render_heading(
  level : Int,
  inlines : Array[@markdown.Inline],
  ctx : RenderContext,
) -> String {
  let title_text = plain_text_from_inlines(inlines)
  let anchor = unique_slug(slugify(title_text), ctx.slug_counts)
  let full_anchor = ctx.opt.heading_anchor_prefix + anchor
  ctx.toc.push({ level, title: title_text, anchor: full_anchor })
  let tag = heading_tag(level)
  "<" +
  tag +
  " id=\"" +
  escape_attr(full_anchor) +
  "\">" +
  "<a class=\"heading-anchor\" href=\"#" +
  escape_attr(full_anchor) +
  "\" aria-hidden=\"true\">#</a>" +
  render_inlines(inlines, ctx) +
  "</" +
  tag +
  ">"
}

///|
fn render_inlines(
  inlines : Array[@markdown.Inline],
  ctx : RenderContext,
) -> String {
  let out = StringBuilder::new()
  for inline in inlines {
    out.write_string(render_inline(inline, ctx))
  }
  out.to_string()
}

///|
fn render_inline(inline : @markdown.Inline, ctx : RenderContext) -> String {
  match inline {
    @markdown.Text(s) => escape_html(s)
    @markdown.Emphasis(xs) => "<em>" + render_inlines(xs, ctx) + "</em>"
    @markdown.Strong(xs) => "<strong>" + render_inlines(xs, ctx) + "</strong>"
    @markdown.Code(s) => "<code>" + escape_html(s) + "</code>"
    @markdown.Link(label, href) => render_link(label, href, ctx)
    @markdown.Image(alt, src) => render_image(alt, src)
    @markdown.Html(raw) =>
      if ctx.opt.allow_raw_html {
        raw
      } else {
        escape_html(raw)
      }
    @markdown.SoftBreak => "\n"
    @markdown.HardBreak => "<br>"
  }
}

///|
fn render_link(
  label : Array[@markdown.Inline],
  href : String,
  ctx : RenderContext,
) -> String {
  "<a href=\"" + escape_attr(href) + "\">" + render_inlines(label, ctx) + "</a>"
}

///|
fn render_image(alt : String, src : String) -> String {
  "<img src=\"" +
  escape_attr(src) +
  "\" alt=\"" +
  escape_attr(alt) +
  "\" loading=\"lazy\" decoding=\"async\"" +
  ">"
}

///|
fn render_code_block(lang : String?, code : String) -> String {
  let lang_text = option_string(lang)
  let lang_label = if lang_text == "" { "text" } else { lang_text }
  let code_attrs = if lang_text == "" {
    ""
  } else {
    " class=\"language-" + escape_attr(slugify(lang_text)) + "\""
  }
  let out = StringBuilder::new()
  out.write_string("<div class=\"code-block\">")
  out.write_string("<div class=\"code-header\">")
  out.write_string(
    "<span class=\"code-lang\">" + escape_html(lang_label) + "</span>",
  )
  out.write_string(
    "<button class=\"code-copy\" type=\"button\" data-copy-button>copy</button>",
  )
  out.write_string("</div>")
  out.write_string("<pre class=\"code-body\"><code")
  out.write_string(code_attrs)
  out.write_string(">")
  out.write_string(escape_html(code))
  out.write_string("</code></pre>")
  out.write_string("</div>")
  out.to_string()
}

///|
fn render_list(list : @markdown.ListBlock, ctx : RenderContext) -> String {
  let tag = if list.ordered { "ol" } else { "ul" }
  let mut attrs = ""
  if list.ordered {
    match list.start {
      Some(start) => attrs = " start=\"" + start.to_string() + "\""
      None => ()
    }
  }
  let out = StringBuilder::new()
  out.write_string("<" + tag + attrs + ">")
  for item in list.items {
    out.write_string("<li>")
    out.write_string(render_blocks(item, ctx))
    out.write_string("</li>")
  }
  out.write_string("</" + tag + ">")
  out.to_string()
}

///|
fn heading_tag(level : Int) -> String {
  if level <= 1 {
    "h1"
  } else if level == 2 {
    "h2"
  } else if level == 3 {
    "h3"
  } else if level == 4 {
    "h4"
  } else if level == 5 {
    "h5"
  } else {
    "h6"
  }
}

///|
fn plain_text_from_inlines(inlines : Array[@markdown.Inline]) -> String {
  let out = StringBuilder::new()
  for inline in inlines {
    out.write_string(plain_text_from_inline(inline))
  }
  out.to_string()
}

///|
fn plain_text_from_inline(inline : @markdown.Inline) -> String {
  match inline {
    @markdown.Text(s) => s
    @markdown.Emphasis(xs) => plain_text_from_inlines(xs)
    @markdown.Strong(xs) => plain_text_from_inlines(xs)
    @markdown.Code(s) => s
    @markdown.Link(xs, _) => plain_text_from_inlines(xs)
    @markdown.Image(alt, _) => alt
    @markdown.Html(_) => ""
    @markdown.SoftBreak => " "
    @markdown.HardBreak => " "
  }
}

///|
fn slugify(input : String) -> String {
  let out = StringBuilder::new()
  let mut prev_dash = true
  for raw in input.to_lower() {
    if is_slug_char(raw) {
      out.write_char(raw)
      prev_dash = false
    } else if !prev_dash {
      out.write_char('-')
      prev_dash = true
    }
  }
  let trimmed = trim_dashes(out.to_string())
  if trimmed == "" {
    "section"
  } else {
    trimmed
  }
}

///|
fn unique_slug(base : String, counts : Map[String, Int]) -> String {
  match counts.get(base) {
    None => {
      counts[base] = 1
      base
    }
    Some(count) => {
      let next = count + 1
      counts[base] = next
      base + "-" + next.to_string()
    }
  }
}

///|
fn escape_html(input : String) -> String {
  let out = StringBuilder::new()
  for ch in input {
    match ch {
      '<' => out.write_string("&lt;")
      '>' => out.write_string("&gt;")
      '&' => out.write_string("&amp;")
      '"' => out.write_string("&quot;")
      '\'' => out.write_string("&#39;")
      _ => out.write_char(ch)
    }
  }
  out.to_string()
}

///|
fn escape_attr(input : String) -> String {
  escape_html(input)
}

///|
fn option_string(input : String?) -> String {
  match input {
    Some(s) => s
    None => ""
  }
}

///|
fn is_slug_char(ch : Char) -> Bool {
  (ch >= 'a' && ch <= 'z') ||
  (ch >= '0' && ch <= '9') ||
  ch == '-' ||
  ch.to_int() > 127
}

///|
fn trim_dashes(input : String) -> String {
  let mut start = 0
  while start < input.length() && char_at(input, start) == '-' {
    start = start + 1
  }
  let mut end = input.length()
  while end > start && char_at(input, end - 1) == '-' {
    end = end - 1
  }
  substring(input, start, end)
}

///|
fn substring(input : String, start : Int, end : Int) -> String {
  let out = StringBuilder::new()
  let mut index = start
  while index < end && index < input.length() {
    out.write_char(char_at(input, index))
    index = index + 1
  }
  out.to_string()
}

///|
fn char_at(input : String, index : Int) -> Char {
  input.code_unit_at(index).unsafe_to_char()
}
