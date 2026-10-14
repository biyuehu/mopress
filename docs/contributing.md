---
title: 贡献指南
---

# 贡献指南

感谢你对 MoPress 的关注与支持！无论是提交 Bug 报告、提出功能建议、完善文档、贡献核心代码，还是向 [插件枢纽](./plugins.md) 提交你开发的插件，我们都非常欢迎。

---

## 1. 准备开发环境

在开始贡献代码前，请确保你的本地环境中安装了以下工具：

- **[MoonBit](https://www.moonbitlang.com/)**：最新的 MoonBit 编译器与工具链。
- **[Bun](https://bun.sh/)**（或 Node.js）：用于运行构建预处理脚本及外部插件协议测试。
- **[Just](https://github.com/casey/just)**：通用的命令运行工具（可选，但推荐用于便捷执行常用构建脚本）。
- **Git**：版本管理工具。

> [!CAUTION]
> 由于 MoonBit Native 后端的平台特性，Windows 用户建议确保系统安装并配置了 **MSVC**（Visual Studio C++ 构建工具）环境，而非 MinGW。

---

## 2. 本地开发与构建流程

### 克隆项目并安装依赖

```bash
git clone https://github.com/biyuehu/mopress.git
cd mopress

# 更新 MoonBit 依赖
moon update

# 安装 Git 提交钩子（推荐）
just init
```

### 生成嵌入资源（Prebuild）

MoPress 在编译时会将内置的模板、静态资源与演示项目转录为 MoonBit 源码（`src/includes.mbt`）。在修改了相关资源或执行编译/测试前，请先执行：

```bash
just prebuild
# 等价于：bun scripts/gen-includes.ts
```

### 运行测试

```bash
just test
# 等价于：just prebuild && moon test
```

MoPress 包含单元测试与快照测试。若改动影响到了预期的快照输出，可运行快照更新命令：

```bash
moon test --update
```

### 代码格式化与接口检查

在准备提交代码前，请确保代码已通过 MoonBit 官方格式化并更新了生成的接口声明文件（`.mbti`）：

```bash
moon fmt
moon info
```

> [!TIP]
> 如果项目配置了 `lefthook`，在执行 `git commit` 时会自动触发 pre-commit 钩子，按顺序执行 prebuild、代码格式化、接口更新与全量测试。

---

## 3. 提交规范（Pull Request）

1. **创建分支**：从 `main` 分支切出具名功能分支，如 `git checkout -b feat/my-new-feature` 或 `fix/resolve-issue-123`。
2. **提交信息规范**：遵循 [Conventional Commits](https://www.conventionalcommits.org/) 格式，常见类型包括：
   - `feat:` 新增功能
   - `fix:` 修复缺陷
   - `docs:` 文档改动
   - `test:` 新增或修复测试
   - `chore:` 构建脚本、依赖或工具链调整
3. **编写测试**：为新功能或修复的 Bug 添加对应的测试用例（黑盒测试 `*_test.mbt` 或白盒测试 `*_wbtest.mbt`）。
4. **提交 PR**：发起 Pull Request 并详细说明改动动机、设计思路与影响范围。

---

## 4. 插件枢纽（Plugin Hub）收录申请

如果你开发了适用于 MoPress 的插件（包括预处理器、转换器、Web Components 或 MoonBit 模块），欢迎申请收录进 [插件枢纽](./plugins.md)！

### 收录步骤

1. 将你的插件开源并发布到公开仓库（如 GitHub、Gitee、Codeberg）或 npm / mooncakes。
2. 编辑本项目仓库中的 [`docs/plugins.json`](https://github.com/biyuehu/mopress/blob/main/docs/plugins.json)，在数组末尾追加你的插件元数据：
   ```json
   {
     "name": "插件名称",
     "url": "https://github.com/username/your-plugin-repo",
     "type": "Transformers",
     "description": "简要描述插件的功能与适用场景。"
   }
   ```
3. 提交 PR，标题格式例如：`docs: add <plugin-name> to plugin hub`。

### 插件类型（`type` 字段）

`type` 字段必须为以下四种之一：

| 类型 | 说明 |
| --- | --- |
| `Preprocessers` | 文本预处理器（基于外部程序，通过 stdin/stdout 转换原始 Markdown 文本） |
| `Transformers` | AST 转换器（基于外部程序，通过 stdin/stdout 变换 Markdown AST 节点） |
| `WebComponents` | 前端运行时 Web Component 组件（配合 HTML 块或内嵌标签使用） |
| `MoonBit` | MoonBit 原生 Step 模块（适用于 Site 模式的进程内管道函数） |

### 插件质量要求

- **开源透明**：插件仓库需包含清晰的开源许可证（如 MIT、Apache-2.0、GPL 等）。
- **使用说明**：README 中需提供接入 MoPress（`sena.toml` 或 `site.mbtx`）的配置示例。
- **稳定性与安全**：插件在非正常输入下应能安全退出，外部脚本错误输出需遵循 MoPress 插件协议。

---

## 5. 报告问题与建议

遇到 Bug 或有新的功能想法？欢迎通过以下途径反馈：

- **Bug 报告**：在 GitHub Issues 中详细提供复现步骤、最小复现示例（Markdown 与 `sena.toml`）、操作系统环境以及错误日志。
- **功能讨论**：可以在 Issue 或 Discussions 中发起讨论，分享你的使用场景与设计设想。

