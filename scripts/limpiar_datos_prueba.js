'use strict';
require('dotenv').config({ path: require('path').join(__dirname, '../.env') });

const pool   = require('../src/database/connection');
const { google } = require('googleapis');
const config = require('../src/config');
const fs     = require('fs');
const path   = require('path');

async function limpiarMariaDB() {
  console.log('\n[MariaDB] Limpiando cotizaciones...');
  const [antes] = await pool.execute('SELECT COUNT(*) AS n FROM cotizaciones');
  console.log(`  Registros encontrados: ${antes[0].n}`);

  await pool.execute('DELETE FROM cotizacion_items');
  await pool.execute('DELETE FROM cotizaciones');
  await pool.execute('ALTER TABLE cotizaciones AUTO_INCREMENT = 1');
  await pool.execute('ALTER TABLE cotizacion_items AUTO_INCREMENT = 1');

  const [despues] = await pool.execute('SELECT COUNT(*) AS n FROM cotizaciones');
  console.log(`  Registros tras limpieza: ${despues[0].n}`);
  console.log('  [OK] MariaDB limpia — AUTO_INCREMENT reseteado a 1');
}

async function limpiarDocx() {
  console.log('\n[DOCX] Eliminando archivos generados...');
  const dir = path.join(__dirname, '../cotizaciones_generadas');
  if (!fs.existsSync(dir)) { console.log('  Carpeta vacía, nada que eliminar.'); return; }
  const files = fs.readdirSync(dir).filter(f => f.endsWith('.docx'));
  files.forEach(f => fs.unlinkSync(path.join(dir, f)));
  console.log(`  [OK] ${files.length} archivo(s) .docx eliminados`);
}

async function limpiarSheets() {
  console.log('\n[Sheets] Limpiando filas de prueba...');

  const keyFile = config.googleServiceAccountJson;
  if (!fs.existsSync(keyFile)) {
    console.log('  [SKIP] Credenciales no encontradas:', keyFile);
    return;
  }
  if (!config.spreadsheetId) {
    console.log('  [SKIP] SPREADSHEET_ID no configurado en .env');
    return;
  }

  const auth = new google.auth.GoogleAuth({
    keyFile,
    scopes: ['https://www.googleapis.com/auth/spreadsheets'],
  });
  const sheets = google.sheets({ version: 'v4', auth });
  const SHEET  = 'Cotizaciones';

  // Leer cuántas filas hay
  const info = await sheets.spreadsheets.values.get({
    spreadsheetId: config.spreadsheetId,
    range: `${SHEET}!A:A`,
  });
  const totalFilas = (info.data.values || []).length;
  console.log(`  Filas en Sheets (incluyendo encabezado): ${totalFilas}`);

  if (totalFilas <= 1) {
    console.log('  [OK] Sheets ya está vacío (solo encabezado)');
    return;
  }

  // Obtener el sheetId numérico necesario para batchUpdate
  const meta = await sheets.spreadsheets.get({ spreadsheetId: config.spreadsheetId });
  const sheet = meta.data.sheets.find(s => s.properties.title === SHEET);
  if (!sheet) {
    console.log(`  [ERROR] Pestaña "${SHEET}" no encontrada`);
    return;
  }
  const sheetId = sheet.properties.sheetId;

  // Eliminar filas 2 en adelante (conservar fila 1 = encabezado)
  await sheets.spreadsheets.batchUpdate({
    spreadsheetId: config.spreadsheetId,
    requestBody: {
      requests: [{
        deleteDimension: {
          range: {
            sheetId,
            dimension:  'ROWS',
            startIndex: 1,            // fila 2 (índice 1)
            endIndex:   totalFilas,   // hasta el final
          },
        },
      }],
    },
  });

  console.log(`  [OK] ${totalFilas - 1} fila(s) eliminadas de Google Sheets`);
  console.log('  Encabezado conservado en fila 1');
}

async function main() {
  console.log('================================================');
  console.log(' LIMPIEZA DE DATOS DE PRUEBA');
  console.log('================================================');

  try {
    await limpiarMariaDB();
    await limpiarDocx();
    await limpiarSheets();

    console.log('\n================================================');
    console.log(' LIMPIEZA COMPLETADA');
    console.log('================================================');
  } catch (err) {
    console.error('\n[ERROR]', err.message);
    process.exitCode = 1;
  } finally {
    await pool.end();
    process.exit(process.exitCode || 0);
  }
}

main();
