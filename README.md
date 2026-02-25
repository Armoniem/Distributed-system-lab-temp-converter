# 🌡️ TempConv — gRPC Temperature Converter on GKE

A production-ready, cloud-native temperature conversion application built with:

- **Backend**: Go + gRPC + gRPC-Gateway (HTTP/REST bridge)
- **Frontend**: Flutter Web
- **Infrastructure**: Docker, Kubernetes (GKE), Google Artifact Registry
- **Testing**: Go unit tests, gRPC integration tests, k6 load tests

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        GKE Cluster                              │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                   GCP Load Balancer (Ingress)            │  │
│  │         /           →   tempconv-frontend:80             │  │
│  │         /tempconv.* →   tempconv-backend:8080            │  │
│  └──────────────────────────────────────────────────────────┘  │
│           │                              │                      │
│  ┌────────▼───────┐           ┌──────────▼──────────┐         │
│  │  Flutter Web   │           │    Go Backend        │         │
│  │  (nginx)       │           │                      │         │
│  │  port 80       │  HTTP/JSON│  gRPC  port: 50051   │         │
│  │  2 replicas    ├──────────►│  HTTP  port: 8080    │         │
│  └────────────────┘           │  2–10 replicas (HPA) │         │
│                               └──────────────────────┘         │
└─────────────────────────────────────────────────────────────────┘

Communication: Flutter Web → HTTP/JSON → gRPC-Gateway → gRPC handler
Protocol:      proto/tempconv.proto defines the service contract
```

---

## 📁 Repository Structure

```
.
├── proto/                    # Protocol Buffer definitions
│   └── tempconv.proto        # TempConverter service definition
│
├── backend/                  # Go gRPC service
│   ├── cmd/server/main.go    # Entry point (gRPC + HTTP gateway)
│   ├── internal/server/      # Core business logic
│   │   ├── server.go         # gRPC handlers
│   │   └── server_test.go    # Unit tests
│   ├── gen/tempconv/         # Generated proto code (auto-generated)
│   ├── tests/integration/    # gRPC integration tests
│   ├── go.mod
│   └── Dockerfile            # Multi-stage build
│
├── frontend/                 # Flutter Web application
│   ├── lib/
│   │   ├── main.dart         # App + UI
│   │   ├── proto/            # Hand-written Dart proto stubs
│   │   └── services/         # HTTP client service
│   ├── test/                 # Widget tests
│   ├── web/                  # HTML entry point
│   ├── nginx.conf            # Nginx SPA config
│   └── Dockerfile            # Multi-stage build
│
├── k8s/                      # Kubernetes manifests
│   ├── backend-deployment.yaml
│   ├── backend-service.yaml
│   ├── backend-hpa.yaml      # HorizontalPodAutoscaler
│   ├── frontend-deployment.yaml
│   ├── frontend-service.yaml
│   └── ingress.yaml
│
├── tests/
│   └── load/
│       ├── k6_load_test.js   # k6 load test (ramp to 100 VUs)
│       └── results/          # Test result JSONs
│
├── scripts/
│   └── gen_proto.sh          # Proto code generation helper
│
├── docker-compose.yml        # Local development stack
└── README.md
```

---

## 🚀 Quick Start

### Prerequisites

| Tool         | Version  | Purpose                     |
|--------------|----------|------------------------------|
| Go           | 1.21+    | Backend development          |
| Flutter      | 3.x      | Frontend development         |
| Docker       | 24+      | Container builds             |
| kubectl      | 1.28+    | Kubernetes management        |
| gcloud CLI   | latest   | Google Cloud operations      |
| protoc       | 3.x      | Proto code generation        |
| k6           | 0.49+    | Load testing                 |

### Local development (with Docker Compose)

```bash
# Clone the repo
git clone https://github.com/yourusername/tempconv.git
cd tempconv

# Start everything
docker compose up --build

# Frontend:  http://localhost:3000
# Backend:   http://localhost:8080
```

### Local backend only (without Docker)

```bash
# 1. Generate proto code
bash scripts/gen_proto.sh

# 2. Run backend
cd backend
go run ./cmd/server

# gRPC: localhost:50051
# HTTP: localhost:8080
```

### Test with curl

```bash
# Celsius to Fahrenheit
curl -X POST http://localhost:8080/tempconv.TempConverter/CelsiusToFahrenheit \
  -H 'Content-Type: application/json' \
  -d '{"value": 100}'

# Fahrenheit to Celsius
curl -X POST http://localhost:8080/tempconv.TempConverter/FahrenheitToCelsius \
  -H 'Content-Type: application/json' \
  -d '{"value": 212}'
```

---

## 🧪 Running Tests

### Backend unit tests

```bash
cd backend
go test ./internal/server/... -v -race -cover
```

### Integration tests

```bash
cd backend
go test ./tests/integration/... -v
```

### Frontend widget tests

```bash
cd frontend
flutter test
```

### Load tests (k6)

```bash
# Install k6: https://k6.io/docs/get-started/installation/

# Against local backend
k6 run tests/load/k6_load_test.js

