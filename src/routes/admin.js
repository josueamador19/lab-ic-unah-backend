'use strict';
const { Router }                    = require('express');
const crypto                        = require('crypto');
const pool                          = require('../database/connection');
const adminAuth                     = require('../middleware/adminAuth');
const upload                        = require('../middleware/upload');
const config                        = require('../config');
const { appendCotizacion }          = require('../services/sheetsService');
const { uploadToS3, deleteFromS3 }  = require('../services/s3Service');
const router                        = Router();

// ── Auth (timing-safe) ───────────────────────────────────────────────────────
router.post('/admin/auth', (req, res) => {
  const { password } = req.body ?? {};
  if (!password || !config.adminKey) {
    return res.status(401).json({ ok: false, message: 'Contraseña incorrecta.' });
  }
  try {
    const a = Buffer.from(String(password));
    const b = Buffer.from(config.adminKey);
    const valid = a.length === b.length && crypto.timingSafeEqual(a, b);
    if (valid) return res.json({ ok: true });
  } catch { /* longitudes distintas */ }
  res.status(401).json({ ok: false, message: 'Contraseña incorrecta.' });
});

// Todas las rutas siguientes requieren auth
router.use('/admin', adminAuth);

// ── Servicios ────────────────────────────────────────────────────────────────
router.get('/admin/servicios', async (_req, res) => {
  try {
    const [rows] = await pool.execute('SELECT * FROM servicios ORDER BY categoria, code');
    res.json({ ok: true, data: rows });
  } catch {
    res.status(500).json({ ok: false, message: 'Error.' });
  }
});

router.post('/admin/servicios', async (req, res) => {
  const { code, categoria, name, norma, sub, note, precio } = req.body ?? {};
  if (!code || !categoria || !name) {
    return res.status(400).json({ ok: false, message: 'code, categoria y name son requeridos.' });
  }
  try {
    const [r] = await pool.execute(
      'INSERT INTO servicios (code, categoria, name, norma, sub, note, precio) VALUES (?,?,?,?,?,?,?)',
      [code, categoria, name, norma ?? null, sub ?? null, note ?? null, precio ?? null]
    );
    res.status(201).json({ ok: true, id: r.insertId });
  } catch (e) {
    const msg = e.code === 'ER_DUP_ENTRY' ? 'El código ya existe.' : 'Error al crear servicio.';
    res.status(400).json({ ok: false, message: msg });
  }
});

router.put('/admin/servicios/:id', async (req, res) => {
  const { name, norma, sub, note, precio, activo } = req.body ?? {};
  try {
    await pool.execute(
      'UPDATE servicios SET name=?, norma=?, sub=?, note=?, precio=?, activo=? WHERE id=?',
      [name, norma ?? null, sub ?? null, note ?? null, precio ?? null, activo ?? 1, req.params.id]
    );
    res.json({ ok: true });
  } catch {
    res.status(500).json({ ok: false, message: 'Error al actualizar servicio.' });
  }
});

router.delete('/admin/servicios/:id', async (req, res) => {
  try {
    await pool.execute('DELETE FROM servicios WHERE id = ?', [req.params.id]);
    res.json({ ok: true });
  } catch {
    res.status(500).json({ ok: false, message: 'Error al eliminar servicio.' });
  }
});

// ── Equipos ──────────────────────────────────────────────────────────────────
router.get('/admin/equipos', async (_req, res) => {
  try {
    const [rows] = await pool.execute('SELECT * FROM equipos ORDER BY orden');
    res.json({ ok: true, data: rows });
  } catch {
    res.status(500).json({ ok: false, message: 'Error.' });
  }
});

router.post('/admin/equipos', upload.single('imagen'), async (req, res) => {
  const { title, descripcion, badge, orden } = req.body ?? {};
  if (!title || !descripcion) {
    return res.status(400).json({ ok: false, message: 'title y descripcion son requeridos.' });
  }
  try {
    let img_url = null, img_key = null;
    if (req.file) {
      const s3 = await uploadToS3(req.file.buffer, req.file.originalname, req.file.mimetype);
      img_url = s3.url;
      img_key = s3.key;
    }
    const [r] = await pool.execute(
      'INSERT INTO equipos (title, descripcion, badge, img_url, img_key, orden) VALUES (?,?,?,?,?,?)',
      [title, descripcion, badge ?? null, img_url, img_key, parseInt(orden) || 0]
    );
    res.status(201).json({ ok: true, id: r.insertId });
  } catch (err) {
    res.status(500).json({ ok: false, message: 'Error al crear equipo.' });
  }
});

