const express = require('express');
const router = express.Router();
const controller = require('../controllers/productController');
const validators = require('../validators/productValidator');
const { validationResult } = require('express-validator');
const multer = require('multer');
const path = require('path');
const { S3Client } = require('@aws-sdk/client-s3');
const multerS3 = require('multer-s3');

// ============================================================
// Upload Config: S3 in production, local disk fallback for dev
// ============================================================
let upload;

if (process.env.S3_BUCKET_NAME) {
  // --- PRODUCTION: Upload directly to Amazon S3 ---
  const s3 = new S3Client({ region: process.env.AWS_REGION || 'ap-southeast-2' });

  const s3Storage = multerS3({
    s3: s3,
    bucket: process.env.S3_BUCKET_NAME,
    contentType: multerS3.AUTO_CONTENT_TYPE,
    key: function (req, file, cb) {
      const safe = Date.now() + '-' + file.originalname.replace(/[^a-zA-Z0-9.\-_]/g, '_');
      cb(null, `uploads/${safe}`);
    }
  });

  upload = multer({ storage: s3Storage });
  console.log(`[Upload] Using S3 bucket: ${process.env.S3_BUCKET_NAME}`);
} else {
  // --- LOCAL DEV: Save to disk (only for development) ---
  const localStorage = multer.diskStorage({
    destination: function (req, file, cb) {
      cb(null, path.join(__dirname, '..', 'public', 'uploads'));
    },
    filename: function (req, file, cb) {
      const safe = Date.now() + '-' + file.originalname.replace(/[^a-zA-Z0-9.\-_]/g, '_');
      cb(null, safe);
    }
  });

  upload = multer({ storage: localStorage });
  console.log('[Upload] S3 not configured — using local disk storage (dev mode)');
}

function handleValidation(req, res, next) {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return res.status(400).json({ errors: errors.array() });
  next();
}

router.get('/', controller.list);
router.get('/:id', controller.getOne);
router.post('/', upload.single('imageFile'), validators.create, handleValidation, controller.create);
router.put('/:id', upload.single('imageFile'), validators.put, handleValidation, controller.put);
router.patch('/:id', upload.single('imageFile'), validators.patch, handleValidation, controller.patch);
router.delete('/:id', controller.remove);

module.exports = router;
