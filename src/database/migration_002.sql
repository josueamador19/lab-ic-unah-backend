-- ============================================================
-- Migración 002 — Normas Cards + Proceso Pasos
-- Ejecutar: mysql -u root -p lab_cotizaciones < src/database/migration_002.sql
-- ============================================================

USE lab_cotizaciones;

CREATE TABLE IF NOT EXISTS normas_cards (
  id          VARCHAR(20)   NOT NULL PRIMARY KEY,
  icon_text   VARCHAR(30)   NOT NULL,
  icon_style  TEXT          NOT NULL,   -- JSON con estilos CSS del ícono
  title       VARCHAR(200)  NOT NULL,
  sub         VARCHAR(300)  NOT NULL,
  descripcion TEXT          NOT NULL,
  tags        TEXT          NOT NULL,   -- JSON array ["ASTM D698", ...]
  orden       INT           NOT NULL DEFAULT 0,
  activo      TINYINT(1)    NOT NULL DEFAULT 1,
  updated_at  TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS proceso_pasos (
  id          INT           AUTO_INCREMENT PRIMARY KEY,
  numero      VARCHAR(5)    NOT NULL,
  titulo      VARCHAR(100)  NOT NULL,
  descripcion TEXT          NOT NULL,
  orden       INT           NOT NULL DEFAULT 0,
  activo      TINYINT(1)    NOT NULL DEFAULT 1,
  updated_at  TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Seed normas_cards
INSERT IGNORE INTO normas_cards (id, icon_text, icon_style, title, sub, descripcion, tags, orden) VALUES
('astm',
 'ASTM',
 '{"background":"linear-gradient(135deg,#1a3a6e,#0d2045)","color":"#90c8f8"}',
 'ASTM International',
 'American Society for Testing and Materials',
 'Principal referencia técnica para ensayos de materiales de construcción. Sus métodos estandarizados garantizan reproducibilidad y comparabilidad de resultados a nivel internacional.',
 '["ASTM D698","ASTM D1557","ASTM D4318","ASTM D2216","ASTM C39","ASTM A615"]',
 1),

('aashto',
 'AASHTO',
 '{"background":"linear-gradient(135deg,#1e4d2b,#0f2916)","color":"#7ecf8a","fontSize":"0.6rem"}',
 'AASHTO',
 'American Association of State Highway and Transportation Officials',
 'Normas específicas para materiales y ensayos en infraestructura vial. Complementa la normativa ASTM con requisitos orientados a carreteras, puentes y obras de transporte.',
 '["AASHTO T99","AASHTO T180","AASHTO T89","AASHTO T90","AASHTO T88","AASHTO T193"]',
 2),

('aci',
 'ACI',
 '{"background":"linear-gradient(135deg,#6b1a1a,#3d0f0f)","color":"#f0a0a0"}',
 'ACI — American Concrete Institute',
 'Normas de diseño y control de calidad del concreto',
 'Estándares para diseño de mezclas, control de resistencia y práctica de colocación del concreto estructural. Referencia fundamental en proyectos de edificación e infraestructura.',
 '["ACI 211","ACI 214","ACI 301","ACI 318"]',
 3),

('iso',
 'ISO',
 '{"background":"linear-gradient(135deg,#8a6a00,#5a4400)","color":"#FFFF00"}',
 'ISO — International Organization for Standardization',
 'Normas de gestión y calidad de laboratorio',
 'Marco normativo para sistemas de gestión de calidad, calibración de equipos y aseguramiento de resultados. La norma ISO/IEC 17025 es la referencia internacional para la competencia técnica de laboratorios de ensayo.',
 '["ISO 9001","ISO/IEC 17025"]',
 4),

('nth',
 'NTH\nHN',
 '{"background":"linear-gradient(135deg,#1b2d50,#0a1a3a)","color":"#90c8f8","fontSize":"0.6rem","lineHeight":1.2,"whiteSpace":"pre"}',
 'Normas Técnicas de Honduras',
 'SOPTRAVI / SINIT — Marco nacional',
 'Normativas nacionales emitidas por la Secretaría de Infraestructura y Servicios Públicos de Honduras para obras públicas, carreteras y construcción civil en el territorio nacional.',
 '["Manual de Carreteras HN","SOPTRAVI","SINIT","Especificaciones Generales"]',
 5);

-- Seed proceso_pasos
INSERT IGNORE INTO proceso_pasos (numero, titulo, descripcion, orden) VALUES
('01', 'Solicitud',
 'Complete el formulario con los ensayos requeridos, cantidad de muestras y datos del proyecto.',
 1),
('02', 'Cotización',
 'En línea llenando el formulario o presencial en el segundo piso del edificio B1. El equipo técnico le enviará una propuesta formal con tiempos de entrega en 24–48 horas hábiles.',
 2),
('03', 'Pago',
 'Se le comunicará el proceso de pago vía correo electrónico con las instrucciones y monto a cancelar.',
 3),
('04', 'Ensayo',
 'Entrega de muestras en Edificio B1, 1er nivel. Horario de Lunes a Viernes / 8:00 AM - 3:00 PM',
 4),
('05', 'Resultados',
 'Informe firmado por el Ing. responsable con los resultados técnicos de los ensayos realizados.',
 5);
