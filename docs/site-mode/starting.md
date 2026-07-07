---
title: 开始
---

# 开始

本节将带你从零编写一份最简单的构建脚本，把源目录中的 Markdown 文件渲染为 HTML。

## 准备工作

Site 模式下，项目的入口是一份 MoonBit 源文件（文件名可以自定义，只要在运行时正确指定即可）。需要在项目中引入核心库作为依赖。

## 编写最小示例

假设项目结构如下：

```text
.
├── site.mbt
└── src
    └── hello.markdown
```

在入口文件中写入：

```moonbit
///|
async fn main {
  @core.mopress([
    @core.Glob(
      "*.markdown",
      @core.Text(raw => raw
        |> @core.render_markdown_and_frontmatter
        |> @core.set_extension(".html")
        |> @core.identify),
    ),
  ])
}
```

这份代码声明了一条规则：匹配源目录下所有以".markdown"结尾的文件，将其内容作为文本读入，依次经过"渲染 Markdown 与元数据"和"修改目标扩展名为".html""两个 step，最后调用 `identify` 转换为最终可写入磁盘的格式。

## 运行构建

```bash
moon run site.mbt build
```

构建完成后，源目录中的 `hello.markdown` 会被渲染为输出目录中的 `hello.html`（默认的源目录与输出目录，可以通过 `Options` 自定义，参见下方说明）。

> 提示：这里的命令行参数解析（例如"build"子命令）需要自己在入口函数中处理，`mopress` 本身只负责执行构建，不负责解析命令行参数。如果想要一套类似 Book 模式的命令体系，可以参照 `mopress/main` 中命令分发的写法自行实现。

## 自定义源目录与输出目录

默认情况下，构建函数使用默认的 `Options` 提供的源目录与输出目录。如果需要自定义，可以显式传入：

```moonbit
///|
async fn main {
  let options = @core.Options::{ src: "content", dest: "public" }
  @core.mopress(
    [
      @core.Glob(
        "*.markdown",
        @core.Text(raw => raw
          |> @core.render_markdown_and_frontmatter
          |> @core.set_extension(".html")
          |> @core.identify),
      ),
    ],
    options~,
  )
}
```

## 加入模板

上面的示例只是把 Markdown 渲染为一段 HTML 片段，并没有套上完整的页面结构。可以在管线中加入套用模板的 step：

```moonbit
///|
async fn main {
  @core.mopress([
    @core.Glob(
      "*.markdown",
      @core.Text(raw => raw
        |> @core.render_markdown_and_frontmatter
        |> @core.set_extension(".html")
        |> x => x.load_and_apply_template("templates/default.html")
        |> @core.identify),
    ),
  ])
}
```

> [!TIP]
> 关于模板语法本身、以及模板变量是如何对应起来的，请参见 [组合 Steps](./composing-steps.md) 与 [模板引擎](../custom/template.md) 相关说明。
