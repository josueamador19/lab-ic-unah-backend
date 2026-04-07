from pydantic import BaseModel, EmailStr, field_validator
from typing import List, Optional


class ServicioItem(BaseModel):
    code: str
    name: str
    norma: str
    sub: Optional[str] = None


class UbicacionModel(BaseModel):
    lat: str
    lng: str
    address: Optional[str] = None


class CotizacionRequest(BaseModel):
    # Datos personales
    nombre:   str
    correo:   EmailStr
    empresa:  Optional[str] = None
    telefono: Optional[str] = None

    # Servicios
    servicios: List[ServicioItem]

    # Cantidades (solo para servicios de laboratorio, no topografía)
    muestras: Optional[int] = None
    ensayos:  Optional[int] = None

    # Detalles
    descripcion: Optional[str] = None

    # Mapa
    ubicacion: Optional[UbicacionModel] = None

    @field_validator("nombre")
    @classmethod
    def nombre_no_vacio(cls, v: str) -> str:
        if not v.strip():
            raise ValueError("El nombre no puede estar vacío")
        return v.strip()

    @field_validator("servicios")
    @classmethod
    def al_menos_un_servicio(cls, v: List[ServicioItem]) -> List[ServicioItem]:
        if len(v) == 0:
            raise ValueError("Debe seleccionar al menos un servicio")
        return v


class CotizacionResponse(BaseModel):
    ok:      bool
    message: str
    fila:    Optional[int] = None