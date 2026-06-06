'use strict';
const nodemailer = require('nodemailer');
const config     = require('../config');

function getTransporter() {
  return nodemailer.createTransport({
    service: 'gmail',
    auth: {
      user: config.smtp.user,
      pass: config.smtp.pass,
    },
  });
}

// ── HTML helpers ──────────────────────────────────────────────────────────────

function infoRow(label, value) {
  return `<p style="margin:0 0 6px;font-size:13px;color:#374151;">
    <strong>${label}:</strong> ${value}</p>`;
}

function optionalInfoRow(label, value) {
  return value ? infoRow(label, value) : '';
}

function serviciosTableHeader() {
  const cols = ['Código', 'Ensayo', 'Norma', 'Muestras'];
  const ths  = cols.map(c =>
    `<th style="padding:10px 14px;text-align:left;font-size:10px;font-weight:700;
      color:#6b7280;letter-spacing:.06em;text-transform:uppercase;
      border-bottom:1px solid #e5e7eb;">${c}</th>`
  ).join('');
  return `<tr style="background:#f1f5f9;">${ths}</tr>`;
}

function buildServiciosRows(data) {
  return data.servicios.map(svc => {
    const subHtml = svc.sub
      ? `<br/><span style="font-size:11px;color:#6b7280;font-style:italic">${svc.sub}</span>`
      : '';
    const muestrasCell = svc.muestras != null
      ? `<td style="padding:10px 14px;border-bottom:1px solid #e5e7eb;font-size:13px;
           color:#1e3a8a;font-weight:700;text-align:center">${svc.muestras}</td>`
      : `<td style="padding:10px 14px;border-bottom:1px solid #e5e7eb;font-size:11px;
           color:#9ca3af;text-align:center">—</td>`;

    return `<tr>
      <td style="padding:10px 14px;border-bottom:1px solid #e5e7eb;">
        <span style="display:inline-block;background:#dbeafe;color:#1e40af;
          font-weight:700;font-size:11px;padding:2px 8px;border-radius:5px;">${svc.code}</span>
      </td>
      <td style="padding:10px 14px;border-bottom:1px solid #e5e7eb;font-size:13px;color:#1f2937;">
        ${svc.name}${subHtml}
      </td>
      <td style="padding:10px 14px;border-bottom:1px solid #e5e7eb;font-size:11px;color:#6b7280;">
        ${svc.norma || '—'}
      </td>
      ${muestrasCell}
    </tr>`;
  }).join('');
}

function serviciosTxt(data) {
  return data.servicios.map(s => {
    const muestras = s.muestras != null
      ? ` — ${s.muestras} muestra${s.muestras !== 1 ? 's' : ''}`
      : '';
    return `  • [${s.code}] ${s.name} — ${s.norma || '—'}${muestras}`;
  }).join('\n');
}

// ── Correo de confirmación al solicitante ─────────────────────────────────────

