---
title: CLI 参考
---

# CLI 参考

本页是 `mopress` 可执行程序命令行用法的完整参考。日常上手请优先阅读 [快速开始](../starting.md)（Book 模式）或 [开始](../site-mode/starting.md)（Site 模式），本页仅作查阅之用。

## 基本用法

```bash
mopress <command>
```

`<command>` 缺省或无法识别时，会回退到显示帮助信息，等同于执行 `mopress help`，不会报错退出。

## 命令一览

| 命令 | 作用 |
| --- | --- |
| `init` | 初始化一个新的 Book 模式项目，支持可选的目标目录：`mopress init [dir]` |
| `new` | 创建一个新的 Site 模式项目：`mopress new <dir> [--template <blog|minimal>]` |
| `build` | 构建站点（支持 `--no-emit` 空运行、`--analyze` 性能分析、`--analyze-json` 机器可读报告） |
| `explain` | 打印规则匹配报告与预估输出列表（Dry-run） |
| `serve` | 在本地启动开发服务器预览站点 |
| `version` | 打印版本信息 |
| `help` | 打印帮助信息 |

## mopress init

```bash
mopress init [dir]
```

专用于 **Book 模式** 用户初始化文档项目。
- 若省略 `[dir]` 参数，默认在当前工作目录下初始化；
- 若指定了 `[dir]` 参数，会在指定的子目录下创建并初始化 Book 模式骨架。

若目标目录下已存在配置文件 `sena.toml`，会打印提示信息后直接安全退出，不会覆盖已有配置。否则会依次创建配置文件、`SUMMARY.md`、`index.md`，并在模板（`templates/`）、样式（`styles/`）、脚本（`scripts/`）以及插件（`plugins/`）目录中写入默认的脚手架资产。

`init` 命令是幂等的：对一个已经初始化过的目录重复执行，只会因为配置文件已存在而提前退出，不会产生副作用。但这一判断只检查配置文件是否存在，如果手动删除了模板、样式、脚本目录中的某一个、但保留了配置文件，重新运行 `init` 并不会补齐这些被删除的目录与文件，因为 `handle_init` 的逻辑在检测到配置文件存在时会整体短路返回，不会继续往下逐项检查。

## mopress new

```bash
mopress new <dir> [--template <blog|minimal>]
```

专用于 **Site 模式** 用户创建静态站点项目。
- `<dir>`：必填参数，指定创建项目的目标目录；
- `--template <blog|minimal>`（或 `-t`）：可选参数，指定初始模板类型：
  - `blog`（默认）：包含完整的博客示例、示例博文（`posts/hello-world.md`）、SEO 元数据注入、阅读时长统计、正文摘要截取以及统一的管道脚本 `site.mbtx`；
  - `minimal`：仅包含最基础的静态页面（`index.md`、`about.md`、`contact.md`）和轻量构建脚本，适合定制自己的独特渲染管线。

## mopress build

```bash
mopress build [--no-emit] [--analyze] [--analyze-json]
```

读取当前目录下的配置文件，执行完整的 Book 模式构建流程：解析导航结构、生成 404 页面、渲染所有 Markdown 内容并应用模板，最终将结果写入配置中指定的输出目录。构建过程中的任何失败都会中止整个构建。

- `--no-emit`：在内存中执行完整的构建与转换流程，但**不会将任何文件写入磁盘**，常用于 CI 测试和预检构建正确性。
- `--analyze`：在控制台中打印美观的可视化性能分析报告，包括：
  - 各处理阶段（预处理、转换、Markdown 解析、渲染、模板渲染、静态资源注入等）的总体耗时、页面平均耗时、最大耗时与调用次数；
  - 各页面的 HTML 体积（格式化为 B/KB/MB）、渲染总耗时、模板渲染次数（含 partials 递归计数）以及该页面最慢的处理步骤；
  - 站点总产物体积、平均页面体积与构建总耗时。
- `--analyze-json`：静默构建日志，直接在标准输出（stdout）中输出一份机器可读的结构化 JSON 性能分析报告，方便与外部分析脚本、CI/CD 性能基线或监控系统集成。

## mopress explain

```bash
mopress explain
```

分析当前配置与文件匹配规则，打印出哪些文件会被哪些规则匹配、以及预估会输出的文件清单，不会执行实际写文件操作。

## mopress serve

```bash
mopress serve
```

读取当前目录下的配置文件，转换为构建选项后启动一个本地开发服务器，用于预览站点效果。

## mopress version

```bash
mopress version
```

打印当前版本号与构建时间。

## mopress help

```bash
mopress help
```

打印用法说明与所有命令的简要描述。不带任何参数运行 `mopress`，或者传入一个无法识别的命令，都会得到与显式运行 `mopress help` 完全相同的输出。

## Site 模式下的命令行

以上命令均针对 `mopress` 这个预置的可执行程序，服务于 Book 模式。Site 模式下构建脚本是一份独立的 MoonBit 程序，通过如下方式运行：

```bash
moon run --target native site.mbtx <args>
```

`<args>` 支持 `build`（支持 `--no-emit`、`--analyze`、`--analyze-json`）、`serve` 以及 `explain` 子命令，其行为与 Book 模式对应命令一致。`--target native` 旨在告诉 MoonBit 编译目标为 Native 平台。