# Against GKE (replace with your Ingress IP)
k6 run -e BASE_URL=http://34.XX.XX.XX tests/load/k6_load_test.js
```

Results are saved to `tests/load/results/summary.json`.

---

## 🐳 Building Docker Images

### Backend

```bash
# Build (from repo root)
docker build -f backend/Dockerfile -t backend:latest .

# Or with explicit platform for GKE amd64 nodes
docker buildx build --platform linux/amd64 -f backend/Dockerfile -t backend:latest .
```

### Frontend

```bash
cd frontend
docker build \
  --build-arg BACKEND_URL=http://YOUR_INGRESS_IP \
  -t frontend:latest .
```

---

## ☁️ GKE Deployment

### 1. Set up GCP project

```bash
export PROJECT_ID=your-gcp-project-id
export REGION=europe-west1
export CLUSTER_NAME=tempconv-cluster
export REGISTRY=${REGION}-docker.pkg.dev/${PROJECT_ID}/tempconv
```

### 2. Create GKE cluster

```bash
gcloud container clusters create ${CLUSTER_NAME} \
  --region ${REGION} \
  --machine-type e2-standard-2 \
  --num-nodes 2 \
  --enable-autoscaling \
  --min-nodes 2 \
  --max-nodes 5 \
  --workload-pool ${PROJECT_ID}.svc.id.goog

gcloud container clusters get-credentials ${CLUSTER_NAME} --region ${REGION}
```

### 3. Create Artifact Registry repository

```bash
gcloud artifacts repositories create tempconv \
  --repository-format=docker \
  --location=${REGION} \
  --description="TempConv container images"

gcloud auth configure-docker ${REGION}-docker.pkg.dev
```

### 4. Build and push images

```bash
# Backend
docker buildx build --platform linux/amd64 \
  -f backend/Dockerfile \
  -t ${REGISTRY}/backend:latest \
  --push .

# Frontend (point to Ingress IP or domain)
INGRESS_IP=$(kubectl get ingress tempconv-ingress -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "pending")
docker buildx build --platform linux/amd64 \
  --build-arg BACKEND_URL=http://${INGRESS_IP} \
  -f frontend/Dockerfile \
  -t ${REGISTRY}/frontend:latest \
  --push ./frontend
```

### 5. Update image references in k8s manifests

```bash
# Replace placeholder values in deployment files
sed -i "s|REGION-docker.pkg.dev/PROJECT_ID|${REGISTRY}|g" k8s/backend-deployment.yaml k8s/frontend-deployment.yaml
```

### 6. Deploy to GKE

```bash
kubectl apply -f k8s/backend-deployment.yaml
kubectl apply -f k8s/backend-service.yaml
kubectl apply -f k8s/backend-hpa.yaml
kubectl apply -f k8s/frontend-deployment.yaml
kubectl apply -f k8s/frontend-service.yaml
kubectl apply -f k8s/ingress.yaml

# Watch rollout
kubectl rollout status deployment/tempconv-backend
kubectl rollout status deployment/tempconv-frontend

# Get the Ingress public IP (may take 3-5 minutes)
kubectl get ingress tempconv-ingress -w
```

### 7. Verify

```bash
export INGRESS_IP=$(kubectl get ingress tempconv-ingress -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

curl -X POST http://${INGRESS_IP}/tempconv.TempConverter/CelsiusToFahrenheit \
  -H 'Content-Type: application/json' \
  -d '{"value": 0}'
# Expected: {"result":32,"unit":"Fahrenheit","formula":"..."}

# Open in browser
echo "Frontend: http://${INGRESS_IP}"
```

---

## 📊 Scaling & Load Testing on GKE

```bash
# Watch HPA in action while running load test
kubectl get hpa tempconv-backend-hpa -w &

# Run the k6 load test against the cluster
k6 run -e BASE_URL=http://${INGRESS_IP} tests/load/k6_load_test.js

# Watch pod scaling
kubectl get pods -l app=tempconv-backend -w
```

---

## 🔧 Regenerating Proto Code

If you modify `proto/tempconv.proto`:

```bash
# Install protoc plugins
go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest
go install github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-grpc-gateway@latest

# Generate
bash scripts/gen_proto.sh
```

---

## 📡 API Reference

### CelsiusToFahrenheit

```
POST /tempconv.TempConverter/CelsiusToFahrenheit
Content-Type: application/json

{"value": 100}

→ {"result": 212, "unit": "Fahrenheit", "formula": "(100.0000 °C × 9/5) + 32 = 212.000000 °F"}
```

### FahrenheitToCelsius

```
POST /tempconv.TempConverter/FahrenheitToCelsius
Content-Type: application/json

{"value": 32}

→ {"result": 0, "unit": "Celsius", "formula": "(32.0000 °F − 32) × 5/9 = 0.000000 °C"}
```

---

## 🛡️ Security Notes

- Backend runs as non-root (UID 65532) in a distroless container
- Frontend nginx has security headers (X-Frame-Options, X-Content-Type-Options)
- No secrets are committed to the repo (see `.gitignore`)
- CORS is configured in the Go HTTP gateway

---

## 📄 License

MIT — see [LICENSE](LICENSE) for details.
