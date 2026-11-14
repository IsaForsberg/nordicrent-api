# NordicRent — Database Tests

Three database tests that were run against MySQL. Each test describes what is tested, how it is run, the expected result and the actual result.

| Test ID | What is tested | Date run | Pass/Fail |
|---|---|---|---|
| DB-01 | Read with JOIN | 2026-11-14 | Pass |
| DB-02 | Constraint error | 2026-11-13 (SQL part) | Pass |
| DB-03 | Rollback without half-finished booking lines (+ COMMIT) | 2026-11-14 (SQL part) | Pass |
| DB-04 (extra) | Anonymization: CHECK + UNIQUE with NULL on `customers` | 2026-11-13 | Pass |
| DB-05 (extra) | Constraints on `bookings`: duration CHECK, FK on insert, RESTRICT on delete | 2026-11-13 | Pass |
| DB-06 (extra) | Constraints on `booking_lines`: UNIQUE pair, RESTRICT and CASCADE | 2026-11-13 | Pass |

---

## DB-01: Read with JOIN

**What is tested:** That a JOIN over three tables (`equipment`, `depots`, `categories`) turns the foreign keys `depot_id` and `category_id` into readable data. `equipment` only stores the ids, and the query shows, for every item, which depot (city) it belongs to, its category name, its status and its current daily price. This is query 1 in `database/queries.sql` and the basis for `GET /api/equipment`.

**How it is run:** After a fresh run of `database/setup.sql` followed by `database/seed.sql`, in Database Client (only query 1 selected and run):

```sql
USE nordicrent_api;

SELECT e.equipment_id, e.model_name, d.city, e.status, e.daily_price AS current_daily_price, c.name AS category_name
FROM equipment AS e
JOIN depots AS d ON d.depot_id = e.depot_id
JOIN categories AS c ON c.category_id = e.category_id
ORDER BY d.city, current_daily_price;
```

**Expected result:**
- 12 rows, one per equipment item in the seed data. No item is lost in the (inner) JOIN, because `depot_id` and `category_id` are `NOT NULL` foreign keys, so every item has exactly one existing depot and one existing category.
- All statuses are included, also `maintenance` (item 8) and `retired` (item 12), since the query does not filter on status.
- `city` and `category_name` show names (for example `Umeå` and `Kayak`), not ids.
- Sorted by city, and by price ascending within each city.

**Actual result (2026-11-14):** As expected.
- 12 rows, including the retired item 12.
- City order: Göteborg, Östersund, Umeå. The default collation `utf8mb4_0900_ai_ci` is accent-insensitive, so `Ö` is sorted as `O`. A Swedish collation would have put Östersund last.
- Prices ascending within each city (for example Göteborg: 200.00, 350.00, 450.00).

**Decision after the test:** the retired item is kept in the result on purpose. Query 1 lists the whole inventory, and `status` is shown for every item, so retired equipment is visible as retired. Counting queries filter it out instead (query 2 uses `WHERE e.status <> 'retired'`).

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
1. Rejected: `Check constraint 'chk_equipment_daily_price' is violated.` Database Client showed only the message, not the error code. The code is 3819 (`ER_CHECK_CONSTRAINT_VIOLATED`). This was confirmed with `SHOW ERRORS` on 2026-11-13 during a test of the CHECK constraint on `customers`, which gives the same error type for every violated CHECK.
2. `equipment` was empty.
3. The row was saved with `equipment_id` 1 and `status` = `available`.

**API part (TODO, step 4):** send the same negative price to `POST /api/equipment` with curl, and document the JSON error response and status code.

---

## DB-03: Rollback without half-finished booking lines

**What is tested:** A booking is saved with two inserts: first a row in `bookings`, then one row per item in `booking_lines`. The two inserts must be all or nothing. If a booking line cannot be saved, the booking must not be left behind without lines (a half-finished booking). The test runs two transactions:

- **Transaction A (ROLLBACK):** the second insert fails on purpose, and `ROLLBACK` removes the booking that was already inserted.
- **Transaction B (COMMIT):** both inserts succeed, and `COMMIT` saves them together.

**How it is run:** After a fresh run of `database/setup.sql` followed by `database/seed.sql`, in Database Client, one statement at a time. Before the test: `bookings` has 16 rows and `booking_lines` has 22.

The failure in A is a booking line for equipment 99, which does not exist, so `fk_booking_lines_equipment` rejects it. `LAST_INSERT_ID()` gives the id of the booking that was just inserted, so the booking line does not depend on a hand-written id.

