# Laboratorio de Ingeniería Civil UNAH — Backend

API REST en Node.js/Express para la gestión de cotizaciones, catálogo de servicios y contenido del sitio web de los Laboratorios de Topografía, Suelos y Materiales — UNAH.

---

## Stack

| Capa | Tecnología |
|------|-----------|
| Runtime | Node.js 18+ |
| Framework | Express.js |
| Base de datos | MariaDB 10.6+ |
| Correo | Nodemailer (Gmail SMTP) |
| Documentos | Docxtemplater |
| Registro | Google Sheets API v4 |
| Validación | Zod |
| Subida de archivos | Multer |

---

## Requisitos previos

- **Node.js** ≥ 18 — [nodejs.org](https://nodejs.org)
- **npm** ≥ 9
- **MariaDB** ≥ 10.6 — [mariadb.org](https://mariadb.org/download)
- Cuenta de servicio de **Google Cloud** con acceso a Sheets API
- Cuenta de **Gmail** con [App Password](https://support.google.com/accounts/answer/185833) habilitada

---

## Instalación local

### 1. Clonar el repositorio

```bash
git clone <url-del-repositorio>
cd lab-backend
```

### 2. Instalar dependencias

```bash
npm install
```

### 3. Configurar variables de entorno

```bash
cp .env.example .env
```

Editar `.env` con los valores reales:

```env
DB_PASS=tu_contraseña_mariadb
SPREADSHEET_ID=id_de_tu_hoja_google
SMTP_USER=correo@gmail.com
SMTP_PASS=xxxx_xxxx_xxxx_xxxx
ADMIN_KEY=contraseña_panel_admin
ALLOWED_ORIGINS=http://localhost:5173
```

### 4. Agregar credenciales de Google

Descarga el archivo `service_account.json` desde [Google Cloud Console](https://console.cloud.google.com) y colócalo en:

```
credentials/
└── service_account.json
```

> La cuenta de servicio debe tener acceso de **Editor** a la hoja de Google Sheets.

### 5. Crear la base de datos y tablas

```bash
# Windows
mysql -u root -p < src/database/schema.sql
mysql -u root -p lab_cotizaciones < src/database/migration_001.sql
mysql -u root -p lab_cotizaciones < src/database/migration_002.sql
mysql -u root -p lab_cotizaciones < src/database/migration_003.sql

# Linux / macOS (mismos comandos)
```

### 6. Iniciar el servidor

```bash
npm run dev    # desarrollo (recarga automática)
npm start      # producción
```

Disponible en `http://localhost:8000`.

---

## Variables de entorno

| Variable | Descripción | Ejemplo |
|----------|-------------|---------|
| `PORT` | Puerto del servidor | `8000` |
| `APP_ENV` | Entorno (`development` / `production`) | `development` |
| `ALLOWED_ORIGINS` | Orígenes CORS separados por coma | `http://localhost:5173,https://lab.unah.edu.hn` |
| `DB_HOST` | Host de MariaDB | `localhost` |
| `DB_PORT` | Puerto de MariaDB | `3306` |
| `DB_USER` | Usuario de MariaDB | `root` |
| `DB_PASS` | Contraseña de MariaDB | — |
| `DB_NAME` | Nombre de la base de datos | `lab_cotizaciones` |
| `GOOGLE_SERVICE_ACCOUNT_JSON` | Ruta al JSON de cuenta de servicio | `./credentials/service_account.json` |
| `SPREADSHEET_ID` | ID de la hoja de Google Sheets | `1n593T...` |
| `SMTP_USER` | Correo Gmail para envío | `lab@gmail.com` |
| `SMTP_PASS` | App Password de Gmail (16 caracteres) | `xxxx xxxx xxxx xxxx` |
| `ADMIN_KEY` | Contraseña del panel administrativo | — |

---

## Endpoints de la API

### Públicos

| Método | Ruta | Descripción |
|--------|------|-------------|
| `GET` | `/api/v1/health` | Estado del servidor |
| `GET` | `/api/v1/servicios` | Catálogo agrupado por categoría |
| `GET` | `/api/v1/servicios/flat` | Catálogo en lista plana |
| `GET` | `/api/v1/equipos` | Equipos del laboratorio |
| `GET` | `/api/v1/configuracion` | Datos de contacto |
| `GET` | `/api/v1/normas` | Organismos de normalización |
| `GET` | `/api/v1/proceso` | Pasos del proceso de ensayo |
| `GET` | `/api/v1/faq` | Preguntas frecuentes |
| `POST` | `/api/v1/cotizacion` | Crear cotización |
| `GET` | `/api/v1/cotizacion/:id/docx` | Descargar Word de cotización |

### Administrativos — requieren `Authorization: Bearer <ADMIN_KEY>`

| Método | Ruta | Descripción |
|--------|------|-------------|
| `POST` | `/api/v1/admin/auth` | Verificar contraseña |
| `GET/POST/PUT/DELETE` | `/api/v1/admin/servicios` | CRUD servicios |
| `GET/POST/PUT/DELETE` | `/api/v1/admin/equipos` | CRUD equipos + imagen |
| `GET/PUT` | `/api/v1/admin/configuracion` | Datos de contacto |
| `GET/PUT` | `/api/v1/admin/normas/:id` | Editar organismos normativos |
| `GET/PUT` | `/api/v1/admin/proceso/:id` | Editar pasos del proceso |
| `GET/POST/PUT/DELETE` | `/api/v1/admin/faq` | CRUD preguntas frecuentes |

---

## Estructura del proyecto

```
lab-backend/
├── src/
│   ├── app.js
│   ├── config/index.js
│   ├── database/
│   │   ├── connection.js
│   │   ├── schema.sql            # DDL completo + seed inicial
│   │   ├── migration_001.sql     # Equipos + Configuración
│   │   ├── migration_002.sql     # Normas + Proceso
│   │   └── migration_003.sql     # FAQ
│   ├── middleware/
│   │   ├── adminAuth.js
│   │   └── upload.js             # Multer
│   ├── routes/
│   │   ├── health.js
│   │   ├── servicios.js
│   │   ├── equipos.js
│   │   ├── configuracion.js
│   │   ├── normas.js
│   │   ├── faq.js
│   │   ├── cotizacion.js
│   │   └── admin.js
│   ├── services/
│   │   ├── cotizacionService.js
│   │   ├── docxService.js
│   │   ├── emailService.js
│   │   └── sheetsService.js
│   └── validators/cotizacion.js
├── public/uploads/equipos/       # Imágenes subidas (excluidas del repo)
├── cotizaciones_generadas/        # .docx generados (excluidos del repo)
├── credentials/                   # service_account.json (excluido del repo)
├── plantilla_cotizacion.docx
├── .env.example
└── package.json
```

---

## Despliegue en servidor Linux

### Requisitos del servidor

- Ubuntu 22.04 LTS o similar
- Node.js 18+, MariaDB, Nginx
- Puertos 80 y 443 abiertos

### 1. Clonar y configurar

```bash
git clone <url-del-repositorio> /var/www/lab-backend
cd /var/www/lab-backend
npm install --omit=dev
cp .env.example .env
nano .env   # completar con valores de producción
```

### 2. Cargar la base de datos

```bash
mysql -u root -p < src/database/schema.sql
mysql -u root -p lab_cotizaciones < src/database/migration_001.sql
mysql -u root -p lab_cotizaciones < src/database/migration_002.sql
mysql -u root -p lab_cotizaciones < src/database/migration_003.sql
```

### 3. Gestionar el proceso con PM2

```bash
npm install -g pm2
pm2 start src/app.js --name "lab-backend"
pm2 save
pm2 startup   # genera el comando para auto-inicio
```

### 4. Configurar Nginx como reverse proxy

```nginx
# /etc/nginx/sites-available/lab-backend
server {
    listen 80;
    server_name api.lab.unah.edu.hn;

    location / {
        proxy_pass         http://localhost:8000;
        proxy_http_version 1.1;
        proxy_set_header   Upgrade $http_upgrade;
        proxy_set_header   Connection 'upgrade';
        proxy_set_header   Host $host;
        proxy_cache_bypass $http_upgrade;
        client_max_body_size 10M;
    }
}
```

```bash
ln -s /etc/nginx/sites-available/lab-backend /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx
```

### 5. HTTPS con Let's Encrypt

```bash
apt install certbot python3-certbot-nginx
certbot --nginx -d api.lab.unah.edu.hn
```

---

## CI/CD

### GitHub Actions

Crear `.github/workflows/deploy-backend.yml` en el repositorio:

```yaml
name: Deploy — Backend

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Deploy via SSH
        uses: appleboy/ssh-action@v1
        with:
          host:     ${{ secrets.SSH_HOST }}
          username: ${{ secrets.SSH_USER }}
          key:      ${{ secrets.SSH_PRIVATE_KEY }}
          script: |
            cd /var/www/lab-backend
            git pull origin main
            npm install --omit=dev
            pm2 restart lab-backend
```

**Secrets requeridos** (`Settings → Secrets → Actions`):

| Secret | Descripción |
|--------|-------------|
| `SSH_HOST` | IP o dominio del servidor |
| `SSH_USER` | Usuario SSH (ej. `ubuntu`) |
| `SSH_PRIVATE_KEY` | Llave privada SSH |

> Para **GitLab CI**, el equivalente es `.gitlab-ci.yml` con un runner SSH o un deploy job similar.

---

## Notas de seguridad

- Nunca subir `.env` ni `credentials/` al repositorio — ya están en `.gitignore`.
- Cambiar `ADMIN_KEY` por una clave segura antes de ir a producción.
- Usar HTTPS en producción; las credenciales de Google y SMTP viajan en las variables de entorno del servidor.
