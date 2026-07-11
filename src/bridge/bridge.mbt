// @block processor-error

///|
/// Error type describing why an external preprocessor/transformer command
/// failed while running through `run_markdown_preprocessors` or
/// `run_markdown_transformers`.
pub suberror ProcessorError {
  NonZeroExit(command~ : String, exit_code~ : Int, stderr~ : String)
  StderrReported(command~ : String, message~ : String)
  InvalidStdout(command~ : String, raw~ : String, reason~ : String)
} derive(Debug, Eq)
// @end

///|
pub impl Show for ProcessorError with fn to_string(self : ProcessorError) -> String {
  match self {
    NonZeroExit(command~, exit_code~, stderr~) =>
      "ProcessorError: Command \{command} failed with exit code \{exit_code} and stderr: \{stderr}"
    StderrReported(command~, message~) =>
      "ProcessorError: Command \{command} reported stderr: \{message}"
    InvalidStdout(command~, raw~, reason~) =>
      "ProcessorError: Command \{command} produced invalid stdout: \{raw} (reason: \{reason})"
  }
}

///|
struct MarkdownRequest {
  config : @config.BookConfig
  type_ : String
  target : String
  data : @markdown.Markdown
} derive(ToJson(fields(type_(rename="type"))))

///|
struct MarkdownResponse {
  data : @markdown.Markdown
} derive(FromJson)

///|
struct TextRequest {
  config : @config.BookConfig
  type_ : String
  data : String
  target : String
} derive(ToJson(fields(type_(rename="type"))))

///|
struct TextResponse {
  data : String
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
/// { "config": <BookConfig>, "type": "markdown-ast", "data": <Markdown AST>, "target": <string> }
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
  target : String,
) -> @markdown.Markdown {
  let mut current = data
  for script in config.extensions.transformers {
    current = run_single_markdown_transformer(config, current, target, script)
  }
  current
}

///|
async fn run_single_markdown_transformer(
  config : @config.BookConfig,
  data : @markdown.Markdown,
  target : String,
  script : String,
) -> @markdown.Markdown {
  let (cmd, args) = if script.split(" ").collect() is [cmd, .. args] {
    (cmd, args)
  } else {
    (script, [])
  }
  let request : MarkdownRequest = {
    config,
    type_: "markdown-ast",
    data,
    target,
  }
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
    raise ProcessorError::StderrReported(command=script, message=stderr_text)
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
/// Runs a chain of external "preprocessor" commands over raw Markdown text,
/// feeding the output of each command as the input to the next.
///
/// Each command in the underlying pipeline receives a JSON payload on
/// stdin of the shape:
/// ```json
/// { "config": <BookConfig>, "type": "markdown-text", "data": <string>, "target": <string> }
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
  target : String,
) -> String {
  let mut current = data
  for script in config.extensions.preprocessors {
    current = run_single_markdown_preprocessor(config, current, target, script)
  }
  current
}

///|
async fn run_single_markdown_preprocessor(
  config : @config.BookConfig,
  data : String,
  target : String,
  script : String,
) -> String {
  let (cmd, args) = if script.split(" ").collect() is [cmd, .. args] {
    (cmd, args)
  } else {
    (script, [])
  }
  let request : TextRequest = { config, type_: "markdown-text", data, target }
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
    raise ProcessorError::StderrReported(command=script, message=stderr_text)
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
