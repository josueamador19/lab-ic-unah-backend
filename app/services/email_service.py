"""
Envío de correo de confirmación al solicitante.
Usa Gmail + App Password (smtplib) — sin dependencias externas.
"""
import smtplib
import ssl
import logging
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

from app.core.config import settings
from app.models.cotizacion import CotizacionRequest

logger = logging.getLogger(__name__)


def _build_servicios_rows(data: CotizacionRequest) -> str:
    rows = ""
    for svc in data.servicios:
        sub_html = (
            f"<br/><span style='font-size:11px;color:#6b7280;font-style:italic'>{svc.sub}</span>"
            if svc.sub else ""
        )
        rows += f"""
        <tr>
          <td style="padding:10px 14px;border-bottom:1px solid #e5e7eb;">
            <span style="display:inline-block;background:#dbeafe;color:#1e40af;
                         font-weight:700;font-size:11px;padding:2px 8px;
                         border-radius:5px;">{svc.code}</span>
          </td>
          <td style="padding:10px 14px;border-bottom:1px solid #e5e7eb;
                     font-size:13px;color:#1f2937;">
            {svc.name}{sub_html}
          </td>
          <td style="padding:10px 14px;border-bottom:1px solid #e5e7eb;
                     font-size:11px;color:#6b7280;">{svc.norma}</td>
        </tr>"""
    return rows


def _build_html(data: CotizacionRequest) -> str:
    nombre_corto = data.nombre.strip().split()[0]
    cantidad     = len(data.servicios)
    plural       = "s" if cantidad > 1 else ""

    empresa_html = (
        f"<p style='margin:0 0 6px;font-size:13px;color:#374151;'>"
        f"<strong>Empresa / Institución:</strong> {data.empresa}</p>"
    ) if data.empresa else ""

    telefono_html = (
        f"<p style='margin:0 0 6px;font-size:13px;color:#374151;'>"
        f"<strong>Teléfono:</strong> {data.telefono}</p>"
    ) if data.telefono else ""

    descripcion_html = (
        f"""<div style="margin-top:24px;padding:16px 20px;background:#f9fafb;
                        border-left:4px solid #3b5bdb;border-radius:0 8px 8px 0;">
              <p style="margin:0 0 4px;font-size:10px;font-weight:700;color:#6b7280;
                        letter-spacing:.08em;text-transform:uppercase;">Detalles adicionales</p>
              <p style="margin:0;font-size:13px;color:#374151;line-height:1.6;">{data.descripcion}</p>
            </div>"""
    ) if data.descripcion else ""

    servicios_rows = _build_servicios_rows(data)

    return f"""<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width,initial-scale=1.0"/>
</head>
<body style="margin:0;padding:0;background:#f3f4f6;
             font-family:'Segoe UI',Arial,sans-serif;">
<table width="100%" cellpadding="0" cellspacing="0"
       style="background:#f3f4f6;padding:40px 16px;">
  <tr><td align="center">
  <table width="620" cellpadding="0" cellspacing="0"
         style="max-width:620px;width:100%;">

    <!-- HEADER -->
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

    <!-- CUERPO -->
    <tr>
      <td style="background:#ffffff;padding:36px 40px;">

        <!-- Saludo -->
        <p style="margin:0 0 16px;font-size:16px;font-weight:700;color:#1e3a8a;">
          Hola, {nombre_corto} 👋
        </p>
        <p style="margin:0 0 24px;font-size:14px;color:#374151;line-height:1.7;">
          Hemos recibido su solicitud de cotización correctamente.
          Nuestro equipo técnico la revisará y le enviará una propuesta formal
          en un plazo de <strong>24 a 48 horas hábiles</strong>.
        </p>

        <!-- Datos del solicitante -->
        <div style="background:#f8faff;border:1px solid #e0e7ff;border-radius:10px;
                    padding:18px 22px;margin-bottom:24px;">
          <p style="margin:0 0 10px;font-size:10px;font-weight:700;color:#6b7280;
                    letter-spacing:.08em;text-transform:uppercase;">Datos de su solicitud</p>
          <p style="margin:0 0 6px;font-size:13px;color:#374151;">
            <strong>Nombre:</strong> {data.nombre}
          </p>
          <p style="margin:0 0 6px;font-size:13px;color:#374151;">
            <strong>Correo:</strong> {data.correo}
          </p>
          {empresa_html}
          {telefono_html}
        </div>

        <!-- Servicios solicitados -->
        <p style="margin:0 0 10px;font-size:10px;font-weight:700;color:#6b7280;
                  letter-spacing:.08em;text-transform:uppercase;">
          Ensayo{plural} solicitado{plural} ({cantidad})
        </p>
        <table width="100%" cellpadding="0" cellspacing="0"
               style="border:1px solid #e5e7eb;border-radius:10px;
                      overflow:hidden;border-collapse:collapse;margin-bottom:24px;">
          <thead>
            <tr style="background:#f1f5f9;">
              <th style="padding:10px 14px;text-align:left;font-size:10px;
                         font-weight:700;color:#6b7280;letter-spacing:.06em;
                         text-transform:uppercase;border-bottom:1px solid #e5e7eb;">
                Código</th>
              <th style="padding:10px 14px;text-align:left;font-size:10px;
                         font-weight:700;color:#6b7280;letter-spacing:.06em;
                         text-transform:uppercase;border-bottom:1px solid #e5e7eb;">
                Ensayo</th>
              <th style="padding:10px 14px;text-align:left;font-size:10px;
                         font-weight:700;color:#6b7280;letter-spacing:.06em;
                         text-transform:uppercase;border-bottom:1px solid #e5e7eb;">
                Norma</th>
            </tr>
          </thead>
          <tbody>
            {servicios_rows}
          </tbody>
        </table>

        {descripcion_html}

        <!-- Próximos pasos -->
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

    <!-- FOOTER -->
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
          Para consultas escríbanos directamente a jefatura.labs.ic@unah.edu.hn
        </p>
      </td>
    </tr>

  </table>
  </td></tr>
</table>
</body>
</html>"""