router.put('/admin/equipos/:id', upload.single('imagen'), async (req, res) => {
  const { title, descripcion, badge, orden, activo } = req.body ?? {};
  try {
    if (req.file) {
      const [[row]] = await pool.execute('SELECT img_key FROM equipos WHERE id = ?', [req.params.id]);
      await deleteFromS3(row?.img_key);
      const s3 = await uploadToS3(req.file.buffer, req.file.originalname, req.file.mimetype);
      await pool.execute(
        'UPDATE equipos SET title=?, descripcion=?, badge=?, img_url=?, img_key=?, orden=?, activo=? WHERE id=?',
        [title, descripcion, badge ?? null, s3.url, s3.key, parseInt(orden) || 0, activo ?? 1, req.params.id]
      );
    } else {
      await pool.execute(
        'UPDATE equipos SET title=?, descripcion=?, badge=?, orden=?, activo=? WHERE id=?',
        [title, descripcion, badge ?? null, parseInt(orden) || 0, activo ?? 1, req.params.id]
      );
    }
    res.json({ ok: true });
  } catch {
    res.status(500).json({ ok: false, message: 'Error al actualizar equipo.' });
  }
});

router.delete('/admin/equipos/:id', async (req, res) => {
  try {
    const [[row]] = await pool.execute('SELECT img_key FROM equipos WHERE id = ?', [req.params.id]);
    await deleteFromS3(row?.img_key);
    await pool.execute('DELETE FROM equipos WHERE id = ?', [req.params.id]);
    res.json({ ok: true });
  } catch {
    res.status(500).json({ ok: false, message: 'Error al eliminar equipo.' });
  }
});

// ── Configuración ────────────────────────────────────────────────────────────
router.get('/admin/configuracion', async (_req, res) => {
  try {
    const [rows] = await pool.execute('SELECT clave, label, valor FROM configuracion');
    res.json({ ok: true, data: rows });
  } catch {
    res.status(500).json({ ok: false, message: 'Error.' });
  }
});

router.put('/admin/configuracion', async (req, res) => {
  const updates = req.body ?? {};
  if (!Object.keys(updates).length) {
    return res.status(400).json({ ok: false, message: 'No hay datos para actualizar.' });
  }
  try {
    const promises = Object.entries(updates).map(([clave, valor]) =>
      pool.execute('UPDATE configuracion SET valor = ? WHERE clave = ?', [valor, clave])
    );
    await Promise.all(promises);
    res.json({ ok: true });
  } catch {
    res.status(500).json({ ok: false, message: 'Error al guardar configuración.' });
  }
});

// ── Normas cards ─────────────────────────────────────────────────────────────
router.get('/admin/normas', async (_req, res) => {
  try {
    const [rows] = await pool.execute('SELECT * FROM normas_cards ORDER BY orden');
    res.json({ ok: true, data: rows });
  } catch {
    res.status(500).json({ ok: false, message: 'Error.' });
  }
});

router.post('/admin/normas', async (req, res) => {
  const { id, icon_text, icon_style, title, sub, descripcion, tags } = req.body ?? {};
  if (!id || !icon_text || !icon_style || !title || !sub || !descripcion) {
    return res.status(400).json({ ok: false, message: 'id, icon_text, icon_style, title, sub y descripcion son requeridos.' });
  }
  try {
    const [[{ maxOrden }]] = await pool.execute('SELECT COALESCE(MAX(orden), 0) AS maxOrden FROM normas_cards');
    await pool.execute(
      'INSERT INTO normas_cards (id, icon_text, icon_style, title, sub, descripcion, tags, orden) VALUES (?,?,?,?,?,?,?,?)',
      [
        id,
        icon_text,
        typeof icon_style === 'object' ? JSON.stringify(icon_style) : icon_style,
        title,
        sub,
        descripcion,
        JSON.stringify(Array.isArray(tags) ? tags : JSON.parse(tags || '[]')),
        maxOrden + 1,
      ]
    );
    res.status(201).json({ ok: true, id });
  } catch (e) {
    const msg = e.code === 'ER_DUP_ENTRY' ? 'Ya existe una norma con ese ID.' : 'Error al crear norma.';
    res.status(400).json({ ok: false, message: msg });
  }
});

router.put('/admin/normas/reorder', async (req, res) => {
  const { items } = req.body ?? {};
  if (!Array.isArray(items)) {
    return res.status(400).json({ ok: false, message: 'items debe ser un array.' });
  }
  try {
    for (const { id, orden } of items) {
      await pool.execute('UPDATE normas_cards SET orden=? WHERE id=?', [orden, id]);
    }
    res.json({ ok: true });
  } catch (err) {
    console.error('[reorder normas]', err);
    res.status(500).json({ ok: false, message: err.message });
  }
});

router.delete('/admin/normas/:id', async (req, res) => {
  try {
    await pool.execute('DELETE FROM normas_cards WHERE id = ?', [req.params.id]);
    res.json({ ok: true });
  } catch {
    res.status(500).json({ ok: false, message: 'Error al eliminar norma.' });
  }
});

