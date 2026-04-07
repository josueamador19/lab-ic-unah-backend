"""
Escribe una cotización como nueva fila en Google Sheets.

Columnas del Sheet (A → O):
A  Timestamp
B  Nombre
C  Correo
D  Empresa
E  Teléfono
F  Códigos de servicios  (SU-01, CU-04, ...)
G  Nombres de servicios
H  Normas
I  Cantidad de servicios
J  N° Muestras
K  N° Ensayos
L  Descripción
M  Latitud
N  Longitud
O  Dirección
"""
from datetime import datetime, timezone
from googleapiclient.errors import HttpError
from app.core.sheets import get_sheets_service
from app.core.config import settings
from app.models.cotizacion import CotizacionRequest

SHEET_NAME = "Cotizaciones"
RANGE      = f"{SHEET_NAME}!A:O"

HEADER_ROW = [
    "Timestamp", "Nombre", "Correo", "Empresa", "Teléfono",
    "Códigos", "Servicios", "Normas", "# Servicios",
    "# Muestras", "# Ensayos",
    "Descripción", "Latitud", "Longitud", "Dirección",
]


def _ensure_header(service) -> None:
    """Escribe la fila de encabezado si el sheet está vacío."""
    result = (
        service.spreadsheets()
        .values()
        .get(spreadsheetId=settings.SPREADSHEET_ID, range=f"{SHEET_NAME}!A1:O1")
        .execute()
    )
    if not result.get("values"):
        service.spreadsheets().values().update(
            spreadsheetId=settings.SPREADSHEET_ID,
            range=f"{SHEET_NAME}!A1",
            valueInputOption="RAW",
            body={"values": [HEADER_ROW]},
        ).execute()


def append_cotizacion(data: CotizacionRequest) -> int:
    """
    Agrega una fila al sheet y retorna el número de fila escrita.
    Lanza HttpError si falla la API de Google.
    """
    service = get_sheets_service()
    _ensure_header(service)

    codigos = ", ".join(s.code  for s in data.servicios)
    nombres = ", ".join(s.name  for s in data.servicios)
    normas  = ", ".join(s.norma for s in data.servicios)

    lat = lng = direccion = ""
    if data.ubicacion:
        lat       = data.ubicacion.lat
        lng       = data.ubicacion.lng
        direccion = data.ubicacion.address or ""

    row = [
        datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC"),
        data.nombre,
        data.correo,
        data.empresa  or "",
        data.telefono or "",
        codigos,
        nombres,
        normas,
        len(data.servicios),
        data.muestras if data.muestras is not None else "",  # J — # Muestras
        data.ensayos  if data.ensayos  is not None else "",  # K — # Ensayos
        data.descripcion or "",
        lat,
        lng,
        direccion,
    ]

    result = (
        service.spreadsheets()
        .values()
        .append(
            spreadsheetId=settings.SPREADSHEET_ID,
            range=RANGE,
            valueInputOption="RAW",
            insertDataOption="INSERT_ROWS",
            body={"values": [row]},
        )
        .execute()
    )

    # Extraer número de fila del rango retornado — Ej: "Cotizaciones!A5:O5" → 5
    updated_range = result.get("updates", {}).get("updatedRange", "")
    try:
        fila = int(updated_range.split("!")[1].split(":")[0][1:])
    except Exception:
        fila = -1

    return fila