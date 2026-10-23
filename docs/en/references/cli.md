---
title: CLI Reference
---

# CLI Reference

This page provides the complete reference for the `mopress` command-line executable. For day-to-day getting started guides, please refer to [Quick Start](../starting.md) (Book mode) or [Site Mode](../site-mode/starting.md) first. This page is intended for reference purposes.

## Basic Usage

```bash
mopress <command>
```

When `<command>` is omitted or unrecognised, `mopress` gracefully falls back to displaying help information, equivalent to running `mopress help`, without exiting with an error.

## Command Overview

| Command | Description |
| --- | --- |
| `init` | Initialize a new Book mode project, with optional directory: `mopress init [dir]` |
| `new` | Scaffold a new Site mode project: `mopress new <dir> [--template <blog\|minimal>]` |
| `build` | Build the site (analyze enabled by default, supports `--no-analyze`, `--no-emit`, `--analyze-json`) |
| `explain` | Print rule match diagnostics and estimated output list (Dry-run) |
| `serve` | Start a local development server for live preview |
| `version` | Display version and build information |
| `help` | Display usage and help information |

> **Strict Option Validation**: All subcommands strictly validate incoming command-line options. If any unrecognised option is passed (e.g. `mopress build --unknown`), the command will immediately exit with an error, preventing accidental typos from executing unexpected actions silently.

## mopress init

```bash
mopress init [dir]
```

Specifically designed for **Book mode** users to initialize documentation projects.
- If `[dir]` is omitted, initialization happens in the current working directory.
- If `[dir]` is specified, the Book mode scaffold is created in the specified subfolder.

If a `sena.toml` configuration file already exists in the target directory, `init` prints an informational notice and exits safely without overwriting your setup. Otherwise, it will sequentially create the config file, `SUMMARY.md`, `index.md`, and scaffold default assets in `templates/`, `styles/`, `scripts/`, and `plugins/`.

`init` is idempotent: re-running it in an initialized directory exits early once `sena.toml` is detected. Note that this check only verifies whether `sena.toml` exists; if individual templates or styles have been removed while keeping `sena.toml`, `init` will not backfill them.

## mopress new

```bash
mopress new <dir> [--template <blog|minimal>]
```

Designed for **Site mode** users to create static site projects.
- `<dir>`: Required target directory.
- `--template <blog|minimal>` (or `-t`): Optional template type:
  - `blog` (default): Full-featured blog with example posts (`posts/hello-world.md`), SEO metadata, reading time calculations, excerpt extraction, and a unified pipeline in `site.mbtx`.
  - `minimal`: Minimal static site structure (`index.md`, `about.md`, `contact.md`) with a lightweight build script.

## mopress build

```bash
mopress build [--no-emit] [--no-analyze] [--analyze-json]
```

Reads the configuration in the current working directory, executes the full Book mode build pipeline: parses navigation structure, generates 404 page, renders all Markdown pages with templates, and outputs results into the build target folder.

Build performance profiling is **enabled by default**. Upon build completion, MoPress prints a clear terminal performance report, including:
- Breakdown of build steps (preprocessing, AST transforms, markdown rendering, templates, asset injections) with total time, page average, max time, and call counts.
- Page performance table with HTML output size (B/KB/MB), total render time, template render count (including recursive partials), and slowest step.
- Overall stats: total page count, output byte size, average page size, and total build time.

Option details:
- `--no-analyze`: Disables performance profiling output, displaying only standard progress logs.
- `--analyze`: Explicitly enables performance profiling (enabled by default; rarely needed manually).
- `--no-emit`: Runs the entire build and transformation pipeline in memory **without writing any files to disk**. Ideal for CI verification and dry-run prechecks.
- `--analyze-json`: Silences normal build logs and prints a machine-readable JSON performance report to standard output (`stdout`), suitable for CI/CD benchmarks and dashboards.

## mopress explain

```bash
mopress explain
```

Analyzes current file match rules and config, printing which files match which rules and estimating the output manifest without writing files to disk.

## mopress serve

```bash
mopress serve
```

Reads current configuration, initializes options, and launches a local development preview server.

## mopress version

```bash
mopress version
```

Prints the current version string and build details.

## mopress help

```bash
mopress help
```

Prints help details and short summaries of all available commands.

## Site Mode Command-Line

The commands above target the pre-compiled `mopress` binary for Book mode. Under Site mode, your build script is a standalone MoonBit program executed directly:

```bash
moon run --target native site.mbtx <args>
```

`<args>` supports `build` (along with `--no-emit`, `--analyze`, `--analyze-json`), `serve`, and `explain`, behaving identically to their Book mode equivalents. `--target native` directs MoonBit to compile against the Native target.