router.put('/admin/normas/:id', async (req, res) => {
  const { title, sub, descripcion, tags, activo } = req.body ?? {};
  try {
    await pool.execute(
      'UPDATE normas_cards SET title=?, sub=?, descripcion=?, tags=?, activo=? WHERE id=?',
      [title, sub, descripcion, JSON.stringify(Array.isArray(tags) ? tags : JSON.parse(tags || '[]')), activo ?? 1, req.params.id]
    );
    res.json({ ok: true });
  } catch {
    res.status(500).json({ ok: false, message: 'Error al actualizar norma.' });
  }
});

// ── Proceso pasos ─────────────────────────────────────────────────────────────
router.get('/admin/proceso', async (_req, res) => {
  try {
    const [rows] = await pool.execute('SELECT * FROM proceso_pasos ORDER BY orden');
    res.json({ ok: true, data: rows });
  } catch {
    res.status(500).json({ ok: false, message: 'Error.' });
  }
});

router.post('/admin/proceso', async (req, res) => {
  const { titulo, descripcion } = req.body ?? {};
  if (!titulo || !descripcion) {
    return res.status(400).json({ ok: false, message: 'titulo y descripcion son requeridos.' });
  }
  try {
    const [[{ maxOrden }]] = await pool.execute('SELECT COALESCE(MAX(orden), 0) AS maxOrden FROM proceso_pasos');
    const newOrden = maxOrden + 1;
    const numero   = String(newOrden).padStart(2, '0');
    const [r] = await pool.execute(
      'INSERT INTO proceso_pasos (numero, titulo, descripcion, orden) VALUES (?,?,?,?)',
      [numero, titulo, descripcion, newOrden]
    );
    res.status(201).json({ ok: true, id: r.insertId });
  } catch {
    res.status(500).json({ ok: false, message: 'Error al crear paso.' });
  }
});

router.put('/admin/proceso/reorder', async (req, res) => {
  const { items } = req.body ?? {};
  if (!Array.isArray(items)) {
    return res.status(400).json({ ok: false, message: 'items debe ser un array.' });
  }
  try {
    for (const { id, orden } of items) {
      const numero = String(orden).padStart(2, '0');
      await pool.execute('UPDATE proceso_pasos SET orden=?, numero=? WHERE id=?', [orden, numero, id]);
    }
    res.json({ ok: true });
  } catch (err) {
    console.error('[reorder proceso]', err);
    res.status(500).json({ ok: false, message: err.message });
  }
});

router.delete('/admin/proceso/:id', async (req, res) => {
  try {
    await pool.execute('DELETE FROM proceso_pasos WHERE id = ?', [req.params.id]);
    res.json({ ok: true });
  } catch {
    res.status(500).json({ ok: false, message: 'Error al eliminar paso.' });
  }
});

router.put('/admin/proceso/:id', async (req, res) => {
  const { titulo, descripcion, activo } = req.body ?? {};
  try {
    await pool.execute(
      'UPDATE proceso_pasos SET titulo=?, descripcion=?, activo=? WHERE id=?',
      [titulo, descripcion, activo ?? 1, req.params.id]
    );
    res.json({ ok: true });
  } catch {
    res.status(500).json({ ok: false, message: 'Error al actualizar paso.' });
  }
});

// ── Cotizaciones (backup + retry Sheets) ─────────────────────────────────────
router.get('/admin/cotizaciones', async (req, res) => {
  try {
    const page  = Math.max(1, parseInt(req.query.page  || '1', 10));
    const limit = Math.min(50, Math.max(1, parseInt(req.query.limit || '20', 10)));
    const offset = (page - 1) * limit;

    const [[{ total }]] = await pool.execute('SELECT COUNT(*) as total FROM cotizaciones');
    const [rows] = await pool.execute(
      `SELECT id, numero_cotizacion, nombre, correo, empresa, telefono,
              nombre_proyecto, subtotal, sheets_fila, sheets_synced, sync_error,
              created_at
       FROM cotizaciones ORDER BY created_at DESC LIMIT ? OFFSET ?`,
      [limit, offset]
    );
    res.json({ ok: true, data: rows, total, page, pages: Math.ceil(total / limit) });
  } catch {
    res.status(500).json({ ok: false, message: 'Error.' });
  }
});

router.get('/admin/cotizaciones/:id', async (req, res) => {
  const id = parseInt(req.params.id, 10);
  if (isNaN(id)) return res.status(400).json({ ok: false, message: 'ID inválido.' });
  try {
    const [[cot]] = await pool.execute('SELECT * FROM cotizaciones WHERE id = ?', [id]);
    if (!cot) return res.status(404).json({ ok: false, message: 'Cotización no encontrada.' });

    const [items] = await pool.execute(
      `SELECT servicio_code AS code, servicio_name AS name, norma, sub,
              muestras, precio, total
       FROM cotizacion_items WHERE cotizacion_id = ? ORDER BY id`,
      [id]
    );
    res.json({ ok: true, data: { ...cot, items } });
  } catch {
    res.status(500).json({ ok: false, message: 'Error.' });
  }
});

