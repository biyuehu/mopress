///|
// pub(all) enum SiteOption {
//   One(String, (String) -> Unit)
//   All(String, (Array[String]) -> Unit)
// }

// // 一个Rule就是：匹配模式 + 如何处理匹配到的文件
// struct Rule {
//   pattern : Glob          // 通配符匹配
//   compiler : Compiler     // 处理函数
// }

// // Compiler是核心抽象
// type Compiler = FileContext -> Output raise CompileError

// struct FileContext {
//   path : Path
//   content : String
//   metadata : Map[String, Json]  // front matter
// }

// enum Output {
//   Page(path~ : Path, html~ : String)   // 输出一个HTML页面
//   Asset(path~ : Path, data~ : Bytes)   // 原样复制资源文件
//   Nothing                               // 不输出
// }
