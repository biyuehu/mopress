---
title: Web Components
---

# Web Components

如果需要的不是在构建期改写内容，而是让页面上的某段内容具备交互能力或特殊呈现效果，Web Components 通常是比外部程序更合适、成本也更低的选择。

## 从何而来

众所周知，臭名昭著的 MDX 将 JSX 语法与 MarkDown 结合，而悲剧在于其与臃肿而过时的 React 深度绑定，并向根本不需要的 MarkDown 用户引入了一套繁重的构建流程体系。说到底，只是 frontenders 的玩具。MoPress 则在通用、标准、扩展能力、轻运行时、轻（甚至无）编译时中追求，Web Components 便是完美的答案。

## 核心原理：未识别的 HTML 标签会原样保留

MoPress 的 Markdown 解析器在遇到任何 HTML 标签时，会将其原样保留在语法树中，并在渲染阶段原样输出到最终的 HTML 里，意味着可以在 MarkDown 中直接使用 HTML（毫无疑问，会有愚蠢者钻出来用 XSS 扯皮）。相关的类型定义 [`Block`](https://mooncakes.io/docs/himeno/mopress/markdown#Block) ：

{{@ ../src/markdown/markdown.mbt#block}}

块级的原始 HTML 对应 `Block::HtmlBlock`，行内的原始 HTML 对应 `Inline::Html`，两者在渲染时都会被原样输出。

这意味着，可以直接在 Markdown 正文中写下任意自定义元素标签：

```markdown
这是一段普通的正文。

<code-playground language="moonbit">
fn main {
  println("Hello, MoPress!")
}
</code-playground>

后面继续是普通正文。
```

只要浏览器加载页面时，已经通过 `customElements.define(...)` 注册了 `code-playground` 这个自定义元素，浏览器就会在渲染时原生地接管这段标签，赋予它所定义的交互行为，整个过程不需要 MoPress 在构建期做任何额外的解析或编译。这正是 MoPress 选择拥抱 Web Components 的原因：不需要额外的编译管线，也不需要繁重的运行时，同时坐拥浏览器原生标准之大山，在复杂度、维护成本上都低得多。

## 接入方式

要让自定义元素在页面上生效，只需要保证对应的定义脚本会被加载到页面中。

**通过外部脚本引用引入外部脚本路径或 URL**，适合从 CDN 引入第三方 Web Components 库：

```toml
[extensions]
import_js = ["https://cdn.example.com/some-web-component-library.js"]
```

**通过头部、正文注入外部脚本文件**：

```toml
[extensions]
inject_body = ['<script type="module" src="/scripts/code-playground.js"></script>']
```

**通过内联脚本直接内联脚本代码**，适合体积较小的自定义元素定义：

```toml
[extensions]
use_js = ['''
class CodePlayground extends HTMLElement {
  connectedCallback() {
    // 组件的具体实现
  }
}
customElements.define("code-playground", CodePlayground);
''']
```

以上三种方式的具体语义区别，请阅读 [扩展配置](../../book-mode/extensions.md) 中“内联注入与外部引入”一节。选择哪一种，取决于脚本的来源（自己编写还是引用第三方库）与体积（内联适合小体积的胶水代码，外部引入适合较大的库文件）。

## 与外部程序插件的组合使用

Web Components 与外部 stdin、stdout 程序插件并不冲突，甚至可以配合使用：可以编写一个预处理器，把某种更简洁的自定义语法转换为对应的自定义元素标签，再交由浏览器端的 Web Components 负责实际渲染，前者负责作者友好的书写体验，后者负责页面上的实际交互效果，两者各司其职。

## 局限性

Web Components 的方案依赖浏览器原生支持，组件的渲染逻辑完全运行在客户端，不适合需要在构建期就生成最终静态内容的场景，如需要被搜索引擎直接索引到的文本内容，最好仍然通过 Markdown 本身或构建期渲染提供，而不是完全依赖客户端脚本生成；此外还需要考虑目标读者浏览器对 Custom Elements、Shadow DOM 等标准的支持程度，虽然目前主流现代浏览器普遍已经支持。

较于编译时的预处理器、变换器，Web Components 优点在于运行时中触发有着极高的自主能力、可扩展能力，缺点则是必须严格使用 HTML 标签而无法实现自定义语法。

## 编写

浏览器只支持 JavaScript，因此可选择直接用 JavaScript 基于原生 Web Components 编写。如若愿意引入一定的工程化实践或原生 Web Components 过于繁琐，可考虑使用 TypeScript 基于 Web Components 框架编写，如来自未来的 [Lit](https://lit.dev/)。

> [!IMPORTANT]
> 在未来，MoPress 会提供直接使用 MoonBit 基于 javaScript FFI 编写 Web Components 的支持。

## 示例

基于 Web Components 实现的 Bilibili 视频播放器插件 [bili-video](https://github.com/biyuehu/mopress/blob/main/docs/plugins/runtime/bili-video.js)：

```toml
[extensions]
import-js=["https://raw.githubusercontent.com/biyuehu/mopress/refs/heads/main/docs/plugins/runtime/bili-video.js"]
```

{{@ plugins/runtime/bili-video.js}}
