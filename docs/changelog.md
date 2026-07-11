---
title: Changelog
---

# Changelog

## ...main


### 🚀 Enhancements

- Impl book configuration parser, definition ([9e46eca](https://github.com/biyuehu/mbdoc/commit/9e46eca))
- Add config and core foundations ([ed567da](https://github.com/biyuehu/mbdoc/commit/ed567da))
- Add config and core foundations ([55767b7](https://github.com/biyuehu/mbdoc/commit/55767b7))
- Introduce site pipeline primitives ([a957fbd](https://github.com/biyuehu/mbdoc/commit/a957fbd))
- Add markdown ast parser ([c935b8d](https://github.com/biyuehu/mbdoc/commit/c935b8d))
- Add template parser ([118d186](https://github.com/biyuehu/mbdoc/commit/118d186))
- Improve book-related implementation ([a25a17a](https://github.com/biyuehu/mbdoc/commit/a25a17a))
- Add core type definitions ([fac2a58](https://github.com/biyuehu/mbdoc/commit/fac2a58))
- Add template rendering ([7efadb7](https://github.com/biyuehu/mbdoc/commit/7efadb7))
- **core:** Add basic step functions ([5d63762](https://github.com/biyuehu/mbdoc/commit/5d63762))
- **template:** Add multiple type value definition in context ([d99b290](https://github.com/biyuehu/mbdoc/commit/d99b290))
- **core:** Add Multiple variant for Output type ([93840f9](https://github.com/biyuehu/mbdoc/commit/93840f9))
- **template:** Add render_template_strict function ([dffe2d6](https://github.com/biyuehu/mbdoc/commit/dffe2d6))
- **core:** Implement basic steps and add utils function ([9a95c87](https://github.com/biyuehu/mbdoc/commit/9a95c87))
- **glob:** Add glob package and move from site package ([8edf165](https://github.com/biyuehu/mbdoc/commit/8edf165))
- **glob:** Add scan_files function ([54822e9](https://github.com/biyuehu/mbdoc/commit/54822e9))
- Support template else branches ([2ecbe03](https://github.com/biyuehu/mbdoc/commit/2ecbe03))
- Render template partials ([4d936cc](https://github.com/biyuehu/mbdoc/commit/4d936cc))
- **glob:** Add _with function ([6d11cbc](https://github.com/biyuehu/mbdoc/commit/6d11cbc))
- **coe:** Add of setup and cli function factory ([4f8b402](https://github.com/biyuehu/mbdoc/commit/4f8b402))
- **core:** Add mopress_with function ([f4d71b0](https://github.com/biyuehu/mbdoc/commit/f4d71b0))
- **template:** Add Object variant for Value type ([97b73cf](https://github.com/biyuehu/mbdoc/commit/97b73cf))
- **theme:** Add theme definition and functions ([91415ad](https://github.com/biyuehu/mbdoc/commit/91415ad))
- **renderer:** Implement markdown to html and add basic templates ([eef08ac](https://github.com/biyuehu/mbdoc/commit/eef08ac))
- **core:** Implement cli serve static files ([a1c88e7](https://github.com/biyuehu/mbdoc/commit/a1c88e7))
- **summary:** Implement summary parser ([a9d902d](https://github.com/biyuehu/mbdoc/commit/a9d902d))
- Add use_transformer, remove MarkdownDoc type and update test ([392bb9f](https://github.com/biyuehu/mbdoc/commit/392bb9f))
- **renderer:** Add Toc type alias and add ToJson trait for toc ([81dfcd1](https://github.com/biyuehu/mbdoc/commit/81dfcd1))
- **summary:** Add Summary::flatten method and remove ToJson trait ([ed6aa1b](https://github.com/biyuehu/mbdoc/commit/ed6aa1b))
- **frontend:** Add search and improve styles, layout ([8c46722](https://github.com/biyuehu/mbdoc/commit/8c46722))
- **summary:** Add breadcrumb and prev_next function ([5a71a68](https://github.com/biyuehu/mbdoc/commit/5a71a68))
- **renderer:** Implement parsing and rendering of table ([ed35005](https://github.com/biyuehu/mbdoc/commit/ed35005))
- Improve structure of BookConfig type ([10dac34](https://github.com/biyuehu/mbdoc/commit/10dac34))
- Supports mathjax and code highlight, add inject_head inject_body step ([ed03ba8](https://github.com/biyuehu/mbdoc/commit/ed03ba8))
- **config:** Add assets extension configuration option ([cdca5e4](https://github.com/biyuehu/mbdoc/commit/cdca5e4))
- **book:** Implement command handler ([63abdc0](https://github.com/biyuehu/mbdoc/commit/63abdc0))
- **bridge:** Support external prepoccessers and transformers ([3e9b455](https://github.com/biyuehu/mbdoc/commit/3e9b455))
- Add external preprocesser demo base on ts and bun ([c58b1fe](https://github.com/biyuehu/mbdoc/commit/c58b1fe))
- Add Debug, Eq trait for types, update docs comment and rename functions ([9ac51d3](https://github.com/biyuehu/mbdoc/commit/9ac51d3))
- **renderer:** Improve rendering link that identify external and internal links ([ab16ddf](https://github.com/biyuehu/mbdoc/commit/ab16ddf))
- **book:** Add current var for template ([0b2b3c6](https://github.com/biyuehu/mbdoc/commit/0b2b3c6))
- **core:** Add [36mversion[39m subcommand for cli ([2f1c81c](https://github.com/biyuehu/mbdoc/commit/2f1c81c))
- Add TextRequest struct, implement Show trait for ProcessError, add log information ([267161a](https://github.com/biyuehu/mbdoc/commit/267161a))
- Implement Show for suberrors and add log information ([15e7c7d](https://github.com/biyuehu/mbdoc/commit/15e7c7d))
- **plugins:** Add link-checker, relative2absolute and improve github-alert, refer-file ([f1741f2](https://github.com/biyuehu/mbdoc/commit/f1741f2))
- Improve logger information for cli ([1636c32](https://github.com/biyuehu/mbdoc/commit/1636c32))

### 🩹 Fixes

- **core:** Fix frontmatter parsing problem and add test ([c048763](https://github.com/biyuehu/mbdoc/commit/c048763))
- **glob:** Solve issue of misreading folders ([4dae477](https://github.com/biyuehu/mbdoc/commit/4dae477))
- Improve platform path separator handling ([e9c9681](https://github.com/biyuehu/mbdoc/commit/e9c9681))
- **summary:** Solve is_current logic problem ([768b167](https://github.com/biyuehu/mbdoc/commit/768b167))
- Solve location url problem ([2cc1724](https://github.com/biyuehu/mbdoc/commit/2cc1724))
- Solve location url problem ([bd125a1](https://github.com/biyuehu/mbdoc/commit/bd125a1))
- Solve issue of seprating frontmatter with content ([fa16b16](https://github.com/biyuehu/mbdoc/commit/fa16b16))
- **core:** Update ptoblem of relative path ([6fae7bb](https://github.com/biyuehu/mbdoc/commit/6fae7bb))

### 📖 Documentation

- Add document comments for all public interface ([79bf77e](https://github.com/biyuehu/mbdoc/commit/79bf77e))
- Update summary.md structure ([49bd060](https://github.com/biyuehu/mbdoc/commit/49bd060))
- Create some docs ([2b21ef1](https://github.com/biyuehu/mbdoc/commit/2b21ef1))
- Add site-mode, book-mode, etc. articles and update README.mbt.md ([3836e0e](https://github.com/biyuehu/mbdoc/commit/3836e0e))
- Update docs and add step of building docs to ci.yml ([926724e](https://github.com/biyuehu/mbdoc/commit/926724e))
- Improve all documents ([f3928e4](https://github.com/biyuehu/mbdoc/commit/f3928e4))
- Update all documents ([6dfdfeb](https://github.com/biyuehu/mbdoc/commit/6dfdfeb))
- Improve all of documents ([1d1e91a](https://github.com/biyuehu/mbdoc/commit/1d1e91a))
- Improve all documents ([dbec8ac](https://github.com/biyuehu/mbdoc/commit/dbec8ac))
- Update all documents ([3140a77](https://github.com/biyuehu/mbdoc/commit/3140a77))

### 🏡 Chore

- Initialize project ([ac722cd](https://github.com/biyuehu/mbdoc/commit/ac722cd))
- Link README.md ([35b7d90](https://github.com/biyuehu/mbdoc/commit/35b7d90))
- Create ci action and update moon.mod.json ([b02cf7e](https://github.com/biyuehu/mbdoc/commit/b02cf7e))
- Fix moonbit install sh url of ci.yml ([563625e](https://github.com/biyuehu/mbdoc/commit/563625e))
- Fix installing moonbit of ci.yml ([60cd8f6](https://github.com/biyuehu/mbdoc/commit/60cd8f6))
- Add updating registry step to ci.yml ([1dcba42](https://github.com/biyuehu/mbdoc/commit/1dcba42))
- Update import and create moon.mod file ([344ac8d](https://github.com/biyuehu/mbdoc/commit/344ac8d))
- Rename package, update README.md, and create TODO.md ([2cdf848](https://github.com/biyuehu/mbdoc/commit/2cdf848))
- Set justfile, lefthook.yml and update README.md ([c0bb728](https://github.com/biyuehu/mbdoc/commit/c0bb728))
- Update mbti files ([d18bbf2](https://github.com/biyuehu/mbdoc/commit/d18bbf2))
- Update core .mbti files ([ad2f03f](https://github.com/biyuehu/mbdoc/commit/ad2f03f))
- Update lefthook.yml and add moonbitlang/async module ([cddb392](https://github.com/biyuehu/mbdoc/commit/cddb392))
- Update project structure and improve moon.mod meta information ([0b26f80](https://github.com/biyuehu/mbdoc/commit/0b26f80))
- Update mbti files, .gitignore and README.md ([3ff777f](https://github.com/biyuehu/mbdoc/commit/3ff777f))
- Update core wbtest file ([992006b](https://github.com/biyuehu/mbdoc/commit/992006b))
- Update core wbtest file ([bb61331](https://github.com/biyuehu/mbdoc/commit/bb61331))
- Update .gitignore and delete core wbtest file ([d0eb5d6](https://github.com/biyuehu/mbdoc/commit/d0eb5d6))
- Remove book package ([9c28b5c](https://github.com/biyuehu/mbdoc/commit/9c28b5c))
- Add installing just of step to ci.yml ([74366d3](https://github.com/biyuehu/mbdoc/commit/74366d3))
- Update README.md, .gitignore and ci.yml ([0f40c14](https://github.com/biyuehu/mbdoc/commit/0f40c14))
- Update generate process and create .markdownlint.json file ([4629b2b](https://github.com/biyuehu/mbdoc/commit/4629b2b))
- Update ci.yml ([313f927](https://github.com/biyuehu/mbdoc/commit/313f927))
- Update code format ([2e26969](https://github.com/biyuehu/mbdoc/commit/2e26969))
- Update prebuild code format ([f479bbf](https://github.com/biyuehu/mbdoc/commit/f479bbf))
- Update ci ([452acc0](https://github.com/biyuehu/mbdoc/commit/452acc0))
- Update moon.mod format ([7f3dac2](https://github.com/biyuehu/mbdoc/commit/7f3dac2))
- Update ci.yml ([f407e0e](https://github.com/biyuehu/mbdoc/commit/f407e0e))
- Update ci.yml ([d5d44b7](https://github.com/biyuehu/mbdoc/commit/d5d44b7))
- Update ci.yml ([d228d9e](https://github.com/biyuehu/mbdoc/commit/d228d9e))
- Update ci.yml ([7720673](https://github.com/biyuehu/mbdoc/commit/7720673))
- Update ci.yml ([3abe364](https://github.com/biyuehu/mbdoc/commit/3abe364))
- Update debug information ([3506d8f](https://github.com/biyuehu/mbdoc/commit/3506d8f))
- Update ci ([f038ce4](https://github.com/biyuehu/mbdoc/commit/f038ce4))
- Update ci ([ce0523d](https://github.com/biyuehu/mbdoc/commit/ce0523d))
- Update ci ([5773b8d](https://github.com/biyuehu/mbdoc/commit/5773b8d))
- Update ci ([2e28eb4](https://github.com/biyuehu/mbdoc/commit/2e28eb4))
- Update ci ([814618e](https://github.com/biyuehu/mbdoc/commit/814618e))
- Update ci ([e799216](https://github.com/biyuehu/mbdoc/commit/e799216))
- Update README.mbt.md and add TODO.md file ([6c5c714](https://github.com/biyuehu/mbdoc/commit/6c5c714))
- Update generate.ts, README.md etc. ([50860b3](https://github.com/biyuehu/mbdoc/commit/50860b3))
- Update ci ([fe5e109](https://github.com/biyuehu/mbdoc/commit/fe5e109))
- Update ci.yml ([e773383](https://github.com/biyuehu/mbdoc/commit/e773383))
- Add gen-log.ts that generate changelog and rename generate.ts to gen-includes.ts ([a14cd55](https://github.com/biyuehu/mbdoc/commit/a14cd55))
- Update lefthook.yml, moon.mod ([928b5d6](https://github.com/biyuehu/mbdoc/commit/928b5d6))
- Add ci.yml ([107aa85](https://github.com/biyuehu/mbdoc/commit/107aa85))
- Update README.md ([f2e4a79](https://github.com/biyuehu/mbdoc/commit/f2e4a79))

### ✅ Tests

- Add book-test folder ([cb808c8](https://github.com/biyuehu/mbdoc/commit/cb808c8))
- Update ([d92795f](https://github.com/biyuehu/mbdoc/commit/d92795f))

### 🎨 Styles

- Improve code format and update TODO.md ([e0e65d3](https://github.com/biyuehu/mbdoc/commit/e0e65d3))

### ❤️ Contributors

- Romi ([@biyuehu](https://github.com/biyuehu))
- 有村ロミ ([@biyuehu](https://github.com/biyuehu))
- Hotaru ([@biyuehu](https://github.com/biyuehu))


