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
GITLAB_URL="http://192.168.0.227" \
RUNNER_AUTH_TOKEN="<GLRT_AUTH_TOKEN>" \
RUNNER_NAME="gitlab-runner-02" \
RUNNER_TAG_LIST="docker-2c4g" \
./gitlab-runner-02/register.sh
```

注册完成后，确认 `gitlab-runner-02/config/config.toml` 中以下配置存在：

- `concurrent = 1`
- `[runners.docker]` 下：
  - `cpus = "2"`
  - `memory = "4g"`
  - `memory_swap = "4g"`
  - `privileged = false`

说明：`glrt-` token 建议仅通过环境变量注入注册命令，不要写入仓库文件。注册成功后，Runner 会把实际运行所需 token 写到挂载卷中的 `config.toml`（目标节点本地文件）。

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
