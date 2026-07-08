---
title: 自定义 404 页面
---

# 自定义 404 页面

404 页面用于展示"页面未找到"提示的兜底页面，是一个很好的例子，可以说明 Book 模式与 Site 模式在处理同一类需求时的对应关系。

## Book 模式：不需要额外配置

在 Book 模式下，MoPress 会自动为站点生成一份 404 页面，其内容来自一段内置的默认文本，并经过与其他页面完全相同的处理管线：元数据分离、预处理器、转换器、渲染、套用模板。这意味着 404 页面同样会使用配置中指定的模板与站点信息，视觉上会与站点其余部分保持一致。

对应的实现，节选自 `mopress/main`：

```moonbit
pub async fn run(config : @config.BookConfig) -> Unit {
  let summary = @fs.read_file_to_string(
      @path.Path(config.src).join("SUMMARY.md").to_string(),
    )
    |> @markdown.parse_markdown
    |> @summary.parse_summary

  let not_found_page = step_markdown_raw(
    @core.Item::new(
      "---\ntitle: 404\n---\nYour page can not be found...",
      "404",
      extension=".md",
    ),
    config,
    summary,
  )

  @core.mo_build(
    { src: config.src, dest: config.dest },
    [
      Glob(
        "SUMMARY.md",
        Text(raw => {
          raw
          |> @core.set_extension(".json")
          |> x => {
            x.map_with_eff(_ => {
              @core.Multiple([
                (
                  "index.json",
                  summary.index_articles(config.src).to_json().stringify()
                  |> @core.Doc,
                ),
                ("404.html", not_found_page.data),
              ])
            })
          }
        }),
      ),
      Glob("*.markdown", Text(raw => raw |> step_markdown_raw(config, summary))),
      ..config.extension.assets.map(glob => @core.Glob(glob, Copy)),
    ],
  )
}
```

关键点在于：`not_found_page` 的内容并非来自源目录下的某个实际文件，而是通过 `@core.Item::new` 直接由代码构造出的一段字符串，随后经过与普通文章完全相同的 `step_markdown_raw` 处理；最终它与 `SUMMARY.md` 对应的搜索索引一起，通过 `Thing::Multiple` 在同一条规则中一并产出。

## Site 模式：用一条规则处理

在 Site 模式下，"404 页面"本质上只是"某个 item 经过处理管线后，被写出到 `404.html` 这个特定路径"这样一件事，不需要任何特殊机制，完全可以按照处理其他 Markdown 页面的方式来处理它：

```moonbit
///|
async fn main {
  let not_found = @core.Item::new(
      "---\ntitle: 页面未找到\n---\n很抱歉，你访问的页面不存在。",
      "404",
      extension=".md",
    )
    |> @core.render_markdown_and_frontmatter
    |> @core.set_extension(".html")
    |> x => x.load_and_apply_template("templates/default.html")

  @core.mopress([
    @core.Glob(
      "*.markdown",
      @core.Text(raw => raw
        |> @core.render_markdown_and_frontmatter
        |> @core.set_extension(".html")
        |> x => x.load_and_apply_template("templates/default.html")
        |> @core.identify),
    ),
  ])

  not_found.identify() |> _.write(options.dest, "404.html")
}
```

也可以像 `mopress/main` 内部实现的那样，把 404 页面的生成合并进对某个已有文件（如 `SUMMARY.md`）的处理规则中，借助 `Thing::Multiple` 让一次匹配同时产出多个文件，具体做法请阅读 [输出格式](../site-mode/recipes/output-formats.md) 中的示例。两种方式的效果是等价的，选择哪一种主要取决于希望把这部分逻辑放在哪里、以及是否希望复用某条已有规则的触发时机。

## 小结

不论是 Book 模式还是 Site 模式，404 页面在 MoPress 眼中都只是"一份经过标准处理管线、最终写出到特定路径的内容"，没有任何专属的隐藏机制，这也正是 MoPress 底层"一切皆是 `Item` 经过 step 处理"这一设计哲学贯彻得比较彻底的地方。
