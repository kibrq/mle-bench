#!/bin/bash

# Print commands and their arguments as they are executed
set -x

{
  # log into /home/logs
  LOGS_DIR=/home/logs
  mkdir -p "$LOGS_DIR"
  ls -ld /home /home/nonroot "$LOGS_DIR"

  # Launch grading server, stays alive throughout container lifetime to service agent requests.
  MAMBA_ROOT_PREFIX=${ROOT_MAMBA_ROOT_PREFIX} micromamba -n ${PRIVATE_ENV_NAME} run python3 /private/grading_server.py
} 2>&1 | tee $LOGS_DIR/entrypoint.log
