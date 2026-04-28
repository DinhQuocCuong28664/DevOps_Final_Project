'use strict';
// ============================================================
// stress-test.js - Load Testing Script for HPA Demo
// Usage: node stress-test.js [concurrency] [url]
// Example: node stress-test.js 200 https://www.moteo.fun
// ============================================================
const https = require('https');
const http  = require('http');

const TARGET_URL  = process.argv[3] || 'https://www.moteo.fun/';
const CONCURRENCY = parseInt(process.argv[2]) || 200;

// ---- Stats ----
let totalRequests  = 0;
let successCount   = 0;
let errorCount     = 0;
let totalLatencyMs = 0;
let intervalStart  = Date.now();
let intervalReqs   = 0;

console.log('============================================================');
console.log('  Stress Test - HPA Autoscaling Demo');
console.log('============================================================');
console.log(`  Target      : ${TARGET_URL}`);
console.log(`  Concurrency : ${CONCURRENCY} virtual clients`);
console.log(`  Press Ctrl+C to stop`);
console.log('============================================================');
console.log('');

// Print stats every 5 seconds
setInterval(() => {
  const elapsed  = (Date.now() - intervalStart) / 1000;
  const rps      = (intervalReqs / elapsed).toFixed(1);
  const avgLat   = totalRequests > 0 ? (totalLatencyMs / totalRequests).toFixed(0) : 0;
  const errRate  = totalRequests > 0 ? ((errorCount / totalRequests) * 100).toFixed(1) : 0;

  console.log(
    `[Stats] Total: ${totalRequests} reqs | ` +
    `RPS: ${rps} req/s | ` +
    `Avg latency: ${avgLat}ms | ` +
    `Errors: ${errorCount} (${errRate}%)`
  );
  console.log(`  --> Watch HPA: kubectl get hpa -n production -w`);

  // Reset interval counters
  intervalStart = Date.now();
  intervalReqs  = 0;
}, 5000);

// ---- Choose http or https based on URL ----
const requester = TARGET_URL.startsWith('https') ? https : http;

function sendRequest() {
  const start = Date.now();

  const req = requester.get(TARGET_URL, (res) => {
    res.on('data', () => {});
    res.on('end', () => {
      const latency = Date.now() - start;
      totalRequests++;
      intervalReqs++;
      totalLatencyMs += latency;

      if (res.statusCode >= 200 && res.statusCode < 400) {
        successCount++;
      } else {
        errorCount++;
      }
      sendRequest(); // keep hammering
    });
  });

  req.on('error', (err) => {
    errorCount++;
    totalRequests++;
    intervalReqs++;
    setTimeout(sendRequest, 200); // back off slightly on error
  });

  req.setTimeout(5000, () => {
    req.destroy();
    errorCount++;
    totalRequests++;
    intervalReqs++;
    setTimeout(sendRequest, 200);
  });
}

// ---- Launch all virtual clients ----
for (let i = 0; i < CONCURRENCY; i++) {
  // Stagger start slightly to avoid thundering herd
  setTimeout(sendRequest, i * 5);
}
