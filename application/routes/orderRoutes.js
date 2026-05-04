const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth');
const Order = require('../models/order');
const dataSource = require('../services/dataSource');

/**
 * In-memory cart store reference (shared with cartRoutes)
 * We import the same in-memory carts object via a shared module
 */
const cartStore = require('./cartStore');

/**
 * POST /orders/checkout — Convert cart to an order
 * Body: { shippingAddress: { street, city, country } }
 */
router.post('/checkout', authenticate, async (req, res, next) => {
  try {
    const cart = cartStore.getCart(req.user.id);
    if (!cart.items || cart.items.length === 0) {
      return res.status(400).json({ message: 'Cart is empty' });
    }

    const total = cart.items.reduce((sum, item) => sum + item.price * item.quantity, 0);

    // Build order items with product ObjectId references
    const orderItems = [];
    for (const item of cart.items) {
      const product = await dataSource.getById(item.productId);
      if (!product) {
        return res.status(400).json({ message: `Product ${item.name} no longer exists` });
      }
      orderItems.push({
        product: product.id,
        name: item.name,
        price: item.price,
        quantity: item.quantity
      });
    }

    const order = await Order.create({
      user: req.user.id,
      items: orderItems,
      total: Math.round(total * 100) / 100,
      status: 'pending',
      shippingAddress: req.body.shippingAddress || {}
    });

    // Clear the cart after successful checkout
    cartStore.clearCart(req.user.id);

    res.status(201).json({ data: order });
  } catch (err) { next(err); }
});

/**
 * GET /orders — Get current user's orders
 */
router.get('/', authenticate, async (req, res, next) => {
  try {
    const orders = await Order.find({ user: req.user.id })
      .sort({ createdAt: -1 })
      .populate('items.product', 'name price imageUrl');
    res.json({ data: orders });
  } catch (err) { next(err); }
});

/**
 * GET /orders/:id — Get a specific order
 */
router.get('/:id', authenticate, async (req, res, next) => {
  try {
    const order = await Order.findOne({ _id: req.params.id, user: req.user.id })
      .populate('items.product', 'name price imageUrl');
    if (!order) return res.status(404).json({ message: 'Order not found' });
    res.json({ data: order });
  } catch (err) { next(err); }
});

/**
 * PATCH /orders/:id/cancel — Cancel an order (only if pending)
 */
router.patch('/:id/cancel', authenticate, async (req, res, next) => {
  try {
    const order = await Order.findOne({ _id: req.params.id, user: req.user.id });
    if (!order) return res.status(404).json({ message: 'Order not found' });
    if (order.status !== 'pending') {
      return res.status(400).json({ message: 'Only pending orders can be cancelled' });
    }
    order.status = 'cancelled';
    await order.save();
    res.json({ data: order });
  } catch (err) { next(err); }
});

module.exports = router;