function buildHtml(data) {
  const nombreCorto = data.nombre.trim().split(' ')[0];
  const cantidad    = data.servicios.length;
  const plural      = cantidad > 1 ? 's' : '';

  const descripcionHtml = data.descripcion
    ? `<div style="margin-top:24px;padding:16px 20px;background:#f9fafb;
         border-left:4px solid #3b5bdb;border-radius:0 8px 8px 0;">
         <p style="margin:0 0 4px;font-size:10px;font-weight:700;color:#6b7280;
           letter-spacing:.08em;text-transform:uppercase;">Detalles adicionales</p>
         <p style="margin:0;font-size:13px;color:#374151;line-height:1.6;">${data.descripcion}</p>
       </div>`
    : '';

  return `<!DOCTYPE html>
<html lang="es">
<head><meta charset="UTF-8"/><meta name="viewport" content="width=device-width,initial-scale=1.0"/></head>
<body style="margin:0;padding:0;background:#f3f4f6;font-family:'Segoe UI',Arial,sans-serif;">
<table width="100%" cellpadding="0" cellspacing="0" style="background:#f3f4f6;padding:40px 16px;">
<tr><td align="center">
<table width="620" cellpadding="0" cellspacing="0" style="max-width:620px;width:100%;">

  <tr>
    <td style="background:linear-gradient(135deg,#1e3a8a 0%,#3b5bdb 100%);
               border-radius:16px 16px 0 0;padding:36px 40px;text-align:center;">
      <p style="margin:0 0 6px;font-size:11px;font-weight:700;color:#93c5fd;
                letter-spacing:.12em;text-transform:uppercase;">
        Universidad Nacional Autónoma de Honduras
      </p>
      <h1 style="margin:0 0 4px;font-size:22px;font-weight:800;color:#ffffff;">
        Laboratorios de Ingeniería Civil
      </h1>
      <p style="margin:0;font-size:12px;color:#bfdbfe;">
        Departamento de Ingeniería Civil &nbsp;·&nbsp; Edificio B1, Primer Nivel
      </p>
    </td>
  </tr>

  <tr>
    <td style="background:#ffffff;padding:36px 40px;">
      <p style="margin:0 0 16px;font-size:16px;font-weight:700;color:#1e3a8a;">
        Hola, ${nombreCorto}
      </p>
      <p style="margin:0 0 24px;font-size:14px;color:#374151;line-height:1.7;">
        Hemos recibido su solicitud de cotización correctamente.
        Nuestro equipo técnico la revisará y le enviará una propuesta formal
        en un plazo de <strong>24 a 48 horas hábiles</strong>.
      </p>

      <div style="background:#f8faff;border:1px solid #e0e7ff;border-radius:10px;
                  padding:18px 22px;margin-bottom:16px;">
        <p style="margin:0 0 10px;font-size:10px;font-weight:700;color:#6b7280;
                  letter-spacing:.08em;text-transform:uppercase;">Datos de su solicitud</p>
        ${infoRow('Nombre', data.nombre)}
        ${infoRow('Correo', data.correo)}
        ${infoRow('Empresa / Institución', data.empresa)}
        ${infoRow('Teléfono', data.telefono)}
        ${optionalInfoRow('RTN', data.rtn)}
      </div>

      <div style="background:#f0f9ff;border:1px solid #bae6fd;border-radius:10px;
                  padding:18px 22px;margin-bottom:24px;">
        <p style="margin:0 0 10px;font-size:10px;font-weight:700;color:#6b7280;
                  letter-spacing:.08em;text-transform:uppercase;">Datos del proyecto</p>
        ${infoRow('Nombre del proyecto', data.nombreProyecto)}
        ${optionalInfoRow('Dirección del proyecto', data.direccionProyecto)}
      </div>

      <p style="margin:0 0 10px;font-size:10px;font-weight:700;color:#6b7280;
                letter-spacing:.08em;text-transform:uppercase;">
        Ensayo${plural} solicitado${plural} (${cantidad})
      </p>
      <table width="100%" cellpadding="0" cellspacing="0"
             style="border:1px solid #e5e7eb;border-radius:10px;
                    overflow:hidden;border-collapse:collapse;margin-bottom:24px;">
        <thead>${serviciosTableHeader()}</thead>
        <tbody>${buildServiciosRows(data)}</tbody>
      </table>

      ${descripcionHtml}

      <div style="margin-top:28px;background:#fffbeb;border:1px solid #fde68a;
                  border-radius:10px;padding:18px 22px;">
        <p style="margin:0 0 8px;font-size:10px;font-weight:700;color:#92400e;
                  letter-spacing:.08em;text-transform:uppercase;">¿Qué sigue?</p>
        <p style="margin:0 0 6px;font-size:13px;color:#78350f;line-height:1.6;">
          📋 &nbsp;Revisaremos su solicitud y prepararemos la propuesta.
        </p>
        <p style="margin:0 0 6px;font-size:13px;color:#78350f;line-height:1.6;">
          📧 &nbsp;Recibirá un correo con los detalles del pago en <strong>24–48 h hábiles</strong>.
        </p>
        <p style="margin:0;font-size:13px;color:#78350f;line-height:1.6;">
          🏛️ &nbsp;Entrega de muestras: Edificio B1, 1er nivel — Lun–Vie 8:00 AM–3:00 PM.
        </p>
      </div>
    </td>
  </tr>

  <tr>
    <td style="background:#1e3a8a;border-radius:0 0 16px 16px;
               padding:24px 40px;text-align:center;">
      <p style="margin:0 0 4px;font-size:13px;font-weight:700;color:#ffffff;">
        Ing. Joel Francisco Amador R.
      </p>
      <p style="margin:0 0 10px;font-size:11px;color:#93c5fd;">
        Jefe de Laboratorios — Ingeniería Civil UNAH
      </p>
      <p style="margin:0;font-size:11px;color:#64748b;">
        ✉️ &nbsp;jefatura.labs.ic@unah.edu.hn
        &nbsp;·&nbsp;
        🏛️ &nbsp;Ciudad Universitaria, Tegucigalpa
      </p>
      <p style="margin:12px 0 0;font-size:10px;color:#475569;">
        Este es un correo automático, por favor no responda a este mensaje.
      </p>
    </td>
  </tr>

</table>
</td></tr>
</table>
</body>
</html>`;
}

