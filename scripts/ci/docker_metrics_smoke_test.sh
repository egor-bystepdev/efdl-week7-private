#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="${1:-week07-ci}"
CONTAINER_NAME="week07-ci-metrics-smoke"
BASE_URL="http://127.0.0.1:5000"

docker run -d --rm --name "${CONTAINER_NAME}" -p 5000:5000 "${IMAGE_NAME}"
trap 'docker logs "${CONTAINER_NAME}" || true; docker stop "${CONTAINER_NAME}" || true' EXIT

ready=0
for _ in $(seq 1 60); do
  if curl -fsS "${BASE_URL}/metrics" >/dev/null; then
    echo "Service is up, running metrics smoke checks"
    ready=1
    break
  fi
  sleep 2
done

if [ "${ready}" -ne 1 ]; then
  echo "Service did not respond in time"
  exit 1
fi

curl -fsS "${BASE_URL}/predict?text=hello" >/dev/null
curl -fsS "${BASE_URL}/predict?text=you+are+an+idiot" >/dev/null

metrics="$(curl -fsS "${BASE_URL}/metrics")"
METRICS_TEXT="${metrics}" python - <<'PY'
import os
import re

metrics = os.environ["METRICS_TEXT"]
match = re.search(r"^app_http_inference_count_total\s+([0-9]+(?:\.[0-9]+)?)$", metrics, re.MULTILINE)
assert match is not None, "app_http_inference_count_total metric missing"
count = float(match.group(1))
assert count >= 2.0, f"Expected app_http_inference_count_total >= 2.0, got {count}"
print("Metrics smoke checks passed")
PY
