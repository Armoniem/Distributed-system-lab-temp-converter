/**
 * k6 Load Test for TempConv backend HTTP gateway
 *
 * Usage:
 *   k6 run tests/load/k6_load_test.js
 *
 * Against a deployed GKE cluster:
 *   k6 run -e BASE_URL=http://YOUR_INGRESS_IP tests/load/k6_load_test.js
 *
 * With custom VU/duration:
 *   k6 run --vus 50 --duration 60s tests/load/k6_load_test.js
 */

import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

// ── Configuration ─────────────────────────────────────────────────────────────
const BASE_URL = __ENV.BASE_URL || 'http://localhost:8080';

const c2f_url = `${BASE_URL}/tempconv.TempConverter/CelsiusToFahrenheit`;
const f2c_url = `${BASE_URL}/tempconv.TempConverter/FahrenheitToCelsius`;

// ── Custom metrics ────────────────────────────────────────────────────────────
const errorRate         = new Rate('error_rate');
const c2fDuration       = new Trend('c2f_duration_ms', true);
const f2cDuration       = new Trend('f2c_duration_ms', true);

// ── Test stages (ramp up, sustain, ramp down) ─────────────────────────────────
export const options = {
  stages: [
    { duration: '30s', target: 10  },  // Ramp up to 10 VUs
    { duration: '60s', target: 50  },  // Ramp up to 50 VUs
    { duration: '60s', target: 100 },  // Peak: 100 VUs simulating heavy load
    { duration: '30s', target: 50  },  // Scale down
    { duration: '30s', target: 0   },  // Ramp down to 0
  ],
  thresholds: {
    // 95th-percentile response time < 500ms
    http_req_duration: ['p(95)<500'],
    // Error rate < 1%
    error_rate: ['rate<0.01'],
    // All requests complete
    http_req_failed: ['rate<0.01'],
  },
};

// ── HTTP headers ─────────────────────────────────────────────────────────────
const jsonHeaders = {
  'Content-Type': 'application/json',
  'Accept':       'application/json',
};

// ── Test scenario ─────────────────────────────────────────────────────────────
export default function () {
  // Randomise temperature in range that's physically meaningful
  const celsius    = (Math.random() * 300) - 100;   // -100 to +200°C
  const fahrenheit = (Math.random() * 500) - 100;   // -100 to +400°F

  // ── CelsiusToFahrenheit ──────────────────────────────────────────────────
  const c2fStart = Date.now();
  const c2fResp = http.post(
    c2f_url,
    JSON.stringify({ value: celsius }),
    { headers: jsonHeaders }
  );
  c2fDuration.add(Date.now() - c2fStart);

  const c2fOk = check(c2fResp, {
    'C→F status 200':         (r) => r.status === 200,
    'C→F has result field':   (r) => {
      try { return JSON.parse(r.body).result !== undefined; }
      catch { return false; }
    },
    'C→F result is number':   (r) => {
      try { return typeof JSON.parse(r.body).result === 'number'; }
      catch { return false; }
    },
    'C→F unit is Fahrenheit': (r) => {
      try { return JSON.parse(r.body).unit === 'Fahrenheit'; }
      catch { return false; }
    },
  });
  errorRate.add(!c2fOk);

  // ── FahrenheitToCelsius ──────────────────────────────────────────────────
  const f2cStart = Date.now();
  const f2cResp = http.post(
    f2c_url,
    JSON.stringify({ value: fahrenheit }),
    { headers: jsonHeaders }
  );
  f2cDuration.add(Date.now() - f2cStart);

  const f2cOk = check(f2cResp, {
    'F→C status 200':       (r) => r.status === 200,
    'F→C has result field': (r) => {
      try { return JSON.parse(r.body).result !== undefined; }
      catch { return false; }
    },
    'F→C unit is Celsius':  (r) => {
      try { return JSON.parse(r.body).unit === 'Celsius'; }
      catch { return false; }
    },
  });
  errorRate.add(!f2cOk);

  // Think-time between requests (simulate realistic user behaviour)
  sleep(0.5 + Math.random() * 0.5); // 0.5–1.0 seconds
}

// ── Summary output ────────────────────────────────────────────────────────────
export function handleSummary(data) {
  const summary = {
    timestamp: new Date().toISOString(),
    thresholds_passed: Object.keys(data.metrics).every(
      (k) => !data.metrics[k].thresholds || 
              Object.values(data.metrics[k].thresholds).every(t => t.ok)
    ),
    requests: {
      total:        data.metrics.http_reqs?.values?.count,
      rate_per_sec: data.metrics.http_reqs?.values?.rate,
      failed:       data.metrics.http_req_failed?.values?.rate,
    },
    latency_ms: {
      avg:  data.metrics.http_req_duration?.values?.avg,
      p90:  data.metrics.http_req_duration?.values['p(90)'],
      p95:  data.metrics.http_req_duration?.values['p(95)'],
      p99:  data.metrics.http_req_duration?.values['p(99)'],
      max:  data.metrics.http_req_duration?.values?.max,
    },
    custom: {
      c2f_p95_ms: data.metrics.c2f_duration_ms?.values['p(95)'],
      f2c_p95_ms: data.metrics.f2c_duration_ms?.values['p(95)'],
      error_rate: data.metrics.error_rate?.values?.rate,
    },
  };

  return {
    'tests/load/results/summary.json': JSON.stringify(summary, null, 2),
    stdout: JSON.stringify(summary, null, 2),
  };
}
