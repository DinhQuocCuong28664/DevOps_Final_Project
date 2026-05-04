/**
 * Shared in-memory cart store.
 * Used by both cartRoutes.js and orderRoutes.js
 * Key: userId (string), Value: { items: [{ productId, name, price, quantity }] }
 */
const carts = {};

function getCart(userId) {
  if (!carts[userId]) {
    carts[userId] = { items: [] };
  }
  return carts[userId];
}

function clearCart(userId) {
  carts[userId] = { items: [] };
}

module.exports = { getCart, clearCart };
