FROM python:3.12-slim AS base

SHELL ["/bin/bash", "-c"]

ENV PIP_INDEX_URL=https://pypi.tuna.tsinghua.edu.cn/simple \
    PIP_NO_CACHE_DIR=1

# Install uv as fast installer
RUN pip install --no-cache-dir uv==0.9.15

WORKDIR /app
COPY pyproject.toml ./
# Use uv to lock+install; fall back to direct install if compile unavailable
RUN uv pip compile --quiet --refresh pyproject.toml -o requirements.txt \
    && uv pip install --system --no-cache-dir -r requirements.txt \
  || uv pip install --system --no-cache-dir fastapi==0.123.5 uvicorn==0.38.0 langchain==1.1.0 fastmcp==2.13.2 agentscope==1.0.8

COPY app ./app
EXPOSE 5000
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "5000"]
