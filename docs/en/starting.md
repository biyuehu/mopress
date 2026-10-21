---
title: Quick Start
language: en
---

# Quick Start

This guide walks you through setting up a functional MoPress documentation site in minutes using **Book Mode**—no coding required.

## Step 0: Install MoPress

You can install MoPress through any of the following methods:

### 1. Via MoonBit (Recommended)

Requires the [MoonBit toolchain](https://www.moonbitlang.com/download/):

```bash
moon install himeno/mopress
mopress version
```

### 2. Download Prebuilt Executable (Windows)

Precompiled binaries for Windows are available on [GitHub Releases](https://github.com/biyuehu/mopress/releases). Download, extract to your preferred directory, and add it to your system `PATH`.

### 3. Build from Source

Requires the MoonBit toolchain, Bun (or Node.js), and Just:

```bash
git clone https://github.com/biyuehu/mopress.git
cd mopress
moon update
just prebuild
moon build --release
```

The resulting executable will be located at `_build/native/release/build/mopress.exe`.

## Step 1: Initialize a Project

Run the following command in a new directory (or provide a directory name like `mopress init my-book`):

```bash
mopress init
```

This scaffolds:
- The core configuration file: `sena.toml`
- Navigation catalog: `SUMMARY.md`
- Starter document: `index.md`
- Essential asset directories: `templates/`, `styles/`, `scripts/`, and `plugins/`

Directory structure:

```text
├── sena.toml
├── index.md
├── SUMMARY.md
├── templates/
│   └── default.html
├── styles/
│   └── index.css
├── scripts/
│    └── main.js
└── plugins/
     ├── runtime/
     ├── preprocessors/
     │    └── github-alert.ts
     └── transformers/
```

## Step 2: Write Content

Create or edit `./index.md`:

```markdown
---
title: Hello World
---

# Hello, MoPress

Welcome to your first documentation page generated with MoPress!
```

Organize your sidebar table of contents in `./SUMMARY.md`:

```markdown
# Summary

- [Home](./index.md)
```

> [!NOTE]
> `SUMMARY.md` defines the navigation structure (sidebar hierarchy, breadcrumbs, and previous/next page links). All `*.md` and `*.markdown` files located within the source directory will be compiled into HTML pages.

## Step 3: Build the Site

```bash
mopress build
```

The compiled static HTML, CSS, JavaScript, and assets will be output to the directory configured in `sena.toml` (defaults to `./dest`).

## Step 4: Preview Locally

```bash
mopress serve
```

This launches a local development server with built-in live reloading, so you can preview changes in real time.

