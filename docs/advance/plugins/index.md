---
title: 插件系统
---

# 插件系统

MoPress 提供三种互不排斥的方式来扩展内容的处理与展现方式，分别对应三种不同的扩展环境：独立于 MoPress 进程之外的外部程序、浏览器运行时标准、以及 MoonBit 生态内的代码库。选择哪一种，取决于想在什么层面、用什么语言解决问题。

## 三种插件形式一览

| 形式 | 扩展环境 | 适用场景 |
| --- | --- | --- |
| 外部 stdin、stdout 程序 | 任意语言的独立进程 | 用熟悉的语言编写文本、语法树处理逻辑，且需要跨项目复用，请阅读 [外部插件协议](./protocol.md) |
| Web Components | 浏览器运行时 | 需要在页面上呈现交互式、富媒体内容，且逻辑运行在客户端，请阅读 [Web Components](./web-components.md) |
| MoonBit 模块 | MoonBit 生态，仅 Site 模式 | 将一组可复用的 step 组合打包为库，在多个 Site 模式项目间共享，请阅读 [MoonBit 模块插件](./moonbit-modules.md) |

## 外部 stdin、stdout 程序

这是与 mdBook 的 preprocessor 机制最为接近的扩展方式：编写一个独立的可执行程序或脚本，MoPress 在构建过程中把内容通过标准输入传给它，读取它的标准输出作为处理结果。

与 mdBook 不同的是，MoPress 把这一机制拆分为两个阶段。对应的调用函数签名：

```moonbit
pub async fn run_markdown_preprocessors(
  config : @config.BookConfig,
  data : String,
  target: String
) -> String raise

pub async fn run_markdown_transformers(
  config : @config.BookConfig,
  data : Array[@markdown.Block],
  target: String,
) -> Array[@markdown.Block] raise
```

**预处理器**（preprocessor）操作原始 Markdown 文本，在解析为语法树之前运行，对应 `run_markdown_preprocessors`。**转换器**（transformer）操作已经解析好的 Markdown 语法树，在渲染为 HTML 之前运行，对应 `run_markdown_transformers`。这让可以根据实际需求，选择在文本层面还是结构层面介入处理流程。两者都通过扩展配置中的 `preprocessors`、`transformers` 字段声明，具体的通信协议请阅读 [外部插件协议](./protocol.md)。

失败时统一抛出以下错误类型 [`ProcessorError`](https://mooncakes.io/docs/himeno/mopress/bridge#ProcessorError)：

{{@ ../src/bridge/bridge.mbt#processor-error}}

试图想象一个平面直角坐标系，处理阶段与处理源分别为正交的 X、Y 轴。处理阶段即预处理器、转换器，描述的是“处理的何物”、“何时进行”。处理源即动作的发生者或者说预处理器、转换器的逻辑存在形式，分为内部与外部。在 [组合 Steps](../../site-mode/composing-steps.md) 中提到的 `use_preprocessor`、`use_transformer` Step 即是运行内部的预处理器、转换器，换而言之如果一个 Step 类型为 `fn (Item[String]) -> Item[String]`、`fn (Item[@markdown.Block]) -> Item[@markdown.Block]` 则分别认为是内部的预处理器、转换器。而上文的 `run_markdown_preprocessors`、`run_markdown_transformers` 函数则是对接外部的预处理器、转换器，具体实现是语言无关的，通过外部插件协议通信。

## Web Components

如果需要的不是“改写内容”，而是“让某段内容在页面上具备交互能力或特殊呈现效果”，Web Components 通常是比外部程序更合适的选择。MoPress 的 Markdown 解析器在遇到无法识别的 HTML 标签时，会将其原样保留在语法树中，而不会报错或丢弃：

{{@ ../src/markdown/markdown.mbt#block}}

其中 `HtmlBlock(String)` 就是原始 HTML 块被保留下来的形态；行内的原始 HTML 则对应 `Inline` 枚举中的 `Html(String)`。这意味着可以直接在 Markdown 正文中写自定义元素标签，只要配合注入脚本引入对应的自定义元素定义脚本，浏览器就会在渲染时原生地接管这部分内容，不需要 MoPress 在构建期做任何额外处理。详情请阅读 [Web Components](./web-components.md)。

## MoonBit 模块

如果扩展逻辑是用 MoonBit 编写的、只在 Site 模式的构建脚本内运行，最自然的做法是把它写成一组可复用的 step 函数，打包发布为一个独立的 MoonBit 包，供其他构建脚本通过包管理器引入。这一形式仅适用于 Site 模式，Book 模式的配置文件无法引用 MoonBit 代码。详情请阅读 [MoonBit 模块插件](./moonbit-modules.md)。

## 如何选择

三种形式的取舍可以归结为两个问题：这段逻辑应该跑在哪里、以及希望用什么语言编写它。

- 需要独立于 MoPress 主进程运行、且可能用非 MoonBit 语言编写，选择外部程序。
- 需要运行在浏览器端、为读者提供交互，选择 Web Components。
- 需要运行在构建期、且愿意用 MoonBit 编写、追求进程内调用的性能与可复用性，选择 MoonBit 模块。

这三者并不互斥，一个站点完全可以同时使用多种形式，用外部程序处理某种自定义 Markdown 语法，同时用 Web Components 渲染交互式图表。
