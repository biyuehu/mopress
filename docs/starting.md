---
title: 快速开始
---

# 快速开始

本节将带你在几分钟内创建一个可以运行的 MoPress 站点。这里使用的是 Book 模式——不需要写任何代码。

> [!WARNING]
> 项目仍在开发中，当前 MoPress 仅保证在 Windows 平台的准确无误，不保证在其他平台的正确性。建议在 Windows 平台上进行开发和测试。

## 第零步：安装 MoPress

提供了三种安装模式。

### 1. 使用 MoonBit 安装

要求已安装 MoonBit 工具链。输入以下命令：

```bash
moon install himeno/mopress
mopress version
```

### 2. 下载可执行文件（仅限 Windows 用户）

在 [Github Releases](https://github.com/biyuehu/mopress/releases) 中提供了 Windows 已构建完毕的可执行文件，下载后解压到任意目录并添加到系统环境变量中。

### 3. 构建可执行文件

要求已安装 MoonBit 工具链、Bun（或 Node.js）。输入以下命令：

```bash
git clone https://github.com/biyuehu/mopress.git
cd mopress
moon update
bun scripts/generate.ts
moon build
```

> [!CAUTION]
> 由于 MoonBit 的 Native 后端支持问题，Windows 用户请确保存在并使用 MSVC 工具链而非 MinGW。

构建完后在 `_build/native/release/build/` 目录中找到可执行文件，将其复制到任意目录并添加到系统环境变量中。

## 第一步：初始化项目

在一个空目录中运行：

```bash
mopress init
```

这个命令会做以下几件事：

- 生成默认的配置文件 `sena.toml`
- 创建 `templates/`、`styles/`、`scripts/`、`plugins/` 四个个目录，并在其中写入一套默认的模板与资源文件

执行完成后，你的目录结构大致如下：

```text
├── sena.toml
├── index.md
├── SUMMARY.md
├── templates/
│   └── default.html
├── styles/
│   └── index.css
├── scripts/
│    └── main.js
└── plugins/
     ├── external/
     ├── preprocessors/
     │    └── github-alert.ts
     └── transformers/
```

## 第二步：编写你的第一篇内容

MoPress 默认会把源目录（在 `sena.toml` 中配置，默认为 `./`）下所有的 `*.md` 与 `*.markdown` 文件构建为对应的 HTML 页面。

创建 `./SUMMARY.md`，定义站点的目录结构：

```markdown
# Summary

- [首页](./index.md)
```

再创建 `./index.md`：

```markdown
---
title: 你好，世界
---

# 你好，MoPress

这是你的第一篇内容。
```

> [!NOTE]
> <i>SUMMARY.md</i> 只负责定义导航结构（面包屑、上一页/下一页链接等），并不决定哪些文件会被构建。只要是 <i>./</i> 目录下的 <i>*.md</i> 、<i>*.markdown</i> 文件，无论是否出现在 <i>SUMMARY.md</i> 中，都会被构建为页面。

## 第三步：构建站点

```bash
mopress build
```

构建完成后，生成的静态文件会输出到 `sena.toml` 中配置的 `dest` 目录（默认为 `dest`）。

## 第四步：本地预览

如果你想在编写内容的同时实时预览效果，可以运行：

```bash
mopress serve
```

这会启动一个本地开发服务器，方便你在浏览器中直接查看站点效果。
