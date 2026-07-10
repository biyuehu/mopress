---
title: 使用插件
---

# 使用插件

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

对于运行时插件则分别将路径或代码写入 `extensions.import-*`、`extensions.use_*`、`extensions.inject-*` 即可。

## 预处理器

## 转换器
