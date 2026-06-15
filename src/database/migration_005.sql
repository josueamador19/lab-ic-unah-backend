-- ============================================================
-- Migración 005 — Columna img_key en equipos (clave S3)
-- Ejecutar: mysql -u root -p lab_cotizaciones < src/database/migration_005.sql
-- ============================================================

USE lab_cotizaciones;

ALTER TABLE equipos
  ADD COLUMN img_key VARCHAR(500) DEFAULT NULL
    COMMENT 'Clave del objeto en S3 (para borrado). Ej: equipos/equipo_abc123.jpg';
