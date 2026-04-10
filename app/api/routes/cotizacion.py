"""
app/routers/cotizacion.py
=========================
POST /cotizacion  → guarda en Sheets + genera .docx + envía correos
GET  /cotizacion/{fila}/docx → descarga el Word desde el servidor
"""

from fastapi import APIRouter, HTTPException, status
from fastapi.responses import FileResponse
from googleapiclient.errors import HttpError
from pathlib import Path

from app.models.cotizacion import CotizacionRequest, CotizacionResponse
from app.services.sheets_service import append_cotizacion
from app.services.email_service import send_confirmation, send_alert
from app.services.docx_service import generar_cotizacion, DOCX_DIR, _numero_cotizacion
import logging

logger = logging.getLogger(__name__)
router = APIRouter()


# ── POST /cotizacion ──────────────────────────────────────────────────────────
@router.post(
    "/cotizacion",
    response_model=CotizacionResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Registrar solicitud de cotización",
)
async def crear_cotizacion(payload: CotizacionRequest):

    # 1. Guardar en Google Sheets
    try:
        fila = append_cotizacion(payload)
    except HttpError as e:
        logger.error(f"Google Sheets API error: {e}")
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail="No se pudo guardar la solicitud. Intente más tarde.",
        )
    except Exception as e:
        logger.error(f"Error inesperado en Sheets: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Error interno del servidor.",
        )

    # 2. Generar el .docx pre-llenado
    docx_path = None
    try:
        docx_path = generar_cotizacion(payload, fila)
        logger.info(f"[DOCX] Generado: {docx_path}")
    except Exception as e:
        logger.error(f"[DOCX] Error generando cotización: {e}")

    # 3. Correo de confirmación al cliente (sin adjunto)
    try:
        send_confirmation(payload, fila)
        logger.info(f"[EMAIL] Confirmación enviada a {payload.correo}")
    except Exception as e:
        logger.error(f"[EMAIL] Falló confirmación a {payload.correo}: {e}")

    # 4. Alerta interna al admin CON el .docx adjunto
    try:
        send_alert(payload, fila, docx_path=docx_path)
        logger.info(f"[EMAIL] Alerta interna enviada con adjunto")
    except Exception as e:
        logger.error(f"[EMAIL] Falló alerta interna: {e}")

    return CotizacionResponse(
        ok=True,
        message="Solicitud recibida. Le responderemos en 24–48 horas hábiles.",
        fila=fila,
    )


# ── GET /cotizacion/{fila}/docx ───────────────────────────────────────────────
@router.get(
    "/cotizacion/{fila}/docx",
    summary="Descargar cotización Word pre-llenada",
    response_class=FileResponse,
)
async def descargar_docx(fila: int):
    """
    Descarga el .docx desde el servidor como respaldo si el adjunto no llegó.
    """
    numero    = _numero_cotizacion(fila)
    docx_path = DOCX_DIR / f"{numero}.docx"

    if not docx_path.exists():
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"No se encontró el archivo para la fila {fila}.",
        )

    return FileResponse(
        path=str(docx_path),
        media_type="application/vnd.openxmlformats-officedocument.wordprocessingml.document",
        filename=f"{numero}.docx",
    )