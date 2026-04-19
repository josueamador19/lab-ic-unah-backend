"""
Escribe una cotización como nueva fila en Google Sheets.

Columnas del Sheet (A → Q):
A  Timestamp
B  Nombre
C  Correo
D  Empresa
E  Teléfono
F  RTN
G  Nombre del proyecto
H  Dirección del proyecto
I  Códigos de servicios  (SU-01, CU-04, ...)
J  Nombres de servicios
K  Normas
L  Cantidad de servicios
M  Muestras por servicio (Ej: "3×SC-01, 1×SC-02")
N  Descripción
O  Latitud
P  Longitud
Q  Dirección (mapa)
"""
from datetime import datetime, timezone
from app.core.sheets import get_sheets_service
from app.core.config import settings
from app.models.cotizacion import CotizacionRequest

SHEET_NAME = "Cotizaciones"
RANGE      = f"{SHEET_NAME}!A:Q"

HEADER_ROW = [
    "Timestamp", "Nombre", "Correo", "Empresa", "Teléfono",
    "RTN", "Nombre del proyecto", "Dirección del proyecto",
    "Códigos", "Servicios", "Normas", "# Servicios",
    "Muestras por servicio",
    "Descripción", "Latitud", "Longitud", "Dirección (mapa)",
]


def _ensure_header(service) -> None:
    result = (
        service.spreadsheets()
        .values()
        .get(spreadsheetId=settings.SPREADSHEET_ID, range=f"{SHEET_NAME}!A1:Q1")
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
    service = get_sheets_service()
    _ensure_header(service)

    codigos = ", ".join(s.code        for s in data.servicios)
    nombres = ", ".join(s.name        for s in data.servicios)
    normas  = ", ".join(s.norma or "" for s in data.servicios)

    # "3×SC-01, 1×SC-02" — omite servicios sin muestras (topografía)
    muestras_col = ", ".join(
        f"{s.muestras}×{s.code}"
        for s in data.servicios
        if s.muestras is not None
    )

    lat = lng = direccion_mapa = ""
    if data.ubicacion:
        lat            = data.ubicacion.lat
        lng            = data.ubicacion.lng
        direccion_mapa = data.ubicacion.address or ""

    row = [
        datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC"),
        data.nombre,
        data.correo,
        data.empresa,
        data.telefono,
        data.rtn               or "",   # F — RTN (opcional)
        data.nombreProyecto,            # G — Nombre del proyecto
        data.direccionProyecto or "",   # H — Dirección del proyecto (opcional)
        codigos,
        nombres,
        normas,
        len(data.servicios),
        muestras_col,
        data.descripcion       or "",
        lat,
        lng,
        direccion_mapa,
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

    updated_range = result.get("updates", {}).get("updatedRange", "")
    try:
        fila = int(updated_range.split("!")[1].split(":")[0][1:])
    except Exception:
        fila = -1

    return fila