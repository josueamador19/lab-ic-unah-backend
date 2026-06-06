'use strict';
const { S3Client, PutObjectCommand, DeleteObjectCommand } = require('@aws-sdk/client-s3');
const crypto = require('crypto');
const path   = require('path');
const config = require('../config');

const client = new S3Client({
  region: config.s3.region,
  ...(config.s3.endpoint && { endpoint: config.s3.endpoint }),
  credentials: {
    accessKeyId:     config.s3.accessKey,
    secretAccessKey: config.s3.secretKey,
  },
  forcePathStyle: config.s3.forcePathStyle, // necesario para MinIO, Cloudflare R2
});

async function uploadToS3(buffer, originalName, mimetype, folder = 'equipos') {
  const ext = path.extname(originalName).toLowerCase();
  const key = `${folder}/${Date.now()}_${crypto.randomBytes(8).toString('hex')}${ext}`;

  await client.send(new PutObjectCommand({
    Bucket:      config.s3.bucket,
    Key:         key,
    Body:        buffer,
    ContentType: mimetype,
  }));

  const base = config.s3.publicUrl
    || `https://${config.s3.bucket}.s3.${config.s3.region}.amazonaws.com`;

  return { key, url: `${base.replace(/\/$/, '')}/${key}` };
}

async function deleteFromS3(key) {
  if (!key) return;
  try {
    await client.send(new DeleteObjectCommand({ Bucket: config.s3.bucket, Key: key }));
  } catch (err) {
    console.warn('[S3] No se pudo eliminar el archivo:', key, err.message);
  }
}

module.exports = { uploadToS3, deleteFromS3 };
