const dataSource = require('../services/dataSource');

async function list(req, res, next) {
  try {
    const categories = await dataSource.getAllCategories();
    res.json({ data: categories });
  } catch (err) { next(err); }
}

async function create(req, res, next) {
  try {
    const { name, description } = req.body;
    const existing = (await dataSource.getAllCategories()).find(c => c.name === name);
    if (existing) return res.status(409).json({ message: 'Category already exists' });
    // For simplicity, we just return a message since full category CRUD is not the focus
    res.status(201).json({ data: { name, description } });
  } catch (err) { next(err); }
}

async function remove(req, res, next) {
  try {
    // For simplicity, return a message since full category CRUD is not the focus
    res.json({ data: { id: req.params.id, deleted: true } });
  } catch (err) { next(err); }
}

module.exports = { list, create, remove };
