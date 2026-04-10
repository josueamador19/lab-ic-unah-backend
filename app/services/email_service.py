"""
Envío de correos vía Gmail SMTP (App Password).

  1. send_confirmation → correo de confirmación al solicitante (SIN el .docx)
  2. send_alert        → correo de alerta interna al admin CON el .docx adjunto
"""
import smtplib
import ssl
import logging
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.base import MIMEBase
from email import encoders
from pathlib import Path

from app.core.config import settings
from app.models.cotizacion import CotizacionRequest

logger = logging.getLogger(__name__)


# ── Helpers ───────────────────────────────────────────────────────────────────

def _build_servicios_rows(data: CotizacionRequest) -> str:
    """Filas HTML de la tabla de servicios. Incluye columna de muestras."""
    rows = ""
    for svc in data.servicios:
        sub_html = (
            f"<br/><span style='font-size:11px;color:#6b7280;font-style:italic'>"
            f"{svc.sub}</span>"
        ) if svc.sub else ""

        muestras_cell = (
            f"<td style='padding:10px 14px;border-bottom:1px solid #e5e7eb;"
            f"font-size:13px;color:#1e3a8a;font-weight:700;text-align:center'>"
            f"{svc.muestras}</td>"
        ) if svc.muestras is not None else (
            f"<td style='padding:10px 14px;border-bottom:1px solid #e5e7eb;"
            f"font-size:11px;color:#9ca3af;text-align:center'>—</td>"
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
                     font-size:11px;color:#6b7280;">{svc.norma or "—"}</td>
          {muestras_cell}
        </tr>"""
    return rows


def _servicios_table_header() -> str:
    cols = ["Código", "Ensayo", "Norma", "Muestras"]
    ths  = "".join(
        f"<th style='padding:10px 14px;text-align:left;font-size:10px;"
        f"font-weight:700;color:#6b7280;letter-spacing:.06em;"
        f"text-transform:uppercase;border-bottom:1px solid #e5e7eb;'>{c}</th>"
        for c in cols
    )
    return f"<tr style='background:#f1f5f9;'>{ths}</tr>"


def _servicios_txt(data: CotizacionRequest) -> str:
    lines = []
    for s in data.servicios:
        muestras = f" — {s.muestras} muestra{'s' if s.muestras != 1 else ''}" \
                   if s.muestras is not None else ""
        lines.append(f"  • [{s.code}] {s.name} — {s.norma or '—'}{muestras}")
    return "\n".join(lines)


# ── Correo de confirmación al solicitante ─────────────────────────────────────

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

    return f"""<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width,initial-scale=1.0"/>
</head>
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
          Hola, {nombre_corto} 
        </p>
        <p style="margin:0 0 24px;font-size:14px;color:#374151;line-height:1.7;">
          Hemos recibido su solicitud de cotización correctamente.
          Nuestro equipo técnico la revisará y le enviará una propuesta formal
          en un plazo de <strong>24 a 48 horas hábiles</strong>.
        </p>

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

        <p style="margin:0 0 10px;font-size:10px;font-weight:700;color:#6b7280;
                  letter-spacing:.08em;text-transform:uppercase;">
          Ensayo{plural} solicitado{plural} ({cantidad})
        </p>
        <table width="100%" cellpadding="0" cellspacing="0"
               style="border:1px solid #e5e7eb;border-radius:10px;
                      overflow:hidden;border-collapse:collapse;margin-bottom:24px;">
          <thead>{_servicios_table_header()}</thead>
          <tbody>{_build_servicios_rows(data)}</tbody>
        </table>

        {descripcion_html}

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
</html>"""


def _build_plain(data: CotizacionRequest) -> str:
    nombre_corto = data.nombre.strip().split()[0]
    return f"""Hola, {nombre_corto}.

Hemos recibido su solicitud de cotización correctamente.
Le responderemos en un plazo de 24 a 48 horas hábiles.

SERVICIOS SOLICITADOS:
{_servicios_txt(data)}

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


# ── Correo de alerta interna al administrador (CON .docx adjunto) ─────────────

def _build_alert_html(data: CotizacionRequest, fila: int) -> str:
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
        f"""<div style="margin-top:16px;padding:14px 18px;background:#f9fafb;
                        border-left:4px solid #f59e0b;border-radius:0 8px 8px 0;">
              <p style="margin:0 0 4px;font-size:10px;font-weight:700;color:#6b7280;
                        letter-spacing:.08em;text-transform:uppercase;">Detalles adicionales</p>
              <p style="margin:0;font-size:13px;color:#374151;line-height:1.6;">{data.descripcion}</p>
            </div>"""
    ) if data.descripcion else ""

    ubicacion_html = (
        f"""<div style="margin-top:16px;padding:14px 18px;background:#f0fdf4;
                        border:1px solid #86efac;border-radius:10px;">
              <p style="margin:0 0 4px;font-size:10px;font-weight:700;color:#166534;
                        letter-spacing:.08em;text-transform:uppercase;">Ubicación del proyecto</p>
              <p style="margin:0;font-size:13px;color:#166534;">
                {data.ubicacion.address or f'{data.ubicacion.lat}, {data.ubicacion.lng}'}
              </p>
            </div>"""
    ) if data.ubicacion else ""

    return f"""<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width,initial-scale=1.0"/>
</head>
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
          🔔 Nueva solicitud de cotización
        </h1>
        <p style="margin:0;font-size:12px;color:#a7f3d0;">
          Referencia de fila en Sheets: <strong style="color:#fff;">#{fila}</strong>
        </p>
      </td>
    </tr>

    <tr>
      <td style="background:#ffffff;padding:32px 40px;">

        <!-- Aviso del adjunto -->
        <div style="margin-bottom:24px;padding:14px 18px;background:#f0fdf4;
                    border:1px solid #86efac;border-radius:10px;
                    display:flex;align-items:center;gap:10px;">
          <p style="margin:0;font-size:13px;color:#166534;line-height:1.5;">
            📎 <strong>Cotización Word adjunta.</strong>
            Ábrala, agregue los precios y envíela al cliente
            (<a href="mailto:{data.correo}" style="color:#059669;">{data.correo}</a>).
          </p>
        </div>

        <div style="background:#f8faff;border:1px solid #e0e7ff;border-radius:10px;
                    padding:18px 22px;margin-bottom:24px;">
          <p style="margin:0 0 10px;font-size:10px;font-weight:700;color:#6b7280;
                    letter-spacing:.08em;text-transform:uppercase;">Datos del solicitante</p>
          <p style="margin:0 0 6px;font-size:13px;color:#374151;">
            <strong>Nombre:</strong> {data.nombre}
          </p>
          <p style="margin:0 0 6px;font-size:13px;color:#374151;">
            <strong>Correo:</strong>
            <a href="mailto:{data.correo}" style="color:#3b5bdb;">{data.correo}</a>
          </p>
          {empresa_html}
          {telefono_html}
        </div>

        <p style="margin:0 0 10px;font-size:10px;font-weight:700;color:#6b7280;
                  letter-spacing:.08em;text-transform:uppercase;">
          Ensayo{plural} solicitado{plural} ({cantidad})
        </p>
        <table width="100%" cellpadding="0" cellspacing="0"
               style="border:1px solid #e5e7eb;border-radius:10px;
                      overflow:hidden;border-collapse:collapse;margin-bottom:8px;">
          <thead>{_servicios_table_header()}</thead>
          <tbody>{_build_servicios_rows(data)}</tbody>
        </table>

        {descripcion_html}
        {ubicacion_html}
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
</html>"""


