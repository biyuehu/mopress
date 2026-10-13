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

///|
test "whitespace inside tag is trimmed" {
  guard @template.parse_template("$ title $") is [@template.Variable("title")] else {
    fail("expected single variable")
  }
}

///|
test "dotted identifier is a variable" {
  guard @template.parse_template("$a.b$") is [@template.Variable("a.b")] else {
    fail("expected dotted variable")
  }
}

///|
test "unterminated tag" {
  let message = try @template.parse_template("a $b") catch {
    @template.TemplateParseError(m) => m
  } noraise {
    _ => abort("expected parse error")
  }
  assert_true(message.contains("unterminated"))
}

///|
test "dangling endif and missing endfor" {
  let m1 = try @template.parse_template("$endif$") catch {
    @template.TemplateParseError(m) => m
  } noraise {
    _ => abort("expected parse error")
  }
  assert_true(m1.contains("unexpected $endif$"))
  let m2 = try @template.parse_template("$for(x)$a") catch {
    @template.TemplateParseError(m) => m
  } noraise {
    _ => abort("expected parse error")
  }
  assert_true(m2.contains("missing $endfor$"))
}

///|
test "partial requires quoted path" {
  let message = try @template.parse_template("$partial(a.html)$") catch {
    @template.TemplateParseError(m) => m
  } noraise {
    _ => abort("expected parse error")
  }
  assert_true(message.contains("partial expects a quoted path"))
}

///|
test "invalid tag" {
  let message = try @template.parse_template("$a b$") catch {
    @template.TemplateParseError(m) => m
  } noraise {
    _ => abort("expected parse error")
  }
  assert_true(message.contains("invalid template tag"))
}

///|
test "lenient render of missing variable and loop" {
  let t1 = @template.parse_template("a$x$b")
  assert_eq(@template.apply_template(t1, {}), "ab")
  let t2 = @template.parse_template("a$for(x)$z$endfor$b")
  assert_eq(@template.apply_template(t2, { "x": @template.String("no") }), "ab")
}

///|
test "strict reports non array loop" {
  let t = @template.parse_template("$for(x)$z$endfor$")
  let message = try
    @template.apply_template_strict(t, { "x": @template.String("no") })
  catch {
    @template.NonArrayForLoopError(m) => m
    _ => abort("expected non-array error")
  } noraise {
    _ => abort("expected error")
  }
  assert_true(message.contains("expected array for loop"))
}

///|
test "truthiness of numbers and strings" {
  let t = @template.parse_template("$if(n)$y$else$n$endif$")
  assert_eq(@template.apply_template(t, { "n": @template.Number(0) }), "y")
  assert_eq(@template.apply_template(t, { "n": @template.String("x") }), "y")
  assert_eq(
    @template.apply_template(t, {
      "n": @template.Array([@template.Bool(false)]),
    }),
    "y",
  )
}

///|
test "nested if inside for" {
  let t = @template.parse_template(
    "$for(xs)$$if(item.on)$[$item.name$]$endif$$endfor$",
  )
  let result = @template.apply_template(t, {
    "xs": @template.Array([
      @template.Object({
        "on": @template.Bool(true),
        "name": @template.String("a"),
      }),
      @template.Object({
        "on": @template.Bool(false),
        "name": @template.String("b"),
      }),
    ]),
  })
  assert_eq(result, "[a]")
}

///|
test "value to_string" {
  assert_eq(@template.Bool(true).to_string(), "true")
  assert_eq(@template.String("s").to_string(), "s")
  assert_eq(
    @template.Array([@template.String("a"), @template.Bool(true)]).to_string(),
    "[\"a\", true]",
  )
  assert_eq(
    @template.Object({ "k": @template.String("v") }).to_string(),
    "{k: \"v\"}",
  )
}

///|
test "value from json" {
  let json = @json.parse("{\"a\":[1,true,null,\"s\"]}")
  @debug.assert_eq(
    @template.Value::from_json(json),
    @template.Object({
      "a": @template.Array([
        @template.Number(1),
        @template.Bool(true),
        @template.String(""),
        @template.String("s"),
      ]),
    }),
  )
}
