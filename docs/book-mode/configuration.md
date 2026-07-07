---
title: 配置
---

# 配置（sena.toml）

在 Book 模式下，`sena.toml` 是站点唯一需要的配置文件，位于项目根目录。运行 `mopress init` 时会自动生成一份带有默认值的 `sena.toml`。

## 基本格式

`sena.toml` 使用 [TOML](https://toml.io/) 格式编写。一个最简单的示例如下：

```toml
title = "我的文档站"
description = "一个用 mopress 搭建的站点"
keywords = "moonbit, 文档, 静态站点"
favicon = "favicon.ico"
logo = "logo.png"
authors = ["Sena", "Romi"]
language = "zh"
repository = "https://github.com/example/example"
src = "./src"
dest = "./dest"
base-url = "/"

[features]
highlight_enabled = true
highlight_theme = "github"
mathjax_enabled = false

[extension]
template = "templates/default.html"
assets = ["images/*", "styles/*", "scripts/*"]
inject-head = []
inject-body = []
use-js = []
use-css = ["console.log('Hello, MoPress!');"]
import-css = []
import-js = []
preprocessors = []
transformers = []

```

## 字段说明

下表列出了 `sena.toml` 顶层支持的所有字段。

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `title` | 字符串 | 站点标题，用于页面 `<title>` |
| `description` | 字符串 | 站点简介，用于 `<meta name="description">` 元信息 |
| `keywords` | 字符串 | 站点关键词，用于 `<meta name="keywords">` 元信息 |
| `favicon` | 字符串 | favicon 文件路径（相对于站点根目录），用于页面 `<link rel="icon">` |
| `logo` | 字符串 | 站点 Logo 文件路径 |
| `authors` | 字符串数组 | 作者列表，渲染时会以逗号拼接 |
| `language` | 字符串 | 站点主语言，用于 HTML 的 `lang` 属性 |
| `repository` | 字符串（可选） | 源码仓库地址，若填写会通过 `repository` 变量暴露给模板 |
| `src` | 字符串 | 源文件目录，相对于项目根目录 |
| `dest` | 字符串 | 构建输出目录，相对于项目根目录 |
| `base-url` | 字符串 | 基本 URL，用于构建输出的 URL 路径，默认值为 `/` |
| `[features]` | 表 | 内置功能开关，详见 [Features 预设](./features.md) |
| `[extension]` | 表 | 模板、资源注入与插件相关配置，详见 [扩展配置](./extensions.md) |

## 注意事项

- `title`、`description`、`keywords`、`favicon`、`logo`、`authors`、`language` 字段均会以不同形式自动注入为模板中的变量，具体行为参考 [TODO:]
- `src` 与 `dest` 建议使用相对路径，且不要让两者产生嵌套关系（例如 `dest` 是 `src` 的子目录），否则构建时可能会把已生成的输出当作源文件重复处理。
- `repository` 字段留空时，对应的模板变量会是空字符串，而不是不存在——在模板中使用 `{{#if repository}}` 之类的判断时需要留意这一点。
- `[features]` 与 `[extension]` 并非互斥关系：`features` 中的开关会在配置加载时自动展开（脱糖）为 `extension` 中的具体字段（例如注入对应的 CSS/JS）。也就是说，你既可以只用 `features` 走"预设"路线，也可以直接在 `extension` 中手写等效配置，两者最终作用的对象是一致的。详见 [Features 预设](./features.md)。
