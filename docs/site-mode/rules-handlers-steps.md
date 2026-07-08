---
title: Rules, Handlers 和 Steps
---

# Rules, Handlers 和 Steps

本节详细介绍 Site 模式构建管线中的三个基础构件：`Rule`（规则）、处理方式（Handler）与 `Item`（数据载体）。

## Item：贯穿始终的数据载体

`Item[T]` 是构建管线中数据流动的基本单位，包含三个部分：

```moonbit
pub struct Item[T] {
  data : T
  priv extension : String
  vars : Vars
  target : String
} derive(Eq, Debug)
```

- `data : T`：实际的内容数据，类型会随着管线的推进而变化。
- `vars : Map[String, @template.Value]`：附加在这个 item 上的模板变量，用于后续套用模板时提供渲染上下文。
- `target : String`：该 item 最终应当写出的目标路径。

`Item` 提供了一组用于操作自身的方法：

- `Item::new(data, target, extension?, vars?)`——创建一个新的 item。
- `Item::map(self, f, target?, extension?, vars?)`——对 `data` 应用一个不会失败的函数 `f`，得到新类型的 item，同时可以顺带覆盖 `target`/`extension`/`vars`。
- `Item::map_with_eff(self, f, target?, extension?, vars?)`——与 `map` 类似，但 `f` 可以 `raise` 错误，错误会向外传播。
- `Item::base(self, target?, extension?, vars?)`——仅修改 `target`/`extension`/`vars`，`data` 保持不变。
- `Item::add_vars`／`Item::set_var`／`Item::clear_var`——分别用于批量合并变量、设置单个变量、清除某个变量。
- `Item::location(self)`——返回该 item 当前的 `target` 路径，常用于计算面包屑、上一页/下一页等导航信息。

>[!NOTE]
> **关于扩展名的约定**：任何涉及 `extension` 参数的地方（`Item::new`、`Item::base`、`Item::map`、以及顶层的 `set_extension` 函数），传入的字符串都需要包含前导的点号，例如".html"而非"html"。

## Step：数据流动的基本单元

Step 是形如 `(Item[T]) -> Item[R]`（可能是 `async`，也可能会 `raise`）的函数。可以把一条处理管线理解为一连串 Step 的接续调用，借助 MoonBit 的管道操作符"|>"可以写得非常直观：

```moonbit
raw
|> @core.separate_frontmatter
|> @core.parse_markdown
|> @core.render_markdown_from_ast
```

核心库提供了大量现成的 step，覆盖了从"分离元数据"到"解析 Markdown"到"渲染 HTML"到"应用模板"等各个环节，具体如何挑选、组合这些 step 请参见组合 Steps 相关说明。

## Rule：声明"谁该被怎样处理"

一条 `Rule` 描述了"哪些文件应该被匹配到、并以何种方式处理"，有两种构造方式：

```moonbit
pub(all) enum Rule {
  Glob(String, Handler)
  Guard(String, (String) -> Bool, Handler)
}
```

- **`Glob(pattern, handler)`**：使用 Glob 模式匹配文件路径，凡是匹配到的文件都会以给定的处理方式处理。Glob 语法的完整说明请参见相关参考。
- **`Guard(pattern, predicate, handler)`**：在 Glob 匹配的基础上，追加一层自定义的判定函数——只有当文件路径同时满足 Glob 模式并且让 `predicate` 返回"true"时，才会被这条规则处理。`predicate` 接收的是文件相对于源目录的完整路径。这在需要比 Glob 语法更精细的匹配逻辑时非常有用，例如"排除掉某个特定命名规则的文件"或"根据文件内容做条件判断"。

一个使用 `Guard` 的例子——排除掉草稿文章（假设草稿文件名以"draft-"开头）：

```moonbit
@core.Guard(
  "*.markdown",
  path => !path.has_prefix("draft-"),
  @core.Text(raw => raw |> /* ... */),
)
```

`Rule` 上还提供了两个便捷方法：

- `Rule::check(self, path)`——判断给定路径是否命中这条规则，可用于调试或自行实现构建预览等功能。
- `Rule::mode(self)`——取出这条规则关联的处理方式，避免手动模式匹配"Glob"/"Guard"两种情形。

多条规则会按照数组中的顺序依次匹配；一个文件一旦被某条规则匹配到，通常不会再被后续规则重复处理，具体的匹配优先级取决于构建函数的调度实现。

## Handler：处理方式

处理方式描述了"匹配到的文件应该以什么形式读入、经过怎样的处理"：

```moonbit
pub(all) enum Mode {
  Text(async (Item[String]) -> Item[Thing])
  Binary(async (Item[Bytes]) -> Item[Thing])
  Copy
}
```

- **`Text(step)`**：将匹配到的文件作为 UTF-8 文本读入，包装成"Item[String]"，交给 `step` 处理，最终产出"Item[Thing]"。这是处理 Markdown、模板等文本类内容最常用的方式。
- **`Binary(step)`**：将匹配到的文件作为原始字节读入，包装成"Item[Bytes]"，交给 `step` 处理。适用于需要对二进制内容做处理的场景（例如图片压缩、字体子集化等）。
- **`Copy`**：不做任何处理，将匹配到的文件原样复制到输出目录中的对应位置。这是静态资源配置底层依赖的处理方式。

处理方式本身也提供了一个 `run` 方法，用于直接对某个路径执行该处理方式并得到结果，通常不需要手动调用它——构建函数会在遍历匹配到的文件时自动完成这一步。

> [!TIP]
> 关于最终 Step 的输出类型 `Item[Thing]`、输出多个文件、自定义输出文件名字等内容请参考 [输出格式](./output-formats.md)。
