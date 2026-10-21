---
title: Template Engine
---

# Template Engine

MoPress includes a lightweight, built-in template engine inspired by Hakyll. It handles variables, conditionals, loops, partial includes, and escaping.

## Basic Syntax

### Variable Interpolation

```html
<title>$title$</title>
<p>Author: $author.name$</p>
```

### Conditionals

```html
$if(repository)$
  <a href="$repository$">GitHub Repository</a>
$endif$

$if(!draft)$
  <span class="badge">Published</span>
$else$
  <span class="badge draft">Draft</span>
$endif$
```

### Loops

```html
<ul>
  $for(items)$
    <li><a href="$location$">$title$</a></li>
  $endfor$
</ul>
```

### Partial Includes

```html
$include("partials/header.html")$
<main>$body$</main>
$include("partials/footer.html")$
```

### Escaping Dollars

To output a literal dollar sign, write `$$`:

```html
Price: $$100 USD
```
