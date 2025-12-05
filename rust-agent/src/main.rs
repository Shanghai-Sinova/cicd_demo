use salvo::prelude::*;

#[handler]
async fn hello(req: &mut Request, res: &mut Response) {
    let name = req.query::<String>("name").unwrap_or_else(|| "world".into());
    res.render(Json(serde_json::json!({"message": format!("Hello, {}! — Salvo@0.82.0", name)})));
}

#[handler]
async fn health(_req: &mut Request, res: &mut Response) {
    res.render(Json(serde_json::json!({"status": "ok"})));
}

#[tokio::main]
async fn main() {
    let router = Router::new()
        .get(health)
        .push(Router::with_path("api/hello").get(hello));

    Server::new(TcpListener::bind("0.0.0.0:5002"))
        .serve(router)
        .await;
}
