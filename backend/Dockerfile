# ─── Stage 1: Go build ─────────────────────────────────────────────────────────
# We use hand-written proto stubs in backend/gen/ (committed to the repo).
# This avoids needing protoc, googleapis protos, and network access during build.
# To regenerate from .proto: run scripts/gen_proto.sh locally and commit the output.
FROM --platform=linux/amd64 golang:1.21-alpine AS builder

WORKDIR /app

# Download dependencies (layer cache)
COPY backend/go.mod backend/go.sum* ./
RUN go mod download

# Copy all source including the gen/ stubs
COPY backend/ .

# Build for linux/amd64 (GKE node architecture)
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -ldflags="-s -w" -o /bin/server ./cmd/server

# ─── Stage 2: Minimal runtime image ──────────────────────────────────────────
FROM gcr.io/distroless/static-debian12:nonroot

COPY --from=builder /bin/server /server

# gRPC port
EXPOSE 50051
# HTTP gateway port
EXPOSE 8080

USER nonroot:nonroot
ENTRYPOINT ["/server"]