function buildPlain(data) {
  const nombreCorto = data.nombre.trim().split(' ')[0];
  const rtnTxt      = data.rtn               ? `\n  RTN      : ${data.rtn}`               : '';
  const dirProyTxt  = data.direccionProyecto ? `\n  Dirección: ${data.direccionProyecto}` : '';

  return `Hola, ${nombreCorto}.

Hemos recibido su solicitud de cotización correctamente.
Le responderemos en un plazo de 24 a 48 horas hábiles.

DATOS DE SU SOLICITUD
  Nombre   : ${data.nombre}
  Correo   : ${data.correo}
  Empresa  : ${data.empresa}
  Teléfono : ${data.telefono}${rtnTxt}

PROYECTO
  Nombre   : ${data.nombreProyecto}${dirProyTxt}

SERVICIOS SOLICITADOS:
${serviciosTxt(data)}

${data.descripcion ? 'DETALLES: ' + data.descripcion : ''}

¿Qué sigue?
  1. Revisaremos su solicitud y prepararemos la propuesta.
  2. Recibirá un correo con los detalles del pago en 24–48 h hábiles.
  3. Entrega de muestras: Edificio B1, 1er nivel — Lun–Vie 8:00 AM–3:00 PM.

---
Ing. Joel Francisco Amador R.
Jefe de Laboratorios — Ingeniería Civil UNAH
jefatura.labs.ic@unah.edu.hn
Ciudad Universitaria, Tegucigalpa, Honduras

Este es un correo automático, por favor no responda a este mensaje.
`;
}

// ── HTML correo de alerta interna ─────────────────────────────────────────────

function buildAlertHtml(data, fila) {
  const cantidad = data.servicios.length;
  const plural   = cantidad > 1 ? 's' : '';

  const descripcionHtml = data.descripcion
    ? `<div style="margin-top:16px;padding:14px 18px;background:#f9fafb;
         border-left:4px solid #f59e0b;border-radius:0 8px 8px 0;">
         <p style="margin:0 0 4px;font-size:10px;font-weight:700;color:#6b7280;
           letter-spacing:.08em;text-transform:uppercase;">Detalles adicionales</p>
         <p style="margin:0;font-size:13px;color:#374151;line-height:1.6;">${data.descripcion}</p>
       </div>`
    : '';

  const ubicacionHtml = data.ubicacion
    ? `<div style="margin-top:16px;padding:14px 18px;background:#f0fdf4;
         border:1px solid #86efac;border-radius:10px;">
         <p style="margin:0 0 4px;font-size:10px;font-weight:700;color:#166534;
           letter-spacing:.08em;text-transform:uppercase;">Ubicación del proyecto (mapa)</p>
         <p style="margin:0;font-size:13px;color:#166534;">
           ${data.ubicacion.address || `${data.ubicacion.lat}, ${data.ubicacion.lng}`}
         </p>
       </div>`
    : '';

  return `<!DOCTYPE html>
<html lang="es">
<head><meta charset="UTF-8"/><meta name="viewport" content="width=device-width,initial-scale=1.0"/></head>
<body style="margin:0;padding:0;background:#f3f4f6;font-family:'Segoe UI',Arial,sans-serif;">
<table width="100%" cellpadding="0" cellspacing="0" style="background:#f3f4f6;padding:40px 16px;">
<tr><td align="center">
<table width="620" cellpadding="0" cellspacing="0" style="max-width:620px;width:100%;">

  <tr>
    <td style="background:linear-gradient(135deg,#064e3b 0%,#059669 100%);
               border-radius:16px 16px 0 0;padding:28px 40px;text-align:center;">
      <p style="margin:0 0 6px;font-size:11px;font-weight:700;color:#6ee7b7;
                letter-spacing:.12em;text-transform:uppercase;">
        Alerta interna — Lab. Ingeniería Civil UNAH
      </p>
      <h1 style="margin:0 0 4px;font-size:20px;font-weight:800;color:#ffffff;">
        Nueva solicitud de cotización
      </h1>
      <p style="margin:0;font-size:12px;color:#a7f3d0;">
        Referencia de fila en Sheets: <strong style="color:#fff;">#${fila}</strong>
      </p>
    </td>
  </tr>

  <tr>
    <td style="background:#ffffff;padding:32px 40px;">
      <div style="margin-bottom:24px;padding:14px 18px;background:#f0fdf4;
                  border:1px solid #86efac;border-radius:10px;">
        <p style="margin:0;font-size:13px;color:#166534;line-height:1.5;">
          📎 <strong>Cotización Word adjunta.</strong>
          Ábrala, agregue los precios y envíela al cliente
          (<a href="mailto:${data.correo}" style="color:#059669;">${data.correo}</a>).
        </p>
      </div>

      <div style="background:#f8faff;border:1px solid #e0e7ff;border-radius:10px;
                  padding:18px 22px;margin-bottom:16px;">
        <p style="margin:0 0 10px;font-size:10px;font-weight:700;color:#6b7280;
                  letter-spacing:.08em;text-transform:uppercase;">Datos del solicitante</p>
        ${infoRow('Nombre', data.nombre)}
        ${infoRow('Correo', `<a href="mailto:${data.correo}" style="color:#3b5bdb;">${data.correo}</a>`)}
        ${infoRow('Empresa / Institución', data.empresa)}
        ${infoRow('Teléfono', data.telefono)}
        ${optionalInfoRow('RTN', data.rtn)}
      </div>

      <div style="background:#f0f9ff;border:1px solid #bae6fd;border-radius:10px;
                  padding:18px 22px;margin-bottom:24px;">
        <p style="margin:0 0 10px;font-size:10px;font-weight:700;color:#6b7280;
                  letter-spacing:.08em;text-transform:uppercase;">Datos del proyecto</p>
        ${infoRow('Nombre del proyecto', data.nombreProyecto)}
        ${optionalInfoRow('Dirección del proyecto', data.direccionProyecto)}
      </div>

      <p style="margin:0 0 10px;font-size:10px;font-weight:700;color:#6b7280;
                letter-spacing:.08em;text-transform:uppercase;">
        Ensayo${plural} solicitado${plural} (${cantidad})
      </p>
      <table width="100%" cellpadding="0" cellspacing="0"
             style="border:1px solid #e5e7eb;border-radius:10px;
                    overflow:hidden;border-collapse:collapse;margin-bottom:8px;">
        <thead>${serviciosTableHeader()}</thead>
        <tbody>${buildServiciosRows(data)}</tbody>
      </table>

      ${descripcionHtml}
      ${ubicacionHtml}
    </td>
  </tr>

  <tr>
    <td style="background:#064e3b;border-radius:0 0 16px 16px;
               padding:20px 40px;text-align:center;">
      <p style="margin:0;font-size:11px;color:#6ee7b7;">
        Sistema de cotizaciones — Laboratorios de Ingeniería Civil UNAH
      </p>
      <p style="margin:6px 0 0;font-size:10px;color:#34d399;">
        Este correo es de uso interno. No reenviar.
      </p>
    </td>
  </tr>

</table>
</td></tr>
</table>
</body>
</html>`;
}

