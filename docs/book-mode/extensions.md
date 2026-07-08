---
title: 扩展配置
---

# 扩展配置（extension）

`sena.toml` 中的 `[extensions]` 表用于配置模板、静态资源、注入内容以及外部插件——这是 Book 模式下自定义构建行为的主要入口。

## 字段一览

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `template` | 字符串 | HTML 模板文件路径，所有页面都会套用该模板 |
| `assets` | 字符串数组 | Glob 匹配模式，用于指定需要原样复制到输出目录的静态资源 |
| `inject_head` | 字符串数组 | 注入到每个页面 `<head>` 中的原始 HTML 片段 |
| `inject_body` | 字符串数组 | 注入到每个页面 `</body>` 结束前的原始 HTML 片段 |
| `use_css` | 字符串数组 | 直接内联的 CSS 代码，每个元素会生成一个独立的 `<style>` 标签，插入到 `</head>` 之前 |
| `use_js` | 字符串数组 | 直接内联的 JavaScript 代码，每个元素会生成一个独立的 `<script>` 标签，插入到 `</body>` 之前 |
| `import_css` | 字符串数组 | 外部 CSS 文件的路径或 URL，以 `<link>` 的形式引入，而非内联 |
| `import_js` | 字符串数组 | 外部 JavaScript 文件的路径或 URL，以 `<script src>` 的形式引入，而非内联 |
| `preprocessors` | 字符串数组 | 依次执行的外部预处理命令，作用于原始 Markdown 文本 |
| `transformers` | 字符串数组 | 依次执行的外部转换命令，作用于已解析的 Markdown AST |

## 模板

`template` 字段指向的文件决定了页面的整体 HTML 结构。模板语法与变量系统的完整说明请参见 [模板引擎](../custom/template.md)。

## 静态资源

`assets` 使用 Glob 模式匹配需要原样复制的文件（例如图片、字体等），这些文件不会经过 Markdown 处理，只是从源目录复制到 `dest` 目录下的对应位置。Glob 语法的完整说明请参见 [Glob 模式](../references/glob.md)。

## 内联注入 vs 外部引入

`use_css`/`use_js` 与 `import_css`/`import_js` 都是用于给页面添加样式或脚本，但两者的语义完全不同：

- `use_css`/`use_js` 中的每一项都是**代码本体**，会被原样包裹进 `<style>`/`<script>` 标签直接嵌入页面中。
- `import_css`/`import_js` 中的每一项都是**文件路径或 URL**，会以 `<link>`/`<script src>` 的形式引用外部资源。

选择哪一种取决于你的使用场景：内联适合少量、页面强相关的样式或脚本；外部引入适合体积较大、或希望利用浏览器缓存的公共资源。

## 头部与正文注入

`inject_head` 与 `inject_body` 允许你插入任意原始 HTML 片段——例如统计脚本、Open Graph 元标签、第三方组件的初始化代码等。这两个字段常与 [Web Components 插件](../custom/plugins/web-components.md) 搭配使用：先通过 `inject_head` 或 `use_js`/`import_js` 引入自定义元素的定义脚本，再直接在 Markdown 正文中使用对应的自定义标签。

## 预处理器与转换器

`preprocessors` 与 `transformers` 分别对应两个不同的处理阶段：

- **预处理器**（preprocessors）在 Markdown 文本被解析为 AST **之前**执行，操作对象是原始文本，适合处理自定义语法（例如将某种特殊标记转换为标准 Markdown 或 HTML）。
- **转换器**（transformers）在 Markdown 文本被解析为 AST **之后**执行，操作对象是结构化的语法树，适合做更精确的结构级修改（例如重写某种特定的节点）。

两者都以数组形式配置，数组中的每一项是一条外部命令；命令会按数组顺序依次执行，前一个命令的输出会作为后一个命令的输入。这些命令与 mopress 之间通过标准输入/标准输出上的 JSON 协议通信，完整说明请参见 [外部插件协议](../custom/plugins/protocol.md)；更多插件形式（不局限于外部进程）请参见 [插件总览](../custom/plugins/index.md)。
