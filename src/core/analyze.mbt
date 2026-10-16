///|
/// A trace of a single step during item processing.
pub(all) struct StepTrace {
  name : String
  duration_ms : Int64
} derive(Eq, Debug)

///|
pub extend StepTrace with Eq::{not_equal, equal}

///|
pub extend StepTrace with @debug.Debug::{to_repr}

///|
/// Performance report for a single built file/page.
pub(all) struct PageAnalysis {
  path : String
  size_bytes : Int32
  total_duration_ms : Int64
  template_renders : Int32
  slowest_step : String
  slowest_step_ms : Int64
  step_traces : Array[StepTrace]
} derive(Eq, Debug)

///|
pub extend PageAnalysis with Eq::{not_equal, equal}

///|
pub extend PageAnalysis with @debug.Debug::{to_repr}

///|
/// Summary of a step across all processed pages.
pub(all) struct StepSummary {
  name : String
  total_ms : Int64
  call_count : Int32
  max_ms : Int64
} derive(Eq, Debug)

///|
pub extend StepSummary with Eq::{not_equal, equal}

///|
pub extend StepSummary with @debug.Debug::{to_repr}

///|
/// Overall build analysis report.
pub(all) struct BuildAnalysisReport {
  pages : Array[PageAnalysis]
  steps : Array[StepSummary]
  total_pages : Int32
  total_size_bytes : Int32
  total_build_ms : Int64
} derive(Eq, Debug)

///|
pub extend BuildAnalysisReport with Eq::{not_equal, equal}

///|
pub extend BuildAnalysisReport with @debug.Debug::{to_repr}

///|
pub fn StepTrace::to_json(self : StepTrace) -> Json {
  {
    "name": Json::string(self.name),
    "duration_ms": Json::number(self.duration_ms.to_double()),
  }
}

///|
pub impl ToJson for StepTrace with fn to_json(self : StepTrace) -> Json {
  self.to_json()
}

///|
pub fn PageAnalysis::to_json(self : PageAnalysis) -> Json {
  {
    "path": Json::string(self.path),
    "size_bytes": Json::number(self.size_bytes.to_double()),
    "total_duration_ms": Json::number(self.total_duration_ms.to_double()),
    "template_renders": Json::number(self.template_renders.to_double()),
    "slowest_step": Json::string(self.slowest_step),
    "slowest_step_ms": Json::number(self.slowest_step_ms.to_double()),
    "step_traces": Json::array(self.step_traces.map(t => t.to_json())),
  }
}

///|
pub impl ToJson for PageAnalysis with fn to_json(self : PageAnalysis) -> Json {
  self.to_json()
}

///|
pub fn StepSummary::to_json(self : StepSummary) -> Json {
  {
    "name": Json::string(self.name),
    "total_ms": Json::number(self.total_ms.to_double()),
    "call_count": Json::number(self.call_count.to_double()),
    "max_ms": Json::number(self.max_ms.to_double()),
  }
}

///|
pub impl ToJson for StepSummary with fn to_json(self : StepSummary) -> Json {
  self.to_json()
}

///|
pub fn BuildAnalysisReport::to_json(self : BuildAnalysisReport) -> Json {
  {
    "pages": Json::array(self.pages.map(p => p.to_json())),
    "steps": Json::array(self.steps.map(s => s.to_json())),
    "total_pages": Json::number(self.total_pages.to_double()),
    "total_size_bytes": Json::number(self.total_size_bytes.to_double()),
    "total_build_ms": Json::number(self.total_build_ms.to_double()),
  }
}

///|
pub impl ToJson for BuildAnalysisReport with fn to_json(
  self : BuildAnalysisReport,
) -> Json {
  self.to_json()
}

///|
let current_page_traces : Ref[Array[StepTrace]?] = Ref(None)

///|
pub async fn[T] with_page_trace(
  traces : Array[StepTrace],
  f : async () -> T,
) -> T {
  let prev = current_page_traces.val
  current_page_traces.val = Some(traces)
  defer {
    current_page_traces.val = prev
  }
  f()
}

///|
pub fn record_step_trace(name : String, duration_ms : Int64) -> Unit {
  match current_page_traces.val {
    Some(traces) => traces.push({ name, duration_ms, })
    None => ()
  }
}

