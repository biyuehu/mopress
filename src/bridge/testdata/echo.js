const req = JSON.parse(await Bun.stdin.text())
const mode = Bun.argv[2] ?? "echo"

const emit = (obj) => process.stdout.write(JSON.stringify(obj))

switch (mode) {
  case "echo":
    if (req.type === "markdown-text") emit({ data: req.data + " [echo]" })
    else emit({ data: req.data })
    break
  case "empty":
    break
  case "fail":
    process.stderr.write("intentional failure\n")
    process.exit(1)
  case "stderr":
    process.stderr.write("boom\n")
    break
  case "badjson":
    process.stdout.write("this is not json")
    break
  case "wrongshape":
    emit({ nope: true })
    break
  case "inspect-text":
    // Encode the observed protocol fields into `data` so the test can
    // assert on them directly.
    emit({
      data: JSON.stringify({
        type: req.type,
        target: req.target,
        hasConfig: typeof req.config === "object" && req.config !== null,
        args: Bun.argv.slice(3),
      }),
    })
    break
  case "check-ast":
    // Return the input AST only if the protocol fields match what the
    // transformer path is documented to send; otherwise return an empty
    // AST so the test fails.
    if (req.type !== "markdown-ast" || req.target !== Bun.argv[3]) {
      emit({ data: [] })
    } else {
      emit({ data: req.data })
    }
    break
}