'use strict';
require('dotenv').config();
const path      = require('path');
const express   = require('express');
const cors      = require('cors');
const helmet    = require('helmet');
const rateLimit = require('express-rate-limit');
const config    = require('./config');

const healthRouter        = require('./routes/health');
const cotizacionRouter    = require('./routes/cotizacion');
const serviciosRouter     = require('./routes/servicios');
const equiposRouter       = require('./routes/equipos');
const configuracionRouter = require('./routes/configuracion');
const normasRouter        = require('./routes/normas');
const faqRouter           = require('./routes/faq');
const adminRouter         = require('./routes/admin');

const app = express();

// ── Seguridad: cabeceras HTTP ─────────────────────────────────────────────────
app.use(helmet({
  crossOriginResourcePolicy: { policy: 'cross-origin' },
}));

// ── CORS ──────────────────────────────────────────────────────────────────────
app.use(cors({ origin: config.cors.origins, credentials: true }));

// ── Rate limiting ─────────────────────────────────────────────────────────────
app.use('/api/v1/admin/auth', rateLimit({
  windowMs: 15 * 60 * 1000, max: 10,
  standardHeaders: true, legacyHeaders: false,
  message: { ok: false, message: 'Demasiados intentos. Espere 15 minutos.' },
}));
app.use('/api/v1/cotizacion', rateLimit({
  windowMs: 5 * 60 * 1000, max: 10,
  standardHeaders: true, legacyHeaders: false,
  message: { ok: false, message: 'Demasiadas solicitudes. Intente en unos minutos.' },
}));

app.use(express.json({ limit: '2mb' }));

// ── Estáticos (solo desarrollo — en producción las imágenes van a S3) ─────────
if (config.env !== 'production') {
  app.use(express.static(path.join(__dirname, '../public')));
}

// ── Rutas ─────────────────────────────────────────────────────────────────────
const API = '/api/v1';
app.use(API, healthRouter);
app.use(API, cotizacionRouter);
app.use(API, serviciosRouter);
app.use(API, equiposRouter);
app.use(API, configuracionRouter);
app.use(API, normasRouter);
app.use(API, faqRouter);
app.use(API, adminRouter);

// ── 404 ───────────────────────────────────────────────────────────────────────
app.use((_req, res) => {
  res.status(404).json({ ok: false, message: 'Ruta no encontrada.' });
});

// ── Error handler ─────────────────────────────────────────────────────────────
app.use((err, _req, res, _next) => {
  console.error('[Unhandled]', err);
  res.status(500).json({ ok: false, message: 'Error interno del servidor.' });
});

module.exports = app;
