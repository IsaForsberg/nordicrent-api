# NordicRent — Database Tests

Three database tests that were run against MySQL. Each test describes what is tested, how it is run, the expected result and the actual result.

| Test ID | What is tested | Date run | Pass/Fail |
|---|---|---|---|
| DB-01 | Read with JOIN | | |
| DB-02 | Constraint error | 2026-11-13 (SQL part) | Pass |
| DB-03 | Rollback without half-finished booking lines | | |

---

## DB-01: Read with JOIN

**What is tested:** TODO

**How it is run:** TODO (SQL query or API request)

**Expected result:** TODO

**Actual result:** *not run yet*

---

## DB-02: Constraint error

**What is tested:** The `CHECK` constraint `chk_equipment_daily_price` on `equipment` (`daily_price >= 0`). A negative daily price makes no sense for a rental, so the database itself should refuse the row, even if the backend validation were to miss it.

**How it is run:** After a fresh run of `database/setup.sql`, in Database Client:

```sql
-- Prerequisites: the FKs need an existing depot and category
INSERT INTO depots (name, city, address) VALUES ('NordicRent Centrum', 'Umeå', 'Storgatan 12');
INSERT INTO categories (name, description) VALUES ('Kayak', 'Single and double sea kayaks with paddles');

-- 1. Negative price (should fail)
INSERT INTO equipment (category_id, depot_id, model_name, daily_price, purchase_date)
VALUES (1, 1, 'Prijon Kodiak', -50, '2025-04-15');

-- 2. No row should have been saved
SELECT * FROM equipment;

-- 3. Same row with a valid price (should succeed)
INSERT INTO equipment (category_id, depot_id, model_name, daily_price, purchase_date)
VALUES (1, 1, 'Prijon Kodiak', 350, '2025-04-15');

SELECT * FROM equipment;
```

**Expected result:**
1. The insert is rejected with a check constraint error naming `chk_equipment_daily_price`.
2. `equipment` is empty.
3. The insert succeeds: one row, `status` = `available` (default).

**Actual result (SQL, 2026-11-13):**
1. Rejected: `Check constraint 'chk_equipment_daily_price' is violated.` Database Client showed only the message, not the error code. According to the MySQL documentation this error is `ER_CHECK_CONSTRAINT_VIOLATED`, code 3819 (not yet confirmed with `SHOW ERRORS`).
2. `equipment` was empty.
3. The row was saved with `equipment_id` 1 and `status` = `available`.

**API part (TODO, step 4):** send the same negative price to `POST /api/equipment` with curl, and document the JSON error response and status code.

---

## DB-03: Rollback without half-finished booking lines

**What is tested:** TODO

**How it is run:** TODO (how one step of the booking transaction is made to fail on purpose)

**Expected result:** TODO (what should exist in `bookings` and `booking_lines` afterwards)

**Actual result:** *not run yet*
