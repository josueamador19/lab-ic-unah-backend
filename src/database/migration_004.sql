-- ============================================================
-- Migración 004 — Columna sheets_synced en cotizaciones
-- Ejecutar: mysql -u root -p lab_cotizaciones < src/database/migration_004.sql
-- ============================================================

USE lab_cotizaciones;

-- sheets_fila ya existe pero puede ser NULL si Sheets falló.
-- Agregamos sheets_synced como bandera explícita y sync_intentos para el admin.
ALTER TABLE cotizaciones
  ADD COLUMN IF NOT EXISTS sheets_synced   TINYINT(1) NOT NULL DEFAULT 0 AFTER sheets_fila,
  ADD COLUMN IF NOT EXISTS sync_error      TEXT       DEFAULT NULL AFTER sheets_synced;

-- Marcar como sincronizadas las cotizaciones que ya tienen fila en Sheets
UPDATE cotizaciones SET sheets_synced = 1 WHERE sheets_fila IS NOT NULL AND sheets_fila > 0;
