const CategoryModel = require('../models/category');

async function list(req, res, next) {
  try {
    const categories = await CategoryModel.find().sort({ name: 1 }).lean();
    res.json({ data: categories });
  } catch (err) { next(err); }
}

async function create(req, res, next) {
  try {
    const { name, description } = req.body;
    const existing = await CategoryModel.findOne({ name });
    if (existing) return res.status(409).json({ message: 'Category already exists' });
    const category = await CategoryModel.create({ name, description });
    res.status(201).json({ data: category });
  } catch (err) { next(err); }
}

async function remove(req, res, next) {
  try {
    const category = await CategoryModel.findByIdAndDelete(req.params.id);
    if (!category) return res.status(404).json({ message: 'Category not found' });
    res.json({ data: category });
  } catch (err) { next(err); }
}

module.exports = { list, create, remove };
