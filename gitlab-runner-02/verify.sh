#!/usr/bin/env sh
set -eu

echo "1) Runner service status"
echo "----------------------------------------"
docker compose ps gitlab-runner-02
echo

echo "2) Runner registration details"
echo "----------------------------------------"
docker compose exec gitlab-runner-02 gitlab-runner verify
echo

echo "3) Effective resource limits in config"
echo "----------------------------------------"
if [ -f "./gitlab-runner-02/config/config.toml" ]; then
  sed -n '/\\[\\[runners\\]\\]/,/^$/p' ./gitlab-runner-02/config/config.toml
else
  echo "config.toml not found: ./gitlab-runner-02/config/config.toml"
fi
echo

cat <<'EOF'
Manual checks in GitLab UI:
- Runner is online in Project > Settings > CI/CD > Runners.
- Runner has tag: docker-2c4g.
- Runner does NOT pick untagged jobs.
- Trigger two tagged pipelines together and confirm only one job runs at a time (concurrent=1).
EOF
