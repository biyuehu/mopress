---
title: Glob 模式
---

# Glob 模式

Glob 模式用于按路径规则匹配文件，在 MoPress 中出现在两处：Book 模式扩展配置中的静态资源字段，以及 Site 模式的 `Rule::Glob`、`Rule::Guard`。本页是这套语法的独立参考。

## 完整函数签名

```moonbit
pub fn glob_match(pattern : String, path : String) -> Bool

pub fn glob_match_with(pattern : String, path : String, f : (String) -> Bool) -> Bool

pub fn scan_files(root : String, pattern : String) -> Array[String] raise @fs.IOError

pub fn scan_files_with(
  root : String,
  pattern : String,
  f : (String) -> Bool,
) -> Array[String] raise @fs.IOError
```

`glob_match` 判断给定路径是否匹配给定的 glob 模式，返回布尔值。`glob_match_with` 在此基础上追加一层自定义判定：`f` 会收到与 `glob_match` 相同的候选完整相对路径，其返回值决定该路径是否被视为匹配，这正是 `Rule::Guard` 底层依赖的匹配方式。`scan_files` 递归扫描 `root` 目录，返回其中所有匹配 `pattern` 的文件路径数组；`scan_files_with` 是它的自定义判定版本，`f` 同样收到每个候选文件相对于 `root` 的完整路径。两个扫描函数都可能因为目录无法读取（不存在、无权限等）而抛出 `@fs.IOError`。

## 支持的通配符

| 通配符 | 含义 |
| --- | --- |
| `*` | 匹配路径中单个片段内的任意字符序列，不跨越"/" |
| `?` | 匹配任意单个字符 |
| `**` | 匹配任意深度的路径片段，可以跨越"/" |

除以上三种以外，不支持花括号扩展（如"{a,b}"）、字符类（如"[abc]"）等其他 glob 语法扩展。

## 示例

| 模式 | 说明 |
| --- | --- |
| `*.md` | 匹配当前目录下所有以".md"结尾的文件 |
| `assets/*` | 匹配"assets"目录下的所有直接子项，不含更深层级 |
| `./**/*.js` | 匹配任意深度目录下的所有".js"文件 |
| `src/?.md` | 匹配源目录下文件名恰好为单个字符加".md"的文件，例如"src/a.md" |

## 在 Book 模式中的使用

扩展配置中的静态资源字段接受一组 glob 模式：

```moonbit
pub(all) struct ExtensionConfig {
  template : String
  assets : Array[String]
  inject_head : Array[String]
  inject_body : Array[String]
  use_js : Array[String]
  use_css : Array[String]
  import_css : Array[String]
  import_js : Array[String]
  preprocessors : Array[String]
  transformers : Array[String]
} derive(Eq, ToJson, @debug.Debug)
```

`assets` 中的每一项都会被当作 glob 模式，匹配到的文件会被原样复制到输出目录，不经过任何 Markdown 处理，具体请阅读 [扩展配置](../book-mode/extensions.md)。

## 在 Site 模式中的使用

```moonbit
pub(all) enum Rule {
  Glob(String, Handler)
  Guard(String, (String) -> Bool, Handler)
}
```

`Rule::Glob` 的第一个参数是一个 glob 模式，用于匹配文件；`Rule::Guard` 在此基础上追加一个自定义判定函数，判定函数收到的路径与本页 `glob_match_with` 描述的一致，是相对于源目录的完整路径，具体请阅读 [Rules, Handlers 和 Steps](../site-mode/rules-handlers-steps.md)。
