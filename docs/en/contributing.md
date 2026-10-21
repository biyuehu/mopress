---
title: Contributing Guide
---

# Contributing Guide

Thank you for your interest in MoPress! Whether you are reporting bugs, proposing features, improving documentation, contributing core features, or publishing plugins to the [Plugins Hub](./plugins.md), contributions are warmly welcomed.

---

## 1. Prerequisites

Before starting development, ensure you have the following installed locally:

- **[MoonBit](https://www.moonbitlang.com/)**: The latest MoonBit compiler and toolchain.
- **[Bun](https://bun.sh/)** (or Node.js): For running asset generators and external plugin protocol test suites.
- **[Just](https://github.com/casey/just)**: Command runner (recommended for running common tasks).
- **Git**: Version control.

> [!CAUTION]
> For MoonBit's native target on Windows, ensure the **MSVC** (Visual Studio C++ Build Tools) environment is installed and active.

---

## 2. Local Development & Workflow

### Clone and Install Dependencies

```bash
git clone https://github.com/biyuehu/mopress.git
cd mopress

# Update MoonBit dependencies
moon update

# Install Git hooks (recommended)
just init
```

### Prebuild Assets

MoPress embeds default templates, static stylesheets, and demo projects directly into MoonBit source code (`src/includes.mbt`). Run prebuild after changing these assets:

```bash
just prebuild
# Equivalent to: bun scripts/gen-includes.ts
```

### Running Tests

```bash
just test
# Equivalent to: just prebuild && moon test
```

MoPress has comprehensive unit and snapshot tests. If intentional changes affect snapshot outputs, update them with:

```bash
moon test --update
```

### Formatting and Interface Verification

Before submitting code, ensure formatting and package interface declarations (`.mbti`) are updated:

```bash
moon fmt
moon info
```

---

## 3. Pull Request Guidelines

1. Create a feature branch from `main`: `git checkout -b feat/my-feature`
2. Follow [Conventional Commits](https://www.conventionalcommits.org/) for your commit messages (e.g. `feat: ...`, `fix: ...`, `docs: ...`).
3. Ensure all tests pass (`moon test`) and `moon fmt` produces no uncommitted changes.
