const { v4: uuidv4 } = require('uuid');
const ProductModel = require('../models/product');
const CategoryModel = require('../models/category');
const fs = require('fs').promises;
const path = require('path');

let inMemory = [];
let inMemoryCategories = [];
let isMongo = false;

// ============================================================
// Seed Categories
// ============================================================
function createSeedCategories() {
  return [
    { id: uuidv4(), name: 'Smartphones', description: 'Latest smartphones with cutting-edge technology' },
    { id: uuidv4(), name: 'Laptops', description: 'Powerful laptops for work and creativity' },
    { id: uuidv4(), name: 'Tablets', description: 'Versatile tablets for productivity and entertainment' },
    { id: uuidv4(), name: 'Wearables', description: 'Smartwatches and wearable technology' },
    { id: uuidv4(), name: 'Audio', description: 'Headphones, earbuds, and audio accessories' },
    { id: uuidv4(), name: 'Smart Home', description: 'Smart home devices and assistants' },
  ];
}

function createAppleProducts() {
  const categories = inMemoryCategories;
  const getCatId = (name) => {
    const cat = categories.find(c => c.name === name);
    return cat ? cat.id : null;
  };

  const products = [
    {
      name: 'iPhone 14 Pro Max',
      price: 1099,
      color: 'space-black',
      description: '6.7‑inch Super Retina XDR display, A16 Bionic chip, pro camera system with 48MP main sensor.',
      imageUrl: '',
      category: getCatId('Smartphones')
    },
    {
      name: 'iPhone SE (3rd generation)',
      price: 429,
      color: 'black',
      description: 'Compact design with A15 Bionic chip, great value for everyday use with Touch ID.',
      imageUrl: '',
      category: getCatId('Smartphones')
    },
    {
      name: 'MacBook Pro 14-inch (M2 Pro)',
      price: 1999,
      color: 'silver',
      description: 'Powerful M2 Pro chip with 12-core CPU, Liquid Retina XDR display, up to 18‑hour battery life.',
      imageUrl: '',
      category: getCatId('Laptops')
    },
    {
      name: 'MacBook Air 13-inch (M2)',
      price: 1199,
      color: 'midnight',
      description: 'Thin and light with M2 chip, silent fanless design, 15‑hour battery life, MagSafe charging.',
      imageUrl: '',
      category: getCatId('Laptops')
    },
    {
      name: 'iPad Pro 11-inch (M4)',
      price: 799,
      color: 'silver',
      description: 'M4 chip with 10-core CPU, Liquid Retina display with ProMotion, Thunderbolt support.',
      imageUrl: '',
      category: getCatId('Tablets')
    },
    {
      name: 'Apple Watch Series 9',
      price: 399,
      color: 'starlight',
      description: 'Faster S9 chip with 4-core Neural Engine, brighter display, Double Tap gesture.',
      imageUrl: '',
      category: getCatId('Wearables')
    },
    {
      name: 'AirPods Pro (2nd generation)',
      price: 249,
      color: 'white',
      description: 'Active Noise Cancellation with Adaptive Audio, Personalized Spatial Audio, USB-C charging.',
      imageUrl: '',
      category: getCatId('Audio')
    },
    {
      name: 'HomePod (2nd generation)',
      price: 299,
      color: 'white',
      description: 'High-fidelity audio with room-sensing technology, Siri smart home control, Matter support.',
      imageUrl: '',
      category: getCatId('Smart Home')
    },
    {
      name: 'iPhone 13',
      price: 699,
      color: 'blue',
      description: 'A15 Bionic chip, excellent dual-camera system with Cinematic mode, great battery life.',
      imageUrl: '',
      category: getCatId('Smartphones')
    },
    {
      name: 'iPad (10th generation)',
      price: 449,
      color: 'pink',
      description: 'Updated design with 10.9-inch Liquid Retina display, A14 Bionic chip, USB-C, landscape camera.',
      imageUrl: '',
      category: getCatId('Tablets')
    },
    {
      name: 'MacBook Pro 16-inch (M2 Max)',
      price: 3499,
      color: 'space-gray',
      description: 'Ultimate pro laptop with M2 Max 12-core CPU/38-core GPU, 64GB unified memory, 22hr battery.',
      imageUrl: '',
      category: getCatId('Laptops')
    },
    {
      name: 'iPhone 15 Pro Max',
      price: 1199,
      color: 'natural-titanium',
      description: 'A17 Pro chip, titanium design, 48MP pro camera system with 5x optical zoom, USB-C.',
      imageUrl: '',
      category: getCatId('Smartphones')
    },
    {
      name: 'AirPods Max',
      price: 549,
      color: 'space-gray',
      description: 'Over-ear headphones with H1 chip, Active Noise Cancellation, Transparency mode, Spatial Audio.',
      imageUrl: '',
      category: getCatId('Audio')
    },
    {
      name: 'iPad mini (6th generation)',
      price: 499,
      color: 'purple',
      description: '8.3-inch Liquid Retina display, A15 Bionic chip, USB-C, support for Apple Pencil 2nd gen.',
      imageUrl: '',
      category: getCatId('Tablets')
    },
    {
      name: 'Apple Watch Ultra 2',
      price: 799,
      color: 'natural',
      description: '49mm titanium case, Precision dual-frequency GPS, 36hr battery, Action button, dive computer.',
      imageUrl: '',
      category: getCatId('Wearables')
    }
  ];

  return products.map(p => ({ id: uuidv4(), ...p }));
}

