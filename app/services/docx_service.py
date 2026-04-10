"""
app/services/docx_service.py
============================
Genera un .docx de cotización pre-llenado a partir de los datos del cliente.

Flujo:
  1. El endpoint POST /cotizacion llama a generar_cotizacion(payload, fila)
  2. Se copia la plantilla y se llenan los campos
  3. El archivo se guarda en DOCX_DIR / "COT-{fila}.docx"
  4. El admin descarga vía GET /api/v1/cotizacion/{fila}/docx

Dependencias:
  pip install python-docx
"""

import copy
from datetime import date
from pathlib import Path

from docx import Document
from docx.oxml.ns import qn

from app.models.cotizacion import CotizacionRequest

# ── Rutas ─────────────────────────────────────────────────────────────────────
BASE_DIR     = Path(__file__).parent.parent.parent          # raíz del proyecto
TEMPLATE     = BASE_DIR / "plantilla_cotizacion.docx"       # tu plantilla original
DOCX_DIR     = BASE_DIR / "cotizaciones_generadas"          # carpeta de salida
DOCX_DIR.mkdir(exist_ok=True)


# ─────────────────────────────────────────────────────────────────────────────
# HELPERS
# ─────────────────────────────────────────────────────────────────────────────

def _unique_cells(row):
    """Devuelve solo las celdas únicas de una fila (ignora merged duplicates)."""
    seen, cells = set(), []
    for cell in row.cells:
        cid = id(cell._tc)
        if cid not in seen:
            seen.add(cid)
            cells.append(cell)
    return cells


def _write(cell, text: str):
    """
    Escribe texto en una celda preservando el formato XML del primer run.
    Si la celda está vacía, crea un run nuevo.
    """
    text = str(text) if text is not None else ""
    para = cell.paragraphs[0]

    # Recolectar todos los runs de todos los párrafos de la celda
    all_runs = [r for p in cell.paragraphs for r in p.runs]

    if all_runs:
        # Usar el formato del primer run; borrar el resto
        first_run = all_runs[0]
        for r in all_runs[1:]:
            r.text = ""
        first_run.text = text
    else:
        # Celda sin runs — agregar uno limpio
        para.add_run(text)


def _numero_cotizacion(fila: int) -> str:
    year = date.today().year
    return f"COT-{fila:04d}-{year}"


# ─────────────────────────────────────────────────────────────────────────────
# FUNCIÓN PRINCIPAL
# ─────────────────────────────────────────────────────────────────────────────

def generar_cotizacion(data: CotizacionRequest, fila: int) -> Path:
    """
    Llena la plantilla .docx con los datos del cliente y la guarda en disco.

    Retorna el Path del archivo generado (ej. cotizaciones_generadas/COT-0042.docx)
    """
    numero = _numero_cotizacion(fila)
    doc    = Document(str(TEMPLATE))
    tables = doc.tables

    # ── TABLA 0 — Número de cotización ────────────────────────────────────────
    # cell[1] → párrafo 0 = "COTIZACIÓN", párrafo 1 = número
    cot_cell = tables[0].rows[0].cells[1]
    if len(cot_cell.paragraphs) >= 2:
        num_para = cot_cell.paragraphs[1]
        if num_para.runs:
            num_para.runs[0].text = numero
        else:
            num_para.add_run(numero)

    # ── TABLA 1 — Datos del cliente ───────────────────────────────────────────
    t1 = tables[1]

    def fill_t1(row_idx: int, col_idx: int, value: str):
        """Escribe en la celda de valor (columna derecha) de la tabla 1."""
        unique = _unique_cells(t1.rows[row_idx])
        if col_idx < len(unique):
            _write(unique[col_idx], value)

    hoy         = date.today().strftime("%d/%m/%Y")
    nombre      = data.nombre
    empresa     = data.empresa or ""
    contacto    = f"{nombre}" + (f" — {empresa}" if empresa else "")
    direccion   = ""
    ubicacion_txt = ""

    if data.ubicacion:
        ubicacion_txt = data.ubicacion.address or f"{data.ubicacion.lat}, {data.ubicacion.lng}"

    # row1 col1 → Nombre / Razón Social
    fill_t1(1, 1, empresa or nombre)
    # row2 col1 → Dirección (usamos la del mapa si existe)
    fill_t1(2, 1, ubicacion_txt)
    # row3 col1 → Teléfono | col3 → Correo
    fill_t1(3, 1, data.telefono or "")
    fill_t1(3, 3, data.correo)
    # row4 col1 → RTN (vacío, admin lo completa) | col3 → Fecha de solicitud
    fill_t1(4, 1, "")
    fill_t1(4, 3, hoy)
    # row5 col1 → Nombre del Proyecto / Obra
    fill_t1(5, 1, data.descripcion or "")
    # row6 col1 → Ubicación
    fill_t1(6, 1, ubicacion_txt)
    # row7 col1 → Contacto
    fill_t1(7, 1, contacto)

    # ── TABLA 2 — Detalle de ensayos ──────────────────────────────────────────
    # Filas de datos: rows 2–11 (10 filas, numeradas 1–10)
    # Columnas únicas por fila de datos:
    #   0=No. | 1=Descripción | 2=Norma | 3=No.Muestras | 5=P.Unitario | 7=Total
    t2          = tables[2]
    DATA_START  = 2          # índice de la primera fila de datos
    MAX_ROWS    = 10

    servicios = data.servicios[:MAX_ROWS]

    for i, svc in enumerate(servicios):
        row     = t2.rows[DATA_START + i]
        unique  = _unique_cells(row)
        # unique[0]=No, unique[1]=Descripción, unique[2]=Norma,
        # unique[3]=Muestras, unique[4]=P.Unitario, unique[5]=Total
        descripcion = svc.name + (f"\n({svc.sub})" if svc.sub else "")
        muestras    = str(svc.muestras) if svc.muestras is not None else ""

        if len(unique) > 1: _write(unique[1], descripcion)
        if len(unique) > 2: _write(unique[2], svc.norma or "")
        if len(unique) > 3: _write(unique[3], muestras)
        # P. Unitario y Total los deja el admin — se limpian para que estén en blanco
        if len(unique) > 4: _write(unique[4], "")
        if len(unique) > 5: _write(unique[5], "")

    # Limpiar filas sobrantes (las que no tienen servicio)
    for i in range(len(servicios), MAX_ROWS):
        row    = t2.rows[DATA_START + i]
        unique = _unique_cells(row)
        for col in [1, 2, 3, 4, 5]:
            if col < len(unique):
                _write(unique[col], "")

    # SUBTOTAL y TOTAL — dejar en blanco para que el admin los calcule
    for row_idx in [12, 13]:
        row    = t2.rows[row_idx]
        unique = _unique_cells(row)
        if len(unique) > 1:
            _write(unique[1], "")

    # ── TABLA 3 — Condiciones: Observaciones ─────────────────────────────────
    # cell[1] col derecha → "Observaciones:" + espacio para notas del admin
    # No tocamos las condiciones fijas (izquierda); solo limpiamos observaciones.
    # (Ya están en blanco en la plantilla — no hace falta modificar)

    # ── Guardar ───────────────────────────────────────────────────────────────
    output_path = DOCX_DIR / f"{numero}.docx"
    doc.save(str(output_path))
    return output_path