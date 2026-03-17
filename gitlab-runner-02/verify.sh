#!/usr/bin/env sh
set -eu

CFG="./gitlab-runner-02/config/config.toml"

echo "1) Runner service status"
echo "----------------------------------------"
docker compose ps gitlab-runner-02
echo

echo "2) Runner registration details"
echo "----------------------------------------"
docker compose exec gitlab-runner-02 gitlab-runner verify
echo

echo "3) Effective config (runner block)"
echo "----------------------------------------"
if [ -f "$CFG" ]; then
  sed -n '/\\[\\[runners\\]\\]/,/^$/p' "$CFG"
else
  echo "config.toml not found: $CFG"
  exit 1
fi
echo

echo "4) Key checks"
echo "----------------------------------------"
check_line() {
  key="$1"
  if grep -q "$key" "$CFG"; then
    echo "[OK] $key"
  else
    echo "[FAIL] missing: $key"
  fi
}

check_line '^concurrent = 1'
check_line 'cpus = "2"'
check_line 'memory = "4g"'
check_line 'memory_swap = "4g"'
check_line '/var/run/docker.sock:/var/run/docker.sock'
echo

cat <<'EOF'
Manual checks in GitLab UI:
- Runner is online in Project > Settings > CI/CD > Runners.
- Runner has tag: docker-2c4g.
- Runner does NOT pick untagged jobs.
- Trigger two tagged pipelines together and confirm only one job runs at a time (concurrent=1).
EOF
