---
title: 模板引擎
---

# 模板引擎

MoPress 内置了一套简单、轻量的模板引擎，负责将页面内容与站点的整体 HTML 结构结合起来。本节介绍模板的语法与渲染上下文。

## 模板节点的完整定义

模板被解析为一棵由以下节点类型组成的语法树 [`TemplateNode`](https://mooncakes.io/docs/himeno/mopress/template#TemplateNode)：

{{@ ../src/template/template.mbt#template-node}}

## 基本语法

其语法参考自 Hakyll。

### 变量插值

```html
<title>$title$</title>
```

支持点语法：

```html
<div>$item.title$</div>
```

### 条件判断

```html
$if(repository)$
<a href="$repository$">查看源码</a>
$endif$
```

支持 `!` 取反语法（`!` 后面允许有空格），与 `$else$` 分支互为反向：

```html
$if(!draft)$
<p>这是正式发布的文章</p>
$endif$
```

支持点语法取反，例如 `$if(!page.draft)$`。

`$else$` 分支：

```html
<title>
  $if(title)$
    $title$ - $site_title$
  $else$
    $site_title$
  $endif$
</title>
```

### 循环

```html
<ul>
$for(authors)$
  <li>$index$. $item.name$ <$item.email$></li>
$endfor$
</ul>
```

在循环作用域内通过以下变量访问当前循环信息：
- `$item$`：访问当前循环项。
- `$index$`：从 `0` 开始的当前索引数值。
- `$first$`：布尔值，是否为第一项（第一项为 `true`）。
- `$last$`：布尔值，是否为最后一项（最后一项为 `true`；若数组仅一项，则 `$first$` 与 `$last$` 均为 `true`）。

> [!NOTE]
> 这三个循环变量会在循环作用域内覆盖外层的同名变量，循环结束后自动恢复外层上下文。

### 局部引用

```html
$partial("path/header.html")$
```

`$partial("...")$` 会引入另一份模板文件，并将其渲染结果内联到当前位置，便于拆分和复用公共的页面片段，如页头、页脚。

同时也支持**传递参数**：

```html
$partial("nav-item.html", href=item.url, label="首页")$
```

- 参数值可以是在调用处上下文中查找的变量名或点路径（如 `item.url`），也可以是用双引号包裹的字符串字面量（如 `"首页"`）。
- 传入的参数只对该 partial 模板生效，不会污染或修改调用方的外层上下文。

> [!CAUTION]
> 谨慎使用，注意循环引用。

## 支持的值类型

模板变量的值使用 [`Value`](https://mooncakes.io/docs/himeno/mopress/template#Value) 类型表示：

{{@ ../src/template/template.mbt#value}}

`Array` 类型的值可以配合 `$for$` 循环使用；`Object` 类型的值可以配合点号访问其字段，如上面循环示例中的 `item.title`。

`""`、`false`、`[]`、未定义值（宽松模式）会被条件判断为假，其他值均为真。

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

模板渲染时能够访问到的所有变量，来自当前 `Item` 的 `vars`。在 Book 模式下，`vars` 中通常包含站点的基础信息（如 `site_title`、`site_description`）、元数据中声明的字段、导航相关信息（如 `breadcrumb`、`prev`、`next`、`section`），以及来自 `data_dir`（默认 `data/`）的结构化数据。

### 变量优先级与覆盖规则

在 Book 模式构建中，上下文变量的注入顺序与覆盖优先级为：

$$\text{内置基础变量（site\_* 等）} < \text{结构化数据（\$data.*\$）} < \text{页面 Frontmatter}$$

也就是说，如果某篇 Markdown 文章在 Frontmatter 中显式声明了同名变量（例如 `site_title: "专用标题"`），它会覆盖全局与数据源变量。

### 共享结构化数据（JSON / TOML）

在项目根目录创建 `data/` 目录，放置 `.json` 或 `.toml` 文件，文件内容将自动作为全局变量注入到所有页面的模板中，统一置于 `$data$` 命名空间下：

例如 `data/authors.json`：

```json
[
  { "name": "Alice", "url": "https://example.com/alice" },
  { "name": "Bob", "url": "https://example.com/bob" }
]
```

模板中即可直接遍历引用：

```html
$for(data.authors)$
  <a href="$item.url$">$item.name$</a>
$endfor$
```

又如 `data/settings.toml`：

```toml
banner_text = "欢迎访问文档站点！"
show_banner = true
```

模板中可通过点语法直接访问：

```html
$if(data.settings.show_banner)$
  <div class="banner">$data.settings.banner_text$</div>
$endif$
```

在 Site 模式下，可以使用 `@data.load_data(item, "data")` Step 将数据目录手动挂载进自定义管线。详细说明请参考 [组合 Steps](../site-mode/composing-steps.md)。

## 严格模式与宽松模式

模板渲染有两种模式：

- **宽松模式**（`apply_template`）：渲染过程中遇到问题，如引用了不存在的变量，会跳过对应的模板节点、以空内容代替，然后继续渲染文档的其余部分，不会导致整个渲染失败。
- **严格模式**（`apply_template_strict`）：一旦渲染中遇到任何问题，会立即中止并抛出具体的错误。对应的错误类型 [`TemplateParseError`](https://mooncakes.io/docs/himeno/mopress/template#TemplateParseError) 定义如下：

{{@ ../src/template/template.mbt#template-render-error}}

解析阶段的错误则是另一种独立的错误类型 [`TemplateRenderError`](https://mooncakes.io/docs/himeno/mopress/template#TemplateRenderError)：

{{@ ../src/template/template.mbt#template-parse-error}}

在 Book 模式中，`load_and_apply_template` 提供了 `strict` 参数用于在两种模式间切换，默认使用宽松模式。开发阶段建议开启严格模式以尽早暴露问题，正式发布时可以视情况切换回宽松模式，避免个别页面因为模板问题而导致整个构建失败。
