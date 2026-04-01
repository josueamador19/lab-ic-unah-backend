"""
Envío de correo de confirmación (opcional).
Por ahora solo imprime en consola; conecta SendGrid / SMTP cuando tengas credenciales.
"""
from app.models.cotizacion import CotizacionRequest
import logging

logger = logging.getLogger(__name__)


def send_confirmation(data: CotizacionRequest, fila: int) -> None:
    """
    Envía un correo de confirmación al solicitante.
    TODO: implementar con smtplib o SendGrid.
    """
    logger.info(
        f"[EMAIL] Confirmación para {data.correo} — fila {fila} en Sheets. "
        f"Servicios: {[s.code for s in data.servicios]}"
    )
    # Ejemplo con smtplib (descomentar y configurar):
    # import smtplib, ssl
    # from email.mime.text import MIMEText
    # msg = MIMEText(f"Hola {data.nombre}, recibimos tu solicitud...")
    # msg["Subject"] = "Confirmación de cotización — Lab. Ing. Civil UNAH"
    # msg["From"] = settings.SMTP_USER
    # msg["To"] = data.correo
    # with smtplib.SMTP_SSL("smtp.gmail.com", 465, context=ssl.create_default_context()) as s:
    #     s.login(settings.SMTP_USER, settings.SMTP_PASS)
    #     s.send_message(msg)
