---
title: 组合 Steps
---

# 组合 Steps

核心库提供了一系列基础 step，可以借助 MoonBit 的管道操作符 `|>` 将它们自由拼接成一条完整的处理管线。本节介绍常用 step 的分类与用法，以及贯穿整条管线的模板变量机制。

## 常用 step

### 元数据与解析

```moonbit
pub fn separate_frontmatter(item : Item[String]) -> Item[(Map[String, String], String)]

pub fn[T : Show] extract_markdown(item : Item[T]) -> Item[(Map[String, String], String)]

pub fn[T : Show] parse_markdown(item : Item[T]) -> Item[Array[@markdown.Block]]
```

`separate_frontmatter` 将文本拆分为 YAML 元数据（`Map[String, String]`）与正文文本，输入要求是 `Item[String]`；`extract_markdown` 的作用与之相同，区别在于它接受任意实现了 `Show` 的类型作为输入，而不局限于 `String`。`parse_markdown` 将文本解析为 [Markdown 语法树](https://mooncakes.io/docs/himeno/mopress/markdown#Markdown)。

### 渲染

```moonbit
pub fn[T : Show] render_markdown(item : Item[T]) -> Item[String]

pub fn[T : Show] render_markdown_and_frontmatter(item : Item[T]) -> Item[String]

pub fn render_markdown_from_ast(item : Item[Array[@markdown.Block]]) -> Item[String]

pub fn render_markdown_and_frontmatter_from_ast(
  item : Item[Array[@markdown.Block]],
  frontmatter : Map[String, String],
) -> Item[String]
```

`render_markdown` 直接将文本解析并渲染为 HTML，不处理元数据，如果输入本身带有元数据块，元数据会被当作正文的一部分一并渲染，通常不是想要的效果。`render_markdown_and_frontmatter` 在渲染前先调用 `separate_frontmatter` 分离元数据，避免这个问题。`render_markdown_from_ast`、`render_markdown_and_frontmatter_from_ast` 是以上两者基于已经解析好的语法树的对应版本，适用于在解析和渲染之间插入了自定义处理逻辑（如转换器）的场景，其中 `render_markdown_and_frontmatter_from_ast` 需要额外显式传入元数据，因为语法树本身不携带元数据信息。

### 模板与资源注入

```moonbit
pub fn apply_template(item : Item[String], template : Array[@template.TemplateNode]) -> Item[String]

pub fn apply_template_strict(item : Item[String], template : Array[@template.TemplateNode]) -> Item[String] raise

pub fn load_and_apply_template(item : Item[String], path : String, strict? : Bool) -> Item[String] raise

pub fn use_css(item : Item[String], code : Array[String]) -> Item[String]

pub fn use_js(item : Item[String], code : Array[String]) -> Item[String]

pub fn import_css(item : Item[String], paths : Array[String]) -> Item[String]

pub fn import_js(item : Item[String], paths : Array[String]) -> Item[String]

pub fn inject_head(item : Item[String], html : String) -> Item[String]

pub fn inject_body(item : Item[String], html : String) -> Item[String]
```

`apply_template` 是宽松模式的渲染，遇到问题会跳过对应节点、以空内容代替；`apply_template_strict` 是严格模式，遇到问题会直接 `raise` 具体的错误，两者都要求预先解析好的模板节点数组。`load_and_apply_template` 把“读取模板文件、解析、渲染”三步合成一步，`strict` 参数决定内部走哪种渲染模式，默认宽松。

`use_css`、`use_js` 接受的是代码本体，数组中的每一项会各自生成一个独立的 `<style>`、`<script>` 标签直接内联到页面中，`use_css` 注入在 `</head>` 之前，`use_js` 注入在 `</body>` 之前。`import_css`、`import_js` 接受的是路径或 URL，以 `<link>`、`<script src>` 的形式引用外部资源，不内联代码本体。`inject_head`、`inject_body` 接受一段原始 HTML 片段，分别注入到页面的头部、尾部。这几个 step 的注入内容最终都是通过写入 `Item.vars` 中的对应变量实现的，只有在 item 之后被套用了模板，这些注入内容才会真正体现在渲染输出中。

### 元信息与收尾

```moonbit
pub fn[T] set_extension(item : Item[T], extension : String) -> Item[T]

pub fn[T : Thingable] unify(item : Item[T]) -> Item[Thing]
```

`set_extension` 修改 item 的目标扩展名，传入的字符串需要带上前导点号，如 `.html` 而非 `html`。`unify` 把最终数据归一为 `Thing`，是管线中最常见的收尾步骤，要求数据类型实现 `Thingable`：

```moonbit
pub trait Thingable {
  fn to_thing(Self) -> Thing
}

pub impl Thingable for String
pub impl Thingable for Bytes
pub impl Thingable for Json
```

`String` 会被转换为 `Thing::Doc`，`Bytes` 会被转换为 `Thing::Asset`，`Json` 会被转换为其自身对应的表示，具体的 `Thing` 定义与写入方式请阅读 [输出格式](./output-formats.md)。

### 外部插件桥接

```moonbit
pub async fn run_markdown_preprocessors(
  config : @config.BookConfig,
  data : String,
) -> String raise

pub async fn run_markdown_transformers(
  config : @config.BookConfig,
  data : Array[@markdown.Block],
) -> Array[@markdown.Block] raise
```

`run_markdown_preprocessors` 对原始文本依次执行一系列外部预处理命令，`run_markdown_transformers` 对已解析的语法树依次执行一系列外部转换命令。这两个函数本身不是 `(Item[T]) -> Item[R]` 形状的 step，而是接受、返回裸数据（`String`、`Array[@markdown.Block]`）的普通函数，接入管线时通常需要配合 `Item::map_with_eff` 使用：

```moonbit
item.map_with_eff(text => @bridge.run_markdown_preprocessors(config, text))
```

完整的通信协议、错误类型定义，请阅读 [外部插件协议](../advance/plugins/protocol.md)。

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

这两个 step 会按顺序依次调用数组中的每一个函数，前一个的输出作为后一个的输入，语义上与外部命令版本的预处理器、转换器完全一致，区别只是执行环境从独立进程变成了进程内的普通函数调用，因此不需要经过 JSON 序列化，性能开销更低，也更方便调试，可以直接打断点、直接抛出 MoonBit 原生的错误类型。

## 模板变量从哪里来

在 Site 模式中模板渲染的上下文变量通过 `Item::add_vars`、`Item::set_var`，或者其他 step 内部隐式设置。举例来说，。

如果希望像 Book 模式那样，自动把元数据的字段暴露为模板变量，可以使用 `render_markdown_and_frontmatter`、 `render_markdown_and_frontmatter_from_ast` step 或：

```moonbit
raw
|> @core.separate_frontmatter
|> x => {
  let (frontmatter, body) = x.data
  x.map(_ => body).add_vars(frontmatter.map(k, v => (k, @template.Value::String(v))))
}
```

反过来，如果场景不需要元数据出现在模板变量中，完全可以跳过这一步，`vars` 就不会包含任何元数据内容——这一切都在自己的掌控之中，Book 模式的自动行为只是这套机制的一种预设组合方式，而非唯一的固定行为。

## 完整的组合示例

Book 模式的 MarkDown 页面渲染函数 [`process_markdown_page`](https://mooncakes.io/docs/himeno/himeno/mopress#process_markdown_page) 就是最好的参考示例：

{{@ ../src/mod.mbt#steps }}
