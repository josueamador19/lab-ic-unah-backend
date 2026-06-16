-- ============================================================
-- Schema completo de producción — Lab. Ingeniería Civil UNAH
-- Incluye: schema.sql + migraciones 001–006
-- Ejecutar UNA sola vez en la base de datos nueva.
-- ============================================================

-- ── Tablas ───────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS servicios (
  id         INT            AUTO_INCREMENT PRIMARY KEY,
  code       VARCHAR(20)    NOT NULL UNIQUE,
  categoria  VARCHAR(50)    NOT NULL,
  name       VARCHAR(255)   NOT NULL,
  norma      VARCHAR(150)   DEFAULT NULL,
  sub        VARCHAR(255)   DEFAULT NULL,
  note       VARCHAR(255)   DEFAULT NULL,
  precio     DECIMAL(10,2)  DEFAULT NULL,
  activo     TINYINT(1)     NOT NULL DEFAULT 1,
  created_at TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

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
  sheets_fila        INT            DEFAULT NULL,
  sheets_synced      TINYINT(1)     NOT NULL DEFAULT 0,
  sync_error         TEXT           DEFAULT NULL,
  docx_path          VARCHAR(500)   DEFAULT NULL,
  docx_key           VARCHAR(500)   DEFAULT NULL,
  docx_url           VARCHAR(1000)  DEFAULT NULL,
  created_at         TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

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

CREATE TABLE IF NOT EXISTS equipos (
  id          INT            AUTO_INCREMENT PRIMARY KEY,
  title       VARCHAR(255)   NOT NULL,
  descripcion TEXT           NOT NULL,
  badge       VARCHAR(150)   DEFAULT NULL,
  img_url     VARCHAR(500)   DEFAULT NULL,
  img_key     VARCHAR(500)   DEFAULT NULL,
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

CREATE TABLE IF NOT EXISTS normas_cards (
  id          VARCHAR(20)   NOT NULL PRIMARY KEY,
  icon_text   VARCHAR(30)   NOT NULL,
  icon_style  TEXT          NOT NULL,
  title       VARCHAR(200)  NOT NULL,
  sub         VARCHAR(300)  NOT NULL,
  descripcion TEXT          NOT NULL,
  tags        TEXT          NOT NULL,
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

CREATE TABLE IF NOT EXISTS faq (
  id          INT           AUTO_INCREMENT PRIMARY KEY,
  pregunta    TEXT          NOT NULL,
  respuesta   TEXT          NOT NULL,
  orden       INT           NOT NULL DEFAULT 0,
  activo      TINYINT(1)    NOT NULL DEFAULT 1,
  created_at  TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ── Seed: Servicios ──────────────────────────────────────────────────────────

INSERT IGNORE INTO servicios (code, categoria, name, norma, sub, note, precio) VALUES
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
('CU-01', 'concreto',  'Curado de Cilindros',           'ASTM C31 / AASHTO T23', NULL, NULL, 200.00),
('CU-04', 'concreto',  'Rotura de Cilindros y Bloques', 'ASTM C39 / AASHTO T22', NULL, NULL, 250.00),
('AG-02', 'agregados', 'Desgaste Los Ángeles',       'ASTM C131 / AASHTO T96', NULL, NULL, 800.00),
('AG-04', 'agregados', 'Peso Unitario con Golpes',   'ASTM C29 / AASHTO T19',  NULL, NULL, 300.00),
('AG-05', 'agregados', 'Peso Unitario sin Golpes',   'ASTM C29 / AASHTO T19',  NULL, NULL, 300.00),
('AG-08', 'agregados', 'Alterabilidad por Sulfatos', 'ASTM C88 / AASHTO T104', NULL, NULL, 5000.00),
('AC-01', 'acero',     'Varillas a Tensión — Fluencia y Elongación', 'ASTM A615 / ASTM E8', 'No. 11, 10 y 8', NULL, 1500.00),
('AC-02', 'acero',     'Varillas a Tensión — Fluencia y Elongación', 'ASTM A615 / ASTM E8', 'No. 6 y 8',      NULL, 1000.00),
('AC-03', 'acero',     'Varillas a Tensión — Fluencia y Elongación', 'ASTM A615 / ASTM E8', 'No. 4 y 3',      NULL,  950.00),
('ST-01', 'topografia', 'Tegucigalpa (TGU)',         'Normas Propias', NULL, 'Tarifa por día de trabajo en campo',     3000.00),
('ST-02', 'topografia', 'San Pedro Sula (SPS)',       'Normas Propias', NULL, 'Tarifa por día de trabajo en campo',     4500.00),
('ST-03', 'topografia', 'Tierra Adentro / Interior', 'Normas Propias', NULL, 'Incluye viáticos según zona de destino', 6000.00),
('ST-04', 'topografia', 'Proyectos de Ingeniería',   'Normas Propias', NULL, 'Tarifa por día de trabajo en campo',        0.00);

-- ── Seed: Equipos (sin imágenes — se suben desde el panel admin) ─────────────

INSERT IGNORE INTO equipos (id, title, descripcion, badge, img_url, img_key, orden) VALUES
(1, 'Topografía',
   'Ofrecemos levantamientos topográficos catastrales, planimétricos y altimétricos para proyectos de construcción e ingeniería. Contamos con estación total de alta precisión y dron RTK para fotogrametría aérea, cubriendo zonas urbanas y rurales en Tegucigalpa, San Pedro Sula e interior del país.',
   'Topografía', NULL, NULL, 1),
(2, 'Máquina de Desgaste L.A',
   'Equipo para determinar la resistencia al desgaste de agregados gruesos mediante abrasión e impacto. Ensayo bajo norma ASTM C131 / AASHTO T96.',
   'Agregados · AG-02', NULL, NULL, 2),
(3, 'Equipo de Hidrometría',
   'Determinación de la distribución granulométrica de suelos finos mediante sedimentación. Análisis de partículas menores a 0.075 mm bajo norma ASTM D7928 / AASHTO T88.',
   'Suelos · SU-22', NULL, NULL, 3),
(4, 'Granulometría y Copa de Casagrande',
   'Juego de tamices para análisis granulométrico (ASTM D6913) y copa de Casagrande para determinación del límite líquido de suelos (ASTM D4318 / AASHTO T89).',
   'Suelos · SU-02 / SU-04', NULL, NULL, 4),
(5, 'Máquina de Compresión Universal',
   'Prensa hidráulica para ensayo de resistencia a la compresión de cilindros y tension en el acero. Capacidad hasta 950 kN bajo norma ASTM C39 / AASHTO T22.',
   'Concreto · CU-04', NULL, NULL, 5);

-- ── Seed: Configuración ──────────────────────────────────────────────────────

INSERT IGNORE INTO configuracion (clave, label, valor) VALUES
('email',        'Correo electrónico',    'laboratorio.ic@unah.edu.hn'),
('jefe',         'Jefe de Laboratorios',  'ING. JOEL FRANCISCO AMADOR R.'),
('departamento', 'Departamento',          'INGENIERÍA CIVIL — UNAH'),
('ubicacion',    'Ubicación',             'EDIFICIO B1, PRIMER NIVEL — CIUDAD UNIVERSITARIA'),
('colaboracion', 'En colaboración con',   'FUNDAUNAH'),
('horario',      'Horario de atención',   'LUNES – VIERNES / 8:00 AM – 3:00 PM');

-- ── Seed: Normas ─────────────────────────────────────────────────────────────

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

-- ── Seed: Proceso ────────────────────────────────────────────────────────────

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

-- ── Seed: FAQ ────────────────────────────────────────────────────────────────

INSERT IGNORE INTO faq (id, pregunta, respuesta, orden) VALUES
(1, '¿Cuánto tiempo tarda en estar listo un ensayo?',
 'Los tiempos de entrega están sujetos a la demanda laboral bajo la cual se encuentre el laboratorio al momento de recibir las muestras, así como a la cantidad de muestras entregadas y al tipo de ensayo requerido.',
 1),
(2, '¿Cómo entrego mis muestras al laboratorio?',
 'Las muestras deben entregarse de forma presencial en el Edificio B1, Primer Nivel, Ciudad Universitaria — UNAH. El horario de recepción es de Lunes a Viernes de 8:00 AM a 3:00 PM. Cada muestra debe venir identificada con el nombre del proyecto y el tipo de ensayo requerido.',
 2),
(3, '¿Cuáles son los métodos de pago aceptados?',
 'Una vez recibida la solicitud de cotización, el equipo técnico le enviará las instrucciones de pago por correo electrónico con el monto a cancelar.',
 3),
(4, '¿Los ensayos cumplen con normas internacionales?',
 'Sí. Todos nuestros ensayos se realizan bajo las normativas ASTM (American Society for Testing and Materials) y AASHTO (American Association of State Highway and Transportation Officials), que son los estándares internacionales aplicados en ingeniería civil y geotecnia.',
 4),
(5, '¿Puedo solicitar varios ensayos en una sola cotización?',
 'Sí. El formulario de cotización permite agregar múltiples ensayos de distintas categorías (Suelos, Concreto, Agregados, Acero, Topografía) en una sola solicitud. Para cada ensayo puede especificar la cantidad de muestras y el número de ensayos requeridos.',
 5),
(6, '¿Qué sucede si mis muestras no cumplen con los requisitos mínimos?',
 'Si al recibir las muestras el personal técnico detecta que no cumplen con los requisitos mínimos (cantidad insuficiente, contaminación, mal etiquetado), se le notificará de inmediato para coordinar una nueva entrega sin costo adicional por la revisión.',
 6),
(7, '¿Los resultados tienen validez oficial?',
 'Los informes emitidos por el Laboratorio de Topografía, Suelos y Materiales están respaldados y firmados por los ingenieros del laboratorio, quienes son responsables de la ejecución de los ensayos y de la veracidad de los resultados reportados.',
 7),
(8, '¿Existen limitaciones respecto a los servicios con drones?',
 'Sí. La prestación de servicios con drones está condicionada por la Ley de Aeronáutica Civil de Honduras y las regulaciones vigentes sobre áreas de vuelo restringido en el país. Esto implica que ciertas zonas geográficas — como proximidades a aeropuertos, instalaciones militares, áreas gubernamentales u otras zonas de restricción aérea — pueden limitar o impedir la realización de vuelos con aeronaves no tripuladas. Antes de programar cualquier servicio con dron, el equipo técnico evaluará la viabilidad operativa conforme a la normativa aplicable.',
 8);
