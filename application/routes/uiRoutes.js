const express = require('express');
const router = express.Router();
const dataSource = require('../services/dataSource');

router.get('/', async (req, res, next) => {
  try {
    const { page, limit, search, category, sortBy, order } = req.query;
    const result = await dataSource.getAll({ page, limit, search, category, sortBy, order });
    const categories = await dataSource.getAllCategories();
    res.render('index', {
      products: result.data,
      pagination: result.pagination,
      categories,
      search: search || '',
      selectedCategory: category || '',
      sortBy: sortBy || '',
      order: order || '',
      hostname: require('os').hostname(),
      source: dataSource.isMongo ? 'mongodb' : 'in-memory'
    });
  } catch (err) { next(err); }
});

module.exports = router;