def _build_alert_plain(data: CotizacionRequest, fila: int) -> str:
    ubicacion_txt = (
        f"\nUbicación      : {data.ubicacion.address or f'{data.ubicacion.lat}, {data.ubicacion.lng}'}"
    ) if data.ubicacion else ""

    return f"""NUEVA SOLICITUD DE COTIZACIÓN — Ref. #{fila}

📎 El archivo Word de la cotización va adjunto en este correo.
   Ábralo, agregue los precios y envíelo al cliente: {data.correo}

SOLICITANTE
  Nombre   : {data.nombre}
  Correo   : {data.correo}
  Empresa  : {data.empresa  or '—'}
  Teléfono : {data.telefono or '—'}

SERVICIOS SOLICITADOS ({len(data.servicios)}):
{_servicios_txt(data)}

{"DETALLES: " + data.descripcion if data.descripcion else ""}{ubicacion_txt}

---
Sistema de cotizaciones — Lab. Ingeniería Civil UNAH
"""


# ── SMTP ──────────────────────────────────────────────────────────────────────

def _smtp_send(msg: MIMEMultipart) -> None:
    context = ssl.create_default_context()
    with smtplib.SMTP_SSL("smtp.gmail.com", 465, context=context) as server:
        server.login(settings.SMTP_USER, settings.SMTP_PASS)
        server.send_message(msg)


