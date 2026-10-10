///|
test "parse variables and text" {
  let template = @template.parse_template("<h1>$title$</h1>")
  guard template
    is [
      @template.Text("<h1>"),
      @template.Variable("title"),
      @template.Text("</h1>"),
    ] else {
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
  let template = @template.parse_template(source)
  guard template
    is [
      @template.If("relatedPosts", if_nodes, []),
      @template.Text("\n"),
      @template.Partial("templates/footer.html"),
    ] else {
    fail("expected if block followed by partial")
  }
  guard if_nodes
    is [
      @template.Text("\n<h2>相关文章</h2>\n"),
      @template.For("relatedPosts", for_nodes),
      @template.Text("\n"),
    ] else {
    fail("expected heading text and for block")
  }
  guard for_nodes
    is [
      @template.Text("\n<a href=\""),
      @template.Variable("url"),
      @template.Text("\">"),
      @template.Variable("title"),
      @template.Text("</a><br>\n"),
    ] else {
    fail("expected link template inside for block")
  }
}

///|
test "parse reports missing closing tags" {
  let message = try @template.parse_template("$if(posts)$oops") catch {
    @template.TemplateParseError(message) => message
  } noraise {
    _ => abort("expected parse error")
  }
  assert_true(message.contains("missing $endif$"))
}

///|
test "parse rejects malformed tags" {
  let message = try @template.parse_template("$if(123)$") catch {
    @template.TemplateParseError(message) => message
  } noraise {
    _ => abort("expected parse error")
  }
  assert_true(message.contains("invalid template identifier"))
}

///|
test "render variables and text" {
  let template = @template.parse_template("<h1>$title$</h1>")
  let result = @template.apply_template(template, {
    "title": @template.String("Hello"),
  })
  assert_eq(result, "<h1>Hello</h1>")
}

///|
test "render if condition" {
  let template = @template.parse_template("$if(show)$Hello$endif$")
  assert_eq(
    @template.apply_template(template, { "show": @template.Bool(true) }),
    "Hello",
  )
  assert_eq(
    @template.apply_template(template, { "show": @template.Bool(false) }),
    "",
  )
  assert_eq(
    @template.apply_template(template, { "show": @template.String("") }),
    "",
  )
  assert_eq(
    @template.apply_template(template, { "show": @template.Array([]) }),
    "",
  )
  assert_eq(@template.apply_template(template, {}), "")
}

///|
test "parse if with else branch" {
  let template = @template.parse_template("$if(show)$yes$else$no$endif$")
  guard template
    is [@template.If("show", [@template.Text("yes")], [@template.Text("no")])] else {
    fail("expected if node with else branch")
  }
}

///|
test "render if else branch" {
  let template = @template.parse_template("$if(show)$yes$else$no$endif$")
  assert_eq(
    @template.apply_template(template, { "show": @template.Bool(true) }),
    "yes",
  )
  assert_eq(
    @template.apply_template(template, { "show": @template.Bool(false) }),
    "no",
  )
  assert_eq(
    @template.apply_template(template, { "show": @template.String("") }),
    "no",
  )
  assert_eq(
    @template.apply_template(template, { "show": @template.Array([]) }),
    "no",
  )
  assert_eq(@template.apply_template(template, {}), "no")
}

///|
test "parse rejects dangling else" {
  let message = try @template.parse_template("$else$") catch {
    @template.TemplateParseError(message) => message
  } noraise {
    _ => abort("expected parse error")
  }
  assert_true(message.contains("unexpected $else$"))
}

///|
test "render for loop" {
  let template = @template.parse_template("$for(items)$$item$$endfor$")
  let result = @template.apply_template(template, {
    "items": @template.Array([
      @template.Number(1),
      @template.Number(2),
      @template.Number(3),
    ]),
  })
  assert_eq(result, "123")
}

///|
test "render object fields in variables conditions and loops" {
  let template = @template.parse_template(
    "$if(page.badge)$[$page.badge$]$endif$$for(page.items)$$item.title$:$item.url$;$endfor$",
  )
  let result = @template.apply_template(template, {
    "page": @template.Object({
      "badge": @template.String("stable"),
      "items": @template.Array([
        @template.Object({
          "title": @template.String("Intro"),
          "url": @template.String("index.html"),
        }),
        @template.Object({
          "title": @template.String("API"),
          "url": @template.String("api.html"),
        }),
      ]),
    }),
  })
  assert_eq(result, "[stable]Intro:index.html;API:api.html;")
}

///|
test "render reports missing variable" {
  let template = @template.parse_template("$name$")
  let message = try @template.apply_template_strict(template, {}) catch {
    @template.UndefinedVariableError(msg) => msg
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
  let template = @template.parse_template(source)
  let result = @template.apply_template(template, {
    "title": @template.String("Hello"),
  })
  assert_true(result.contains("<main>Hello</main>"))
  assert_true(result.contains("<footer>Hello</footer>"))
}

///|
test "render nested partial from file" {
  let source =
    #|$partial("src/template/testdata/footer.html")$
    #|$partial("src/template/testdata/footer.html")$
  let template = @template.parse_template(source)
  let result = @template.apply_template(template, {
    "title": @template.String("Twice"),
  })
  assert_true(result.contains("<footer>Twice</footer>"))
  assert_true(result.length() > "<footer>Twice</footer>".length())
}

///|
test "render reports missing partial file" {
  let template = @template.parse_template(
    "$partial(\"src/template/testdata/missing.html\")$",
  )
  let message = try @template.apply_template_strict(template, {}) catch {
    @template.PartialLoadError(msg) => msg
    _ => abort("expected partial load error")
  } noraise {
    _ => abort("expected partial load error, but got no error")
  }
  assert_true(message.contains("failed to read partial"))
}

///|
test "render reports malformed partial" {
  let template = @template.parse_template(
    "$partial(\"src/template/testdata/malformed.html\")$",
  )
  let message = try @template.apply_template_strict(template, {}) catch {
    @template.PartialParseError(msg) => msg
    _ => abort("expected partial parse error")
  } noraise {
    _ => abort("expected partial parse error, but got no error")
  }
  assert_true(message.contains("failed to parse partial"))
}

///|
test "render detects recursive partials" {
  let template = @template.parse_template(
    "$partial(\"src/template/testdata/recursive.html\")$",
  )
  let message = try @template.apply_template_strict(template, {}) catch {
    @template.RecursivePartialError(msg) => msg
    _ => abort("expected recursive partial error")
  } noraise {
    _ => abort("expected recursive partial error, but got no error")
  }
  assert_true(message.contains("recursive partial"))
}
