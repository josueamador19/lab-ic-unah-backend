from pydantic_settings import BaseSettings
from typing import List


class Settings(BaseSettings):
    # Google Sheets
    GOOGLE_SERVICE_ACCOUNT_JSON: str = "./credentials/service_account.json"
    SPREADSHEET_ID: str = ""

    # CORS — separados por coma en el .env
    # Ej: ALLOWED_ORIGINS=http://localhost:5173,https://tudominio.com
    ALLOWED_ORIGINS: str = "http://localhost:5173"

    @property
    def origins_list(self) -> List[str]:
        return [o.strip() for o in self.ALLOWED_ORIGINS.split(",")]

    # SMTP — Gmail + App Password
    SMTP_USER: str = ""
    SMTP_PASS: str = ""

    # App
    APP_ENV: str = "development"

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


settings = Settings()