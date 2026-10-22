# Changelog

## v4.0.0...main

[compare changes](https://github.com/biyuehu/mbdoc/compare/v4.0.0...main)

### 🚀 Enhancements

- Add explain and --no-emit for build rules ([44dac1e](https://github.com/biyuehu/mbdoc/commit/44dac1e))
- Add feed and sitemap generation ([2462a1c](https://github.com/biyuehu/mbdoc/commit/2462a1c))
- **template:** Add loop variables, if-negation, and partial arguments ([d167b63](https://github.com/biyuehu/mbdoc/commit/d167b63))
- **plugins:** Implement MoonBit Playground Web Component plugin ([06a411a](https://github.com/biyuehu/mbdoc/commit/06a411a))
- **core:** Enable concurrent file processing in mo_build ([954e574](https://github.com/biyuehu/mbdoc/commit/954e574))
- **cli:** Add --analyze flag to mopress build for performance profiling ([9914f5f](https://github.com/biyuehu/mbdoc/commit/9914f5f))
- **cli:** Support --analyze-json flag for machine-readable performance metrics ([cddc2c8](https://github.com/biyuehu/mbdoc/commit/cddc2c8))
- **data:** Support structured data directory (JSON and TOML) for templates ([e7e6cad](https://github.com/biyuehu/mbdoc/commit/e7e6cad))
- **data:** Cache loaded data directory to avoid redundant disk reads ([60e49e1](https://github.com/biyuehu/mbdoc/commit/60e49e1))
- **core:** Skip rewriting unchanged files using content hashing in Thing::write_if_changed ([4d695f4](https://github.com/biyuehu/mbdoc/commit/4d695f4))
- **serve:** Add live reload client injection and status endpoint to mopress serve ([36380b1](https://github.com/biyuehu/mbdoc/commit/36380b1))
- **search:** Enhance client search with multi-word scoring, snippet context, and keyboard navigation ([ddf793d](https://github.com/biyuehu/mbdoc/commit/ddf793d))
- **core:** Extract TOC from rendered markdown and expose as \\$ template variable ([b664ed6](https://github.com/biyuehu/mbdoc/commit/b664ed6))
- **docs:** Enhance meta tags and SEO metadata for landing page ([f38b5cd](https://github.com/biyuehu/mbdoc/commit/f38b5cd))
- **core,summary,config:** Add fine-grained atomic SEO steps, robots.txt generator, and book integration ([e5d5258](https://github.com/biyuehu/mbdoc/commit/e5d5258))
- **core:** Implement excerpt, reading time, and pagination combinators for site mode ([e43b994](https://github.com/biyuehu/mbdoc/commit/e43b994))
- **new:** Upgrade site-mode scaffold with SEO, excerpt, reading-time, and posts/ example ([ba51579](https://github.com/biyuehu/mbdoc/commit/ba51579))
- **data:** Add YAML (.yaml/.yml) structured data source support ([0cccbf3](https://github.com/biyuehu/mbdoc/commit/0cccbf3))
- **cli:** Support init [dir] target and new <dir> [--template <blog ([minimal>]](https://github.com/biyuehu/mbdoc/commit/minimal>]))
- **i18n:** Add multi-language configuration, hreflang injection, and template variables ([d97ee2f](https://github.com/biyuehu/mbdoc/commit/d97ee2f))

### 🩹 Fixes

- Resolve warnings and migrate toml dependency ([2c6fac6](https://github.com/biyuehu/mbdoc/commit/2c6fac6))
- Compute relative path correctly when scanning assets for glob matching ([6102682](https://github.com/biyuehu/mbdoc/commit/6102682))
- Correct plugins directory names in init ([5fc543c](https://github.com/biyuehu/mbdoc/commit/5fc543c))
- Serialize lefthook pre-commit commands and stage test output ([ca4c45a](https://github.com/biyuehu/mbdoc/commit/ca4c45a))
- Serialize lefthook pre-commit commands to stage prebuild artifacts ([5d106ed](https://github.com/biyuehu/mbdoc/commit/5d106ed))
- **glob:** Degrade ** to * when not a standalone path segment ([3450466](https://github.com/biyuehu/mbdoc/commit/3450466))
- **glob:** Normalize backslash paths across all platforms and eliminate to_json deprecation warnings ([0c17219](https://github.com/biyuehu/mbdoc/commit/0c17219))
- **docs:** Restore @block steps marker in process_markdown_page ([2a8054c](https://github.com/biyuehu/mbdoc/commit/2a8054c))
- **docs:** Eliminate mobile sidebar flash by using CSS drawer and responsive init ([b21706a](https://github.com/biyuehu/mbdoc/commit/b21706a))
- **mbti:** Synchronize generated interface files with latest toolchain Int32 signatures ([9ecb759](https://github.com/biyuehu/mbdoc/commit/9ecb759))
- **mbti:** Update generated interface files to Int32 signatures for latest toolchain ([d22efbd](https://github.com/biyuehu/mbdoc/commit/d22efbd))

### 📖 Documentation

- Fix API name and field inconsistencies ([ab45dee](https://github.com/biyuehu/mbdoc/commit/ab45dee))
- Update TODO with new roadmap items and test gaps ([c4dae14](https://github.com/biyuehu/mbdoc/commit/c4dae14))
- Fix TODO.md corruption ([c1362ae](https://github.com/biyuehu/mbdoc/commit/c1362ae))
- Resolve documentation inconsistencies, add contributing guide, and automate index version update ([c9487e5](https://github.com/biyuehu/mbdoc/commit/c9487e5))
- Document template loop variables, negation, and partial arguments ([84f34d8](https://github.com/biyuehu/mbdoc/commit/84f34d8))
- Update TODO.md with data sources and build profiling completion ([db84b86](https://github.com/biyuehu/mbdoc/commit/db84b86))
- Update documentation for data_dir, variable priority, and build analyze options ([435fca2](https://github.com/biyuehu/mbdoc/commit/435fca2))
- Align documentation with latest CLI flags and API signatures ([d90843e](https://github.com/biyuehu/mbdoc/commit/d90843e))
- **site-mode:** Document excerpt, reading time, atomic SEO steps, and updated scaffold structure ([e6d6443](https://github.com/biyuehu/mbdoc/commit/e6d6443))
- Comprehensive proofreading and documentation update for CLI, features, pages, and i18n ([ae9c6a8](https://github.com/biyuehu/mbdoc/commit/ae9c6a8))
- **i18n:** Add English documentation, language switcher, and en navigation ([07b879f](https://github.com/biyuehu/mbdoc/commit/07b879f))
- **en:** Add Composing Steps and CLI Reference documentation ([a3dfc08](https://github.com/biyuehu/mbdoc/commit/a3dfc08))
- **en:** Complete full English documentation translation and navigation tree ([84f6799](https://github.com/biyuehu/mbdoc/commit/84f6799))
- **en:** Ensure newline at end of files ([db288c5](https://github.com/biyuehu/mbdoc/commit/db288c5))

### 🏡 Chore

- Add development roadmap to TODO ([11c3d56](https://github.com/biyuehu/mbdoc/commit/11c3d56))
- Stage generated artifacts via lefthook fallback ([cd0f775](https://github.com/biyuehu/mbdoc/commit/cd0f775))
- Migrate chalk dependency to moonbit-community ([4d5ed82](https://github.com/biyuehu/mbdoc/commit/4d5ed82))
- Exclude bridge test fixture from linguist stats ([f8658b9](https://github.com/biyuehu/mbdoc/commit/f8658b9))
- Include generated mbti files in lefthook stage-generated ([35eeeae](https://github.com/biyuehu/mbdoc/commit/35eeeae))
- Update lefthook.yml ([ed21e3e](https://github.com/biyuehu/mbdoc/commit/ed21e3e))

### ✅ Tests

- Expand and strengthen unit test coverage ([8ea105f](https://github.com/biyuehu/mbdoc/commit/8ea105f))
- **glob:** Cover tokenizer, scanner, and wildcard edge cases ([609b97b](https://github.com/biyuehu/mbdoc/commit/609b97b))
- Expand coverage and mark test roadmap items done ([e75f926](https://github.com/biyuehu/mbdoc/commit/e75f926))
- **template:** Add comprehensive tests for loop variables, negation, and partials ([7fa4648](https://github.com/biyuehu/mbdoc/commit/7fa4648))
- **mod:** Add test verifying embedded search template and script assets integrity ([7c61bf7](https://github.com/biyuehu/mbdoc/commit/7c61bf7))

### ❤️ Contributors

- Romi <biyuehuya@gmail.com>
- D47bc67 ([@romi](https://github.com/romi))


