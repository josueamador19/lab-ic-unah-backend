'use strict';
/**
 * Escribe una cotización como nueva fila en Google Sheets.
 *
 * Columnas (A → Q):
 * A  Timestamp        B  Nombre          C  Correo
 * D  Empresa          E  Teléfono        F  RTN
 * G  Nombre proyecto  H  Dir. proyecto   I  Códigos
 * J  Nombres          K  Normas          L  # Servicios
 * M  Muestras         N  Descripción     O  Latitud
 * P  Longitud         Q  Dir. mapa
 */
const { google }  = require('googleapis');
const config      = require('../config');

const SHEET_NAME  = 'Cotizaciones';
const RANGE       = `${SHEET_NAME}!A:Q`;
const SCOPES      = ['https://www.googleapis.com/auth/spreadsheets'];

const HEADER_ROW = [
  'Timestamp', 'Nombre', 'Correo', 'Empresa', 'Teléfono',
  'RTN', 'Nombre del proyecto', 'Dirección del proyecto',
  'Códigos', 'Servicios', 'Normas', '# Servicios',
  'Muestras por servicio', 'Descripción', 'Latitud', 'Longitud', 'Dirección (mapa)',
];

let _sheetsClient = null;

function _loadCredentials() {
  const raw = config.googleServiceAccountJson;
  if (!raw) return null;
  // Si parece JSON (producción/serverless), parsearlo directamente
  if (raw.trim().startsWith('{')) {
    try { return JSON.parse(raw); } catch { return null; }
  }
  // Si es una ruta de archivo (desarrollo local), leer el archivo
  try {
    return JSON.parse(require('fs').readFileSync(raw, 'utf8'));
  } catch { return null; }
}

async function getSheetsClient() {
  if (_sheetsClient) return _sheetsClient;

  const credentials = _loadCredentials();
  const auth = new google.auth.GoogleAuth({
    ...(credentials ? { credentials } : { keyFile: config.googleServiceAccountJson }),
    scopes: SCOPES,
  });
  _sheetsClient = google.sheets({ version: 'v4', auth });
  return _sheetsClient;
}

async function _ensureHeader(sheets) {
  const res = await sheets.spreadsheets.values.get({
    spreadsheetId: config.spreadsheetId,
    range:         `${SHEET_NAME}!A1:Q1`,
  });
  if (!res.data.values || res.data.values.length === 0) {
    await sheets.spreadsheets.values.update({
      spreadsheetId:     config.spreadsheetId,
      range:             `${SHEET_NAME}!A1`,
      valueInputOption:  'RAW',
      requestBody:       { values: [HEADER_ROW] },
    });
  }
}

async function appendCotizacion(data) {
  const sheets = await getSheetsClient();
  await _ensureHeader(sheets);

  const codigos      = data.servicios.map(s => s.code).join(', ');
  const nombres      = data.servicios.map(s => s.name).join(', ');
  const normas       = data.servicios.map(s => s.norma || '').join(', ');
  const muestrasCol  = data.servicios
    .filter(s => s.muestras != null)
    .map(s => `${s.muestras}×${s.code}`)
    .join(', ');

  const lat           = data.ubicacion?.lat           || '';
  const lng           = data.ubicacion?.lng           || '';
  const direccionMapa = data.ubicacion?.address       || '';

  const row = [
    new Date().toISOString().replace('T', ' ').slice(0, 19) + ' UTC',
    data.nombre,
    data.correo,
    data.empresa,
    data.telefono,
    data.rtn               || '',
    data.nombreProyecto,
    data.direccionProyecto || '',
    codigos,
    nombres,
    normas,
    data.servicios.length,
    muestrasCol,
    data.descripcion       || '',
    lat,
    lng,
    direccionMapa,
  ];

  const res = await sheets.spreadsheets.values.append({
    spreadsheetId:    config.spreadsheetId,
    range:            RANGE,
    valueInputOption: 'RAW',
    insertDataOption: 'INSERT_ROWS',
    requestBody:      { values: [row] },
  });

  const updatedRange = res.data.updates?.updatedRange || '';
  try {
    return parseInt(updatedRange.split('!')[1].split(':')[0].slice(1), 10);
  } catch {
    return -1;
  }
}

module.exports = { appendCotizacion };
