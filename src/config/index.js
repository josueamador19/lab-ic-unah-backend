'use strict';
require('dotenv').config();

const config = {
  port: parseInt(process.env.PORT || '8000', 10),
  env:  process.env.APP_ENV || 'development',

  cors: {
    origins: (process.env.ALLOWED_ORIGINS || 'http://localhost:5173')
      .split(',')
      .map(o => o.trim()),
  },

  // Puede ser la ruta al archivo JSON (desarrollo) o el contenido JSON como string (producción)
  googleServiceAccountJson: process.env.GOOGLE_SERVICE_ACCOUNT_JSON || './credentials/service_account.json',
  spreadsheetId:            process.env.SPREADSHEET_ID || '',

  db: {
    host:     process.env.DB_HOST     || 'localhost',
    port:     parseInt(process.env.DB_PORT || '3306', 10),
    user:     process.env.DB_USER     || 'root',
    password: process.env.DB_PASS     || '',
    database: process.env.DB_NAME     || 'lab_cotizaciones',
  },

  smtp: {
    user: process.env.SMTP_USER || '',
    pass: process.env.SMTP_PASS || '',
  },

  adminKey: process.env.ADMIN_KEY || 'cambiar_esta_clave',

  s3: {
    endpoint:       process.env.S3_ENDPOINT        || null,   // solo para Cloudflare R2, DO Spaces, MinIO…
    region:         process.env.S3_REGION          || 'us-east-1',
    bucket:         process.env.S3_BUCKET          || '',
    accessKey:      process.env.S3_ACCESS_KEY       || '',
    secretKey:      process.env.S3_SECRET_KEY       || '',
    publicUrl:      process.env.S3_PUBLIC_URL       || null,  // URL pública o CDN del bucket
    forcePathStyle: process.env.S3_FORCE_PATH_STYLE === 'true',
  },
};

module.exports = config;
