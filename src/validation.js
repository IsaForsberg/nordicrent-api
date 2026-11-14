'use strict';

function positiveId(value) {
  return /^[1-9]\d*$/.test(String(value ?? ''))
    && Number.isSafeInteger(Number(value));
}

function isObject(value) {
  return value !== null
    && typeof value === 'object'
    && !Array.isArray(value);
}

function validDate(value) {
      return typeof value === 'string'
    && /^\d{4}-\d{2}-\d{2}$/.test(value);
}
function validEquipment(body) {
  return isObject(body)
    && positiveId(body.category_id)
    && positiveId(body.depot_id)
    && typeof body.model_name === 'string'
    && body.model_name.trim().length > 0
    && body.model_name.trim().length <= 80
    && typeof body.daily_price === 'number'
    && body.daily_price >= 0
    && body.daily_price <= 99999.99
    && validDate(body.purchase_date);
}

function validBooking(body) {
  return isObject(body)
    && positiveId(body.booking_id)
    && Array.isArray(body.equipment_ids)
    && body.equipment_ids.length >= 1
    && body.equipment_ids.length <= 10
    && body.equipment_ids.every(positiveId)
    && validDate(body.start_date)
    && validDate(body.end_date)
    && new Set(body.equipment_ids.map(Number)).size === body.equipment_ids.length;
}




function validReport(body) {
  return isObject(body)
    && positiveId(body.equipment_id)
    && typeof body.notes === 'string'
    && body.notes.trim().length > 0
    && body.notes.trim().length <= 1000
    && (
      body.checklist === undefined
      || (
        Array.isArray(body.checklist)
        && body.checklist.every(
          item => typeof item === 'string' && item.length <= 100
        )
      )
    )
    && (
      body.damageFlag === undefined
      || typeof body.damageFlag === 'boolean'
    );
}

module.exports = {
  positiveId,
  isObject,
  validEquipment,
  validBooking,
  validReport
};