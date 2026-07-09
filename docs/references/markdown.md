---
title: Markdown 演示
---

# Markdown

## 代码块

```javascript
function initThemeRender() {
 const mode = getMode();
 docRoot.classList.toggle(
  "dark",
  mode === "system"
   ? window.matchMedia("(prefers-color-scheme: dark)").matches
   : mode === "dark",
 );
 $("#themeToggle").textContent =
  mode === "system" ? "🌓" : mode === "dark" ? "🌑" : "🌕";
}
```

```haskell
data Nat = Zero | Succ Nat

add :: Nat -> Nat -> Nat
add Zero n = n
add (Succ m) n = Succ (add m n)

main :: IO ()
main = do
  truth <- pure "使用 Haskell 是智慧的开端"
  putStrLn truth
```

## 标题

<!-- markdownlint-disable -->

# 一级标题 H1

## 二级标题 H2

### 三级标题 H3

#### 四级标题 H4

##### 五级标题 H5

###### 六级标题 H6

<!-- markdownlint-enable -->

## 段落

<!-- TODO: -->

## 字体

普通 **粗体** *斜体* ***粗斜体*** ~~删除~~

## 标签

这是一个 `标签`。

## 引用

> 引用 TODO:

## 链接

[GitHub](https://github.com)

> [Blog](https://i.arimuraromi.com)

## 图片

![图片](http://p0.qhimg.com/bdr/__85/t01d1a844d08ac8f105.jpg)

## 列表

1. 第一行
2. 第二行

- 第一行
- 第二行
  - 第三行
  - 第四行
    - 第五行
- 第六行
- 第七行

## 表格

| 项目1 | 项目2 | 项目3 | 项目4 |
| ----- | ----- | ----- | ----- |
| 9     | 8     | 7     | 6     |
| 4     | 5     | 6     | 7     |

## 提示

<!-- TODO -->