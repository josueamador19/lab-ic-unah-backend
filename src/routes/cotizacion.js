'use strict';
const { Router }            = require('express');
const pool                  = require('../database/connection');
const { CotizacionRequest } = require('../validators/cotizacion');
const { appendCotizacion }  = require('../services/sheetsService');
const { saveCotizacion }    = require('../services/cotizacionService');
const { sendConfirmation, sendAlert } = require('../services/emailService');
const { generarCotizacion } = require('../services/docxService');
const { uploadToS3, deleteFromS3 } = require('../services/s3Service');

const router = Router();

// ── POST /cotizacion ──────────────────────────────────────────────────────────
router.post('/cotizacion', async (req, res) => {
  const parsed = CotizacionRequest.safeParse(req.body);
  if (!parsed.success) {
    return res.status(422).json({
      ok:      false,
      message: 'Datos inválidos.',
      errors:  parsed.error.flatten().fieldErrors,
    });
  }

  const data = parsed.data;

  // 1. Guardar en MariaDB PRIMERO — garantizado aunque Sheets falle
  let dbResult;
  try {
    dbResult = await saveCotizacion(data, null, null);
  } catch (err) {
    console.error('[DB] Error crítico al guardar cotización:', err.message);
    return res.status(500).json({ ok: false, message: 'Error interno al guardar la solicitud.' });
  }

  const { id, numero } = dbResult;

  // 2. Generar .docx en memoria y subir a S3
  let docxBuffer = null, docxFilename = null, docxKey = null, docxUrl = null;
  try {
    const docx = generarCotizacion(data, numero);
    docxBuffer   = docx.buffer;
    docxFilename = docx.filename;
    const s3 = await uploadToS3(docxBuffer, docxFilename, 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', 'cotizaciones');
    docxKey = s3.key;
    docxUrl = s3.url;
    await pool.execute('UPDATE cotizaciones SET docx_key=?, docx_url=? WHERE id=?', [docxKey, docxUrl, id]);
  } catch (err) {
    console.error('[DOCX/S3]', err.message);
  }

  // 3. Google Sheets — no bloqueante
  let sheetsFila = null;
  try {
    sheetsFila = await appendCotizacion(data);
    await pool.execute(
      'UPDATE cotizaciones SET sheets_fila = ?, sheets_synced = 1 WHERE id = ?',
      [sheetsFila, id]
    );
  } catch (err) {
    console.error('[Sheets] Error (no crítico — cotización guardada en BD):', err.message);
    await pool.execute(
      "UPDATE cotizaciones SET sync_error = ? WHERE id = ?",
      [err.message.slice(0, 500), id]
    ).catch(() => {});
  }

  // 4. Correos — no bloqueantes
  const refId = sheetsFila || id;
  try { await sendConfirmation(data, refId); } catch (err) {
    console.error('[Email] Confirmación fallida:', err.message);
  }
  try { await sendAlert(data, refId, docxBuffer, docxFilename); } catch (err) {
    console.error('[Email] Alerta fallida:', err.message);
  }

  return res.status(201).json({
    ok:      true,
    message: 'Solicitud recibida. Le responderemos en 24–48 horas hábiles.',
    numero,
    id,
    fila: sheetsFila,
  });
});

// ── GET /cotizacion/:id/docx ──────────────────────────────────────────────────
router.get('/cotizacion/:id/docx', async (req, res) => {
  const id = parseInt(req.params.id, 10);
  if (isNaN(id)) return res.status(400).json({ ok: false, message: 'ID inválido.' });

  try {
    const [[row]] = await pool.execute(
      'SELECT numero_cotizacion, docx_url FROM cotizaciones WHERE id = ?', [id]
    );
    if (!row) return res.status(404).json({ ok: false, message: `Cotización ${id} no encontrada.` });
    if (!row.docx_url) return res.status(404).json({ ok: false, message: 'Archivo .docx no disponible.' });

    res.redirect(row.docx_url);
  } catch (err) {
    console.error('[DOCX] Descarga:', err.message);
    res.status(500).json({ ok: false, message: 'Error interno.' });
  }
});

module.exports = router;