def _build_plain(data: CotizacionRequest) -> str:
    nombre_corto = data.nombre.strip().split()[0]
    servicios_txt = "\n".join(
        f"  • [{s.code}] {s.name} — {s.norma}" for s in data.servicios
    )
    return f"""Hola, {nombre_corto}.

Hemos recibido su solicitud de cotización correctamente.
Le responderemos en un plazo de 24 a 48 horas hábiles.

SERVICIOS SOLICITADOS:
{servicios_txt}

{"DETALLES: " + data.descripcion if data.descripcion else ""}

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
"""


def send_confirmation(data: CotizacionRequest, fila: int) -> None:
    """
    Envía un correo HTML de confirmación al solicitante vía Gmail SMTP.
    Lanza excepción si falla (el llamador la captura y solo loguea el warning).
    """
    if not settings.SMTP_USER or not settings.SMTP_PASS:
        logger.warning("[EMAIL] SMTP_USER o SMTP_PASS no configurados — correo omitido.")
        return

    msg = MIMEMultipart("alternative")
    msg["Subject"] = f"✅ Solicitud recibida — Lab. Ingeniería Civil UNAH (Ref. #{fila})"
    msg["From"]    = settings.SMTP_USER
    msg["To"]      = data.correo

    msg.attach(MIMEText(_build_plain(data), "plain", "utf-8"))
    msg.attach(MIMEText(_build_html(data),  "html",  "utf-8"))

    context = ssl.create_default_context()
    with smtplib.SMTP_SSL("smtp.gmail.com", 465, context=context) as server:
        server.login(settings.SMTP_USER, settings.SMTP_PASS)
        server.send_message(msg)

    logger.info(f"[EMAIL] Confirmación enviada a {data.correo} — Ref. #{fila}")