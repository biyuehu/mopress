---
title: 组合 Steps
---

# 组合 Steps

核心库提供了一系列基础 step，可以借助 MoonBit 的管道操作符"|>"将它们自由拼接成一条完整的处理管线。本节介绍常用 step 的分类与用法，以及贯穿整条管线的模板变量机制。

## 常用 step 分类

TODO: 提供类型定义

### 元数据与解析

- `separate_frontmatter`：将文本拆分为 YAML 元数据（`Map[String, String]`）与正文文本。
- `extract_markdown`：与 `separate_frontmatter` 类似，但适用于任意"Show"类型的输入。
- `parse_markdown`：将文本解析为 Markdown 语法树（`Array[@markdown.Block]`）。

### 渲染

- `render_markdown`：直接将文本解析并渲染为 HTML（不处理元数据）。
- `render_markdown_and_frontmatter`：在渲染前先分离元数据，避免元数据内容被误当作正文渲染。
- `render_markdown_from_ast`、`render_markdown_and_frontmatter_from_ast`：基于已经解析好的语法树进行渲染，适用于在解析和渲染之间插入了自定义处理逻辑的场景。

### 模板与资源注入

- `load_and_apply_template`、`apply_template`、`apply_template_strict`：套用 HTML 模板，详见下方"模板变量"一节以及模板引擎相关说明。
- `use_css`、`use_js`：注入内联的 CSS/JS 代码。
- `import_css`、`import_js`：注入外部 CSS/JS 文件引用。
- `inject_head`、`inject_body`：注入原始 HTML 片段。

### 元信息与收尾

- `set_extension`：修改 item 的目标扩展名（记得带上前导点号）。
- `unify`：将最终数据转换为"Thing"，作为管线的收尾步骤。

### 外部插件桥接

- `run_markdown_preprocessors`：对原始文本依次执行一系列外部预处理命令。
- `run_markdown_transformers`：对已解析的语法树依次执行一系列外部转换命令。

### 进程内插件组合

除了通过外部命令扩展处理逻辑，Site 模式还允许直接传入一组 MoonBit 函数作为处理步骤：

```moonbit
pub fn use_preprocessor(
  item : Item[String],
  preprocessors : Array[(Item[String]) -> Item[String] raise],
) -> Item[String] raise

pub fn use_transformer(
  item : Item[Array[@markdown.Block]],
  transformers : Array[(Item[Array[@markdown.Block]]) -> Item[Array[@markdown.Block]] raise],
) -> Item[Array[@markdown.Block]] raise
```

这两个 step 会按顺序依次调用数组中的每一个函数，前一个的输出作为后一个的输入——语义上与外部命令版本的预处理器/转换器完全一致，区别只是执行环境从"独立进程"变成了"进程内的普通函数调用"，因此不需要经过 JSON 序列化，性能开销更低，也更方便调试。

## 模板变量从哪里来

`vars` 是附加在每个 `Item` 上的一组键值对，最终会作为渲染上下文提供给模板引擎。`vars` 并不会自动填充：它需要通过 `Item::add_vars`、`Item::set_var`，或者其他 step 内部隐式设置。举例来说，`inject_head`、`inject_body`、`use_css`、`use_js`、`import_css`、`import_js` 这类 step，内部都会自动将对应内容写入 `vars` 中的相应变量，以便模板能够在正确的位置渲染出这些内容——这也是这类注入 step 需要配合套用模板的 step 一起使用的原因，如果一个 item 从未被套用模板，这些注入的变量将不会体现在最终输出中。

如果希望像 Book 模式那样，自动把元数据的字段暴露为模板变量，可以手动完成这一步：

```moonbit
raw
|> @core.separate_frontmatter
|> x => {
  let (frontmatter, body) = x.data
  x
  |> @core.Item::map(_ => body)
  |> @core.Item::add_vars(
    frontmatter.map(k, v => (k, @template.Value::String(v))),
  )
}
```

反过来，如果场景不需要元数据出现在模板变量中，完全可以跳过这一步，`vars` 就不会包含任何元数据内容——这一切都在自己的掌控之中，Book 模式的自动行为只是这套机制的一种预设组合方式，而非唯一的固定行为。

## 一个较为完整的组合示例

将以上各类 step 组合起来，一条典型的 Markdown 处理管线大致如下：

```moonbit
raw
|> @core.separate_frontmatter
|> x => {
  let (frontmatter, body) = x.data
  x
  |> @core.Item::map(_ => body)
  |> @core.Item::add_vars(
    frontmatter.map(k, v => (k, @template.Value::String(v))),
  )
}
|> x => x.map_with_eff(text => @bridge.run_markdown_preprocessors(config, text))
|> @core.parse_markdown
|> x => x.map_with_eff(ast => @bridge.run_markdown_transformers(config, ast))
|> @core.render_markdown_from_ast
|> @core.set_extension(".html")
|> x => x.load_and_apply_template("templates/default.html")
|> @core.unify
```
