# ─── Stage 1: Proto code generation ───────────────────────────────────────────
FROM golang:1.21-alpine AS proto-gen

RUN apk add --no-cache protobuf protobuf-dev curl unzip

# Install protoc plugins
RUN go install google.golang.org/protobuf/cmd/protoc-gen-go@v1.33.0 && \
    go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@v1.3.0 && \
    go install github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-grpc-gateway@v2.19.1 && \
    go install github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-openapiv2@v2.19.1

# Download googleapis protos needed by grpc-gateway
RUN mkdir -p /googleapis && \
    curl -sSL https://github.com/googleapis/googleapis/archive/master.tar.gz | \
    tar -xz -C /tmp && \
    cp -r /tmp/googleapis-master/google /googleapis/google

WORKDIR /workspace
COPY proto/ proto/

RUN mkdir -p backend/gen/tempconv && \
    protoc \
      -I proto \
      -I /googleapis \
      --go_out=backend/gen/tempconv \
      --go_opt=paths=source_relative \
      --go-grpc_out=backend/gen/tempconv \
      --go-grpc_opt=paths=source_relative \
      --grpc-gateway_out=backend/gen/tempconv \
      --grpc-gateway_opt=paths=source_relative \
      proto/tempconv.proto

# ─── Stage 2: Go build ─────────────────────────────────────────────────────────
FROM golang:1.21-alpine AS builder

WORKDIR /app

# Copy generated proto code
COPY --from=proto-gen /workspace/backend/gen ./gen

# Download dependencies first (layer cache)
COPY backend/go.mod backend/go.sum* ./
RUN go mod download

# Copy source
COPY backend/ .

# Copy generated code into the right spot
COPY --from=proto-gen /workspace/backend/gen ./gen

# Build for linux/amd64 (GKE node architecture)
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -ldflags="-s -w" -o /bin/server ./cmd/server

# ─── Stage 3: Minimal runtime image ──────────────────────────────────────────
FROM gcr.io/distroless/static:nonroot

COPY --from=builder /bin/server /server

# gRPC port
EXPOSE 50051
# HTTP gateway port
EXPOSE 8080

USER nonroot:nonroot
ENTRYPOINT ["/server"]
