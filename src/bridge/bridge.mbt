///|
/// Error type describing why an external preprocessor/transformer command
/// failed while running through `run_markdown_preprocessors` or
/// `run_markdown_transformers`.
pub suberror ProcessorError {
  NonZeroExit(command~ : String, exit_code~ : Int, stderr~ : String)
  StderrReported(command~ : String, message~ : String)
  InvalidStdout(command~ : String, raw~ : String, reason~ : String)
} derive(Debug, Eq)

///|
/// The JSON request payload sent on stdin to each markdown-ast/markdown-text
/// processor command. Not intended to be constructed or consumed outside of
/// `run_markdown_preprocessors` / `run_markdown_transformers`.
struct MarkdownRequest {
  config : @config.BookConfig
  type_ : String
  data : @markdown.Markdown
} derive(ToJson)

///|
/// The expected JSON response shape read from a processor command's
/// stdout on success, i.e. `{ "data": ... }`. Not intended to be
/// constructed or consumed outside of `run_markdown_preprocessors` /
/// `run_markdown_transformers`.
struct MarkdownResponse {
  data : @markdown.Markdown
} derive(FromJson)

///|
/// The expected JSON payload read from a processor command's stderr when
/// it reports an application-level error, i.e. `{ "error": string }`. Not
/// intended to be constructed or consumed outside of
/// `run_markdown_preprocessors` / `run_markdown_transformers`.
struct StderrPayload {
  error : String
} derive(FromJson)

///|
/// Runs a chain of external "transformer" commands over a Markdown AST,
/// feeding the output of each command as the input to the next.
///
/// This mirrors `run_markdown_preprocessors`, except the payload's `data`
/// field carries a Markdown AST (`Array[@markdown.Block]`) rather than raw
/// text, and the `type` field sent to each command is `"markdown-ast"`
/// instead of `"markdown-text"`.
///
/// Each command receives on stdin:
/// ```json
/// { "config": <BookConfig>, "type": "markdown-ast", "data": <Markdown AST> }
/// ```
/// and must write to stdout either:
/// - `{ "data": <Markdown AST> }` — the transformed AST, passed on to the
///   next command, or
/// - an empty stdout — meaning this command leaves the AST unchanged.
///
/// As with `run_markdown_preprocessors`, a non-zero exit code or any
/// stderr output from a command raises `ProcessorError` and aborts the
/// remaining chain.
pub async fn run_markdown_transformers(
  config : @config.BookConfig,
  data : @markdown.Markdown,
) -> @markdown.Markdown {
  let mut current = data
  for script in config.extensions.transformers {
    current = run_single_markdown_transformer(config, current, script)
  }
  current
}

///|
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
/// Runs a chain of external "preprocessor" commands over raw Markdown text,
/// feeding the output of each command as the input to the next.
///
/// Each command in the underlying pipeline receives a JSON payload on
/// stdin of the shape:
/// ```json
/// { "config": <BookConfig>, "type": "markdown-text", "data": <string> }
/// ```
/// and is expected to write one of the following to stdout:
/// - `{ "data": <string> }` — the transformed text, which becomes the input
///   to the next command in the chain.
/// - An empty stdout — signals that this command does not want to modify
///   the data; the current text is passed through unchanged to the next
///   command.
///
/// If a command exits with a non-zero status, or writes anything to
/// stderr, this function raises `ProcessorError` and the chain is aborted;
/// no further commands in the pipeline are executed.
///
/// `config` is forwarded verbatim to every command invocation and is not
/// itself modified by this function.
pub async fn run_markdown_preprocessors(
  config : @config.BookConfig,
  data : String,
) -> String {
  let mut current = data
  for script in config.extensions.preprocessors {
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
