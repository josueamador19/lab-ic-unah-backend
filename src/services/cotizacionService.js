'use strict';
const pool = require('../database/connection');

function numeroCotizacion(id) {
  const year = new Date().getFullYear();
  return `COT-${String(id).padStart(4, '0')}-${year}`;
}

async function saveCotizacion(data, sheetsFila, docxPath) {
  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();

    const subtotal = data.servicios.reduce((acc, s) => {
      return acc + (s.muestras || 0) * (s.precio || 0);
    }, 0);

    const lat           = data.ubicacion?.lat     || null;
    const lng           = data.ubicacion?.lng     || null;
    const direccionMapa = data.ubicacion?.address || null;

    const [result] = await conn.execute(
      `INSERT INTO cotizaciones
        (numero_cotizacion, nombre, correo, empresa, telefono, rtn,
         nombre_proyecto, direccion_proyecto, descripcion,
         lat, lng, direccion_mapa, subtotal, sheets_fila, docx_path)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        '',  // placeholder — se actualiza abajo con el ID real
        data.nombre,
        data.correo,
        data.empresa,
        data.telefono,
        data.rtn               || null,
        data.nombreProyecto,
        data.direccionProyecto || null,
        data.descripcion       || null,
        lat,
        lng,
        direccionMapa,
        subtotal,
        sheetsFila             || null,
        docxPath               || null,
      ]
    );

    const id = result.insertId;
    const numero = numeroCotizacion(id);
    await conn.execute(
      'UPDATE cotizaciones SET numero_cotizacion = ? WHERE id = ?',
      [numero, id]
    );

    if (data.servicios.length > 0) {
      const itemValues = data.servicios.map(s => {
        const total = (s.muestras || 0) * (s.precio || 0);
        return [id, s.code, s.name, s.norma || null, s.sub || null, s.muestras || null, s.precio || null, total];
      });
      await conn.query(
        `INSERT INTO cotizacion_items
          (cotizacion_id, servicio_code, servicio_name, norma, sub, muestras, precio, total)
         VALUES ?`,
        [itemValues]
      );
    }

    await conn.commit();
    return { id, numero };
  } catch (err) {
    await conn.rollback();
    throw err;
  } finally {
    conn.release();
  }
}

async function getCotizacionById(id) {
  const [rows] = await pool.execute(
    `SELECT c.*, GROUP_CONCAT(ci.servicio_name SEPARATOR ', ') AS servicios_nombres
     FROM cotizaciones c
     LEFT JOIN cotizacion_items ci ON ci.cotizacion_id = c.id
     WHERE c.id = ?
     GROUP BY c.id`,
    [id]
  );
  return rows[0] || null;
}

module.exports = { saveCotizacion, getCotizacionById, numeroCotizacion };
