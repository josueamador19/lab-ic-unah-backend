'use strict';
const mysql  = require('mysql2/promise');
const config = require('../config');

const pool = mysql.createPool({
  host:            config.db.host,
  port:            config.db.port,
  user:            config.db.user,
  password:        config.db.password,
  database:        config.db.database,
  waitForConnections:    true,
  connectionLimit:       1,
  timezone:              'Z',
  enableKeepAlive:       true,
  keepAliveInitialDelay: 0,
});

module.exports = pool;
