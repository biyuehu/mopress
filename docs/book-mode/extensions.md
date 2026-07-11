---
title: 扩展配置
---

# 扩展配置（extension）

`sena.toml` 中的 `[extensions]` 表用于配置模板、静态资源、注入内容以及外部插件——这是 Book 模式下自定义构建行为的主要入口。

## 字段一览

具体定义参考 [`ExtensionsConfig`](https://mooncakes.io/docs/himeno/mopress/config#ExtensionsConfig)。

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `template` | String | HTML 模板文件路径，所有页面都会套用该模板 |
| `assets` | Array[String] | Glob 匹配模式，用于指定需要原样复制到输出目录的静态资源 |
| `inject_head` | Array[String] | 注入到每个页面 `<head>` 中的原始 HTML 片段 |
| `inject_body` | Array[String] | 注入到每个页面 `</body>` 结束前的原始 HTML 片段 |
| `use_css` | Array[String] | 直接内联的 CSS 代码，每个元素会生成一个独立的 `<style>` 标签，插入到 `</head>` 之前 |
| `use_js` | Array[String] | 直接内联的 JavaScript 代码，每个元素会生成一个独立的 `<script>` 标签，插入到 `</body>` 之前 |
| `import_css` | Array[String] | 外部 CSS 文件的路径或 URL，以 `<link>` 的形式引入，而非内联 |
| `import_js` | Array[String] | 外部 JavaScript 文件的路径或 URL，以 `<script src>` 的形式引入，而非内联 |
| `preprocessors` | Array[String] | 依次执行的外部预处理命令，作用于原始 Markdown 文本 |
| `transformers` | Array[String] | 依次执行的外部转换命令，作用于已解析的 Markdown AST |

> [!TIP]
> 运用 <i>template</i>、<i>assets</i>、<i>use_*</i> 等字段可以高度定制页面，详细说明请参见 <a href="./pages.html">页面定制</a>。

## 模板

`template` 字段指向的文件决定了页面的整体 HTML 结构。模板语法与变量系统的完整说明请参见 [模板引擎](../advance/template.md)。

## 静态资源

`assets` 使用 Glob 匹配需要原样复制的文件（如图片、字体等），这些文件不会经过 Markdown 处理，只是从源目录复制到 `dest` 目录下的对应位置。Glob 语法的完整说明请参见 [Glob 匹配](../advance/glob.md)。

## 内联注入 vs 外部引入

`use_css`、`use_js` 与 `import_css`、`import_js` 都是用于给页面添加样式或脚本，但两者的语义完全不同：

- `use_css`、`use_js` 中的每一项都是**代码本体**，会被原样包裹进 `<style>`、`<script>` 标签直接嵌入页面中。
- `import_css`、`import_js` 中的每一项都是**文件路径或 URL**，会以 `<link>`、`<script src>` 的形式引用外部资源。

选择哪一种取决于你的使用场景：内联适合少量、页面强相关的样式或脚本；外部引入适合体积较大、或希望利用浏览器缓存的公共资源。

> [!NOTE]
> 当引用外部资源时，如果是本地资源，请确保其包含在 <i>assets</i> 中，否则相应资源不会被复制到输出目录。

## 头部与正文注入

`inject_head` 与 `inject_body` 允许你插入任意原始 HTML 片段——如统计脚本、Open Graph 元标签、第三方组件、Google Analytics 的初始化代码等。

理论上额外引用内容借助 `use_css`、`use_js` 或 `import_css`、`import_js` 即可满足大部分需求，例外的是 `use_*` 引入 CSS 或 JavaScript 代码的生成的 HTML 位于 `import_*` 导入 CSS 或 JavaScript 资源生成的 HTML 之后，而某些 JavaScript 库要求引入前得先有配置代码，故此即可使用 `inject_*` 自由地插入这些内容。如 MoPress 对 MathJax 功能的处理：

{{@ ../src/config/config.mbt#mathjax}}

## 预处理器与转换器

`preprocessors` 与 `transformers` 分别对应两个不同的处理阶段：

- **预处理器**（preprocessors）在 Markdown 文本被解析为 AST **之前**执行，操作对象是原始文本，适合处理自定义语法（如将某种特殊标记转换为标准 Markdown 或 HTML）。
- **转换器**（transformers）在 Markdown 文本被解析为 AST **之后**执行，操作对象是结构化的语法树，适合做更精确的结构级修改（如重写某种特定的节点）。

两者都以数组形式配置，数组中的每一项是一条外部命令；命令会按数组顺序依次执行，前一个命令的输出会作为后一个命令的输入。这些命令与 MoPress 之间通过标准输入、标准输出上的 JSON 协议通信，完整说明请参见 [外部插件协议](../advance/plugins/protocol.md)；更多插件形式（不局限于外部进程）请参见 [插件系统](../advance/plugins/index.md)。

## 使用插件

在 [多样化的插件](../advance/plugins/index.md) 中提到 MoPress 支持三种类型插件，不过 Book 模式只会用到其中两种。对于其具体信息暂时不必关心，且可以有一套另类的角度分类插件：

- **编译时插件**：语言无关的插件，基于标准输入、标准输出与 MoPress 通信，在构建时触发。具体信息参考 [外部插件协议](../advance/plugins/protocol.md)。
  - **预处理器**：处理对象为 Markdown 文本。
  - **转换器**：处理对象为 [Markdown 语法树](https://mooncakes.io/docs/himeno/mopress/markdown#Markdown)。
- **运行时插件**：某种意义上也是语言无关的，只要编译目标是 JavaScript 或 WebAssembly 即可。系作用于浏览器的 JavaScript 代码。
  - **Web Components**：听说过 [MDX](https://mdxjs.com/) 嘛？没错就是那个非要和 React 绑死还很臃肿的东西。神来一笔的 Web Components 插件解决了其许多问题，具体参考 [Web Components](../advance/plugins/web-components.md)。
  - 其他的 JavaScript、CSS 内容等

MoPress 提供的编译时插件几乎都使用 TypeScript 编写与 Bun 运行，Node.js 用户请注意。

> [!TIP]
> 运行时插件的最直接形式是使用 JavaScript，不过仍建议使用 TypeScript 提高开发体验，除非你真得不想有一点 JavaScript/TypeScript 工具链编译处理等杂事。

对于编译时插件分别将执行命令写入 `extensions.preprocessors` 与 `extensions.converters` 中即可。

对于运行时插件则分别将路径或代码写入 `extensions.import-*`、`extensions.use-*`、`extensions.inject-*` 即可。

## 寻觅插件

插件可在开源社区中寻求，也可以在 [插件中枢](../plugins.md) 寻找被 MoPress 收录的插件。
