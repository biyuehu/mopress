---
title: 配置
---

# 配置（sena.toml）

在 Book 模式下，`sena.toml` 是站点唯一需要的配置文件，位于项目根目录。运行 `mopress init` 时会自动生成一份带有默认值的 `sena.toml`。

## 基本格式

`sena.toml` 使用 [TOML](https://toml.io/) 格式编写。以下是本书的完整配置：

{{@ sena.toml}}

## 字段说明

下表列出了 `sena.toml` 顶层支持的所有字段。具体定义参考 [`BookConfig`](https://mooncakes.io/docs/himeno/mopress/config#BookConfig)。

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `title` | String | 站点标题，用于页面 `<title>` |
| `description` | String | 站点简介，用于 `<meta name="description">` 元信息 |
| `keywords` | String | 站点关键词，用于 `<meta name="keywords">` 元信息 |
| `favicon` | String | favicon 文件路径（相对于站点根目录），用于页面 `<link rel="icon">` |
| `logo` | String | 站点 Logo 文件路径 |
| `authors` | Array[String] | 作者列表，渲染时会以逗号拼接 |
| `language` | String | 站点主语言，用于 HTML 的 `lang` 属性 |
| `languages` | Array[String] | 站点支持的所有语言列表，用于多语言（i18n）站点与 `hreflang` 标签生成 |
| `repository` | String? | 源码仓库地址，若填写会通过 `repository` 变量暴露给模板 |
| `src` | String | 源文件目录，相对于项目根目录 |
| `dest` | String | 构建输出目录，相对于项目根目录 |
| `base_url` | String | 基本 URL，用于构建输出的 URL 路径，默认值为 `/` |
| `site_url` | String? | 站点完整绝对 URL（包含协议与域名，如 `https://example.com`），用于 Feed 与 Sitemap。若未设置则跳过 Feed 生成 |
| `feed_enabled` | Bool | 是否启用 Atom Feed 生成（输出 `feed.xml`），默认值为 `true`（需设置 `site_url` 生效） |
| `feed_limit` | Int | Feed 收录的最大条目数，默认值为 `20` |
| `sitemap_enabled` | Bool | 是否启用站点地图生成（输出 `sitemap.xml`），默认值为 `true` |
| `[features]` | [FeaturesConfig](https://mooncakes.io/docs/himeno/mopress/config#FeaturesConfig) | 内置功能开关，详见 [功能预设](./features.md) |
| `[extensions]` | [ExtensionsConfig](https://mooncakes.io/docs/himeno/mopress/config#ExtensionsConfig) | 模板、资源注入与插件相关配置，详见 [扩展配置](./extensions.md) |

## Feed 与 Sitemap 生成

MoPress Book 模式开箱内置了站点地图（Sitemap）与 Atom 订阅源（Feed）生成能力：

- **Feed（`feed.xml`）**：采用标准的 Atom 1.0 格式。构建时会自动收录 `SUMMARY.md` 中索引的全部页面（最多收录 `feed_limit` 篇）。因为 Atom 协议要求条目链接必须为完整绝对路径，**生成 Feed 前必须在顶层配置 `site_url`**；若未指定 `site_url`，则会自动跳过 Feed 生成。
- **Sitemap（`sitemap.xml`）**：采用标准 Sitemap 0.9 格式，收录 `SUMMARY.md` 中的所有页面。当配置了 `site_url` 时使用绝对 URL，否则自动拼接 `base_url`。
- **页面元数据识别**：Feed 与 Sitemap 会优先从页面 [Frontmatter 元数据](./frontmatter.md) 中提取 `title`、`description`（摘要）、`keywords`（分类标签，以逗号分隔）、`authors`（作者，逗号分隔）、`date`（更新时间戳）与 `language`（语言标签）。**这些字段均为可选，有则使用、无则优雅忽略**；条目时间戳若未指定 `date` 则统一回退使用站点构建时间，作者若未指定则回退使用全局 `authors`。

## 多语言（i18n）支持

MoPress 支持构建多语言国际化文档：
- **主语言与备选语言**：通过顶层 `language = "zh"` 指定主语言，通过 `languages = ["zh", "en", "ja"]` 指定支持的所有语言。
- **SEO hreflang 自动注入**：当配置了 `site_url` 与 `languages` 时，MoPress 会自动在每个页面的 `<head>` 中注入所有对应语言版本的 `<link rel="alternate" hreflang="..." href="...">` 规范链接。
- **模板语言切换**：页面模板上下文中提供 `$site_language$`（当前站点主语言）和 `$site_languages$`（所有语言列表），可在模板中通过 `$for(site_languages)$` 轻松遍历渲染语言切换器。
## 注意事项

- 除 `[features]` 与 `[extensions]` 字段外，均会以不同形式自动注入为模板中的变量，具体行为参考 [页面定制](./pages.md)
- `src` 与 `dest` 建议使用相对路径，且不要让两者产生嵌套关系（如 `dest` 是 `src` 的子目录），否则构建时可能会把已生成的输出当作源文件重复处理。
- `[features]` 与 `[extensions]` 并非互斥关系：`features` 中的开关会在配置加载时自动展开（脱糖）为 `extension` 中的具体字段（如注入对应的 CSS/JS）。也就是说，你既可以只用 `features` 走“预设”路线，也可以直接在 `extension` 中手写等效配置，两者最终作用的对象是一致的。详见 [功能预设](./features.md)。
