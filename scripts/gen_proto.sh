#!/usr/bin/env bash
# gen_proto.sh — Generate Go gRPC + gateway code from proto/tempconv.proto
# Run from the repo root: bash scripts/gen_proto.sh
set -euo pipefail

PROTO_DIR="proto"
OUT_DIR="backend/gen/tempconv"
GOOGLEAPIS_DIR="${GOOGLEAPIS_DIR:-/usr/local/include}"

mkdir -p "$OUT_DIR"

protoc \
  -I "$PROTO_DIR" \
  -I "$GOOGLEAPIS_DIR" \
  --go_out="$OUT_DIR" \
  --go_opt=paths=source_relative \
  --go-grpc_out="$OUT_DIR" \
  --go-grpc_opt=paths=source_relative \
  --grpc-gateway_out="$OUT_DIR" \
  --grpc-gateway_opt=paths=source_relative \
  "$PROTO_DIR/tempconv.proto"

echo "✅  Proto generation complete → $OUT_DIR"
