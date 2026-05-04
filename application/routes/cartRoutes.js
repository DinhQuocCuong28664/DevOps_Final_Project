const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth');
const dataSource = require('../services/dataSource');
const cartStore = require('./cartStore');

/**
 * GET /cart — Get current user's cart
 */
router.get('/', authenticate, (req, res) => {
  const cart = cartStore.getCart(req.user.id);
  const total = cart.items.reduce((sum, item) => sum + item.price * item.quantity, 0);
  res.json({ data: { items: cart.items, total: Math.round(total * 100) / 100 } });
});

/**
 * POST /cart/add — Add a product to the cart
 * Body: { productId, quantity }
 */
router.post('/add', authenticate, async (req, res, next) => {
  try {
    const { productId, quantity = 1 } = req.body;
    if (!productId) return res.status(400).json({ message: 'productId is required' });

    const product = await dataSource.getById(productId);
    if (!product) return res.status(404).json({ message: 'Product not found' });

    const cart = cartStore.getCart(req.user.id);
    const existing = cart.items.find(item => item.productId === productId);

    if (existing) {
      existing.quantity += Math.max(1, parseInt(quantity) || 1);
    } else {
      cart.items.push({
        productId: product.id,
        name: product.name,
        price: product.price,
        quantity: Math.max(1, parseInt(quantity) || 1)
      });
    }

    const total = cart.items.reduce((sum, item) => sum + item.price * item.quantity, 0);
    res.json({ data: { items: cart.items, total: Math.round(total * 100) / 100 } });
  } catch (err) { next(err); }
});

/**
 * PUT /cart/update/:productId — Update quantity of a cart item
 * Body: { quantity }
 */
router.put('/update/:productId', authenticate, (req, res) => {
  const cart = cartStore.getCart(req.user.id);
  const item = cart.items.find(i => i.productId === req.params.productId);
  if (!item) return res.status(404).json({ message: 'Item not in cart' });

  const qty = parseInt(req.body.quantity);
  if (qty <= 0) {
    cart.items = cart.items.filter(i => i.productId !== req.params.productId);
  } else {
    item.quantity = qty;
  }

  const total = cart.items.reduce((sum, item) => sum + item.price * item.quantity, 0);
  res.json({ data: { items: cart.items, total: Math.round(total * 100) / 100 } });
});

/**
 * DELETE /cart/remove/:productId — Remove an item from cart
 */
router.delete('/remove/:productId', authenticate, (req, res) => {
  const cart = cartStore.getCart(req.user.id);
  cart.items = cart.items.filter(i => i.productId !== req.params.productId);
  const total = cart.items.reduce((sum, item) => sum + item.price * item.quantity, 0);
  res.json({ data: { items: cart.items, total: Math.round(total * 100) / 100 } });
});

/**
 * DELETE /cart/clear — Clear the entire cart
 */
router.delete('/clear', authenticate, (req, res) => {
  cartStore.clearCart(req.user.id);
  res.json({ data: { items: [], total: 0 } });
});

module.exports = router;