# ── Funciones públicas ────────────────────────────────────────────────────────

def send_confirmation(data: CotizacionRequest, fila: int) -> None:
    """Correo al cliente: solo confirmación, sin adjuntos."""
    if not settings.SMTP_USER or not settings.SMTP_PASS:
        logger.warning("[EMAIL] SMTP no configurado — correo omitido.")
        return

    msg            = MIMEMultipart("alternative")
    msg["Subject"] = f"Solicitud recibida — Lab. Ingeniería Civil UNAH (Ref. #{fila})"
    msg["From"]    = settings.SMTP_USER
    msg["To"]      = data.correo

    msg.attach(MIMEText(_build_plain(data), "plain", "utf-8"))
    msg.attach(MIMEText(_build_html(data),  "html",  "utf-8"))

    _smtp_send(msg)
    logger.info(f"[EMAIL] Confirmación enviada a {data.correo} — Ref. #{fila}")


def send_alert(data: CotizacionRequest, fila: int, docx_path: Path | None = None) -> None:
    """
    Correo interno al admin con el .docx pre-llenado adjunto.

    docx_path: Path del archivo generado por docx_service.generar_cotizacion()
               Si es None, se envía igualmente pero sin adjunto.
    """
    if not settings.SMTP_USER or not settings.SMTP_PASS:
        return

    # Usamos mixed para poder adjuntar el archivo
    msg = MIMEMultipart("mixed")
    msg["Subject"] = (
        f"Nueva solicitud #{fila} — {data.nombre} "
        f"({len(data.servicios)} servicio{'s' if len(data.servicios) > 1 else ''})"
    )
    msg["From"] = settings.SMTP_USER
    msg["To"]   = settings.SMTP_USER

    # Parte de texto/html
    body = MIMEMultipart("alternative")
    body.attach(MIMEText(_build_alert_plain(data, fila), "plain", "utf-8"))
    body.attach(MIMEText(_build_alert_html(data, fila),  "html",  "utf-8"))
    msg.attach(body)

    # Adjuntar el .docx si existe
    if docx_path and docx_path.exists():
        with open(docx_path, "rb") as f:
            part = MIMEBase(
                "application",
                "vnd.openxmlformats-officedocument.wordprocessingml.document",
            )
            part.set_payload(f.read())
        encoders.encode_base64(part)
        part.add_header(
            "Content-Disposition",
            "attachment",
            filename=docx_path.name,
        )
        msg.attach(part)
        logger.info(f"[EMAIL] Adjuntando {docx_path.name} a la alerta interna")
    else:
        logger.warning(f"[EMAIL] docx_path no encontrado — alerta sin adjunto (Ref. #{fila})")

    _smtp_send(msg)
    logger.info(f"[EMAIL] Alerta interna enviada a {settings.SMTP_USER} — Ref. #{fila}")