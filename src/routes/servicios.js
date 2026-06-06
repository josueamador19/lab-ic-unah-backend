'use strict';
const { Router } = require('express');
const pool  = require('../database/connection');
const router = Router();

/**
 * GET /servicios
 * Devuelve el catálogo completo de servicios agrupado por categoría.
 * Equivale a SERVICIOS + TOPOGRAFIA de labData.js, pero desde MariaDB.
 */
router.get('/servicios', async (req, res) => {
  try {
    const [rows] = await pool.execute(
      'SELECT * FROM servicios WHERE activo = 1 ORDER BY categoria, code'
    );

    const grouped = {};
    for (const row of rows) {
      if (!grouped[row.categoria]) grouped[row.categoria] = [];
      grouped[row.categoria].push({
        id:     row.id,
        code:   row.code,
        name:   row.name,
        norma:  row.norma,
        sub:    row.sub,
        note:   row.note,
        precio: row.precio !== null ? parseFloat(row.precio) : null,
      });
    }

    res.json({ ok: true, data: grouped });
  } catch (err) {
    res.status(500).json({ ok: false, message: 'Error al obtener servicios.' });
  }
});

/**
 * GET /servicios/flat
 * Lista plana de todos los servicios activos (útil para selectores en el frontend).
 */
router.get('/servicios/flat', async (req, res) => {
  try {
    const [rows] = await pool.execute(
      'SELECT code, categoria, name, norma, sub, note, precio FROM servicios WHERE activo = 1 ORDER BY code'
    );
    res.json({
      ok:   true,
      data: rows.map(r => ({ ...r, precio: r.precio !== null ? parseFloat(r.precio) : null })),
    });
  } catch (err) {
    res.status(500).json({ ok: false, message: 'Error al obtener servicios.' });
  }
});

module.exports = router;
