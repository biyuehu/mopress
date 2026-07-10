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
| `init` | 初始化一个新的 Book 模式项目 |
| `new` | 创建一个新的 Site 模式项目 |
| `build` | 构建站点 |
| `serve` | 在本地启动开发服务器预览站点 |
| `version` | 打印版本信息 |
| `help` | 打印帮助信息 |

## mopress init

```bash
mopress init
```

针对的是 Book 模式用户。若当前目录下已存在配置文件，会打印提示信息后直接结束，不做任何修改，不会覆盖已有配置。否则会依次写入一份带默认值的配置文件；若模板、样式、脚本三个目录尚不存在，则分别创建；写入默认的模板文件、样式文件与脚本文件。

`init` 命令是幂等的：对一个已经初始化过的目录重复执行，只会因为配置文件已存在而提前退出，不会产生副作用。但这一判断只检查配置文件是否存在，如果手动删除了模板、样式、脚本目录中的某一个、但保留了配置文件，重新运行 `init` 并不会补齐这些被删除的目录与文件，因为 `handle_init` 的逻辑在检测到配置文件存在时会整体短路返回，不会继续往下逐项检查。

## mopress new

```bash
mopress new <dir>
```

针对的是 Site 模式用户。需输入一个目录参数。

## mopress build

```bash
mopress build
```

读取当前目录下的配置文件，解析后交给 `run` 执行完整的 Book 模式构建流程：解析导航结构、生成 404 页面、渲染所有 Markdown 内容并应用模板，最终将结果写入配置中指定的输出目录。构建过程中的任何失败都会中止整个构建。

## mopress serve

```bash
mopress serve
```

读取当前目录下的配置文件，转换为构建选项后启动一个本地开发服务器，用于预览站点效果。

## mopress version

```bash
mopress version
```

打印当前版本号。

## mopress help

```bash
mopress help
```

打印用法说明与四个命令的简要描述。不带任何参数运行 `mopress`，或者传入一个无法识别的命令，都会得到与显式运行 `mopress help` 完全相同的输出。

## Site 模式下的命令行

以上命令均针对 `mopress` 这个预置的可执行程序，服务于 Book 模式。Site 模式下并不存在与之对应的固定命令集，构建脚本是一份独立的 MoonBit 程序，通过如下方式运行：

```bash
moon run --target native site.mbtx <args>
```

`<args>` 仅支持 `build` 与 `serve` 两个子命令，其中 `server` 与 `mopress serve` 效果基本一致。`--target native` 旨在告诉 MoonBit 编译目标为 Native 平台。
