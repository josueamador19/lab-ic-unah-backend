'use strict';
const { Router } = require('express');
const pool   = require('../database/connection');
const router = Router();

router.get('/faq', async (_req, res) => {
  try {
    const [rows] = await pool.execute(
      'SELECT id, pregunta, respuesta FROM faq WHERE activo = 1 ORDER BY orden'
    );
    res.json({ ok: true, data: rows });
  } catch {
    res.status(500).json({ ok: false, message: 'Error al obtener FAQ.' });
  }
});

module.exports = router;
