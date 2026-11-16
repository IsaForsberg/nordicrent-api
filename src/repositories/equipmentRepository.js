'use strict';

// All SQL for equipment. Only talks to the database: no req/res, no status codes.
// Errors are not caught here, they go to the route's catch.
class EquipmentRepository {
  // The pool (ready-made MySQL connections) is passed in, so the whole app shares one.
  constructor(pool) {
    this.pool = pool;
  }

  async findAll() {
    const [rows] = await this.pool.execute(
      `SELECT e.equipment_id, e.model_name, d.city, e.status, e.daily_price AS current_daily_price, c.name AS category_name
       FROM equipment AS e
       JOIN depots AS d ON d.depot_id = e.depot_id
       JOIN categories AS c ON c.category_id = e.category_id
       ORDER BY d.city, current_daily_price;`
    );
    return rows;
  }

  async create(data) {
    const [result] = await this.pool.execute(
      'INSERT INTO equipment (category_id, depot_id, model_name, daily_price, purchase_date) VALUES (?, ?, ?, ?, ?)',
      [Number(data.category_id), Number(data.depot_id), data.model_name.trim(), data.daily_price, data.purchase_date]
    );
    return result.insertId;
  }

  // update and retire return affectedRows: 0 = no matching row → the route answers 404.
  async update(id, data) {
    const [result] = await this.pool.execute(
      `UPDATE equipment
       SET category_id=?, depot_id=?, model_name=?, daily_price=?, purchase_date=?
       WHERE equipment_id=? AND status <> 'retired'`,
      [Number(data.category_id), Number(data.depot_id), data.model_name.trim(), data.daily_price, data.purchase_date, Number(id)]
    );
    return result.affectedRows;
  }

  // Soft delete: the row is kept for the booking history (FK RESTRICT, no DELETE privilege).
  async retire(id) {
    const [result] = await this.pool.execute(
      `UPDATE equipment
       SET status='retired'
       WHERE equipment_id=? AND status<>'retired' AND status<>'rented'`,
      [Number(id)]
    );
    return result.affectedRows;
  }

  async findById(id) {
    const [rows] = await this.pool.execute(
      `SELECT equipment_id FROM equipment WHERE equipment_id = ? AND status <> 'retired'`,
      [Number(id)]
    );
    return rows;
  }
}

module.exports = EquipmentRepository;
