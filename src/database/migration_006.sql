-- ============================================================
-- Migración 006 — Columnas docx_key y docx_url en cotizaciones
-- El docx ahora se almacena en S3 en vez del filesystem local.
-- Ejecutar: mysql -u root -p lab_cotizaciones < src/database/migration_006.sql
-- ============================================================

USE lab_cotizaciones;

ALTER TABLE cotizaciones
  ADD COLUMN docx_key VARCHAR(500) DEFAULT NULL
    COMMENT 'Clave del objeto .docx en S3 (para borrado). Ej: cotizaciones/1234_abc.docx',
  ADD COLUMN docx_url VARCHAR(1000) DEFAULT NULL
    COMMENT 'URL pública del .docx en S3 (para descarga directa)';
