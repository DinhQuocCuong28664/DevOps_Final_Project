'use strict';
// ============================================================
// metrics.js - Custom Application-Level Metrics (prom-client)
// Exposes /metrics endpoint for Prometheus to scrape
// ============================================================
const client = require('prom-client');

// Separate registry to avoid conflicts with the default registry
const register = new client.Registry();

// Collect default Node.js process metrics:
// (event loop lag, heap usage, GC stats, active handles...)
client.collectDefaultMetrics({
  register,
  prefix: 'moteo_',         // Prefix for easy identification in Grafana
  gcDurationBuckets: [0.001, 0.01, 0.1, 1, 2, 5],
});

// --------------------------------------------------------------
// 1. HTTP Request Counter - counts total requests by method + route + status
// --------------------------------------------------------------
const httpRequestsTotal = new client.Counter({
  name: 'moteo_http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route', 'status_code'],
  registers: [register],
});

// --------------------------------------------------------------
// 2. HTTP Request Duration - histogram measuring request processing time (ms)
// --------------------------------------------------------------
const httpRequestDurationMs = new client.Histogram({
  name: 'moteo_http_request_duration_ms',
  help: 'HTTP request duration in milliseconds',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [10, 50, 100, 200, 500, 1000, 2000, 5000],
  registers: [register],
});

// --------------------------------------------------------------
// 3. Active HTTP Connections - gauge measuring in-flight requests
// --------------------------------------------------------------
const httpActiveRequests = new client.Gauge({
  name: 'moteo_http_active_requests',
  help: 'Number of HTTP requests currently being processed',
  registers: [register],
});

// --------------------------------------------------------------
// 4. Product Operations Counter - counts CRUD operations
// --------------------------------------------------------------
const productOperationsTotal = new client.Counter({
  name: 'moteo_product_operations_total',
  help: 'Total number of product CRUD operations',
  labelNames: ['operation', 'status'],   // operation: create|read|update|delete, status: success|error
  registers: [register],
});

// --------------------------------------------------------------
// 5. File Upload Counter - counts image uploads to S3
// --------------------------------------------------------------
const fileUploadsTotal = new client.Counter({
  name: 'moteo_file_uploads_total',
  help: 'Total number of file uploads to S3',
  labelNames: ['status'],   // success | error
  registers: [register],
});

// --------------------------------------------------------------
// Middleware: attaches to Express to automatically measure all requests
// --------------------------------------------------------------
function metricsMiddleware(req, res, next) {
  // Skip the /metrics endpoint itself to avoid self-referencing
  if (req.path === '/metrics') return next();

  const start = Date.now();
  httpActiveRequests.inc();

  res.on('finish', () => {
    const duration = Date.now() - start;
    // Normalize route: replace :id params with :id to avoid cardinality explosion
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

// --------------------------------------------------------------
// Exports
// --------------------------------------------------------------
module.exports = {
  register,
  metricsMiddleware,
  // Counters used in controllers/routes
  productOperationsTotal,
  fileUploadsTotal,
};