function buildAlertPlain(data, fila) {
  const rtnTxt      = data.rtn               ? `\n  RTN      : ${data.rtn}`               : '';
  const dirProyTxt  = data.direccionProyecto ? `\n  Dirección: ${data.direccionProyecto}` : '';
  const ubicTxt     = data.ubicacion
    ? `\nUBICACIÓN (MAPA)\n  ${data.ubicacion.address || `${data.ubicacion.lat}, ${data.ubicacion.lng}`}`
    : '';

  return `NUEVA SOLICITUD DE COTIZACIÓN — Ref. #${fila}

📎 El archivo Word de la cotización va adjunto en este correo.
   Ábralo, agregue los precios y envíelo al cliente: ${data.correo}

SOLICITANTE
  Nombre   : ${data.nombre}
  Correo   : ${data.correo}
  Empresa  : ${data.empresa}
  Teléfono : ${data.telefono}${rtnTxt}

PROYECTO
  Nombre   : ${data.nombreProyecto}${dirProyTxt}

SERVICIOS SOLICITADOS (${data.servicios.length}):
${serviciosTxt(data)}

${data.descripcion ? 'DETALLES: ' + data.descripcion : ''}${ubicTxt}

---
Sistema de cotizaciones — Lab. Ingeniería Civil UNAH
`;
}

// ── Funciones públicas ────────────────────────────────────────────────────────

async function sendConfirmation(data, fila) {
  if (!config.smtp.user || !config.smtp.pass) return;

  const transporter = getTransporter();
  await transporter.sendMail({
    from:    config.smtp.user,
    to:      data.correo,
    subject: `Solicitud recibida — Lab. Ingeniería Civil UNAH (Ref. #${fila})`,
    text:    buildPlain(data),
    html:    buildHtml(data),
  });
}

async function sendAlert(data, fila, docxBuffer = null, docxFilename = null) {
  if (!config.smtp.user || !config.smtp.pass) return;

  const cantidad    = data.servicios.length;
  const transporter = getTransporter();

  const mailOptions = {
    from:    config.smtp.user,
    to:      config.smtp.user,
    subject: `Nueva solicitud #${fila} — ${data.nombre} (${cantidad} servicio${cantidad > 1 ? 's' : ''})`,
    text:    buildAlertPlain(data, fila),
    html:    buildAlertHtml(data, fila),
    attachments: [],
  };

  if (docxBuffer && docxFilename) {
    mailOptions.attachments.push({
      filename:    docxFilename,
      content:     docxBuffer,
      contentType: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    });
  }

  await transporter.sendMail(mailOptions);
}

module.exports = { sendConfirmation, sendAlert };
