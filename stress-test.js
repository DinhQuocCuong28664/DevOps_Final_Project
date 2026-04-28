const https = require('https');

const URL = 'https://www.moteo.fun/';
const CONCURRENCY = 200; // Number of virtual clients sending requests concurrently
let requestCount = 0;

console.log(`[STRESS TEST] Starting full-scale stress test on: ${URL}`);
console.log(`[CONFIG] Concurrency level: ${CONCURRENCY} virtual clients running simultaneously`);
console.log(`(Press Ctrl+C at any time to stop)`);
console.log('------------------------------------------------------------');

function sendRequest() {
    https.get(URL, (res) => {
        requestCount++;
        
        // Report progress every 1000 requests
        if (requestCount % 1000 === 0) {
            console.log(`[PROGRESS] Sent ${requestCount} requests so far...`);
        }
        
        // Consume response data (helps Node.js GC)
        res.on('data', () => {}); 
        res.on('end', () => {
            // Immediately send another request when the previous one completes (infinite loop)
            sendRequest();
        });
    }).on('error', (err) => {
        console.error(`[ERROR] Request failed (${err.message})... Continuing stress test!`);
        // Keep going even if there are intermittent errors
        setTimeout(sendRequest, 100); 
    });
}

// Launch all virtual clients
for (let i = 0; i < CONCURRENCY; i++) {
    sendRequest();
}
