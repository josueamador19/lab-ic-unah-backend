"""
Tests básicos del endpoint /cotizacion.
Ejecutar con: pytest tests/
"""
from fastapi.testclient import TestClient
from unittest.mock import patch
from main import app

client = TestClient(app)

PAYLOAD_VALIDO = {
    "nombre": "María López",
    "correo": "maria@ejemplo.com",
    "empresa": "Constructora HN",
    "telefono": "+504 9999-0000",
    "servicios": [
        {"code": "SU-01", "name": "Contenido de Humedad", "norma": "ASTM D2216"},
        {"code": "CU-04", "name": "Rotura de Cilindros",  "norma": "ASTM C39"},
    ],
    "descripcion": "3 cilindros de concreto, proyecto Torre Norte",
    "ubicacion": {
        "lat": "14.081800",
        "lng": "-87.206800",
        "address": "Ciudad Universitaria, Tegucigalpa",
    },
}


def test_health():
    r = client.get("/api/v1/health")
    assert r.status_code == 200
    assert r.json()["status"] == "ok"


@patch("app.api.routes.cotizacion.append_cotizacion", return_value=5)
@patch("app.api.routes.cotizacion.send_confirmation", return_value=None)
def test_crear_cotizacion_ok(mock_email, mock_sheets):
    r = client.post("/api/v1/cotizacion", json=PAYLOAD_VALIDO)
    assert r.status_code == 201
    assert r.json()["ok"] is True
    assert r.json()["fila"] == 5


def test_crear_cotizacion_sin_servicios():
    payload = {**PAYLOAD_VALIDO, "servicios": []}
    r = client.post("/api/v1/cotizacion", json=payload)
    assert r.status_code == 422  # Pydantic validation error


def test_crear_cotizacion_correo_invalido():
    payload = {**PAYLOAD_VALIDO, "correo": "no-es-un-correo"}
    r = client.post("/api/v1/cotizacion", json=payload)
    assert r.status_code == 422
