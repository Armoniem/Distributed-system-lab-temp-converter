# TempConv Load Test Results

Results are saved as `summary.json` after each k6 run.

## Running the test

```bash
# Against local backend
k6 run tests/load/k6_load_test.js

# Against deployed GKE ingress
k6 run -e BASE_URL=http://YOUR_INGRESS_IP tests/load/k6_load_test.js

# Custom scale
k6 run --vus 200 --duration 120s -e BASE_URL=http://YOUR_INGRESS_IP tests/load/k6_load_test.js
```

## Default test profile

| Stage      | Duration | Target VUs |
|------------|----------|-----------|
| Ramp up    | 30s      | 10        |
| Ramp up    | 60s      | 50        |
| Peak load  | 60s      | 100       |
| Scale down | 30s      | 50        |
| Ramp down  | 30s      | 0         |

## Success thresholds

- p95 response time < 500ms
- Error rate < 1%
