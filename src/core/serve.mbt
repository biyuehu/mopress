///|
let default_serve_host : String = "127.0.0.1"

///|
let default_serve_port : Int = 8000

///|
async fn serve_static_dir(
  root : String,
  host? : String = default_serve_host,
  port? : Int = default_serve_port,
) -> Unit {
  let addr = @socket.Addr::parse("\{host}:\{port}")
  let server = @http.Server(addr, reuse_addr=true)
  println("Serving \{root} at http://\{host}:\{server.addr.port()}/")
  server.run_forever(allow_failure=true) <| ((request, _body, conn) => {
    serve_static_request(root, request, conn)
  })
}

///|
async fn serve_static_request(
  root : String,
  request : @http.Request,
  conn : @http.ServerConnection,
) -> Unit {
  match request.meth {
    Get => serve_path(root, request.path, false, conn)
    Head => serve_path(root, request.path, true, conn)
    _ => send_text(conn, 405, "Method Not Allowed", "Method Not Allowed", true)
  }
}

///|
async fn serve_path(
  root : String,
  request_path : String,
  head_only : Bool,
  conn : @http.ServerConnection,
) -> Unit {
  match request_target_to_relative_path(request_path) {
    None => send_text(conn, 403, "Forbidden", "Forbidden", head_only)
    Some(relative_path) => {
      let full_path = @path.Path(root).join(relative_path).to_string()
      if !@afs.exists(full_path) {
        send_text(conn, 404, "Not Found", "Not Found", head_only)
      } else {
        match @afs.kind(full_path) {
          Directory => serve_directory_index(full_path, head_only, conn)
          Regular => serve_file(full_path, head_only, conn)
          _ => send_text(conn, 404, "Not Found", "Not Found", head_only)
        }
      }
    }
  }
}

///|
async fn serve_directory_index(
  dir_path : String,
  head_only : Bool,
  conn : @http.ServerConnection,
) -> Unit {
  let index_path = @path.Path(dir_path).join("index.html").to_string()
  if @afs.exists(index_path) && @afs.kind(index_path) is Regular {
    serve_file(index_path, head_only, conn)
  } else {
    send_text(conn, 404, "Not Found", "Not Found", head_only)
  }
}

///|
async fn serve_file(
  file_path : String,
  head_only : Bool,
  conn : @http.ServerConnection,
) -> Unit {
  let file = @afs.open(file_path, mode=ReadOnly)
  defer file.close()
  conn.send_response(200, "OK", extra_headers={
    "Content-Type": content_type(file_path),
    "Content-Length": file.size().to_string(),
    "Cache-Control": "no-cache",
  })
  if !head_only {
    conn.write_reader(file)
  }
  conn.end_response()
}

///|
async fn send_text(
  conn : @http.ServerConnection,
  status : Int,
  reason : String,
  body : String,
  head_only : Bool,
) -> Unit {
  conn.send_response(status, reason, extra_headers={
    "Content-Type": "text/plain; charset=utf-8",
    "Content-Length": body.length().to_string(),
    "Cache-Control": "no-cache",
  })
  if !head_only {
    conn.write_string(body)
  }
  conn.end_response()
}

///|
fn request_target_to_relative_path(target : String) -> String? {
  let path = strip_query_and_fragment(target)
  if path.contains("\\") || path.contains("\u0000") {
    None
  } else {
    let parts : Array[String] = []
    for part in path.split("/") {
      if part == "" || part == "." {
        continue
      } else if part == ".." {
        return None
      } else {
        parts.push(percent_decode_unreserved(part.to_owned()))
      }
    }
    if parts.length() == 0 {
      Some("index.html")
    } else {
      Some(parts.join(@path.sep.to_string()))
    }
  }
}

///|
fn strip_query_and_fragment(target : String) -> String {
  let query = target.find("?")
  let fragment = target.find("#")
  let end = match (query, fragment) {
    (Some(q), Some(f)) => if q < f { q } else { f }
    (Some(q), None) => q
    (None, Some(f)) => f
    (None, None) => target.length()
  }
  Show::to_string(target[0:end])
}

///|
fn percent_decode_unreserved(part : String) -> String {
  let out = StringBuilder::new()
  let mut index = 0
  while index < part.length() {
    if part[index] == '%' && index + 2 < part.length() {
      let decoded = decode_percent_byte(part[index + 1], part[index + 2])
      match decoded {
        Some(ch) =>
          if is_unreserved_url_unit(ch) {
            out.write_string(Int::unsafe_to_char(ch.to_int()).to_string())
            index = index + 3
            continue
          } else {
            out.write_string(Show::to_string(part[index:index + 1]))
          }
        None => out.write_string(Show::to_string(part[index:index + 1]))
      }
    } else {
      out.write_string(Show::to_string(part[index:index + 1]))
    }
    index = index + 1
  }
  out.to_string()
}

///|
fn decode_percent_byte(high : UInt16, low : UInt16) -> UInt16? {
  match (hex_value(high), hex_value(low)) {
    (Some(h), Some(l)) => Some((h * 16 + l).to_uint16())
    _ => None
  }
}

///|
fn hex_value(ch : UInt16) -> Int? {
  if ch >= '0' && ch <= '9' {
    Some(ch.to_int() - '0'.to_int())
  } else if ch >= 'a' && ch <= 'f' {
    Some(ch.to_int() - 'a'.to_int() + 10)
  } else if ch >= 'A' && ch <= 'F' {
    Some(ch.to_int() - 'A'.to_int() + 10)
  } else {
    None
  }
}

///|
fn is_unreserved_url_unit(ch : UInt16) -> Bool {
  (ch >= 'A' && ch <= 'Z') ||
  (ch >= 'a' && ch <= 'z') ||
  (ch >= '0' && ch <= '9') ||
  ch == '-' ||
  ch == '.' ||
  ch == '_' ||
  ch == '~'
}

///|
fn content_type(path : String) -> String {
  match @path.Path(path).extname().to_owned().to_lower() {
    ".html" | ".htm" => "text/html; charset=utf-8"
    ".css" => "text/css; charset=utf-8"
    ".js" | ".mjs" => "text/javascript; charset=utf-8"
    ".json" => "application/json; charset=utf-8"
    ".txt" | ".md" => "text/plain; charset=utf-8"
    ".xml" => "application/xml; charset=utf-8"
    ".svg" => "image/svg+xml"
    ".png" => "image/png"
    ".jpg" | ".jpeg" => "image/jpeg"
    ".gif" => "image/gif"
    ".webp" => "image/webp"
    ".ico" => "image/x-icon"
    ".wasm" => "application/wasm"
    ".pdf" => "application/pdf"
    ".woff" => "font/woff"
    ".woff2" => "font/woff2"
    _ => "application/octet-stream"
  }
}
