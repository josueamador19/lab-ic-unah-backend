'use strict';
const crypto = require('crypto');
const config = require('../config');

module.exports = function adminAuth(req, res, next) {
  const header = req.headers['authorization'] ?? '';
  const token  = header.startsWith('Bearer ') ? header.slice(7) : '';

  if (!token || !config.adminKey) {
    return res.status(401).json({ ok: false, message: 'No autorizado.' });
  }

  // Comparación en tiempo constante — previene timing attacks
  try {
    const a = Buffer.from(token);
    const b = Buffer.from(config.adminKey);
    const valid = a.length === b.length && crypto.timingSafeEqual(a, b);
    if (!valid) return res.status(401).json({ ok: false, message: 'No autorizado.' });
  } catch {
    return res.status(401).json({ ok: false, message: 'No autorizado.' });
  }

  next();
};
