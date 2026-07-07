---
title: 输出格式
---

# 输出格式

管线处理完成后，最终需要落地为实际写入磁盘的文件——这一层由"Thing"类型描述。本节介绍"Thing"的几种形态，以及如何让单个 item 产出多个输出文件。

## Thing 的四种形态

```moonbit
pub(all) enum Thing {
  Doc(String)
  Asset(Bytes)
  Multiple(Array[(String, Thing)])
  Empty
}
```

- **`Doc(String)`**：文本类输出，例如渲染完成的 HTML 页面、生成的 JSON 文本等，会被作为文本文件写入磁盘。
- **`Asset(Bytes)`**：二进制输出，例如图片、字体等，会被作为二进制文件写入磁盘。
- **`Multiple(Array[(String, Thing)])`**：一个 item 同时产出多个具名输出——数组中的每一项是一对"文件名, Thing"，文件名需要包含扩展名。这在希望一份源文件同时生成多份不同用途的输出时非常有用。
- **`Empty`**：不产出任何文件。适用于某些只是"参与计算但本身不需要落地"的中间 item。

`unify` 这个 step（要求数据类型实现"Thingable"trait）通常是管线的最后一步，负责把最终的数据（"String"、"Bytes"，或者"Json"）转换为对应的"Thing"。"Thingable"目前为这三种类型提供了默认实现，分别对应转换为"Doc"、"Asset"，以及"Json"自身的相应表示。

## 写入磁盘

```moonbit
pub fn Thing::write(self : Self, dest : String, name : String) -> Unit raise @fs.IOError
```

`Thing::write` 负责把一个"Thing"实际写入输出目录下、以"name"命名的位置：对于"Doc"/"Asset"会直接写入对应的文本/二进制文件；对于"Multiple"，则会把"name"当作一个子目录，将数组中的每一项按各自的文件名递归写入该子目录下；"Empty"则不执行任何写入操作。这个方法是对底层文件系统写入能力的一层薄封装，本身不做任何额外的内容处理。

通常不需要手动调用"Thing::write"——构建函数会在遍历完所有匹配的规则后自动完成写入；只有在需要更细粒度地控制"何时写、写到哪"时，才需要直接使用它。

## 示例：一个源文件产出多个输出

将"SUMMARY.md"同时渲染为一份搜索索引 JSON 和一份 404 页面：

```moonbit
@core.Glob(
  "SUMMARY.md",
  @core.Text(raw => raw
    |> @core.set_extension(".json")
    |> x => x.map_with_eff(_ => @core.Multiple([
      (
        "index.json",
        summary.index_articles(config.src).to_json().stringify() |> @core.Doc,
      ),
      ("404.html", not_found_page.data),
    ]))),
)
```

这条规则匹配到"SUMMARY.md"文件后，并不会将其渲染为对应的"SUMMARY.html"，而是借助"Multiple"一次性产出了两个完全不同用途的文件：一份用于站内搜索的索引数据，以及一份 404 兜底页面。这个例子也说明了"Rule"匹配的文件路径与最终产出的文件名之间并不需要有直接对应关系。
