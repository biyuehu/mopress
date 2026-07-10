///|
async fn main {
  command_handler() catch {
    e => {
      let error = e.to_string()
      if error == "Cancelled" {
        @c.chalk().color(Yellow).render("Command cancelled.") |> println
      } else {
        @c.chalk()
        .modifier(Bold)
        .color(Red)
        .render("Failed to execute command!")
        |> println
        @c.chalk().color(Red).render(e.to_string()) |> println
      }
    }
  }
}
