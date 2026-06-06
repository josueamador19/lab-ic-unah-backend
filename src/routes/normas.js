'use strict';
const { Router } = require('express');
const pool   = require('../database/connection');
const router = Router();

router.get('/normas', async (_req, res) => {
  try {
    const [cards] = await pool.execute(
      'SELECT id, icon_text, icon_style, title, sub, descripcion, tags FROM normas_cards WHERE activo = 1 ORDER BY orden'
    );
    const data = cards.map(c => ({
      id:         c.id,
      icon:       { text: c.icon_text, style: JSON.parse(c.icon_style) },
      title:      c.title,
      sub:        c.sub,
      desc:       c.descripcion,
      tags:       JSON.parse(c.tags),
    }))
    res.json({ ok: true, data })
  } catch {
    res.status(500).json({ ok: false, message: 'Error al obtener normas.' })
  }
})

router.get('/proceso', async (_req, res) => {
  try {
    const [rows] = await pool.execute(
      'SELECT numero, titulo, descripcion FROM proceso_pasos WHERE activo = 1 ORDER BY orden'
    )
    res.json({ ok: true, data: rows })
  } catch {
    res.status(500).json({ ok: false, message: 'Error al obtener proceso.' })
  }
})

module.exports = router
