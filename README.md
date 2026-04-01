# Lab. Ingeniería Civil UNAH — Backend

FastAPI backend para gestión de cotizaciones. 
## Setup rápido

```bash
# 1. Clonar y entrar al proyecto
cd lab-backend

# 2. Crear entorno virtual
python -m venv .venv
source .venv/bin/activate      # Windows: .venv\Scripts\activate

# 3. Instalar dependencias
pip install -r requirements.txt

# 4. Configurar variables de entorno
cp .env.example .env
# Editar .env con tu SPREADSHEET_ID

# 5. Agregar credenciales de Google
mkdir credentials
# Colocar service_account.json dentro de credentials/

# 6. Levantar el servidor
uvicorn main:app --reload --port 8000
```


Docs interactivas: `http://localhost:8000/docs` (solo en development)



