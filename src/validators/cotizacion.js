'use strict';
const { z } = require('zod');

const ServicioItem = z.object({
  code:     z.string().min(1),
  name:     z.string().min(1),
  norma:    z.string().optional().nullable(),
  sub:      z.string().optional().nullable(),
  muestras: z.number().int().positive().optional().nullable(),
  precio:   z.number().nonnegative().optional().nullable(),
});

const UbicacionModel = z.object({
  lat:     z.string(),
  lng:     z.string(),
  address: z.string().optional().nullable(),
});

const CotizacionRequest = z.object({
  nombre:            z.string().trim().min(1, 'El nombre no puede estar vacío'),
  correo:            z.string().email('Correo inválido'),
  empresa:           z.string().trim().min(1, 'La empresa no puede estar vacía'),
  telefono:          z.string().trim().min(1, 'El teléfono no puede estar vacío'),
  rtn:               z.string().optional().nullable(),
  nombreProyecto:    z.string().trim().min(1, 'El nombre del proyecto no puede estar vacío'),
  direccionProyecto: z.string().optional().nullable(),
  descripcion:       z.string().optional().nullable(),
  servicios:         z.array(ServicioItem).min(1, 'Debe seleccionar al menos un servicio'),
  ubicacion:         UbicacionModel.optional().nullable(),
});

module.exports = { CotizacionRequest };
