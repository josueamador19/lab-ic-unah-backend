'use strict';
const path          = require('path');
const fs            = require('fs');
const PizZip        = require('pizzip');
const Docxtemplater = require('docxtemplater');

const TEMPLATE = path.join(__dirname, '..', '..', 'plantilla_cotizacion.docx');

function fmt(value) {
  return Number(value || 0).toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

function buildTemplateData(data, numero) {
  const hoy = new Date().toLocaleDateString('es-HN', {
    day: '2-digit', month: '2-digit', year: 'numeric',
  });

  const direccionMapa = data.ubicacion
    ? (data.ubicacion.address || `${data.ubicacion.lat}, ${data.ubicacion.lng}`)
    : '';

  const templateData = {
    NUM_COT:            numero,
    NOMBRE:             data.nombre,
    EMPRESA:            data.empresa,
    DIRECCION_MAPA:     direccionMapa,
    TELEFONO:           data.telefono,
    CORREO:             data.correo,
    RTN:                data.rtn || '',
    FECHA:              hoy,
    NOMBRE_PROYECTO:    data.nombreProyecto,
    DIRECCION_PROYECTO: data.direccionProyecto || '',
    DESCRIPCION:        data.descripcion || '',
    CONTACTO:           `${data.correo}  |  ${data.telefono}`,
  };

  const servicios = (data.servicios || []).slice(0, 10);
  let subtotal = 0;

  for (let i = 1; i <= 10; i++) {
    const svc = servicios[i - 1];
    if (svc) {
      const muestras = svc.muestras || 0;
      const precio   = parseFloat(svc.precio || 0);
      const total    = muestras * precio;
      subtotal      += total;

      templateData[`S${i}_DESC`]     = svc.name + (svc.sub ? ` (${svc.sub})` : '');
      templateData[`S${i}_NORMA`]    = svc.norma || '';
      templateData[`S${i}_MUESTRAS`] = muestras ? String(muestras) : '';
      templateData[`S${i}_PRECIO`]   = fmt(precio);
      templateData[`S${i}_TOTAL`]    = fmt(total);
    } else {
      templateData[`S${i}_DESC`]     = '';
      templateData[`S${i}_NORMA`]    = '';
      templateData[`S${i}_MUESTRAS`] = '';
      templateData[`S${i}_PRECIO`]   = '';
      templateData[`S${i}_TOTAL`]    = '';
    }
  }

  templateData.SUBTOTAL = fmt(subtotal);
  templateData.TOTAL    = fmt(subtotal);

  return templateData;
}

// Devuelve { buffer, filename } — sin escritura en disco (compatible serverless)
function generarCotizacion(data, numero) {
  if (!fs.existsSync(TEMPLATE)) {
    throw new Error(`Plantilla no encontrada: ${TEMPLATE}`);
  }

  const content = fs.readFileSync(TEMPLATE, 'binary');
  const zip     = new PizZip(content);
  const doc     = new Docxtemplater(zip, {
    paragraphLoop: true,
    linebreaks:    true,
  });

  doc.render(buildTemplateData(data, numero));

  const buffer   = doc.getZip().generate({ type: 'nodebuffer' });
  const filename = `${numero}.docx`;

  return { buffer, filename };
}

module.exports = { generarCotizacion };
