---
title: 外部插件协议
---

# 外部插件协议

本节详细说明外部预处理器、转换器程序需要遵循的标准输入、标准输出通信协议。无论用什么语言（TypeScript、Python、Go、JavaScript、PHP、Lua、Teal、Gleam、Haskell、Idris、Rust、C、Swift、Scala、Kotlin、Scheme、Koka 等）编写这些程序，只要遵循本节描述的协议，就可以被 MoPress 正确调用。

## 两个阶段

外部程序分为两类，分别在构建管线的不同阶段被调用：预处理器在 Markdown 文本被解析为语法树之前运行，操作对象是原始文本；转换器在 Markdown 文本被解析为语法树之后运行，操作对象是语法树。两者的通信协议结构一致，仅在 `type` 字段与 `data` 字段的内容上有区别。

## 请求：通过 stdin 发送的内容

每次调用外部程序时，MoPress 会将以下 JSON 结构写入该进程的标准输入：

```json
{
  "config": { "...": "当前的站点配置（BookConfig）" },
  "type": "markdown-text",
  "data": "..."
}
```

`config` 字段是当前站点的完整配置，对应 `BookConfig`，供程序按需读取。`type` 字段固定为两个取值之一：预处理器收到的是 `markdown-text`，转换器收到的是 `markdown-ast`。`data` 字段是待处理的实际内容：预处理器收到的是纯文本字符串，转换器收到的是 Markdown 语法树的 JSON 表示。

## 响应：通过 stdout 返回的内容

程序处理完成后，需要将结果写入标准输出，有两种合法的返回形式。

**返回处理结果**：

```json
{ "data": "..." }
```

`data` 字段的类型与请求中的 `data` 字段保持一致。这个结果会成为下一个程序（如果配置了多个）的输入，或者成为该阶段的最终输出。

**返回空输出**：如果标准输出为空字符串，表示该程序判断当前内容不需要处理，数据将原样传递给下一个程序，不做任何修改。

## 错误：程序如何上报失败

如果处理过程中出现错误，程序应当以非零状态码退出，并且向标准错误写入以下 JSON 结构：

```json
{ "error": "对错误的描述" }
```

MoPress 在解析结果时会依次检查：

- **退出码**：非零退出码会被视为该程序执行失败，无论标准错误中写了什么内容，构建会中止并报告这次失败，标准错误的内容会一并附带，用于辅助排查。
- **标准错误内容**：即使退出码为零，只要标准错误非空，也会被视为程序主动上报的业务错误，同样会中止构建。MoPress 会尝试将标准错误按上述结构解析；如果无法解析，会将标准错误的原始文本整体作为错误信息。
- **标准输出内容**：只有在退出码为零、且标准错误为空的前提下，才会去解析标准输出。空字符串意味着不处理、原样传递；非空字符串会被按上述结构解析，如果不是合法的 JSON，或者不符合预期结构，同样会被视为错误并中止构建。

## 链式调用

预处理器、转换器都是以数组的形式配置多个程序，程序会按数组中声明的顺序依次执行，前一个程序的输出（或者，如果它选择不处理，则是它收到的原始输入）会作为下一个程序的输入。任意一个程序在链条中失败，都会导致整个链条中止，不再执行后续程序。

## 一个最简单的预处理器示例

用 TypeScript 编写、通过 Bun 运行的预处理器，检查内容中是否包含某个占位符文本，如果没有则不做任何处理：

```typescript
const req = JSON.parse(await Bun.stdin.text());

if (!req.data.includes("{{BUILD_TIME}}")) {
  process.stdout.write("");
} else {
  const data = req.data.replaceAll("{{BUILD_TIME}}", new Date().toISOString());
  process.stdout.write(JSON.stringify({ data }));
}
```

## GitHub-Alerts

项目中提供的 [Github-Alerts](https://github.com/biyuehu/mopress/blob/main/docs/plugins/preprocessers/github-alert.ts) 插件就是基于 TypeScript 编写、通过 Bun 运行的预处理器：

```toml
# ...
[extensions]
# ...
preprocessors = ["bun plugins/preprocessers/github-alert"]
```

```typescript
const req = JSON.parse(await Bun.stdin.text());

const COLORS: Record<string, string> = {
 NOTE: "#0969da",
 TIP: "#1a7f37",
 IMPORTANT: "#8250df",
 WARNING: "#9a6700",
 CAUTION: "#cf222e",
};

const re =
 /^> \[!(NOTE|TIP|IMPORTANT|WARNING|CAUTION)\][ \t]*\r?\n((?:>.*(?:\r?\n|$))*)/gim;

let matched = false;
const data = (req.data as string).replace(
 re,
 (_m: string, type: string, block: string) => {
  matched = true;
  type = type.toUpperCase();
  const content = block
   .split(/\r?\n/)
   .map((l) => l.replace(/^>\s?/, ""))
   .join("\n")
   .trim();
  const color = COLORS[type];
  const title = type[0] + type.slice(1).toLowerCase();
  return `<div style="border-left:4px solid ${color};padding:8px 16px;margin:16px 0;background:${color}1a">
<p style="font-weight:600;color:${color};margin:0 0 4px">${title}</p>
<p style="margin:0;white-space:pre-wrap">${content}</p>
</div>\n`;
 },
);

if (!matched) {
 process.stdout.write("");
} else {
 process.stdout.write(JSON.stringify({ data }));
}

export {};
```
