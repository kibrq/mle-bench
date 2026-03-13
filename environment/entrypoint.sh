#!/bin/bash
set -euo pipefail
set -x

LOGS_DIR=/home/logs
mkdir -p "$LOGS_DIR"
ls -ld /home /home/nonroot "$LOGS_DIR"

PRIVATE_DATA_DIR="${PRIVATE_DATA_DIR:-/private/data}"
COMPETITION_ID="${COMPETITION_ID:-}"

cleanup() {
  if [ -n "${SERVER_PID:-}" ] && kill -0 "${SERVER_PID}" 2>/dev/null; then
    kill "${SERVER_PID}" 2>/dev/null || true
    wait "${SERVER_PID}" 2>/dev/null || true
  fi
}
trap cleanup EXIT

if [ -n "${COMPETITION_ID}" ]; then
  # Launch grading server and keep it alive in the background.
  MAMBA_ROOT_PREFIX=${ROOT_MAMBA_ROOT_PREFIX} \
    micromamba -n ${PRIVATE_ENV_NAME} run python3 /private/grading_server.py \
    >>"$LOGS_DIR/entrypoint.log" 2>&1 &
  SERVER_PID=$!

  # Wait briefly for the server to come online.
  for _ in $(seq 1 30); do
    if MAMBA_ROOT_PREFIX=${ROOT_MAMBA_ROOT_PREFIX} micromamba -n ${PRIVATE_ENV_NAME} run python3 -c "import sys, urllib.request; urllib.request.urlopen('http://127.0.0.1:5000/health', timeout=1); sys.exit(0)" >/dev/null 2>&1; then
      break
    fi
    sleep 1
  done
else
  echo "COMPETITION_ID is not set; skipping grading server startup." >>"$LOGS_DIR/entrypoint.log"
fi

if [ "$#" -eq 0 ]; then
  if [ -n "${SERVER_PID:-}" ]; then
    wait "${SERVER_PID}"
  else
    tail -f /dev/null
  fi
else
  exec "$@"
fi
