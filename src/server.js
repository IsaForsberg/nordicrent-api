'use strict';

require('dotenv').config();
const express = require('express');
const pool = require('./config/db');
const EquipmentRepository = require('./repositories/equipmentRepository');
const { connectMongo, reportsCollection, closeMongo } = require('./config/mongo');
const { positiveId, validEquipment, validBooking, validReport } = require('./validation');


// MySQL errors that passed the JS validation → HTTP status.
// 409 = conflicts with existing data, 400 = MySQL rejected the input,
// 500 = unexpected error (generic message to the client, details only in the terminal).
function dbFailure(error, res) {
  if (['ER_DUP_ENTRY', 'ER_ROW_IS_REFERENCED_2'].includes(error.code)) {
    return res.status(409).json({ error: 'Database constraint rejected the change' });
  }
  if (['ER_CHECK_CONSTRAINT_VIOLATED', 'ER_NO_REFERENCED_ROW_2'].includes(error.code)) {
    return res.status(400).json({ error: 'Database rejected the data input' });
  }
  console.error('MySQL failure:', error.code || error.message);
  return res.status(500).json({ error: 'Database operation failed' });
}


const app = express();
app.use(express.json());


// GET /api/health: shows that the API is running.
app.get('/api/health', (req, res) => res.json({ status: 'ok' }));


const equipmentRepository = new EquipmentRepository(pool);

// GET /api/equipment: all equipment with city and category name (JOIN).
app.get('/api/equipment', async (req, res) => {
  try {
    const rows = await equipmentRepository.findAll();
    return res.json(rows);
  } catch (error) {
    console.error('GET /api/equipment failed:', error.message);
    return dbFailure(error, res);
  }
});

// POST /api/equipment: adds a new item → 201 + equipment_id.
app.post('/api/equipment', async (req, res) => {
  if (!validEquipment(req.body)) {
    return res.status(400).json({ error: 'Missing or invalid fields. Required: category_id, depot_id, model_name, daily_price, purchase_date' });
  }
  try {
    const equipmentId = await equipmentRepository.create(req.body);
    return res.status(201).json({ equipment_id: equipmentId });
  } catch (error) {
    console.error('POST /api/equipment failed:', error.message);
    return dbFailure(error, res);
  }
});

// PUT /api/equipment/:id: updates all fields of an item that is not retired.
app.put('/api/equipment/:id', async (req, res) => {
  if (!positiveId(req.params.id) || !validEquipment(req.body)) {
    return res.status(400).json({ error: 'Valid equipment id in the URL and valid fields required: category_id, depot_id, model_name, daily_price, purchase_date' });
  }
  try {
    const affectedRows = await equipmentRepository.update(req.params.id, req.body);
    if (affectedRows === 0) {
      return res.status(404).json({ error: 'Equipment not found or is retired' });
    }
    return res.json({ updated: true });
  } catch (error) {
    console.error('PUT /api/equipment failed:', error.message);
    return dbFailure(error, res);
  }
});

// DELETE /api/equipment/:id: retires the item (soft delete), the row is kept.
app.delete('/api/equipment/:id', async (req, res) => {
  if (!positiveId(req.params.id)) {
    return res.status(400).json({ error: 'Valid equipment ID required' });
  }
  try {
    const affectedRows = await equipmentRepository.retire(req.params.id);
    if (affectedRows === 0) {
      return res.status(404).json({ error: 'Equipment not found or is rented or retired' });
    }
    return res.status(200).json({ equipment_id: Number(req.params.id), status: 'retired' });
  } catch (error) {
    console.error('DELETE /api/equipment failed:', error.message);
    return dbFailure(error, res);
  }
});


