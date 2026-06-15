'use strict';
const { Router } = require('express');
const pool   = require('../database/connection');
const router = Router();

router.get('/configuracion', async (_req, res) => {
  try {
    const [rows] = await pool.execute('SELECT clave, valor FROM configuracion');
    const data = Object.fromEntries(rows.map(r => [r.clave, r.valor]));
    res.json({ ok: true, data });
  } catch {
    res.status(500).json({ ok: false, message: 'Error al obtener configuración.' });
  }
});

module.exports = router;
