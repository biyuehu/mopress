---
title: Web Components
---

# Web Components

MoPress embraces native W3C Web Components as the premier solution for interactive documentation widgets. Unlike MDX, which couples Markdown with bloated client framework dependencies, Web Components provide native browser-standard encapsulation with zero build overhead.

## Principle: Unparsed HTML Retention

MoPress's Markdown parser leaves valid raw HTML blocks untouched. You can embed custom tags directly into Markdown:

```markdown
Here is a live playground:

<interactive-tabs>
  <tab-item label="Native">moon run --target native site.mbtx</tab-item>
  <tab-item label="Wasm">moon run --target wasm site.mbtx</tab-item>
</interactive-tabs>
```

## Registering Components

Simply register the custom element definition script in `sena.toml`:

```toml
[extensions]
import_js = ["/scripts/tabs.js"]
```