router.delete('/admin/cotizaciones/:id', async (req, res) => {
  const id = parseInt(req.params.id, 10);
  if (isNaN(id)) return res.status(400).json({ ok: false, message: 'ID inválido.' });
  try {
    const [[cot]] = await pool.execute('SELECT docx_key FROM cotizaciones WHERE id = ?', [id]);
    if (!cot) return res.status(404).json({ ok: false, message: 'Cotización no encontrada.' });
    await deleteFromS3(cot.docx_key);
    await pool.execute('DELETE FROM cotizaciones WHERE id = ?', [id]);
    res.json({ ok: true });
  } catch {
    res.status(500).json({ ok: false, message: 'Error al eliminar.' });
  }
});

router.post('/admin/cotizaciones/:id/sync-sheets', async (req, res) => {
  const id = parseInt(req.params.id, 10);
  if (isNaN(id)) return res.status(400).json({ ok: false, message: 'ID inválido.' });

  try {
    // Reconstruir payload desde BD
    const [[cot]] = await pool.execute('SELECT * FROM cotizaciones WHERE id = ?', [id]);
    if (!cot) return res.status(404).json({ ok: false, message: 'Cotización no encontrada.' });
    if (cot.sheets_synced) return res.json({ ok: true, message: 'Ya sincronizada.', fila: cot.sheets_fila });

    const [items] = await pool.execute(
      'SELECT servicio_code as code, servicio_name as name, norma, sub, muestras, precio FROM cotizacion_items WHERE cotizacion_id = ?',
      [id]
    );

    const payload = {
      nombre:            cot.nombre,
      correo:            cot.correo,
      empresa:           cot.empresa,
      telefono:          cot.telefono,
      rtn:               cot.rtn,
      nombreProyecto:    cot.nombre_proyecto,
      direccionProyecto: cot.direccion_proyecto,
      descripcion:       cot.descripcion,
      servicios:         items,
      ubicacion:         cot.lat ? { lat: cot.lat, lng: cot.lng, address: cot.direccion_mapa } : null,
    };

    const fila = await appendCotizacion(payload);
    await pool.execute(
      'UPDATE cotizaciones SET sheets_fila = ?, sheets_synced = 1, sync_error = NULL WHERE id = ?',
      [fila, id]
    );
    res.json({ ok: true, fila });
  } catch (err) {
    await pool.execute(
      'UPDATE cotizaciones SET sync_error = ? WHERE id = ?',
      [err.message.slice(0, 500), id]
    ).catch(() => {});
    res.status(502).json({ ok: false, message: `Error sincronizando con Sheets: ${err.message}` });
  }
});

// ── FAQ ───────────────────────────────────────────────────────────────────────
router.get('/admin/faq', async (_req, res) => {
  try {
    const [rows] = await pool.execute('SELECT * FROM faq ORDER BY orden');
    res.json({ ok: true, data: rows });
  } catch {
    res.status(500).json({ ok: false, message: 'Error.' });
  }
});

router.post('/admin/faq', async (req, res) => {
  const { pregunta, respuesta, orden } = req.body ?? {};
  if (!pregunta || !respuesta) {
    return res.status(400).json({ ok: false, message: 'pregunta y respuesta son requeridas.' });
  }
  try {
    const [r] = await pool.execute(
      'INSERT INTO faq (pregunta, respuesta, orden) VALUES (?,?,?)',
      [pregunta, respuesta, parseInt(orden) || 0]
    );
    res.status(201).json({ ok: true, id: r.insertId });
  } catch {
    res.status(500).json({ ok: false, message: 'Error al crear FAQ.' });
  }
});

router.put('/admin/faq/:id', async (req, res) => {
  const { pregunta, respuesta, orden, activo } = req.body ?? {};
  try {
    await pool.execute(
      'UPDATE faq SET pregunta=?, respuesta=?, orden=?, activo=? WHERE id=?',
      [pregunta, respuesta, parseInt(orden) || 0, activo ?? 1, req.params.id]
    );
    res.json({ ok: true });
  } catch {
    res.status(500).json({ ok: false, message: 'Error al actualizar FAQ.' });
  }
});

router.delete('/admin/faq/:id', async (req, res) => {
  try {
    await pool.execute('DELETE FROM faq WHERE id = ?', [req.params.id]);
    res.json({ ok: true });
  } catch {
    res.status(500).json({ ok: false, message: 'Error al eliminar FAQ.' });
  }
});

module.exports = router;
