from pydantic import BaseModel, EmailStr, field_validator
from typing import List, Optional


class ServicioItem(BaseModel):
    code:     str
    name:     str
    norma:    Optional[str]   = None
    sub:      Optional[str]   = None
    muestras: Optional[int]   = None
    precio:   Optional[float] = None


class UbicacionModel(BaseModel):
    lat:     str
    lng:     str
    address: Optional[str] = None


class CotizacionRequest(BaseModel):
    nombre:            str
    correo:            EmailStr
    empresa:           str
    telefono:          str
    rtn:               Optional[str] = None
    nombreProyecto:    str
    direccionProyecto: Optional[str] = None
    descripcion:       Optional[str] = None
    servicios:         List[ServicioItem]
    ubicacion:         Optional[UbicacionModel] = None

    @field_validator("nombre")
    @classmethod
    def nombre_no_vacio(cls, v: str) -> str:
        if not v.strip():
            raise ValueError("El nombre no puede estar vacío")
        return v.strip()

    @field_validator("empresa")
    @classmethod
    def empresa_no_vacia(cls, v: str) -> str:
        if not v.strip():
            raise ValueError("La empresa o institución no puede estar vacía")
        return v.strip()

    @field_validator("telefono")
    @classmethod
    def telefono_no_vacio(cls, v: str) -> str:
        if not v.strip():
            raise ValueError("El teléfono no puede estar vacío")
        return v.strip()

    @field_validator("nombreProyecto")
    @classmethod
    def nombre_proyecto_no_vacio(cls, v: str) -> str:
        if not v.strip():
            raise ValueError("El nombre del proyecto no puede estar vacío")
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