// POST /api/bookings: booking + booking lines in one transaction (all or nothing).
app.post('/api/bookings', async (req, res) => {
  if (!validBooking(req.body)) {
    return res.status(400).json({ error: 'Missing or invalid fields. Required: customer_id, equipment_ids, start_date, end_date' });
  }
  // Declared before try so catch and finally can use it (block scope).
  const connection = await pool.getConnection();
  try {
    // The transaction lives on one connection, so every query uses connection, not pool.
    await connection.beginTransaction();
    const [result] = await connection.execute(
      'INSERT INTO bookings (customer_id, start_date, end_date) VALUES (?, ?, ?)',
      [Number(req.body.customer_id), req.body.start_date, req.body.end_date]
    );
    const bookingId = result.insertId;

    const equipment_ids = req.body.equipment_ids;

    for (const equipmentId of equipment_ids) {

      // Overlap check (<= and >= give the buffer day). Runs before the INSERT,
      // otherwise it would find this booking's own line.
      const [conflicts] = await connection.execute(
        `SELECT b.booking_id
         FROM booking_lines AS bl
         JOIN bookings AS b ON b.booking_id = bl.booking_id
         WHERE bl.equipment_id = ?
           AND b.status IN ('confirmed', 'active')
           AND b.start_date <= ?
           AND b.end_date   >= ?`,
        [Number(equipmentId), req.body.end_date, req.body.start_date]
      );

      if (conflicts.length > 0) {
        await connection.rollback();
        return res.status(409).json({ error: 'The selected date is not available' });
      }

      // Price is copied from equipment (snapshot), never taken from the client.
      const [lineResult] = await connection.execute(
        `INSERT INTO booking_lines (booking_id, equipment_id, daily_price)
         SELECT ?, equipment_id, daily_price
         FROM equipment
         WHERE equipment_id = ? AND status <> 'retired' AND status <> 'maintenance'`,
        [bookingId, Number(equipmentId)]
      );

      // 0 rows = equipment missing, retired or in maintenance → undo the whole booking.
      if (lineResult.affectedRows === 0) {
        await connection.rollback();
        return res.status(409).json({ error: 'Equipment not found or not available' });
      }
    }
    await connection.commit();
    return res.status(201).json({ booking_id: bookingId });
  } catch (error) {
    await connection.rollback();
    console.error('POST /api/bookings failed:', error.message);
    return dbFailure(error, res);
  } finally {
    connection.release();
  }
});


// POST /api/reports: saves a condition report in MongoDB after checking the item in MySQL.
app.post('/api/reports', async (req, res) => {
  if (!validReport(req.body)) {
    return res.status(400).json({ error: 'Valid equipmentId, notes, checklist and damageFlag is required' });
  }
  try {
    // No FK between MongoDB and MySQL, so the backend checks that the equipment exists.
    const rows = await equipmentRepository.findById(req.body.equipmentId);
    if (!rows.length) return res.status(404).json({ error: 'Equipment not found or is retired' });

    const document = {
      equipmentId: Number(req.body.equipmentId),
      notes: req.body.notes.trim(),
      checklist: req.body.checklist,
      damageFlag: req.body.damageFlag,
      createdAt: new Date()
    };
    const result = await reportsCollection().insertOne(document);
    return res.status(201).json({ report_id: result.insertedId.toString() });
  } catch (error) {
    // Only a SELECT in MySQL (no constraint errors possible), so no dbFailure here.
    console.error('POST /api/reports failed:', error.message);
    return res.status(500).json({ error: 'Could not save report' });
  }
});

// GET /api/reports/equipment/:id: the item's condition reports, newest first.
app.get('/api/reports/equipment/:id', async (req, res) => {
  if (!positiveId(req.params.id)) {
    return res.status(400).json({ error: 'Valid equipment ID required' });
  }
  try {
    // req.params is always a string; equipmentId is stored as a number. No reports = 200 [].
    const reports = await reportsCollection()
      .find({ equipmentId: Number(req.params.id) })
      .sort({ createdAt: -1 })
      .toArray();
    return res.json(reports);
  } catch (error) {
    console.error('GET /api/reports/equipment/:id failed:', error.message);
    return res.status(500).json({ error: 'Could not fetch reports' });
  }
});


const PORT = Number(process.env.PORT || 3007);

async function start() {
  await pool.query('SELECT 1');
  await connectMongo();
  return app.listen(PORT, () => {
    console.log(`NordicRent API is running at http://localhost:${PORT}/api/health`);
  });
}


start().catch(async (error) => {
  console.error('Startup failed:', error.code || error.message);
  await pool.end();
  await closeMongo().catch(() => {});
  process.exitCode = 1;
});
