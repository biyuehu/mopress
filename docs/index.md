---
title: 介绍
---

# MoPress

MoPress 是一个面向 MoonBit 生态的现代文档与通用静态站点生成工具，设计上同时参考了 [mdBook](https://rust-lang.github.io/mdBook/) 与 [Hakyll](https://jaspervdj.be/hakyll/)。它的核心使用嵌入式 DSL（Domain Specific Language）来声明配置和函数式的处理管线来表达构建流程，同时提供丰富的语言无关向插件系统与自定义能力，以满足各种需求。

## 为什么是 MoPress

如果你只是想快速写一本文档、发布一个博客，你不应该重复造论写一套构建系统；但如果你的需求超出了写 Markdown、套模板，你也不应该被工具的边界卡住手脚，但也不应重复繁琐的细节处理。MoPress 试图同时兼顾这两种情况，为此提供了两种互不冲突的使用方式：

- [**Book 模式**](./book-mode/index.md)：开箱即用，体验上接近 mdBook。只需要一份 `sena.toml` 配置文件和一堆 Markdown 文件，不需要写任何代码。但同时又拥有许多 mdBook 所不能及的特性，比如多种插件系统、代码注入、自定义模板、frontmatter、AST 变换（即 transformers）等。
- [**Site 模式**](./site-mode/index.md)：在 `site.mbtx` 中以 DSL 的形式声明规则（Rule）与处理管线（Pipeline），通过提供的大量原子化 Step 表达构建流程，既能对内容如何被处理、渲染拥有完全的控制权，又能在函数式编程下灵活、自由地组合 Step 发挥无限表达力又不必关注无趣的底层处理细节。~~在 MoonBit 的优雅语法加持下，这一声明式风格或许会让函数式编程爱好者们兴奋。~~

两种模式共享同一套底层能力（Markdown 解析、模板引擎、外部插件协议等）。事实上，Site 模式旨在通用的静态网站生成器，而 Book 模式是基于 Site 模式的最佳实践示例兼预设了一套书籍文档网站构建流程的开箱即用生成器。

## 接下来读什么

如果你想尽快看到效果，请从 [快速开始](./quick-start.md) 开始；如果你已经知道自己要用哪种模式，可以直接跳到 [Book 模式](./book-mode/overview.md) 或 [Site 模式](./site-mode/overview.md) 章节。

## 本书结构

- MoPress 的两种模式虽密切相关，但使用人群终然不同，故必要在一定程度上分别道来。在 [快速开始](./starting.md) 一篇与 [Book 模式](./book-mode/index.md) 一章中均为讲解 Book 模式，而 [Site 模式](./site-mode/index.md) 着重讲解 Site 模式。
- [高级](./advance/index.md) 一章中详细讲解 MoPress 的高级功能与插件系统，对于 Book 模式 与 Site 模式共有的重要概念也会一并出现在本章。
- 之后给出了几篇参考说明。
- 最后是本书的若干篇附录。
