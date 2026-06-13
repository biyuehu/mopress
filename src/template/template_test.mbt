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
      If("relatedPosts", if_nodes, []),
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
test "parse if with else branch" {
  let template = parse_template("$if(show)$yes$else$no$endif$")
  guard template is [If("show", [Text("yes")], [Text("no")])] else {
    fail("expected if node with else branch")
  }
}

///|
test "render if else branch" {
  let template = parse_template("$if(show)$yes$else$no$endif$")
  assert_eq(apply_template(template, { "show": Bool(true) }), "yes")
  assert_eq(apply_template(template, { "show": Bool(false) }), "no")
  assert_eq(apply_template(template, { "show": String("") }), "no")
  assert_eq(apply_template(template, { "show": Array([]) }), "no")
  assert_eq(apply_template(template, {}), "no")
}

///|
test "parse rejects dangling else" {
  let message = try parse_template("$else$") catch {
    TemplateParseError(message) => message
  } noraise {
    _ => abort("expected parse error")
  }
  assert_true(message.contains("unexpected $else$"))
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
test "render object fields in variables conditions and loops" {
  let template = parse_template(
    "$if(page.badge)$[$page.badge$]$endif$$for(page.items)$$item.title$:$item.url$;$endfor$",
  )
  let result = apply_template(template, {
    "page": Object({
      "badge": String("stable"),
      "items": Array([
        Object({ "title": String("Intro"), "url": String("index.html") }),
        Object({ "title": String("API"), "url": String("api.html") }),
      ]),
    }),
  })
  assert_eq(result, "[stable]Intro:index.html;API:api.html;")
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

///|
test "render partial from file" {
  let source =
    #|<main>$title$</main>
    #|$partial("src/template/testdata/footer.html")$
  let template = parse_template(source)
  let result = apply_template(template, { "title": String("Hello") })
  assert_true(result.contains("<main>Hello</main>"))
  assert_true(result.contains("<footer>Hello</footer>"))
}

///|
test "render nested partial from file" {
  let source =
    #|$partial("src/template/testdata/footer.html")$
    #|$partial("src/template/testdata/footer.html")$
  let template = parse_template(source)
  let result = apply_template(template, { "title": String("Twice") })
  assert_true(result.contains("<footer>Twice</footer>"))
  assert_true(result.length() > "<footer>Twice</footer>".length())
}

///|
test "render reports missing partial file" {
  let template = parse_template(
    "$partial(\"src/template/testdata/missing.html\")$",
  )
  let message = try apply_template_strict(template, {}) catch {
    PartialLoadError(msg) => msg
    _ => abort("expected partial load error")
  } noraise {
    _ => abort("expected partial load error, but got no error")
  }
  assert_true(message.contains("failed to read partial"))
}

///|
test "render reports malformed partial" {
  let template = parse_template(
    "$partial(\"src/template/testdata/malformed.html\")$",
  )
  let message = try apply_template_strict(template, {}) catch {
    PartialParseError(msg) => msg
    _ => abort("expected partial parse error")
  } noraise {
    _ => abort("expected partial parse error, but got no error")
  }
  assert_true(message.contains("failed to parse partial"))
}

///|
test "render detects recursive partials" {
  let template = parse_template(
    "$partial(\"src/template/testdata/recursive.html\")$",
  )
  let message = try apply_template_strict(template, {}) catch {
    RecursivePartialError(msg) => msg
    _ => abort("expected recursive partial error")
  } noraise {
    _ => abort("expected recursive partial error, but got no error")
  }
  assert_true(message.contains("recursive partial"))
}