///|
/// Formats and prints a human-readable performance analysis report.
pub fn print_analysis_report(report : BuildAnalysisReport) -> Unit {
  println("")
  @c.chalk()
  .modifier(Bold)
  .color(Cyan)
  .render(
    "============================= Build Analysis =============================",
  )
  |> println

  println("")
  @c.chalk()
  .modifier(Bold)
  .render("📊 Step Performance Breakdown (Steps sorted by total time):")
  |> println
  println(
    "  ---------------------------------------------------------------------------------",
  )
  println(
    "  Step Name                        Total Time   Avg / Page      Max   Calls",
  )
  println(
    "  ---------------------------------------------------------------------------------",
  )

  let sorted_steps = report.steps.copy()
  sorted_steps.sort_by((a, b) => b.total_ms.compare(a.total_ms))
  for s in sorted_steps {
    let avg = if s.call_count > 0 {
      s.total_ms.to_double() / s.call_count.to_double()
    } else {
      0.0
    }
    let name_padded = pad_right(s.name, 30)
    let total_str = pad_left("\{s.total_ms} ms", 12)
    let avg_str = pad_left("\{format_one_decimal(avg)} ms", 12)
    let max_str = pad_left("\{s.max_ms} ms", 8)
    let calls_str = pad_left("\{s.call_count}", 7)
    println("  \{name_padded} \{total_str} \{avg_str} \{max_str} \{calls_str}")
  }

  println("")
  @c.chalk()
  .modifier(Bold)
  .render("📄 Page Performance (Top pages sorted by elapsed time):")
  |> println
  println(
    "  ---------------------------------------------------------------------------------",
  )
  println(
    "  Page Path                           Time        Size   Tpl   Slowest Step",
  )
  println(
    "  ---------------------------------------------------------------------------------",
  )

  let sorted_pages = report.pages.copy()
  sorted_pages.sort_by((a, b) => {
    b.total_duration_ms.compare(a.total_duration_ms)
  })
  for page in sorted_pages {
    let path_padded = pad_right(truncate_path(page.path, 33), 33)
    let time_str = pad_left("\{page.total_duration_ms} ms", 9)
    let size_str = pad_left(format_size(page.size_bytes), 11)
    let tpl_str = pad_left("\{page.template_renders}", 5)
    let slowest = if page.slowest_step.is_empty() {
      "-"
    } else {
      "\{page.slowest_step} (\{page.slowest_step_ms}ms)"
    }
    println("  \{path_padded} \{time_str} \{size_str} \{tpl_str}   \{slowest}")
  }

  println("")
  @c.chalk().modifier(Bold).render("📦 Output & Totals:") |> println
  println("  - Total Pages Built: \{report.total_pages}")
  println(
    "  - Total Output Size: \{format_size(report.total_size_bytes)} (\{report.total_size_bytes} bytes)",
  )
  let avg_page_size = if report.total_pages > 0 {
    report.total_size_bytes / report.total_pages
  } else {
    0
  }
  println("  - Average Page Size: \{format_size(avg_page_size)}")
  println("  - Total Build Duration: \{report.total_build_ms} ms")
  @c.chalk()
  .modifier(Bold)
  .color(Cyan)
  .render(
    "==========================================================================",
  )
  |> println
  println("")
}

///|
fn format_size(bytes : Int32) -> String {
  if bytes < 1024 {
    "\{bytes} B"
  } else if bytes < 1024 * 1024 {
    let kb = bytes.to_double() / 1024.0
    "\{format_one_decimal(kb)} KB"
  } else {
    let mb = bytes.to_double() / (1024.0 * 1024.0)
    "\{format_one_decimal(mb)} MB"
  }
}

///|
fn format_one_decimal(val : Double) -> String {
  let rounded = (val * 10.0 + 0.5).to_int()
  let integer = rounded / 10
  let decimal = rounded % 10
  "\{integer}.\{decimal}"
}

///|
fn pad_right(s : String, width : Int32) -> String {
  if s.length() >= width {
    s
  } else {
    let mut out = s
    let pad = width - s.length()
    for _ in 0..<pad {
      out = out + " "
    }
    out
  }
}

///|
fn pad_left(s : String, width : Int32) -> String {
  if s.length() >= width {
    s
  } else {
    let mut out = ""
    let pad = width - s.length()
    for _ in 0..<pad {
      out = out + " "
    }
    out + s
  }
}

///|
fn truncate_path(s : String, max_len : Int32) -> String {
  if s.length() <= max_len {
    s
  } else {
    "..." + s[s.length() - max_len + 3:].to_owned()
  }
}
