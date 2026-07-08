---
title: 功能预设
---

# 功能预设

`sena.toml` 中的 `[features]` 表提供了一组开箱即用的功能开关。与 `[extensions]` 中需要手写具体配置项不同，`features` 只需要打开对应的布尔开关，mopress 就会在加载配置时自动将其“展开”为等效的 `extensions` 配置。

## 字段一览

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `highlight_enabled` | Bool | 是否启用代码块语法高亮 |
| `highlight_theme` | String | 语法高亮使用的主题名称，仅在 `highlight_enabled` 为 `true` 时生效 |
| `mathjax_enabled` | Bool | 是否启用 MathJax 数学公式渲染 |

### 关于高亮主题

MoPress 默认使用 [Highlight.js](https://highlightjs.org/) 作为语法高亮引擎。可前往 [此处](https://highlightjs.org/demo/) 查看可用主题列表，支持 `*-min` 主。如希望使用 `tokyo-night-dark-min` 时，`highlight_theme` 字段填写 `tokyo-night-dark` 即可，默认为 `github` 主题。

## 工作原理

`features` 本质上是一层“预设语法糖”：配置加载完成后，MoPress 会根据 `features` 中各开关的取值，自动向 `extensions` 中的相应字段（如 `use_js`、`use_css`、`import_css`、`import_js` 等）追加所需的脚本或样式引用。这个展开过程是自动完成的，你不需要手动调用任何命令。

举例来说，当 `highlight_enabled = true` 时，MoPress 会自动为页面引入一套语法高亮所需的 CSS 与 JS；当 `mathjax_enabled = true` 时，会自动引入 MathJax 的运行时脚本。你完全不需要自己去 `use_js`、`import_js` 中手写这些内容。

## 与 extensions 手动配置的关系

`features` 和 `extensions` 并不是两套割裂的配置——它们最终作用的是同一份 `extensions` 数据。

如果 `features` 提供的预设无法满足你的定制需求（如你想用一套自己完全手写的语法高亮方案，而不是 MoPress 内置提供的那一套），你可以不启用对应的 `features` 开关，转而直接在 `extensions` 中手动配置等效（或更符合你需求）的内容，参见 [扩展配置](./extensions.md)。两种方式可以按字段自由混用：某些功能用 `features` 走预设，某些功能用 `extensions` 手写定制，互不冲突。
