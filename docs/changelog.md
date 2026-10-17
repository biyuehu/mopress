---
title: Changelog
---

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

### 🩹 Fixes

- Resolve warnings and migrate toml dependency ([2c6fac6](https://github.com/biyuehu/mbdoc/commit/2c6fac6))
- Compute relative path correctly when scanning assets for glob matching ([6102682](https://github.com/biyuehu/mbdoc/commit/6102682))
- Correct plugins directory names in init ([5fc543c](https://github.com/biyuehu/mbdoc/commit/5fc543c))
- Serialize lefthook pre-commit commands and stage test output ([ca4c45a](https://github.com/biyuehu/mbdoc/commit/ca4c45a))
- Serialize lefthook pre-commit commands to stage prebuild artifacts ([5d106ed](https://github.com/biyuehu/mbdoc/commit/5d106ed))
- **glob:** Degrade ** to * when not a standalone path segment ([3450466](https://github.com/biyuehu/mbdoc/commit/3450466))
- **glob:** Normalize backslash paths across all platforms and eliminate to_json deprecation warnings ([0c17219](https://github.com/biyuehu/mbdoc/commit/0c17219))
- **docs:** Restore @block steps marker in process_markdown_page ([2a8054c](https://github.com/biyuehu/mbdoc/commit/2a8054c))

### 📖 Documentation

- Fix API name and field inconsistencies ([ab45dee](https://github.com/biyuehu/mbdoc/commit/ab45dee))
- Update TODO with new roadmap items and test gaps ([c4dae14](https://github.com/biyuehu/mbdoc/commit/c4dae14))
- Fix TODO.md corruption ([c1362ae](https://github.com/biyuehu/mbdoc/commit/c1362ae))
- Resolve documentation inconsistencies, add contributing guide, and automate index version update ([c9487e5](https://github.com/biyuehu/mbdoc/commit/c9487e5))
- Document template loop variables, negation, and partial arguments ([84f34d8](https://github.com/biyuehu/mbdoc/commit/84f34d8))
- Update TODO.md with data sources and build profiling completion ([db84b86](https://github.com/biyuehu/mbdoc/commit/db84b86))
- Update documentation for data_dir, variable priority, and build analyze options ([435fca2](https://github.com/biyuehu/mbdoc/commit/435fca2))

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

### ❤️ Contributors

- Romi <biyuehuya@gmail.com>


