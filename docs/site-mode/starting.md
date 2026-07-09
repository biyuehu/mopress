---
title: 开始
---

# 开始

本节将带你从零编写一份最简单的构建脚本，把源目录中的 Markdown 文件渲染为 HTML。

## 准备工作

请先参考 Book 模式的 [快速开始](../starting.md) 中的安装 MoPress 步骤。

Site 模式下，项目的入口是一份 MoonBit 源文件（文件名可以自定义，只要在运行时正确指定即可）。需要在项目中引入核心库作为依赖。

## 创建项目

输入以下命令：

```bash
mopress new <dir>
```

生成以下 `<dir>` 目录结构：

```text
├── site.mbtx
├── index.md
├── about.md
├── contact.md
├── templates
│   └── default.html
└── styles
    └── default.css
```

其中 `site.mbtx` 为

{{@ demo-site/site.mbtx }}

这份代码声明了一条规则：匹配源目录下所有以 `.md` 结尾的文件，将其内容作为文本读入，依次经过“渲染 Markdown 与元数据”和
修改目标扩展名为`.html`”等多个 step，最后调用 `unify` 转换为最终可写入磁盘的格式。

## 运行构建

```bash
moon run --target native site.mbtx build
```

构建完成后，源目录中的 `hello.markdown` 会被渲染为输出目录 `dest` 中的 `hello.html`。

## 自定义源目录与输出目录

默认情况下，构建函数使用默认的 `Options` 提供的源目录与输出目录。如果需要自定义，可以显式传入：

```moonbit
///|
async fn main {
  let options :  @core.Options = { src: "./content", dest: "./public" }
  @core.mopress(
    options~,
    // ...
  )
}
```

## 初始化与共有项

当需要声明一系列所有规则共用的值时可使用 `@core.mopress_with` 函数：

```moonbit
pub async fn[E] mopress_with(
  options? : Options = Options::default(),
  init : (Options) -> E,
  rules : (Options, E) -> Rules,
) -> Unit
```

在传入的 `init` 函数中自定义返回的类型 `E`，并将其作为 `rules` 函数的第二个参数，所有的规则都将能访问到 `E` 值：

```moonbit
///|
async fn main {
  @core.mopress_with(
    (options) => {
      let shared = {
        "title": "My Site",
        "footer": "© 2026 Himeno Sena",
      }
      shared
    },
    (options, shared) => [
      // ...
    ],
  )
}
```

> [!TIP]
> 关于模板语法本身、以及模板变量是如何对应起来的，请参见 <a href="./composing-steps.html">组合 Steps</a> 与 <a href="../advance/template.html">模板引擎</a> 相关说明。
