# gitlab-runner-02 使用说明

本目录用于在目标节点部署一个 Project 级 GitLab Runner（Docker executor + DooD）。

## 约束

- Runner 名称：`gitlab-runner-02`
- 调度：`tagged only`
- 并发：`concurrent = 1`
- 每个 Job 容器资源上限：`2C/4G`
- Docker 模式：DooD（通过 `/var/run/docker.sock`）

## 一次性注册

在目标节点执行：

```bash
chmod +x ./gitlab-runner-02/register.sh ./gitlab-runner-02/verify.sh

docker compose up -d gitlab-runner-02

GITLAB_URL="http://gitlab" \
RUNNER_AUTH_TOKEN="<GLRT_AUTH_TOKEN>" \
RUNNER_NAME="gitlab-runner-02" \
./gitlab-runner-02/register.sh
```

使用 `glrt-` token 时，以下属性需要在 GitLab UI 创建 Runner 时设置，而不是通过 `register` 参数设置：
- Tags：`docker-2c4g`
- Run untagged jobs：关闭
- Locked to current project：按需开启/关闭

注册完成后，确认 `gitlab-runner-02/config/config.toml` 中以下配置存在：

- `concurrent = 1`
- `[runners.docker]` 下：
  - `cpus = "2"`
  - `memory = "4g"`
  - `memory_swap = "4g"`
  - `privileged = false`

说明：`glrt-` token 建议仅通过环境变量注入注册命令，不要写入仓库文件。注册成功后，Runner 会把实际运行所需 token 写到挂载卷中的 `config.toml`（目标节点本地文件）。

## 常见故障与恢复（生产）

### 症状

执行注册时出现：

- `Runner configuration other than name and executor configuration is reserved`

### 原因

- `glrt-` token 新流程下，`register` 不能传 `--tag-list` / `--run-untagged` / `--locked`。

### 恢复步骤

1. 在 GitLab UI 轮换/重置 Runner token（旧 token 立即失效）。
2. 停止 runner：

```bash
docker compose stop gitlab-runner-02
```

3. 备份并清空配置：

```bash
cp -a ./gitlab-runner-02/config/config.toml ./gitlab-runner-02/config/config.toml.bak.$(date +%F-%H%M%S) 2>/dev/null || true
: > ./gitlab-runner-02/config/config.toml
```

4. 重新启动并注册：

```bash
docker compose up -d gitlab-runner-02
GITLAB_URL="http://gitlab" RUNNER_AUTH_TOKEN="<NEW_GLRT_TOKEN>" RUNNER_NAME="gitlab-runner-02" ./gitlab-runner-02/register.sh
```

5. 重启并验证：

```bash
docker compose restart gitlab-runner-02
./gitlab-runner-02/verify.sh
```

## 启动与重启

```bash
docker compose up -d gitlab-runner-02
docker compose restart gitlab-runner-02
```

## 验证

```bash
./gitlab-runner-02/verify.sh
```

## 回滚

```bash
docker compose stop gitlab-runner-02
docker compose rm -f gitlab-runner-02
```
