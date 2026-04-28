require('dotenv').config();
const express    = require('express');
const mongoose   = require('mongoose');
const os         = require('os');
const path       = require('path');
const fs         = require('fs');
const { register, metricsMiddleware } = require('./metrics');

const productRoutes = require('./routes/productRoutes');
const dataSource    = require('./services/dataSource');
const uiRoutes      = require('./routes/uiRoutes');

const app = express();

// ============================================================
// Metrics Middleware — đo tất cả HTTP requests (tước các route khác)
// ============================================================
app.use(metricsMiddleware);

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// view engine and static
app.set('views', path.join(__dirname, 'views'));
app.set('view engine', 'ejs');
app.use(express.static(path.join(__dirname, 'public')));

app.use('/', uiRoutes);
app.use('/products', productRoutes);

// ============================================================
// Health Check Endpoint — dùng cho K8s readinessProbe / livenessProbe
// GET /health → 200 OK nếu app sẵn sàng, 503 nếu DB lỗi
// ============================================================
app.get('/health', (req, res) => {
  const dbStatus = mongoose.connection.readyState;
  // 0=disconnected, 1=connected, 2=connecting, 3=disconnecting
  const dbMap = { 0: 'disconnected', 1: 'connected', 2: 'connecting', 3: 'disconnecting' };

  const health = {
    status: dbStatus === 1 ? 'ok' : 'degraded',
    timestamp: new Date().toISOString(),
    uptime_seconds: Math.floor(process.uptime()),
    hostname: os.hostname(),
    database: {
      status: dbMap[dbStatus] || 'unknown',
      using_memory_fallback: !dataSource.isMongo
    },
    memory: {
      rss_mb: Math.round(process.memoryUsage().rss / 1024 / 1024),
      heap_used_mb: Math.round(process.memoryUsage().heapUsed / 1024 / 1024),
      heap_total_mb: Math.round(process.memoryUsage().heapTotal / 1024 / 1024)
    }
  };

  const httpStatus = health.status === 'ok' ? 200 : 503;
  res.status(httpStatus).json(health);
});

// ============================================================
// Prometheus Metrics Endpoint
// GET /metrics → trả về tất cả custom metrics ở định dạng text/plain
// Prometheus sẽ tự scrape endpoint này mỗi 15 giây
// ============================================================
app.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});

const PORT = process.env.PORT || 3000;

async function start() {
  // Chỉ tạo thư mục uploads khi KHÔNG dùng S3 (chế độ dev local)
  if (!process.env.S3_BUCKET_NAME) {
    const uploadsDir = path.join(__dirname, 'public', 'uploads');
    if (!fs.existsSync(uploadsDir)) {
      fs.mkdirSync(uploadsDir, { recursive: true });
      console.log(`Created uploads directory at ${uploadsDir}`);
    }
  }

  // Try to connect to MongoDB once with 3s timeout
  const mongoUri = process.env.MONGO_URI || 'mongodb://localhost:27017/products_db';
  let usingMongo = false;
  try {
    await mongoose.connect(mongoUri, {
      serverSelectionTimeoutMS: 3000
    });
    usingMongo = true;
    console.log('Connected to MongoDB — using mongodb as data source.');
  } catch (err) {
    usingMongo = false;
    console.log('Failed to connect to MongoDB within 3s — falling back to in-memory database.');
  }

  await dataSource.init(usingMongo);

  app.listen(PORT, () => {
    console.log(`Server listening on port http://localhost:${PORT} — hostname: ${os.hostname()}`);
    console.log(`Data source in use: ${dataSource.isMongo ? 'mongodb' : 'in-memory'}`);
  });
}

start();

module.exports = app;
