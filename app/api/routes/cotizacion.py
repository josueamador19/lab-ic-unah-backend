from fastapi import APIRouter, HTTPException, status
from googleapiclient.errors import HttpError
from app.models.cotizacion import CotizacionRequest, CotizacionResponse
from app.services.sheets_service import append_cotizacion
from app.services.email_service import send_confirmation
import logging

logger = logging.getLogger(__name__)
router = APIRouter()


@router.post(
    "/cotizacion",
    response_model=CotizacionResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Registrar solicitud de cotización",
)
async def crear_cotizacion(payload: CotizacionRequest):
    """
    Recibe el formulario del frontend, escribe una fila en Google Sheets
    y (opcionalmente) envía correo de confirmación.
    """
    try:
        fila = append_cotizacion(payload)
    except HttpError as e:
        logger.error(f"Google Sheets API error: {e}")
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail="No se pudo guardar la solicitud. Intente más tarde.",
        )
    except Exception as e:
        logger.error(f"Error inesperado: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Error interno del servidor.",
        )

    # Correo de confirmación (no bloquea la respuesta si falla)
    try:
        send_confirmation(payload, fila)
    except Exception as e:
        logger.warning(f"Email no enviado: {e}")

    return CotizacionResponse(
        ok=True,
        message="Solicitud recibida. Le responderemos en 24–48 horas hábiles.",
        fila=fila,
    )
