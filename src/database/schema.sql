-- ============================================================
-- Esquema MariaDB — Laboratorios Ingeniería Civil UNAH
-- ============================================================

CREATE DATABASE IF NOT EXISTS lab_cotizaciones
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE lab_cotizaciones;

-- ── Catálogo de servicios (migrado desde labData.js del frontend) ─────────────
CREATE TABLE IF NOT EXISTS servicios (
  id         INT            AUTO_INCREMENT PRIMARY KEY,
  code       VARCHAR(20)    NOT NULL UNIQUE,
  categoria  VARCHAR(50)    NOT NULL,             -- suelos | concreto | agregados | acero | topografia
  name       VARCHAR(255)   NOT NULL,
  norma      VARCHAR(150)   DEFAULT NULL,
  sub        VARCHAR(255)   DEFAULT NULL,         -- subclasificación (ej: "No. 4 y 3" en acero)
  note       VARCHAR(255)   DEFAULT NULL,         -- nota extra (ej: "Tarifa por día" en topografía)
  precio     DECIMAL(10,2)  DEFAULT NULL,
  activo     TINYINT(1)     NOT NULL DEFAULT 1,
  created_at TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ── Cotizaciones (espejo de Google Sheets + datos extras) ─────────────────────
CREATE TABLE IF NOT EXISTS cotizaciones (
  id                 INT            AUTO_INCREMENT PRIMARY KEY,
  numero_cotizacion  VARCHAR(50)    NOT NULL,
  nombre             VARCHAR(255)   NOT NULL,
  correo             VARCHAR(255)   NOT NULL,
  empresa            VARCHAR(255)   NOT NULL,
  telefono           VARCHAR(50)    NOT NULL,
  rtn                VARCHAR(50)    DEFAULT NULL,
  nombre_proyecto    VARCHAR(255)   NOT NULL,
  direccion_proyecto TEXT           DEFAULT NULL,
  descripcion        TEXT           DEFAULT NULL,
  lat                VARCHAR(50)    DEFAULT NULL,
  lng                VARCHAR(50)    DEFAULT NULL,
  direccion_mapa     TEXT           DEFAULT NULL,
  subtotal           DECIMAL(10,2)  DEFAULT 0.00,
  sheets_fila        INT            DEFAULT NULL,   -- fila registrada en Google Sheets
  docx_path          VARCHAR(500)   DEFAULT NULL,
  created_at         TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ── Ítem de servicio por cotización ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS cotizacion_items (
  id             INT            AUTO_INCREMENT PRIMARY KEY,
  cotizacion_id  INT            NOT NULL,
  servicio_code  VARCHAR(20)    NOT NULL,
  servicio_name  VARCHAR(255)   NOT NULL,
  norma          VARCHAR(150)   DEFAULT NULL,
  sub            VARCHAR(255)   DEFAULT NULL,
  muestras       INT            DEFAULT NULL,
  precio         DECIMAL(10,2)  DEFAULT NULL,
  total          DECIMAL(10,2)  DEFAULT 0.00,
  FOREIGN KEY (cotizacion_id) REFERENCES cotizaciones(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ============================================================
-- SEED — Catálogo de servicios (fuente: labData.js del frontend)
-- ============================================================

INSERT IGNORE INTO servicios (code, categoria, name, norma, sub, note, precio) VALUES

-- ── Ensayos de Suelos ─────────────────────────────────────────────────────────
('SU-01', 'suelos',    'Contenido de Humedad',   'ASTM D2216',               NULL, NULL, 150.00),
('SU-02', 'suelos',    'Granulometría',           'ASTM D6913 / AASHTO T88',  NULL, NULL, 250.00),
('SU-04', 'suelos',    'Límite Líquido',          'ASTM D4318 / AASHTO T89',  NULL, NULL, 200.00),
('SU-05', 'suelos',    'Límite Plástico',         'ASTM D4318 / AASHTO T90',  NULL, NULL, 200.00),
('SU-09', 'suelos',    'Clasificación de Suelo',  'ASTM D2487 / AASHTO M145', NULL, NULL, 600.00),
('SU-10', 'suelos',    'Proctor Estándar',        'ASTM D698 / AASHTO T99',   NULL, NULL, 500.00),
('SU-11', 'suelos',    'Proctor Modificado',      'ASTM D1557 / AASHTO T180', NULL, NULL, 700.00),
('SU-19', 'suelos',    'Peso Específico',         'ASTM D854 / AASHTO T100',  NULL, NULL, 400.00),
('SU-21', 'suelos',    'Peso Volumétrico',        'ASTM D7263',               NULL, NULL, 400.00),
('SU-22', 'suelos',    'Hidrometría',             'ASTM D7928 / AASHTO T88',  NULL, NULL, 1400.00),

-- ── Ensayos de Concreto ───────────────────────────────────────────────────────
('CU-01', 'concreto',  'Curado de Cilindros',           'ASTM C31 / AASHTO T23', NULL, NULL, 200.00),
('CU-04', 'concreto',  'Rotura de Cilindros y Bloques', 'ASTM C39 / AASHTO T22', NULL, NULL, 250.00),

-- ── Ensayos de Agregados ──────────────────────────────────────────────────────
('AG-02', 'agregados', 'Desgaste Los Ángeles',       'ASTM C131 / AASHTO T96', NULL, NULL, 800.00),
('AG-04', 'agregados', 'Peso Unitario con Golpes',   'ASTM C29 / AASHTO T19',  NULL, NULL, 300.00),
('AG-05', 'agregados', 'Peso Unitario sin Golpes',   'ASTM C29 / AASHTO T19',  NULL, NULL, 300.00),
('AG-08', 'agregados', 'Alterabilidad por Sulfatos', 'ASTM C88 / AASHTO T104', NULL, NULL, 5000.00),

-- ── Ensayos de Acero de Refuerzo ──────────────────────────────────────────────
('AC-01', 'acero',     'Varillas a Tensión — Fluencia y Elongación', 'ASTM A615 / ASTM E8', 'No. 11, 10 y 8', NULL, 1500.00),
('AC-02', 'acero',     'Varillas a Tensión — Fluencia y Elongación', 'ASTM A615 / ASTM E8', 'No. 6 y 8',      NULL, 1000.00),
('AC-03', 'acero',     'Varillas a Tensión — Fluencia y Elongación', 'ASTM A615 / ASTM E8', 'No. 4 y 3',      NULL,  950.00),

-- ── Topografía Catastral ──────────────────────────────────────────────────────
('ST-01', 'topografia', 'Tegucigalpa (TGU)',          'Normas Propias', NULL, 'Tarifa por día de trabajo en campo',     3000.00),
('ST-02', 'topografia', 'San Pedro Sula (SPS)',        'Normas Propias', NULL, 'Tarifa por día de trabajo en campo',     4500.00),
('ST-03', 'topografia', 'Tierra Adentro / Interior',  'Normas Propias', NULL, 'Incluye viáticos según zona de destino', 6000.00),

-- ── Topografía para Proyectos de Ingeniería ───────────────────────────────────
('ST-04', 'topografia', 'Proyectos de Ingeniería',    'Normas Propias', NULL, 'Tarifa por día de trabajo en campo',        0.00);