```sql
-- Transaction A: second insert fails, everything is rolled back
SELECT COUNT(*) FROM bookings;        -- before
SELECT COUNT(*) FROM booking_lines;   -- before

START TRANSACTION;

INSERT INTO bookings (customer_id, start_date, end_date)
VALUES (2, '2026-12-03', '2026-12-05');

SELECT * FROM bookings WHERE booking_id = LAST_INSERT_ID();

INSERT INTO booking_lines (booking_id, equipment_id, daily_price)
VALUES (LAST_INSERT_ID(), 99, 350.00);   -- equipment 99 does not exist

SHOW ERRORS;

ROLLBACK;

SELECT COUNT(*) FROM bookings;        -- after
SELECT COUNT(*) FROM booking_lines;   -- after
```

```sql
-- Transaction B: both inserts succeed and are committed
SELECT COUNT(*) FROM bookings;
SELECT COUNT(*) FROM booking_lines;

START TRANSACTION;

INSERT INTO bookings (customer_id, start_date, end_date)
VALUES (2, '2026-12-03', '2026-12-05');

SELECT * FROM bookings WHERE booking_id = LAST_INSERT_ID();

INSERT INTO booking_lines (booking_id, equipment_id, daily_price)
VALUES (LAST_INSERT_ID(), 3, 350.00);    -- equipment 3, free on these dates, current price 350.00

COMMIT;

SELECT * FROM booking_lines WHERE booking_id = 18;
SELECT COUNT(*) FROM bookings;
SELECT COUNT(*) FROM booking_lines;
```

**Expected result:**

*Transaction A*
1. Before: 16 bookings, 22 booking lines.
2. The booking insert succeeds and the new booking (id 17) is visible inside the transaction.
3. The booking line insert is rejected with error 1452 from `fk_booking_lines_equipment`.
4. MySQL does **not** undo the booking by itself. The booking is still there until `ROLLBACK` is run.
5. After `ROLLBACK`: 16 bookings and 22 booking lines again. No half-finished booking.

*Transaction B*
1. The new booking gets id **18**, not 17. `AUTO_INCREMENT` does not give back the id that was used by the rolled-back booking in A.
2. Both inserts succeed.
3. After `COMMIT`: 17 bookings and 23 booking lines. The new line belongs to booking 18, with equipment 3 and daily price 350.00.

**Actual result (SQL, 2026-11-14):** As expected.

*Transaction A*
- Before: 16 / 22.
- Booking 17 was visible in `bookings` before `ROLLBACK`.
- The booking line insert was rejected: `Cannot add or update a child row: a foreign key constraint fails (... CONSTRAINT fk_booking_lines_equipment FOREIGN KEY (equipment_id) REFERENCES equipment (equipment_id) ...)`, error 1452.
- Booking 17 was still there after the error, until `ROLLBACK` was run.
- After `ROLLBACK`: 16 / 22.

*Transaction B*
- The booking got id 18.
- `booking_lines` showed one line for booking 18 (equipment 3, 350.00).
- After `COMMIT`: 17 / 23.

**Lessons from running the test:**
- **Hand-written ids are fragile.** An earlier attempt wrote `booking_id` 17 by hand in transaction B. Since 17 had been used up by the rollback in A, the line would have failed on `fk_booking_lines_booking` instead, and the `COMMIT` would then have saved booking 18 **without any lines**. That is exactly the half-finished booking the test is meant to prevent. `LAST_INSERT_ID()` fixes it.
- **`LAST_INSERT_ID()` changes after every insert with `AUTO_INCREMENT`.** After the booking line insert it returns the new `booking_line_id`, not the booking id. That is why the last `SELECT` in B uses 18 written out.
- **`COMMIT` does not check for earlier errors.** It saves whatever succeeded. Deciding between `COMMIT` and `ROLLBACK` is the backend's job: in step 5 the booking route catches the error and runs `ROLLBACK` itself.

**API part (TODO, step 5):** run the same two cases through `POST /api/bookings` with curl (one with a non-existing equipment id, one valid), and document the status codes and the row counts afterwards.

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------



## DB-04 (extra): Anonymization rules on `customers`

**What is tested:** Customers are anonymized instead of deleted. When that happens, `first_name`, `last_name`, `email` and `phone` are set to `NULL` and `deleted_at` gets a date and time. Two rules make that possible:

