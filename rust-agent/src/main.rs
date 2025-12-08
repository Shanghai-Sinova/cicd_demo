use std::io::{Read, Write};
use std::net::TcpListener;
use std::thread;

fn main() -> std::io::Result<()> {
    let listener = TcpListener::bind("0.0.0.0:5002")?;
    println!("Rust agent listening on 0.0.0.0:5002");

    for stream in listener.incoming() {
        match stream {
            Ok(mut stream) => {
                thread::spawn(move || {
                    // 读取但忽略请求内容
                    let mut buffer = [0u8; 512];
                    let _ = stream.read(&mut buffer);
                    // 简单返回 200 OK
                    let response = b"HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: 17\r\n\r\n{\"status\":\"ok\"}";
                    let _ = stream.write_all(response);
                    let _ = stream.flush();
                });
            }
            Err(e) => eprintln!("Connection failed: {e}"),
        }
    }
    Ok(())
}
