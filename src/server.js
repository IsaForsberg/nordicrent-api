
'use strict';

require('dotenv').config();
const express = require('express');
const pool = require('./config/db');
//const { connectMongo, reportsCollection, closeMongo } = require('./connections/mongo');
const { positiveId, validEquipment, validBooking, validReport} = require('./validation');


function dbFailure(error, res) {
  if (['ER_DUP_ENTRY', 'ER_ROW_IS_REFERENCED_2'].includes(error.code)) {
    return res.status(409).json({ error: 'Database constraint rejected the change' });
  }
  if(['ER_CHECK_CONSTRAINT_VIOLATED', 'ER_NO_REFERENCED_ROW_2'].includes(error.code)) {
    return res.status(400).json({ error: 'Database rejected the data input' });
  }
  console.error('MySQL failure:', error.code || error.message);
  return res.status(500).json({ error: 'Database operation failed' });
}



const app = express();
app.use(express.json());


app.get('/api/health', (req, res) => res.json({ status: 'ok' }));



app.get('/api/equipment', async (req, res) => {
 try {
 const [rows] = await pool.execute(`
     SELECT e.equipment_id, e.model_name, d.city, e.status, e.daily_price AS current_daily_price, c.name AS category_name
    FROM equipment AS e
     JOIN depots AS d ON d.depot_id = e.depot_id
     JOIN categories AS c ON c.category_id = e.category_id
    ORDER BY d.city, current_daily_price;
 `);
 return res.json(rows);
 } catch (error) {  
    console.error('GET /api/equipment failed:', error.message)
    return dbFailure(error, res);
 }
});


  app.post('/api/equipment', async (req, res) => {
      if (!validEquipment(req.body)) {
    return res.status(400).json({ error: 'Missing or invalid fields. Required: category_id, depot_id, model_name, daily_price, purchase_date' });
  }
  try {
    const [result] = await pool.execute(
      'INSERT INTO equipment (category_id, depot_id, model_name, daily_price, purchase_date) VALUES (?, ?, ?, ?, ?)',
      [Number(req.body.category_id), Number(req.body.depot_id), req.body.model_name.trim(), req.body.daily_price, req.body.purchase_date]
    );
    return res.status(201).json({ equipment_id: result.insertId });
  } catch (error) {
    console.error('POST /api/equipment failed:', error.message)
   return dbFailure(error, res);
  }
});

app.put('/api/equipment/:id', async (req, res) => {
  if (!positiveId(req.params.id) || !validEquipment(req.body)) {
    return res.status(400).json({ error: 'Valid equipment id in the URL and valid fields required: category_id, depot_id, model_name, daily_price, purchase_date' });
  }
  try {
    const [result] = await pool.execute(
      `UPDATE equipment 
       SET category_id=?, depot_id=?, model_name=?, daily_price=?, purchase_date=? 
       WHERE equipment_id=? AND status <> 'retired'`,
      [Number(req.body.category_id), Number(req.body.depot_id), req.body.model_name.trim(), req.body.daily_price, req.body.purchase_date, Number(req.params.id)]
    );
    if (result.affectedRows === 0) {
      return res.status(404).json({ error: 'Equipment not found or is retired' });
    }
    return res.json({ updated: true });
  } catch (error) {
    console.error('PUT /api/equipment failed:', error.message)
    return dbFailure(error, res);
  }
});

app.delete('/api/equipment/:id', async (req, res) => {
  if (!positiveId(req.params.id)) {
    return res.status(400).json({ error: 'Valid equipment ID required' });
  }
  try {
    const [result] = await pool.execute(
      `UPDATE equipment
       SET status='retired'
       WHERE equipment_id=? AND status<>'retired' AND status<>'rented'`,
      [Number(req.params.id)]
    );
    if (result.affectedRows === 0) {
      return res.status(404).json({ error: 'Equipment not found or is rented or retired' });
    }
    return res.status(200).json({ equipment_id: Number(req.params.id), status: 'retired' });
  } catch (error) {
    console.error('DELETE /api/equipment failed:', error.message)
    return dbFailure(error, res);
  }
});


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




