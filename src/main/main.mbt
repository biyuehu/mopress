///|
async fn main {
  command_handler() catch {
    e => debug(e)
  }
}
