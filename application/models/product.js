const mongoose = require('mongoose');

const productSchema = new mongoose.Schema({
  name: { type: String, required: true, index: true },
  price: { type: Number, required: true, index: true },
  color: { type: String, required: true },
  description: { type: String },
  imageUrl: { type: String },
  category: { type: mongoose.Schema.Types.ObjectId, ref: 'Category', default: null }
}, {
  timestamps: true
});

// Text index for search functionality
productSchema.index({ name: 'text', description: 'text' });

module.exports = mongoose.model('Product', productSchema);
