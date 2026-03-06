#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="${1:-week07-ci}"
CONTAINER_NAME="week07-ci-grpc-smoke"
GRPC_PORT=50051

docker run -d --rm --name "${CONTAINER_NAME}" \
  -p "${GRPC_PORT}:${GRPC_PORT}" \
  "${IMAGE_NAME}"

trap 'docker logs "${CONTAINER_NAME}" || true; docker stop "${CONTAINER_NAME}" || true' EXIT

ready=0
for _ in $(seq 1 60); do
  if docker exec "${CONTAINER_NAME}" python -c "
import grpc
ch = grpc.insecure_channel('localhost:${GRPC_PORT}')
grpc.channel_ready_future(ch).result(timeout=2)
ch.close()
" 2>/dev/null; then
    echo "gRPC service is up, running classification smoke checks"
    ready=1
    break
  fi
  sleep 2
done

if [ "${ready}" -ne 1 ]; then
  echo "gRPC service did not respond in time"
  exit 1
fi

docker exec "${CONTAINER_NAME}" python - <<'PY'
import grpc
import inference_pb2, inference_pb2_grpc

channel = grpc.insecure_channel("localhost:50051")
stub = inference_pb2_grpc.TextClassifierStub(channel)

toxic = stub.Predict(inference_pb2.TextClassificationInput(text="you are a stupid idiot"))
clean = stub.Predict(inference_pb2.TextClassificationInput(text="have a nice day friend"))

assert toxic.is_toxic is True, f"Expected toxic=True, got: {toxic}"
assert clean.is_toxic is False, f"Expected toxic=False, got: {clean}"

print("gRPC classification smoke checks passed")
channel.close()
PY
