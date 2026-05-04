const request = require('supertest');
const app = require('../main');
require('./setup');

describe('GET /health', () => {
  it('should return 200 OK with health info', async () => {
    const res = await request(app).get('/health');
    expect(res.statusCode).toBe(200);
    expect(res.body).toHaveProperty('status', 'ok');
    expect(res.body).toHaveProperty('hostname');
    expect(res.body).toHaveProperty('uptime_seconds');
    expect(res.body).toHaveProperty('database');
    expect(res.body).toHaveProperty('memory');
  }, 10000);
});
