from pydantic import BaseModel, EmailStr, field_validator
from typing import List, Optional


class ServicioItem(BaseModel):
    code:     str
    name:     str
    norma:    Optional[str] = None  # null para servicios de topografía
    sub:      Optional[str] = None
    muestras: Optional[int] = None  # por servicio, solo lab (no topo)


class UbicacionModel(BaseModel):
    lat:     str
    lng:     str
    address: Optional[str] = None


class CotizacionRequest(BaseModel):
    nombre:      str
    correo:      EmailStr
    empresa:     Optional[str] = None
    telefono:    Optional[str] = None
    servicios:   List[ServicioItem]
    descripcion: Optional[str] = None
    ubicacion:   Optional[UbicacionModel] = None

    @field_validator("nombre")
    @classmethod
    def nombre_no_vacio(cls, v: str) -> str:
        if not v.strip():
            raise ValueError("El nombre no puede estar vacío")
        return v.strip()

    @field_validator("servicios")
    @classmethod
    def al_menos_un_servicio(cls, v: List[ServicioItem]) -> List[ServicioItem]:
        if not v:
            raise ValueError("Debe seleccionar al menos un servicio")
        return v


class CotizacionResponse(BaseModel):
    ok:      bool
    message: str
    fila:    Optional[int] = None