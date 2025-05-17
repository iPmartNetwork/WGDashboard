const express = require('express');
const router = express.Router();

// Middleware برای کنترل نقش
function requireRole(role) {
  return function(req, res, next) {
    if (req.user && req.user.role === role) return next();
    res.status(403).json({ error: 'دسترسی غیرمجاز' });
  };
}

// API مانیتورینگ پهنای‌باند
router.get('/monitor/bandwidth', requireRole('admin'), (req, res) => {
  // داده نمونه یا دریافت از سیستم
  res.json([
    { time: '10:00', value: 120 },
    { time: '10:01', value: 130 },
    // ...
  ]);
});

// API مانیتورینگ وضعیت سرور
router.get('/monitor/server-status', requireRole('admin'), (req, res) => {
  // داده نمونه یا دریافت از سیستم
  res.json([
    { time: '10:00', cpu: 40, ram: 60 },
    { time: '10:01', cpu: 45, ram: 62 },
    // ...
  ]);
});

module.exports = router;