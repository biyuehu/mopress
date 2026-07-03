///|
/// 单次 transformer 调用的通用错误类型，
/// 覆盖了「命令本身跑不起来 / 非零退出码 / stderr 有内容 / stdout 不是合法 JSON」这几种情况。
pub suberror ProcessorError {
  NonZeroExit(command~ : String, exit_code~ : Int, stderr~ : String)
  StderrReported(command~ : String, message~ : String)
  InvalidStdout(command~ : String, raw~ : String, reason~ : String)
} derive(Debug, Eq)

///|
/// stdin 协议：传给子进程的请求体
struct MarkdownRequest {
  config : @config.BookConfig
  type_ : String
  data : @markdown.Markdown
} derive(ToJson)

///|
/// stdout 协议：从子进程读回来的正常响应体
struct MarkdownResponse {
  data : @markdown.Markdown
} derive(FromJson)

///|
/// stderr 协议：从子进程读回来的错误响应体
struct StderrPayload {
  error : String
} derive(FromJson)

///|
/// 执行一系列 markdown-ast transformer 脚本，依次对 Markdown AST 做链式变换。
///
/// `config` 会原样传给每一个脚本，作为上下文信息。
/// `data` 是初始的 Markdown AST。
/// `scripts` 是要依次执行的命令数组，每个元素是完整的命令行参数列表
/// （例如 `["bun", "scripts/my_transformer.ts"]`），
/// 数组里每一条命令依次执行，前一条的输出会作为后一条的输入。
///
/// 如果某个脚本的 stdout 为空字符串，代表该脚本选择不处理这份数据，
/// 数据会原样传递给下一个脚本。
///
/// 如果某个脚本写了 stderr，或者退出码非零，或者 stdout 不是合法的 JSON，
/// 会立即中断并 raise 对应的 `ProcessorError`。
pub async fn run_markdown_transformers(
  config : @config.BookConfig,
  data : @markdown.Markdown,
) -> @markdown.Markdown {
  let mut current = data
  for script in config.extension.transformers {
    current = run_single_markdown_transformer(config, current, script)
  }
  current
}

///|
/// 执行单个 markdown-ast transformer 命令。
/// `script` 是一整条 shell 命令字符串，内部会按空格切分成 cmd + args。
/// 如果你的命令路径本身带空格，建议改用下面的 `run_markdown_transformers_argv`
/// 版本，直接传 `Array[Array[String]]` 避免切分歧义。
async fn run_single_markdown_transformer(
  config : @config.BookConfig,
  data : @markdown.Markdown,
  script : String,
) -> @markdown.Markdown {
  let (cmd, args) = if script.split(" ").collect() is [cmd, .. args] {
    (cmd, args)
  } else {
    (script, [])
  }
  let request = { config, type_: "markdown-ast", data }
  let input_json = request.to_json().stringify()
  let (stdin_r, stdin_w) = @process.write_to_process()
  let (stdout_r, stdout_w) = @process.read_from_process()
  let (stderr_r, stderr_w) = @process.read_from_process()
  let mut stdout_text = ""
  let mut stderr_text = ""
  let mut exit_code = -1
  @async.with_task_group(group => {
    group.spawn_bg(() => {
      stdin_w.write(input_json)
      stdin_w.close()
    })
    group.spawn_bg(() => {
      let out = stdout_r.read_all()
      stdout_text = out.text()
      stdout_r.close()
    })
    group.spawn_bg(() => {
      let err = stderr_r.read_all()
      stderr_text = err.text()
      stderr_r.close()
    })
    exit_code = @process.run(
      cmd,
      args.map(Show::to_string),
      stdin=stdin_r,
      stdout=stdout_w,
      stderr=stderr_w,
    )
  })

  if exit_code != 0 {
    raise ProcessorError::NonZeroExit(
      command=script,
      exit_code~,
      stderr=stderr_text,
    )
  }

  if !stderr_text.trim(chars=" \n\r\t").is_empty() {
    raise ProcessorError::StderrReported(
      command=script,
      message=try {
        let stderr_payload : StderrPayload = @json.from_json(
          @json.parse(stderr_text),
        )
        stderr_payload.error
      } catch {
        _ => stderr_text
      },
    )
  }

  if stdout_text.trim(chars=" \n\r\t").is_empty() {
    return data
  }

  try {
    let json = @json.parse(stdout_text)
    let response : MarkdownResponse = @json.from_json(json)
    response.data
  } catch {
    err =>
      raise ProcessorError::InvalidStdout(
        command=script,
        raw=stdout_text,
        reason=err.to_string(),
      )
  }
}

///|
priv struct TextResponse {
  data : String
} derive(FromJson)

///|
fn build_text_request_json(
  config : @config.BookConfig,
  data : String,
) -> String {
  let obj : Json = {
    "config": config.to_json(),
    "type": "markdown-text",
    "data": data.to_json(),
  }
  obj.stringify()
}

///|
pub async fn run_markdown_preprocessors(
  config : @config.BookConfig,
  data : String,
) -> String {
  let mut current = data
  for script in config.extension.preprocessors {
    current = run_single_markdown_preprocessor(config, current, script)
  }
  current
}

///|
async fn run_single_markdown_preprocessor(
  config : @config.BookConfig,
  data : String,
  script : String,
) -> String {
  let (cmd, args) = if script.split(" ").collect() is [cmd, .. args] {
    (cmd, args)
  } else {
    (script, [])
  }
  let input_json = build_text_request_json(config, data)
  let (stdin_r, stdin_w) = @process.write_to_process()
  let (stdout_r, stdout_w) = @process.read_from_process()
  let (stderr_r, stderr_w) = @process.read_from_process()
  let mut stdout_text = ""
  let mut stderr_text = ""
  let mut exit_code = -1

  @async.with_task_group(group => {
    group.spawn_bg(() => {
      stdin_w.write(input_json)
      stdin_w.close()
    })
    group.spawn_bg(() => {
      let out = stdout_r.read_all()
      stdout_text = out.text()
      stdout_r.close()
    })
    group.spawn_bg(() => {
      let err = stderr_r.read_all()
      stderr_text = err.text()
      stderr_r.close()
    })
    exit_code = @process.run(
      cmd,
      args.map(Show::to_string),
      stdin=stdin_r,
      stdout=stdout_w,
      stderr=stderr_w,
    )
  })

  if exit_code != 0 {
    raise ProcessorError::NonZeroExit(
      command=script,
      exit_code~,
      stderr=stderr_text,
    )
  }

  if !stderr_text.trim(chars=" \n\r\t").is_empty() {
    let message = try {
      let json : Json = @json.parse(stderr_text)
      let payload : StderrPayload = @json.from_json(json)
      payload.error
    } catch {
      _ => stderr_text
    }
    raise ProcessorError::StderrReported(command=script, message~)
  }

  if stdout_text.trim(chars=" \n\r\t").is_empty() {
    return data
  }

  try {
    let json : Json = @json.parse(stdout_text)
    let response : TextResponse = @json.from_json(json)
    response.data
  } catch {
    err =>
      raise ProcessorError::InvalidStdout(
        command=script,
        raw=stdout_text,
        reason=err.to_string(),
      )
  }
}
