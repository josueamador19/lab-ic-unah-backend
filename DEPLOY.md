# Guía de despliegue — Lab Backend

## Variables de entorno requeridas

Copiar `.env.example` a `.env` y completar todos los valores antes de desplegar.

```
APP_ENV=production
PORT=8000
ALLOWED_ORIGINS=https://tu-dominio.com

DB_HOST=...
DB_PORT=3306
DB_USER=...
DB_PASS=...
DB_NAME=lab_cotizaciones

SMTP_USER=correo@gmail.com
SMTP_PASS=app_password_de_16_chars

ADMIN_KEY=clave_larga_aleatoria_aqui

SPREADSHEET_ID=1Abc123_tu_spreadsheet_id_aqui
GOOGLE_SERVICE_ACCOUNT_JSON={"type":"service_account","project_id":"..."}

S3_REGION=us-east-1
S3_BUCKET=nombre-del-bucket
S3_ACCESS_KEY=...
S3_SECRET_KEY=...
S3_PUBLIC_URL=https://nombre-bucket.s3.us-east-1.amazonaws.com
# S3_ENDPOINT=   ← solo para Cloudflare R2, DigitalOcean Spaces, MinIO
```

> **`GOOGLE_SERVICE_ACCOUNT_JSON`** — en producción pegar el contenido completo del JSON
> del service account en **una sola línea** (sin saltos de línea). En desarrollo local
> puede ser la ruta al archivo: `./credentials/service_account.json`

---

## Migraciones de base de datos

Ejecutar **en orden** antes del primer despliegue. Las migraciones son acumulativas.

```bash
mysql -u root -p lab_cotizaciones < src/database/migration_005.sql
mysql -u root -p lab_cotizaciones < src/database/migration_006.sql
```

| Migración | Descripción |
|-----------|-------------|
| 005 | Agrega columna `img_key` en `equipos` — clave S3 para borrado de imágenes |
| 006 | Agrega columnas `docx_key` y `docx_url` en `cotizaciones` — docx almacenado en S3 |

---

## Entry points según plataforma

| Plataforma | Archivo | Comando |
|------------|---------|---------|
| Desarrollo local | `server.js` | `npm run dev` |
| Vercel / Netlify | `api/index.js` | automático vía `vercel.json` |
| AWS Lambda | `lambda.js` | handler: `lambda.handler` |
| VPS / Railway / Render | `server.js` | `npm start` |

---

## Google Sheets — checklist previo

- [ ] Proyecto de Google Cloud con la API de Sheets habilitada
- [ ] Service account creado y JSON descargado
- [ ] El correo del service account (`...@...gserviceaccount.com`) agregado como **Editor** en el Spreadsheet
- [ ] `SPREADSHEET_ID` copiado de la URL del Spreadsheet
- [ ] Hoja dentro del Spreadsheet llamada exactamente `Cotizaciones` (o crearla vacía — el backend agrega el encabezado automáticamente)

---

## S3 — checklist previo

- [ ] Bucket creado en el proveedor elegido
- [ ] Credenciales (Access Key / Secret Key) generadas con permisos de lectura y escritura sobre el bucket
- [ ] CORS habilitado en el bucket si se accede desde el navegador directamente
- [ ] `S3_PUBLIC_URL` apunta a la URL base pública del bucket (sin slash al final)
- [ ] Para Cloudflare R2 / DigitalOcean Spaces: agregar `S3_ENDPOINT` con la URL del endpoint del proveedor

### Valores de referencia por proveedor

| Proveedor | `S3_ENDPOINT` | `S3_PUBLIC_URL` |
|-----------|---------------|-----------------|
| AWS S3 | *(dejar vacío)* | `https://bucket.s3.region.amazonaws.com` |
| Cloudflare R2 | `https://ID_CUENTA.r2.cloudflarestorage.com` | URL del dominio custom o del bucket |
| DigitalOcean Spaces | `https://REGION.digitaloceanspaces.com` | `https://BUCKET.REGION.digitaloceanspaces.com` |
| MinIO local | `http://localhost:9000` | `http://localhost:9000/BUCKET` + `S3_FORCE_PATH_STYLE=true` |

---

## SMTP — checklist previo

El backend usa Gmail con App Password (no la contraseña normal de la cuenta).

1. Activar verificación en dos pasos en la cuenta de Gmail
2. Ir a **Cuenta de Google → Seguridad → Contraseñas de aplicación**
3. Crear una contraseña para "Correo" y copiarla como `SMTP_PASS`

---

## Preguntas para el equipo de infraestructura / dominio

### Hosting y servidor

- ¿Cuál plataforma de despliegue? (Vercel, AWS Lambda, Railway, VPS propio)
- ¿MariaDB en producción? ¿Cómo se conecta el backend — IP pública, red privada, servicio gestionado?
- ¿El panel de la plataforma permite definir variables de entorno? (Necesario para todas las vars de arriba)

### Dominio y DNS

- ¿Dónde está registrado el dominio? (GoDaddy, Namecheap, Cloudflare, etc.)
- ¿El frontend y backend van en el mismo dominio o en subdominios separados?
  - Recomendado: `lab-ic.unah.edu.hn` para frontend, `api.lab-ic.unah.edu.hn` para backend
- ¿El SSL está gestionado por la plataforma de hosting o hay que configurar Let's Encrypt manualmente?

### Google Sheets

- ¿El service account ya tiene acceso al Spreadsheet? (agregar su correo como Editor)
- ¿Cuál es el `SPREADSHEET_ID`? (parte larga en la URL de la hoja)

### S3 / Almacenamiento

- ¿Qué proveedor de almacenamiento usarán? (AWS, Cloudflare R2, DigitalOcean, otro)
- ¿Tienen bucket creado y credenciales generadas?

---

## Verificación rápida post-despliegue

```bash
# 1. Health check
curl https://api.tu-dominio.com/api/v1/health

# 2. Servicios públicos
curl https://api.tu-dominio.com/api/v1/servicios

# 3. Auth del admin (debe devolver 401 con clave incorrecta)
curl -X POST https://api.tu-dominio.com/api/v1/admin/auth \
  -H "Content-Type: application/json" \
  -d '{"password":"incorrecta"}'
```
