from fastapi import FastAPI
from pydantic import BaseModel
from langchain_core.runnables import RunnableLambda

# FastMCP integrates Model Context Protocol endpoints; kept optional
try:
    from fastmcp import FastMCP
except ImportError:  # pragma: no cover - allows app to start without fastmcp
    FastMCP = None

app = FastAPI(title="Hello LangChain Agent", version="0.1.0")

# Simple LangChain runnable acting as an agent
agent = RunnableLambda(lambda payload: f"Hello, {payload.get('name', 'world')}! — LangChain@1.1.0")

class HelloRequest(BaseModel):
    name: str = "world"

@app.post("/api/hello")
async def hello(req: HelloRequest):
    return {"message": agent.invoke(req.model_dump())}

# Optional MCP surface for tool calling clients
if FastMCP:
    mcp = FastMCP("hello-mcp")

    @mcp.tool()
    def greet(name: str) -> str:
        return agent.invoke({"name": name})

    app.mount("/mcp", mcp.streamable_http_app())


@app.get("/health")
async def health():
    return {"status": "ok"}


if __name__ == "__main__":  # local debug
    import uvicorn

    uvicorn.run("app.main:app", host="0.0.0.0", port=5000, reload=True)
