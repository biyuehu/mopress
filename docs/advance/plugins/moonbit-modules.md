---
title: MoonBit 模块
---

# MoonBit 模块插件

本节内容仅适用于 [Site 模式](../../site-mode/index.md)。Book 模式的配置文件无法引用 MoonBit 代码。

## 核心思路

在 Site 模式下，预处理器与转换器不一定需要是独立的外部进程，`use_preprocessor`、`use_transformer` 这两个 step 本身接受的就是一组普通的 MoonBit 函数：

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

如果反复在多个项目中编写类似的处理逻辑，最自然的做法就是把这些函数，或者更广义地说，任何符合 `(Item[T]) -> Item[R] raise` 形状的 step，不局限于预处理器、转换器，提取到一个独立的 MoonBit 模块、包中，作为库发布到 [mooncakes](https://mooncakes.io/)，供其他构建脚本通过 MoonBit 包管理器引入复用。

## 与外部程序插件的对比

| | MoonBit 模块 | 外部 stdin、stdout 程序 |
| --- | --- | --- |
| 适用范围 | 仅 Site 模式 | Book 模式与 Site 模式均可 |
| 编写语言 | 仅 MoonBit | 任意语言 |
| 执行方式 | 进程内函数调用 | 独立进程，通过 JSON 协议通信 |
| 性能开销 | 低，无序列化、无进程创建开销 | 相对较高，需要启动进程、序列化与反序列化数据 |
| 错误处理 | MoonBit 原生的 `raise`、错误类型 | 需要遵循 stdin、stdout 协议约定的退出码与标准错误格式 |

如果扩展逻辑只会在 Site 模式项目中使用、且愿意用 MoonBit 编写，选择打包为 MoonBit 模块通常能获得更好的性能与更直接的调试体验；如果需要复用已有的、用其他语言编写的处理逻辑，或者希望这份扩展逻辑同时能在 Book 模式中使用，外部程序仍然是更合适的选择。

## 编写与建议

本质上是一个普通的 MoonBit Lib，关于 MoonBit 项目初始化操作此处不作赘述，请参考 [MoonBit](https://www.moonbitlang.com/)。

一个设计良好的 step 组合库，通常会以独立函数的形式导出一个或多个 step，而不是强行捆绑成单一的巨大函数，这样使用者可以按需挑选、自由组合，与 MoPress 自身可组合的设计哲学保持一致。如：

```moonbit
///|
/// 将文本中的 :::note ... ::: 语法转换为对应的提示框 HTML。
pub fn use_callout_boxes(item : Item[String]) -> Item[String] raise {
  item.map_with_eff(text => /* 具体转换逻辑 */ text)
}
```

使用者只需要将其接入自己的管线：

```bash
moon add username/callouts
```

```moonbit
import {
  "username/callouts/lib" @callouts,
}
```

```moonbit
raw
|> @callouts.use_callout_boxes
|> @core.parse_markdown
|> /* 后续处理 */
```
