'use strict';
// ============================================================
// metrics.js — Custom Application-Level Metrics (prom-client)
// Expose /metrics endpoint cho Prometheus scrape
// ============================================================
const client = require('prom-client');

// Registry riêng để tránh conflict với default registry
const register = new client.Registry();

// Thu thập các default metrics của Node.js process:
// (event loop lag, heap usage, GC stats, active handles...)
client.collectDefaultMetrics({
  register,
  prefix: 'moteo_',         // prefix để dễ phân biệt trong Grafana
  gcDurationBuckets: [0.001, 0.01, 0.1, 1, 2, 5],
});

// ──────────────────────────────────────────────────────────
// 1. HTTP Request Counter — đếm tổng số request theo method + route + status
// ──────────────────────────────────────────────────────────
const httpRequestsTotal = new client.Counter({
  name: 'moteo_http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route', 'status_code'],
  registers: [register],
});

// ──────────────────────────────────────────────────────────
// 2. HTTP Request Duration — histogram đo thời gian xử lý mỗi request (ms)
// ──────────────────────────────────────────────────────────
const httpRequestDurationMs = new client.Histogram({
  name: 'moteo_http_request_duration_ms',
  help: 'HTTP request duration in milliseconds',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [10, 50, 100, 200, 500, 1000, 2000, 5000],
  registers: [register],
});

// ──────────────────────────────────────────────────────────
// 3. Active HTTP Connections — gauge đo số request đang được xử lý
// ──────────────────────────────────────────────────────────
const httpActiveRequests = new client.Gauge({
  name: 'moteo_http_active_requests',
  help: 'Number of HTTP requests currently being processed',
  registers: [register],
});

// ──────────────────────────────────────────────────────────
// 4. Product Operations Counter — đếm CRUD operations
// ──────────────────────────────────────────────────────────
const productOperationsTotal = new client.Counter({
  name: 'moteo_product_operations_total',
  help: 'Total number of product CRUD operations',
  labelNames: ['operation', 'status'],   // operation: create|read|update|delete, status: success|error
  registers: [register],
});

// ──────────────────────────────────────────────────────────
// 5. File Upload Counter — đếm số lần upload ảnh lên S3
// ──────────────────────────────────────────────────────────
const fileUploadsTotal = new client.Counter({
  name: 'moteo_file_uploads_total',
  help: 'Total number of file uploads to S3',
  labelNames: ['status'],   // success | error
  registers: [register],
});

// ──────────────────────────────────────────────────────────
// Middleware: gắn vào Express để tự động đo mọi request
// ──────────────────────────────────────────────────────────
function metricsMiddleware(req, res, next) {
  // Bỏ qua chính endpoint /metrics để tránh self-referencing
  if (req.path === '/metrics') return next();

  const start = Date.now();
  httpActiveRequests.inc();

  res.on('finish', () => {
    const duration = Date.now() - start;
    // Normalize route: thay :id params bằng :id để tránh cardinality explosion
    const route = req.route ? req.route.path : req.path.replace(/\/\d+/g, '/:id');

    httpRequestsTotal.inc({
      method: req.method,
      route,
      status_code: res.statusCode,
    });

    httpRequestDurationMs.observe(
      { method: req.method, route, status_code: res.statusCode },
      duration,
    );

    httpActiveRequests.dec();
  });

  next();
}

// ──────────────────────────────────────────────────────────
// Exports
// ──────────────────────────────────────────────────────────
module.exports = {
  register,
  metricsMiddleware,
  // Counters dùng trong controllers/routes
  productOperationsTotal,
  fileUploadsTotal,
};