async function init(useMongo) {
  isMongo = !!useMongo;
  inMemoryCategories = createSeedCategories();
  inMemory = createAppleProducts();

  if (isMongo) {
    try {
      // Seed categories
      const catCount = await CategoryModel.countDocuments();
      if (catCount === 0) {
        const catDocs = inMemoryCategories.map(({ name, description }) => ({ name, description }));
        const createdCats = await CategoryModel.insertMany(catDocs);
        // Map in-memory category IDs to MongoDB IDs
        const catMap = {};
        createdCats.forEach((cat, i) => {
          catMap[inMemoryCategories[i].name] = cat._id;
        });
        // Update inMemory with real category IDs
        inMemory = inMemory.map(p => ({
          ...p,
          category: catMap[inMemoryCategories.find(c => c.id === p.category)?.name] || null
        }));
      }

      // Seed products
      const count = await ProductModel.countDocuments();
      if (count === 0) {
        const docs = inMemory.map(({ name, price, color, description, imageUrl, category }) =>
          ({ name, price, color, description, imageUrl, category })
        );
        await ProductModel.insertMany(docs);
      }
    } catch (err) {
      console.log('MongoDB seed failed, falling back to in-memory:', err.message);
      isMongo = false;
    }
  }
}

function toDTO(doc) {
  if (!doc) return null;
  if (doc.id) return doc; // in-memory
  return {
    id: doc._id.toString(),
    name: doc.name,
    price: doc.price,
    color: doc.color,
    description: doc.description || null,
    imageUrl: doc.imageUrl || '',
    category: doc.category ? doc.category.toString() : null,
    createdAt: doc.createdAt,
    updatedAt: doc.updatedAt
  };
}

// ============================================================
// CATEGORY OPERATIONS
// ============================================================
async function getAllCategories() {
  if (isMongo) {
    const docs = await CategoryModel.find().sort({ name: 1 }).lean();
    return docs.map(d => ({ id: d._id.toString(), name: d.name, description: d.description }));
  }
  return inMemoryCategories.slice();
}

// ============================================================
// PRODUCT OPERATIONS with PAGINATION & SEARCH
// ============================================================
async function getAll({ page = 1, limit = 20, search, category, sortBy, order } = {}) {
  page = Math.max(1, parseInt(page) || 1);
  limit = Math.min(100, Math.max(1, parseInt(limit) || 20));
  const skip = (page - 1) * limit;

  if (isMongo) {
    const filter = {};
    if (search) {
      filter.$or = [
        { name: { $regex: search, $options: 'i' } },
        { description: { $regex: search, $options: 'i' } }
      ];
    }
    if (category) {
      filter.category = category;
    }

    const sort = {};
    if (sortBy === 'price') sort.price = order === 'desc' ? -1 : 1;
    else if (sortBy === 'name') sort.name = order === 'desc' ? -1 : 1;
    else if (sortBy === 'createdAt') sort.createdAt = order === 'desc' ? -1 : 1;
    else sort.createdAt = -1; // default: newest first

    const [docs, total] = await Promise.all([
      ProductModel.find(filter).sort(sort).skip(skip).limit(limit).lean(),
      ProductModel.countDocuments(filter)
    ]);

    return {
      data: docs.map(toDTO),
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
        hasNext: skip + limit < total,
        hasPrev: page > 1
      }
    };
  }

  // In-memory mode with filtering
  let results = inMemory.slice();

  if (search) {
    const q = search.toLowerCase();
    results = results.filter(p =>
      p.name.toLowerCase().includes(q) ||
      (p.description && p.description.toLowerCase().includes(q))
    );
  }

  if (category) {
    results = results.filter(p => p.category === category);
  }

  // Sort
  if (sortBy === 'price') {
    results.sort((a, b) => order === 'desc' ? b.price - a.price : a.price - b.price);
  } else if (sortBy === 'name') {
    results.sort((a, b) => order === 'desc'
      ? b.name.localeCompare(a.name)
      : a.name.localeCompare(b.name));
  } else {
    results.reverse(); // newest first (approximate for in-memory)
  }

  const total = results.length;
  const paginated = results.slice(skip, skip + limit);

  return {
    data: paginated,
    pagination: {
      page,
      limit,
      total,
      totalPages: Math.ceil(total / limit),
      hasNext: skip + limit < total,
      hasPrev: page > 1
    }
  };
}

