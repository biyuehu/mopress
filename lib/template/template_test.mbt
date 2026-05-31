///|
test "parse variables and text" {
  let template = parse_template("<h1>$title$</h1>")
  guard template is [Text("<h1>"), Variable("title"), Text("</h1>")] else {
    fail("expected text variable text sequence")
  }
}

///|
test "parse if for and partial nodes" {
  let source =
    #|$if(relatedPosts)$
    #|<h2>相关文章</h2>
    #|$for(relatedPosts)$
    #|<a href="$url$">$title$</a><br>
    #|$endfor$
    #|$endif$
    #|$partial("templates/footer.html")$
  let template = parse_template(source)
  guard template
    is [
      If("relatedPosts", if_nodes),
      Text("\n"),
      Partial("templates/footer.html"),
    ] else {
    fail("expected if block followed by partial")
  }
  guard if_nodes
    is [
      Text("\n<h2>相关文章</h2>\n"),
      For("relatedPosts", for_nodes),
      Text("\n"),
    ] else {
    fail("expected heading text and for block")
  }
  guard for_nodes
    is [
      Text("\n<a href=\""),
      Variable("url"),
      Text("\">"),
      Variable("title"),
      Text("</a><br>\n"),
    ] else {
    fail("expected link template inside for block")
  }
}

///|
test "parse reports missing closing tags" {
  let message = try parse_template("$if(posts)$oops") catch {
    TemplateParseError(message) => message
  } noraise {
    _ => abort("expected parse error")
  }
  assert_true(message.contains("missing $endif$"))
}

///|
test "parse rejects malformed tags" {
  let message = try parse_template("$if(123)$") catch {
    TemplateParseError(message) => message
  } noraise {
    _ => abort("expected parse error")
  }
  assert_true(message.contains("invalid template identifier"))
}

///|
test "render variables and text" {
  let template = parse_template("<h1>$title$</h1>")
  let result = apply_template(template, { "title": String("Hello") })
  assert_eq(result, "<h1>Hello</h1>")
}

///|
test "render if condition" {
  let template = parse_template("$if(show)$Hello$endif$")
  assert_eq(apply_template(template, { "show": Bool(true) }), "Hello")
  assert_eq(apply_template(template, { "show": Bool(false) }), "")
  assert_eq(apply_template(template, { "show": String("") }), "")
  assert_eq(apply_template(template, { "show": Array([]) }), "")
  assert_eq(apply_template(template, {}), "")
}

///|
test "render for loop" {
  let template = parse_template("$for(items)$$item$$endfor$")
  let result = apply_template(template, {
    "items": Array([Number(1), Number(2), Number(3)]),
  })
  assert_eq(result, "123")
}

///|
test "render reports missing variable" {
  let template = parse_template("$name$")
  let message = try apply_template_strict(template, {}) catch {
    UndefinedVariableError(msg) => msg
    _ => abort("expected missing variable error")
  } noraise {
    _ => abort("expected missing variable error, but got no error")
  }
  assert_true(message.contains("missing variable: name"))
}
