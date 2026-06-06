'use strict';
const app    = require('./src/app');
const config = require('./src/config');

const PORT = config.port;
app.listen(PORT, () => {
  console.log(`[Lab Backend] escuchando en http://localhost:${PORT}`);
  console.log(`[Lab Backend] env: ${config.env}`);
});
