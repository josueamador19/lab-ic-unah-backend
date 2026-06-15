-- ============================================================
-- Migración 003 — FAQ
-- Ejecutar: mysql -u root -p lab_cotizaciones < src/database/migration_003.sql
-- ============================================================

USE lab_cotizaciones;

CREATE TABLE IF NOT EXISTS faq (
  id          INT           AUTO_INCREMENT PRIMARY KEY,
  pregunta    TEXT          NOT NULL,
  respuesta   TEXT          NOT NULL,
  orden       INT           NOT NULL DEFAULT 0,
  activo      TINYINT(1)    NOT NULL DEFAULT 1,
  created_at  TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

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
