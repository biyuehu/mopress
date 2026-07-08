---
title: 模板引擎
---

# 模板引擎

MoPress 内置了一套模板引擎，负责将页面内容与站点的整体 HTML 结构结合起来。本节介绍模板的语法与渲染上下文。

## 模板节点的完整定义

模板被解析为一棵由以下节点类型组成的语法树：

```moonbit
pub(all) enum TemplateNode {
  Text(String)
  Variable(String)
  If(String, Array[TemplateNode], Array[TemplateNode])
  For(String, Array[TemplateNode])
  Partial(String)
} derive(Eq, @debug.Debug)
```

- `Text(String)`——字面量、原样输出的文本片段。
- `Variable(String)`——变量引用，渲染时会被替换为对应的值。
- `If(String, Array[TemplateNode], Array[TemplateNode])`——条件分支：待测试的变量名、变量为真时渲染的节点、变量为假时渲染的节点。
- `For(String, Array[TemplateNode])`——循环：待遍历的变量名（要求其值为 `Value::Array`）、每次迭代渲染的节点。
- `Partial(String)`——引用另一份模板文件，将其渲染结果内联到当前位置。

## 基本语法

**变量插值**：

```html
<title>{{ title }}</title>
```

**条件判断**：

```html
{{#if repository}}
<a href="{{ repository }}">查看源码</a>
{{/if}}
```

**循环**：

```html
<ul>
{{#for item in nav_items}}
  <li>{{ item.title }}</li>
{{/for}}
</ul>
```

**局部模板**：

```html
{{> header}}
```

`{{> header}}` 会引入另一份模板文件，并将其渲染结果内联到当前位置，便于拆分和复用公共的页面片段，例如页头、页脚。

## 值类型的完整定义

模板变量的值使用以下类型表示：

```moonbit
pub(all) enum Value {
  String(String)
  Number(Double)
  Bool(Bool)
  Array(Array[Value])
  Object(Map[String, Value])
} derive(Eq, @debug.Debug)
```

`Array` 类型的值可以配合 `{{#for}}` 循环使用；`Object` 类型的值可以配合点号访问其字段，如上面循环示例中的 `item.title`；`Bool` 类型的值可以配合 `{{#if}}` 使用；`Number` 类型内部统一用 `Double` 表示，不区分整数与浮点数；`String` 类型直接作为文本输出。

`Value` 还提供了以下方法：

```moonbit
pub fn Value::from_json(json : Json) -> Self
pub impl Show for Value
```

`Value::from_json` 用于把一段 JSON 数据转换为对应的 `Value` 表示，例如用于把某个结构化的导航信息、索引数据转换为模板可用的变量；`Show` 的实现意味着一个 `Value` 可以直接作为字符串插值到渲染输出中。

## 渲染函数

```moonbit
pub fn apply_template(template : Array[TemplateNode], context : Map[String, Value]) -> String

pub fn apply_template_strict(
  template : Array[TemplateNode],
  context : Map[String, Value],
) -> String raise TemplateRenderError

pub fn[T : Show] parse_template(input : T) -> Array[TemplateNode] raise TemplateParseError
```

`parse_template` 把模板源码解析为 `Array[TemplateNode]`；`apply_template`、`apply_template_strict` 分别对应下面要说的宽松、严格两种渲染模式。

## 渲染上下文：变量从哪里来

模板渲染时能够访问到的所有变量，来自当前 `Item` 的 `vars`。在 Book 模式下，`vars` 中通常包含站点的基础信息（如 `site_title`、`site_description`）、元数据中声明的字段，以及导航相关信息（如 `breadcrumb`、`prev`、`next`、`section`）。在 Site 模式下，`vars` 的内容完全取决于处理管线中调用了哪些 step，请阅读 [组合 Steps](../site-mode/composing-steps.md) 中关于模板变量的详细说明。

## 严格模式与宽松模式

模板渲染有两种模式：

- **宽松模式**（`apply_template`）：渲染过程中遇到问题，例如引用了不存在的变量，会跳过对应的模板节点、以空内容代替，然后继续渲染文档的其余部分，不会导致整个渲染失败。
- **严格模式**（`apply_template_strict`）：一旦渲染中遇到任何问题，会立即中止并抛出具体的错误。对应的错误类型定义如下：

```moonbit
pub suberror TemplateRenderError {
  UndefinedVariableError(String)
  NonArrayForLoopError(String)
  PartialLoadError(String)
  PartialParseError(String)
  RecursivePartialError(String)
} derive(Eq, @debug.Debug)
```

- `UndefinedVariableError`——模板引用了一个渲染上下文中不存在的变量。
- `NonArrayForLoopError`——`{{#for}}` 循环引用的变量的值不是 `Value::Array`。
- `PartialLoadError`——引用的局部模板文件无法被读取。
- `PartialParseError`——引用的局部模板文件内容无法被解析。
- `RecursivePartialError`——局部模板直接或间接地引用了自身，导致无限递归。

解析阶段的错误则是另一种独立的错误类型：

```moonbit
pub suberror TemplateParseError {
  TemplateParseError(String)
} derive(Eq, @debug.Debug)
```

在 Book 模式中，`load_and_apply_template` 提供了 `strict` 参数用于在两种模式间切换，默认使用宽松模式。开发阶段建议开启严格模式以尽早暴露问题，正式发布时可以视情况切换回宽松模式，避免个别页面因为模板问题而导致整个构建失败。
