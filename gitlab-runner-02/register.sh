#!/usr/bin/env sh
set -eu

# Usage:
#   GITLAB_URL=http://gitlab \
#   RUNNER_AUTH_TOKEN=<glrt-token> \
#   ./gitlab-runner-02/register.sh

: "${GITLAB_URL:?GITLAB_URL is required}"
: "${RUNNER_AUTH_TOKEN:?RUNNER_AUTH_TOKEN is required}"

RUNNER_NAME="${RUNNER_NAME:-gitlab-runner-02}"
RUNNER_EXECUTOR="${RUNNER_EXECUTOR:-docker}"
RUNNER_IMAGE="${RUNNER_IMAGE:-alpine:latest}"

docker compose run --rm gitlab-runner-02 register \
  --non-interactive \
  --url "${GITLAB_URL}" \
  --token "${RUNNER_AUTH_TOKEN}" \
  --name "${RUNNER_NAME}" \
  --executor "${RUNNER_EXECUTOR}" \
  --docker-image "${RUNNER_IMAGE}"

echo "Runner registration completed."
echo "For glrt tokens, tags/run-untagged/locked are managed on GitLab server side."
