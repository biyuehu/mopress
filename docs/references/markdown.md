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

初夏，天空一放晴，雨水就被什么东西吸干了似的。阳光明媚，人世间变得空荡而明亮了。窗下的草坪上飘浮着一缕缕清新的游丝，不知不觉间太阳已经西沉。我坐在你的膝上，眺望着西边的杂木林，仿佛刚刚划出了清晰的线条。草坪一端，忽地抹上了色彩，可能是夕阳映照在游丝上吧。母亲漫步其间。

在这个世界上，再没有什么比轮回转世的教诲交织出的童话故事般的梦境更丰富多彩的了。这是人类创造的最美的爱的抒情诗。

灵魂这个词，难道不是天地万物流动力量的形容词吗？

灵魂不灭这种想法，可能是对生者的生命的执着和对死者的爱的依恋，因此相信那个世界的灵魂也具有那个人在这个世界的人格，恐怕这是人情的一种悲伤的虚幻吧。但是，人不仅将自己生前的姿态，甚至将这个世界的爱与憎都带到那个世界去。就是生死相隔，父子还是父子，兄弟还是兄弟。听说西方的亡魂说阴间基本上也像人世的社会，这种只尊重人对生的执着，反而使我觉得孤寂了。

## 字体

普通 **粗体** *斜体* ***粗斜体*** ~~删除~~

## 标签

这是一个 `标签`。

## 引用

> 无能幸福还是不幸，首先都要活着才行。——濑户口廉也

## 链接

[Codeberg](https://codeberg.org)

> [Blog](https://i.arimuraromi.com)

## 图片

![图片](https://img0.huoshen80.top/i/2026/07/11/6a51c361a0307.png)

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

> [!TIP]
> 提示信息

---

> [!WARNING]
> 警告信息

---

> [!CAUTION]
> 注意信息

---

> [!NOTE]
> 注意信息

---

> [!IMPORTANT]
> 重要信息

## Bilibili 视频

```markdown
<bili-video bv="BV1SRcCztERB"></bili-video>
```

<bili-video bv="BV1SRcCztERB"></bili-video>
