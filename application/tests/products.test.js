const request = require('supertest');
const app = require('../main');
require('./setup');

describe('GET /products', () => {
  it('should return a paginated list of products', async () => {
    const res = await request(app).get('/products?limit=5');
    expect(res.statusCode).toBe(200);
    expect(res.body).toHaveProperty('data');
    expect(res.body).toHaveProperty('pagination');
    expect(res.body).toHaveProperty('hostname');
    expect(res.body).toHaveProperty('source');
    expect(Array.isArray(res.body.data)).toBe(true);
    expect(res.body.data.length).toBeLessThanOrEqual(5);
    expect(res.body.pagination).toHaveProperty('page', 1);
    expect(res.body.pagination).toHaveProperty('limit', 5);
    expect(res.body.pagination).toHaveProperty('total');
  }, 10000);

  it('should search products by name', async () => {
    const res = await request(app).get('/products?search=iPhone&limit=10');
    expect(res.statusCode).toBe(200);
    expect(res.body.data.length).toBeGreaterThan(0);
    res.body.data.forEach(product => {
      const matches = product.name.toLowerCase().includes('iphone') ||
                      (product.description && product.description.toLowerCase().includes('iphone'));
      expect(matches).toBe(true);
    });
  }, 10000);

  it('should filter products by category', async () => {
    const allRes = await request(app).get('/products?limit=50');
    const categories = [...new Set(allRes.body.data.map(p => p.category))];
    expect(categories.length).toBeGreaterThan(0);

    const res = await request(app).get(`/products?category=${categories[0]}`);
    expect(res.statusCode).toBe(200);
    res.body.data.forEach(product => {
      expect(product.category).toBe(categories[0]);
    });
  }, 10000);

  it('should sort products by price ascending', async () => {
    const res = await request(app).get('/products?sortBy=price&order=asc&limit=50');
    expect(res.statusCode).toBe(200);
    for (let i = 1; i < res.body.data.length; i++) {
      expect(res.body.data[i].price).toBeGreaterThanOrEqual(res.body.data[i - 1].price);
    }
  }, 10000);

  it('should sort products by price descending', async () => {
    const res = await request(app).get('/products?sortBy=price&order=desc&limit=50');
    expect(res.statusCode).toBe(200);
    for (let i = 1; i < res.body.data.length; i++) {
      expect(res.body.data[i].price).toBeLessThanOrEqual(res.body.data[i - 1].price);
    }
  }, 10000);
});

describe('GET /products/:id', () => {
  it('should return a single product by ID', async () => {
    const listRes = await request(app).get('/products?limit=1');
    expect(listRes.body.data.length).toBeGreaterThan(0);
    const productId = listRes.body.data[0].id;

    const res = await request(app).get(`/products/${productId}`);
    expect(res.statusCode).toBe(200);
    expect(res.body).toHaveProperty('data');
    expect(res.body.data).toHaveProperty('id', productId);
    expect(res.body.data).toHaveProperty('name');
    expect(res.body.data).toHaveProperty('price');
  }, 10000);

  it('should return 404 for non-existent product', async () => {
    const res = await request(app).get('/products/non-existent-id');
    expect(res.statusCode).toBe(404);
  }, 10000);
});