- The CHECK constraint `chk_customer_personal_data` (`deleted_at IS NOT NULL OR (all four personal fields IS NOT NULL)`): an **active** customer (`deleted_at` is `NULL`) must have all four personal fields, while an anonymized customer may have them all as `NULL`.
- `email` is `UNIQUE` but nullable. MySQL allows several `NULL` values in a `UNIQUE` column, so more than one customer can be anonymized.

**How it is run:** After a fresh run of `database/setup.sql`, in Database Client, one statement at a time:

```sql
-- 1. Active customer with all personal data (should succeed)
INSERT INTO customers (first_name, last_name, email, phone)
VALUES ('Anna', 'Andersson', 'anna.andersson@example.com', '070-123 45 67');

-- 2. Active customer without phone (should fail)
INSERT INTO customers (first_name, last_name, email)
VALUES ('Erik', 'Berg', 'erik.berg@example.com');

SHOW ERRORS;

-- 3. Anonymized customer, all personal fields NULL (should succeed)
INSERT INTO customers (deleted_at)
VALUES ('2026-11-13 14:30:00');

-- 4. A second anonymized customer, email also NULL (should succeed: UNIQUE allows several NULL)
INSERT INTO customers (deleted_at)
VALUES ('2026-11-13 15:00:00');

-- 5. All rows
SELECT * FROM customers;

-- 6. Only active customers, with the name combined
SELECT customer_id, CONCAT(first_name, ' ', last_name) AS name, email
FROM customers
WHERE deleted_at IS NULL;
```

**Expected result:**
1. The row is saved.
2. The row is rejected with error 3819, a check constraint violation.
3. The row is saved.
4. The row is saved, even though another customer already has `email` = `NULL`.
5. Three rows: Anna and two anonymized customers. Erik does not exist.
6. Only Anna, with `name` = `Anna Andersson`.

**Actual result (2026-11-13):**
1. Saved, `customer_id` 1.
2. Rejected with error 3819 (`SHOW ERRORS`). At the time of the test the constraint was named `chk_customer_isactive`. It has since been renamed to `chk_customer_personal_data`, and the rule itself is unchanged.
3. Saved, `customer_id` 2.
4. Saved, `customer_id` 3.
5. Three rows. Rows 2 and 3 have `NULL` in all four personal fields and a value in `deleted_at`. Anna is unchanged.
6. Only Anna.

**Not covered yet:** the CHECK still allows a half-finished anonymization, where `deleted_at` is set but some personal data is left. The anonymization itself (an `UPDATE` through the API) belongs to API v2.

---

## DB-05 (extra): Constraints on `bookings`

Run 2026-11-13 after a fresh `setup.sql`, with one customer (`customer_id` 1) inserted first. Error codes read with `SHOW ERRORS`.

| # | Statement | Expected | Actual |
|---|---|---|---|
| 1 | Booking 2026-12-01 → 2026-12-03 for customer 1 | Saved, `status` = `confirmed`, `created_at` set automatically | Saved as expected |
| 2 | Booking 2026-12-01 → 2026-12-01 (same day) | Rejected by `chk_booking_duration` | Error 3819 |
| 3 | Booking 2026-12-05 → 2026-12-01 (end before start) | Rejected by `chk_booking_duration` | Rejected |
| 4 | Booking for `customer_id` 999 (does not exist) | Rejected by `fk_booking_customer` | Error 1452 |
| 5 | `DELETE FROM customers WHERE customer_id = 1` (has a booking) | Rejected by `ON DELETE RESTRICT` | Error 1451 |

Afterwards `bookings` contained one row and customer 1 was still there.

---

## DB-06 (extra): Constraints on `booking_lines`

Run 2026-11-13 after a fresh `setup.sql`, with one depot, one category, two equipment items (id 1 and 2), one customer and one booking (`booking_id` 1) inserted first. Error codes read with `SHOW ERRORS`.

| # | Statement | Expected | Actual |
|---|---|---|---|
| 1 | Two lines on booking 1: equipment 1 and equipment 2 | Both saved | Saved |
| 2 | Equipment 1 on booking 1 a second time | Rejected by `uq_booking_equipment` | Error 1062 |
| 3 | `DELETE FROM equipment WHERE equipment_id = 1` (used on a booking line) | Rejected by `ON DELETE RESTRICT` | Error 1451 |
| 4 | `DELETE FROM bookings WHERE booking_id = 1` | Booking deleted; its lines deleted by `ON DELETE CASCADE`; equipment untouched | `bookings` and `booking_lines` empty, both equipment items still there |
