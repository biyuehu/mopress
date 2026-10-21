---
title: MoonBit Modules
---

# MoonBit Native Modules

In Site mode, Steps, Preprocessors, and Transformers can be authored directly as native MoonBit libraries published to [mooncakes](https://mooncakes.io/).

## Native Steps vs. External CLI Plugins

| Characteristic | MoonBit Native Modules | External CLI Plugins |
| --- | --- | --- |
| Applicability | Site mode | Book mode and Site mode |
| Language | MoonBit | Any language (Python, Node, Rust, etc.) |
| Execution | In-process native calls | Subprocess stdin/stdout via JSON |
| Performance | Zero serialization overhead | Subprocess spawning and JSON parsing |
| Error Handling | Native MoonBit `raise` | Exit codes and stderr messages |

## Authoring Composable Steps

Export composable functions with the Step signature:

```moonbit
pub fn use_callout_boxes(item : Item[String]) -> Item[String] raise {
  item.map_with_raise(text => {
    // Custom string transformation
    text
  })
}
```

Consumers install via `moon add` and plug the step into their `site.mbtx` pipeline using `|>`.
