'use strict';

require('dotenv').config();

const mysql = require('mysql2/promise');

// Connection pool: a set of reusable connections between Node and MySQL.
// Like 5 open checkouts: if all are busy, the next request waits for a free one.
const pool = mysql.createPool({
    host: process.env.DB_HOST || '127.0.0.1',   // Connection settings come from .env (process.env).
    port: Number(process.env.DB_PORT || 3306),  // host, port and database fall back to a default value; user and password do not.
    database: process.env.DB_NAME || 'nordicrent_api',
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    waitForConnections: true,
    connectionLimit: 5,
    decimalNumbers: false // DECIMAL values (e.g. daily_price) are returned as strings like "350.00",
    });                     // because JavaScript numbers cannot store every decimal exactly.

module.exports = pool;