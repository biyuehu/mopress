---
title: Rules, Handlers and Steps
---

# Rules, Handlers and Steps

This section details the primary building blocks in the Site mode pipeline: `Item`, `Step`, `Handler`, and `Rule`.

## The Core Data Carrier: Item[T]

```moonbit
pub type Vars = Map[String, @template.Value]

pub struct Item[T] {
  data : T
  priv extension : String
  vars : Vars
  target : String
} derive(Eq, Debug)
```

- `data`: Typed content payload transforming as it flows through the pipeline.
- `vars`: Template context dictionary attached to the item.
- `target`: Output relative path.

Key methods include `Item::new`, `Item::map`, `Item::map_with_raise`, `Item::add_vars`, and `Item::set_var`.

> [!IMPORTANT]
> Extensions must include a leading dot, e.g. `.html`, not `html`.

## Step

A Step is a function with signature `(Item[T]) -> Item[R]` (which can be `async` or `raise`). Steps are composed with MoonBit's pipe operator `|>`:

```moonbit
raw
|> @core.separate_frontmatter
|> @core.parse_markdown
|> @core.render_markdown_from_ast
```

## Rule and Handler

- **`Rule::Glob(pattern, handler)`**: Matches files matching a glob pattern.
- **`Rule::Guard(pattern, predicate, handler)`**: Combines glob matching with a programmatic filter predicate.

Handlers determine how matched files are loaded and handled:
- `Handler::text(pipeline)`: Reads file content as UTF-8 string.
- `Handler::binary(pipeline)`: Reads file content as raw bytes.
- `Handler::copy()`: Copies the file as-is without processing.

