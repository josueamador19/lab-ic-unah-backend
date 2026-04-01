"""
Cliente singleton de Google Sheets API.
Se autentica con el Service Account y expone el recurso `spreadsheets`.
"""
from google.oauth2 import service_account
from googleapiclient.discovery import build
from app.core.config import settings

SCOPES = ["https://www.googleapis.com/auth/spreadsheets"]

_service = None


def get_sheets_service():
    global _service
    if _service is None:
        creds = service_account.Credentials.from_service_account_file(
            settings.GOOGLE_SERVICE_ACCOUNT_JSON,
            scopes=SCOPES,
        )
        _service = build("sheets", "v4", credentials=creds, cache_discovery=False)
    return _service
