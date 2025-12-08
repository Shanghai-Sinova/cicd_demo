# GitLab CI 本地快速搭建

本地通过 Docker Compose 启动 GitLab CE + GitLab Runner，并使用仓库内的 `.gitlab-ci.yml` 复刻原有 GitHub Actions 流程。

## 前置要求
- Docker Desktop / Docker Engine + Compose Plugin
- 端口可用：8929 (Web)、2222 (SSH)。

## 启动 GitLab 与 Runner
1. 复制环境变量模板并按需修改密码/URL/凭据：
   ```bash
   cp .env.gitlab-ci.example .env.gitlab-ci
   # 编辑 .env.gitlab-ci，填入 VOLCES_PASSWORD、GITLAB_ROOT_PASSWORD 等
   ```
2. 启动服务：
   ```bash
   docker compose -f docker-compose.gitlab-ci.yml --project-name gitlab-ci up -d
   ```
3. 首次启动初始化较慢（~5-10 分钟）。GitLab Web 入口：`http://localhost:8929`，root 密码见 `.env.gitlab-ci`。

## 注册 Runner（docker 执行器）
1. 在 GitLab Web：`Admin > CI/CD > Runners` 复制 **Registration token**。
2. 把 token 写入 `.env.gitlab-ci` 的 `GITLAB_RUNNER_REGISTRATION_TOKEN=` 行。
3. 运行注册命令（会把配置写入 `./.gitlab-runner/config`）：
   ```bash
   docker compose -f docker-compose.gitlab-ci.yml run --rm gitlab-runner register \
     --non-interactive \
     --url "$CI_SERVER_URL" \
     --registration-token "$GITLAB_RUNNER_REGISTRATION_TOKEN" \
     --executor docker \
     --docker-image docker:24.0.7 \
     --docker-privileged \
     --description "local-docker-runner"
   ```
4. 重启 Runner 使注册生效：
   ```bash
   docker compose -f docker-compose.gitlab-ci.yml restart gitlab-runner
   ```

## 配置项目变量
在项目 **Settings > CI/CD > Variables** 中添加：
- `VOLCES_USERNAME`：镜像/Helm registry 用户名（默认 `alexhe@53804650`）。
- `VOLCES_PASSWORD`：镜像/Helm registry 密码或 token。
- 可选：`ENABLE_CLIENT_JOBS=true` 以开启 Android/iOS/Harmony/微信小程序/UniAppX 客户端构建。
- 可选：`VERSION` 用于覆盖镜像/Chart tag（默认使用 `CI_COMMIT_SHA`）。

## 运行流水线
- 推送到仓库或在 GitLab UI 选择 **Run pipeline** 即可触发。
- stages：`clients`（默认跳过）、`images`（Docker Buildx 构建并推送）、`chart`（打包并推送 Helm）。
- 客户端 jobs 需要相应的 runner：
  - Android/Harmony/小程序/UniAppX：`docker` runner；
  - iOS：带 `macos` 标签的 Mac Runner。

## 清理
```bash
docker compose -f docker-compose.gitlab-ci.yml down
rm -rf .gitlab .gitlab-runner
```

> 提示：Compose 文件和 `.env.gitlab-ci` 仅用于本地演示，正式环境请使用安全的凭证与专用 Runner。EOF