async function getById(id) {
  if (isMongo) {
    const doc = await ProductModel.findById(id).populate('category', 'name').lean();
    return toDTO(doc);
  }
  return inMemory.find(p => p.id === id) || null;
}

async function create(payload) {
  if (isMongo) {
    const doc = await ProductModel.create(payload);
    return toDTO(doc.toObject());
  }
  const item = { id: uuidv4(), ...payload };
  inMemory.push(item);
  return item;
}

async function replace(id, payload) {
  if (isMongo) {
    const doc = await ProductModel.findByIdAndUpdate(id, payload, { new: true, runValidators: true }).lean();
    return toDTO(doc);
  }
  const idx = inMemory.findIndex(p => p.id === id);
  if (idx === -1) return null;
  const prev = inMemory[idx];
  if (payload.imageUrl && prev && prev.imageUrl && prev.imageUrl.startsWith('/uploads/')) {
    const filePath = path.join(__dirname, '..', 'public', prev.imageUrl.substring(1));
    try { await fs.unlink(filePath); } catch { /* ignore */ }
  }
  const item = { id, ...payload };
  inMemory[idx] = item;
  return item;
}

async function patch(id, payload) {
  if (isMongo) {
    if (payload.imageUrl) {
      const prevDoc = await ProductModel.findById(id).lean();
      if (prevDoc && prevDoc.imageUrl && prevDoc.imageUrl.startsWith('/uploads/')) {
        const filePath = path.join(__dirname, '..', 'public', prevDoc.imageUrl.substring(1));
        try { await fs.unlink(filePath); } catch { /* ignore */ }
      }
    }
    const doc = await ProductModel.findByIdAndUpdate(id, { $set: payload }, { new: true, runValidators: true }).lean();
    return toDTO(doc);
  }
  const item = inMemory.find(p => p.id === id);
  if (!item) return null;
  if (payload.imageUrl && item.imageUrl && item.imageUrl.startsWith('/uploads/')) {
    const filePath = path.join(__dirname, '..', 'public', item.imageUrl.substring(1));
    try { await fs.unlink(filePath); } catch { /* ignore */ }
  }
  Object.assign(item, payload);
  return item;
}

async function remove(id) {
  if (isMongo) {
    const doc = await ProductModel.findByIdAndDelete(id).lean();
    if (doc && doc.imageUrl && doc.imageUrl.startsWith('/uploads/')) {
      const filePath = path.join(__dirname, '..', 'public', doc.imageUrl.substring(1));
      try { await fs.unlink(filePath); } catch { /* ignore */ }
    }
    return toDTO(doc);
  }
  const idx = inMemory.findIndex(p => p.id === id);
  if (idx === -1) return null;
  const [deleted] = inMemory.splice(idx, 1);
  if (deleted && deleted.imageUrl && deleted.imageUrl.startsWith('/uploads/')) {
    const filePath = path.join(__dirname, '..', 'public', deleted.imageUrl.substring(1));
    try { await fs.unlink(filePath); } catch { /* ignore */ }
  }
  return deleted;
}

module.exports = {
  init,
  getAll,
  getById,
  create,
  replace,
  patch,
  remove,
  getAllCategories,
  get isMongo() { return isMongo; }
};
