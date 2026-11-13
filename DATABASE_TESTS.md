# NordicRent — Database Tests

Three database tests that were run against MySQL. Each test describes what is tested, how it is run, the expected result and the actual result.

| Test ID | What is tested | Date run | Pass/Fail |
|---|---|---|---|
| DB-01 | Read with JOIN | | |
| DB-02 | Constraint error | 2026-11-13 (SQL part) | Pass |
| DB-03 | Rollback without half-finished booking lines | | |
| DB-04 (extra) | Anonymization: CHECK + UNIQUE with NULL on `customers` | 2026-11-13 | Pass |

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
1. Rejected: `Check constraint 'chk_equipment_daily_price' is violated.` Database Client showed only the message, not the error code. The code is 3819 (`ER_CHECK_CONSTRAINT_VIOLATED`). This was confirmed with `SHOW ERRORS` on 2026-11-13 during a test of the CHECK constraint on `customers`, which gives the same error type for every violated CHECK.
2. `equipment` was empty.
3. The row was saved with `equipment_id` 1 and `status` = `available`.

**API part (TODO, step 4):** send the same negative price to `POST /api/equipment` with curl, and document the JSON error response and status code.

---

## DB-03: Rollback without half-finished booking lines

**What is tested:** TODO

**How it is run:** TODO (how one step of the booking transaction is made to fail on purpose)

**Expected result:** TODO (what should exist in `bookings` and `booking_lines` afterwards)

**Actual result:** *not run yet*

---

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
