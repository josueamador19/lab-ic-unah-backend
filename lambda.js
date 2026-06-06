// AWS Lambda entry point
const serverlessHttp = require('serverless-http');
const app            = require('./src/app');

module.exports.handler = serverlessHttp(app);
