#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="${1:-week07-ci}"
CONTAINER_NAME="week07-ci-smoke"
BASE_URL="http://127.0.0.1:5000"

docker run -d --rm --name "${CONTAINER_NAME}" -p 5000:5000 "${IMAGE_NAME}"
trap 'docker logs "${CONTAINER_NAME}" || true; docker stop "${CONTAINER_NAME}" || true' EXIT

ready=0
for _ in $(seq 1 60); do
  if curl -fsS "${BASE_URL}/predict?text=hello" >/dev/null; then
    echo "Service is up, running classification smoke checks"
    ready=1
    break
  fi
  sleep 2
done

if [ "${ready}" -ne 1 ]; then
  echo "Service did not respond in time"
  exit 1
fi

toxic_json="$(curl -fsS "${BASE_URL}/predict?text=you+are+a+stupid+idiot")"
clean_json="$(curl -fsS "${BASE_URL}/predict?text=have+a+nice+day+friend")"

TOXIC_JSON="${toxic_json}" CLEAN_JSON="${clean_json}" python - <<'PY'
import json
import os

toxic = json.loads(os.environ["TOXIC_JSON"])
clean = json.loads(os.environ["CLEAN_JSON"])

assert toxic["is_toxic"] is True, f"Expected toxic=True, got: {toxic}"
assert clean["is_toxic"] is False, f"Expected toxic=False, got: {clean}"

PY
