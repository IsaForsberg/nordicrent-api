
'use strict';

require('dotenv').config();
const express = require('express');
const pool = require('./config/db');
//const { connectMongo, reportsCollection, closeMongo } = require('./connections/mongo');
//const { positiveId, validResource, validLoan, validReport } = require('./validation');


const app = express();
app.use(express.json());


app.get('/api/health', (req, res) => res.json({ status: 'ok' }));



const PORT = Number(process.env.PORT || 3007);
async function start() {
  await pool.query('SELECT 1');
  //await connectMongo();
  return app.listen(PORT, () => {
    console.log(`NordicRent is API running at http://localhost:${PORT}/api/health`);
  });
}


  start().catch(async (error) => {
    console.error('Startup failed:', error.message);
   // console.error('Startup failed:', error.code || error.message);
    await pool.end();
    //await closeMongo().catch(() => {});
    process.exitCode = 1;
  });
