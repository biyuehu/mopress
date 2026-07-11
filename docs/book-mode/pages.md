---
title: 页面定制
---

# 页面定制

本文将介绍在 Book 模式下定制化页面以及 `extensions` 配置的高级用法

关于模板语法请参考 [模板引擎](../advance/template.md)。

## 自定义模板

通过 `extensions.template` 可定义文章使用的 HTML 模板。默认值为 `"templates/default.html"`，此处称之为默认模板。你可以基于默认模板进行修改、添加、删除，也可以完全重写一套自己的模板。

## HTML 模板中的变量

模板的核心是数据，数据的核心是变量，以下提供了在 Book 模式中注册的变量及其行为：

| 变量名 | 类型 | 说明 |
| --- | --- | --- |
| `body` | String | 当前页面正文，即 Markdown 转换为 HTML 后的结果 |
| `section` | Json | 当前页面在导航树中所处位置的结构化数据，通常用于渲染侧边栏、目录树 |
| `site_title` | String | 站点标题，对应配置中的 `title` 字段 |
| `site_description` | String | 站点简介，对应配置中的 `description` 字段 |
| `site_keywords` | String | 站点关键词，对应配置中的 `keywords` 字段 |
| `site_authors` | String | 作者列表，对应配置中的 `authors` 字段，多个作者以顿号拼接的逗号连接 |
| `site_language` | String | 站点主语言，对应配置中的 `language` 字段 |
| `favicon` | String | favicon 路径，对应配置中的 `favicon` 字段 |
| `logo` | String | 站点 Logo 路径，对应配置中的 `logo` 字段 |
| `repository` | String | 源码仓库地址，对应配置中的 `repository` 字段，未配置时为空String |
| `src` | String | 源目录路径，对应配置中的 `src` 字段 |
| `dest` | String | 输出目录路径，对应配置中的 `dest` 字段 |
| `base_url` | String | 站点基础 URL，对应配置中的 `base_url` 字段 |
| `build_time` | String | 本次构建发生的时间 |
| `version` | String | 当前 MoPress 的版本号 |
| `breadcrumb` | String | 当前页面的面包屑路径 |
| `current` | String | 当前页面自身的路径 |
| `prev` | Json? | 上一篇文章，包含 `title`、`location` 两个字段；不存在时为空字符串 |
| `next` | Json? | 下一篇文章，包含 `title`、`location` 两个字段；不存在时为空字符串 |

其中 `prev`、`next` 在模板中需要先判断是否存在再访问其字段，例如：

```html
$if(next)$
<a class="page-nav-btn next" href="$next.location$">
  <div class="page-nav-dir">Next →</div>
  <div class="page-nav-title">$next.title$</div>
</a>
$endif$
```

`prefix_chapters`、`suffix_chapters`、`numbered_chapters` 分别对应导航结构中的前言章节、后记章节、主体编号章节。

`prev`、`next`、`section` 具体结构如下：

```typescript
interface PrevAndNext {
  title: string;
  location: string;
}

interface Section {
  title: string;
  prefix_chapters: SectionItem[];
  numbered_chapters: SectionItem[];
  suffix_chapters: SectionItem[];
}

type SectionItem = SeparatorItem | PartTitleItem | LinkItem;

interface SeparatorItem {
  is_separator: true;
}

interface PartTitleItem {
  is_part_title: true;
  title: string;
}

interface LinkItem {
  is_link: true;
  title: string;
  location: string;
  source: string;
  depth: number;
  is_current: boolean;
  number?: string;
}
```

仅编号章节会在 `LinkItem` 中携带此字段，形如 `1`、`1.2`、`1.2.1`。

### 元数据字段的注入

一篇文章的元数据键值对，不管具体有哪些字段，都会被整体注入到该页面的模板变量中。元数据本身的键值是不固定的，自定义模板可以按需读取任意自定义字段。

默认模板对元数据中的 `title`、`description`、`keywords`、`authors`、`language` 这几个字段做了有效处理，部分字段行为是较于 `site_*` 变量优先选择，而另一部分字段行为是与 `site_*` 变量并并列处理。如：

```html
<html lang="$if(language)$$language$$else$$site_language$$endif$">

<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>$if(title)$$title$ - $site_title$$else$$site_title$$endif$</title>
  <link rel="icon" href="$favicon$" type="image/x-icon">
  <link rel="stylesheet" href="/styles/index.css">
  <meta name="description" content="$if(description)$$site_description$,$description$$else$$site_description$$endif$">
  <meta name="keywords" content="$if(keywords)$$site_keywords$,$keywords$$else$$site_keywords$$endif$">
  <meta name="authors" content="$if(authors)$$site_authors$,$authors$$else$$site_authors$$endif$">
</head>
```

## 基于默认模板自定义主题

通过有限地修改 `styles/index.css` 样式中的根变量达到自定义配色、字体、大小等需求。

当然，自行大改样式文件也可以，但不在此处的讨论范围。

## 自定义主页

主页的本质上是源目录 `/index.md` 渲染为 `/index.html`。在 MarkDown 中可自由地使用 CSS 与 HTML 定制化你的主页。

当然，若你想更自由一点，可直接在源目录重命名 `/index.md` 并新建 `/index.html`，在其中完全不受限制于既定文档书籍页面骨架。

> [!CAUTION]
> 应当强调的是，此处的 HTML 均不是模板环境而是普通的 HTML 文件，意味着模板变量、模板语法完全不可用。

不过，最重要的是应将 `/index.html` 添加到 `extensions.assets` 中，否则将不会被 MoPress 处理。

## 自定义 404 页面

同理，新建 `/404.md` 或 `/404.html` 即可。如本书的：

{{@ 404.md }}

## 插件

通过 `extensions.import-js` 或 `extensions.use-js` 可以引入 JavaScript 代码为页面添加各种功能、效果，如鼠标点击、整页粒子效果等。

通过 Web Components 与外部协议插件可以自定义更多的 MarkDown 语法及功能。
