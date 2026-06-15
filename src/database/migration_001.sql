-- ============================================================
-- Migración 001 — Equipos + Configuración
-- Ejecutar: mysql -u root -p lab_cotizaciones < src/database/migration_001.sql
-- ============================================================

USE lab_cotizaciones;

CREATE TABLE IF NOT EXISTS equipos (
  id          INT            AUTO_INCREMENT PRIMARY KEY,
  title       VARCHAR(255)   NOT NULL,
  descripcion TEXT           NOT NULL,
  badge       VARCHAR(150)   DEFAULT NULL,
  img_url     VARCHAR(500)   DEFAULT NULL,
  orden       INT            NOT NULL DEFAULT 0,
  activo      TINYINT(1)     NOT NULL DEFAULT 1,
  created_at  TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS configuracion (
  clave       VARCHAR(100)   NOT NULL PRIMARY KEY,
  label       VARCHAR(150)   NOT NULL,
  valor       TEXT           NOT NULL,
  updated_at  TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Seed configuración
INSERT IGNORE INTO configuracion (clave, label, valor) VALUES
('email',        'Correo electrónico',    'laboratorio.ic@unah.edu.hn'),
('jefe',         'Jefe de Laboratorios',  'ING. JOEL FRANCISCO AMADOR R.'),
('departamento', 'Departamento',          'INGENIERÍA CIVIL — UNAH'),
('ubicacion',    'Ubicación',             'EDIFICIO B1, PRIMER NIVEL — CIUDAD UNIVERSITARIA'),
('colaboracion', 'En colaboración con',   'FUNDAUNAH'),
('horario',      'Horario de atención',   'LUNES – VIERNES / 8:00 AM – 3:00 PM');

-- Seed equipos
INSERT IGNORE INTO equipos (id, title, descripcion, badge, img_url, orden) VALUES
(1, 'Topografía',
   'Ofrecemos levantamientos topográficos catastrales, planimétricos y altimétricos para proyectos de construcción e ingeniería. Contamos con estación total de alta precisión y dron RTK para fotogrametría aérea, cubriendo zonas urbanas y rurales en Tegucigalpa, San Pedro Sula e interior del país.',
   'Topografía', '/uploads/equipos/Topografia.png', 1),
(2, 'Maquina de Desgaste L.A',
   'Equipo para determinar la resistencia al desgaste de agregados gruesos mediante abrasión e impacto. Ensayo bajo norma ASTM C131 / AASHTO T96.',
   'Agregados · AG-02', '/uploads/equipos/Maquina_de_desgaste.jpg', 2),
(3, 'Equipo de Hidrometría',
   'Determinación de la distribución granulométrica de suelos finos mediante sedimentación. Análisis de partículas menores a 0.075 mm bajo norma ASTM D7928 / AASHTO T88.',
   'Suelos · SU-22', '/uploads/equipos/EquipodeHidrometria.jpg', 3),
(4, 'Granulometría y Copa de Casagrande',
   'Juego de tamices para análisis granulométrico (ASTM D6913) y copa de Casagrande para determinación del límite líquido de suelos (ASTM D4318 / AASHTO T89).',
   'Suelos · SU-02 / SU-04', '/uploads/equipos/granulometria.jpg', 4),
(5, 'Máquina de Compresión Universal',
   'Prensa hidráulica para ensayo de resistencia a la compresión de cilindros y tension en el acero. Capacidad hasta 950 kN bajo norma ASTM C39 / AASHTO T22.',
   'Concreto · CU-04', '/uploads/equipos/compresionuniversal.jpg', 5);
