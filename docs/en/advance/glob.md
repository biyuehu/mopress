---
title: Glob Matching
---

# Glob Matching

Glob patterns match files by path in MoPress, used in Book mode (`[extensions.assets]`) and Site mode (`Rule::Glob`, `Rule::Guard`).

## Function Signatures

```moonbit
pub fn glob_match(pattern : String, path : String) -> Bool

pub fn glob_match_with(pattern : String, path : String, f : (String) -> Bool) -> Bool

pub fn scan_files(root : String, pattern : String) -> Array[String] raise @fs.IOError

pub fn scan_files_with(
  root : String,
  pattern : String,
  f : (String) -> Bool,
) -> Array[String] raise @fs.IOError
```

## Supported Wildcards

| Wildcard | Description |
| --- | --- |
| `*` | Matches any characters within a single path segment (does not cross `/`) |
| `?` | Matches exactly one character |
| `**` | Matches arbitrary directory depth, crossing `/` path separators |

## Examples

- `*.md`: Matches all Markdown files in the current folder.
- `assets/**/*`: Matches all assets recursively within the `assets` folder.
- `src/?.md`: Matches single-character names like `src/a.md`.
