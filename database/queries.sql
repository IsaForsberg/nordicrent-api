USE nordicrent_api;


-- 1. JOIN with three tables (equipment, depots, categories)
-- Question: What equipment do we have at all depots, which category does each item
-- belong to, what is its status and what does it cost per day right now?
-- Sorted by city, and within each city by current daily price.
-- The same query is the basis for GET /api/equipment.
SELECT e.equipment_id, e.model_name, d.city, e.status, e.daily_price AS current_daily_price, c.name AS category_name
FROM equipment AS e
JOIN depots AS d ON d.depot_id = e.depot_id
JOIN categories AS c ON c.category_id = e.category_id
ORDER BY d.city, current_daily_price;

-------------------------------------------------------------------------------------------


-- 2. GROUP BY with COUNT
-- Question: How many pieces of equipment that are still in use does each depot have?
-- "In use" means every status except 'retired', so rented items and items in
-- maintenance are counted, but equipment that has been taken out of service is not.
-- WHERE removes retired equipment before GROUP BY groups the rest into one row per depot.

SELECT d.city, COUNT(e.equipment_id) AS equipment_count
FROM equipment AS e
JOIN depots AS d ON d.depot_id = e.depot_id
WHERE e.status <> 'retired'
GROUP BY d.depot_id, d.city
ORDER BY d.city;

-------------------------------------------------------------------------------------------

-- 3. Nested SELECT (subqueries)
-- Question: Which customers are our top customers, meaning customers who have made
-- more bookings than the average customer?
-- The query first calculates the average number of bookings per customer, and then
-- selects the customers who are above that average.
-- Cancelled bookings are not counted (in either place, so the comparison stays fair).
-- The anonymized customer's booking is counted, because it really took place.
-- The inner query per_customer counts the bookings for each customer, the subquery
-- after > calculates the average, and the JOIN with customers adds the name.
SELECT CONCAT(c.first_name, ' ', c.last_name) AS name, per_customer.booking_count
FROM (
    SELECT b.customer_id, COUNT(*) AS booking_count
    FROM bookings AS b
    WHERE b.status <> 'cancelled'
    GROUP BY b.customer_id
) AS per_customer
JOIN customers AS c ON c.customer_id = per_customer.customer_id
WHERE per_customer.booking_count > (
    SELECT AVG(booking_totals.booking_count)
    FROM (
        SELECT COUNT(*) AS booking_count
        FROM bookings
        WHERE status <> 'cancelled'
        GROUP BY customer_id
    ) AS booking_totals
)
ORDER BY per_customer.booking_count DESC, name;

-------------------------------------------------------------------------------------------


-- 4. Nested SELECT (subqueries): top earners
-- Question: Which equipment items have earned more rental income than the average item?
-- Income for a booking line = daily_price on the line × number of days
-- (DATEDIFF(end_date, start_date)). The price on the line is the price at the time of
-- booking, so later price changes do not affect old income (see equipment 4).
-- Only returned bookings are counted: confirmed bookings have not happened yet, active
-- bookings are not finished, and cancelled bookings never earned anything.
-- Equipment without any returned booking is not part of the average.
-- equipment_id is shown because model names are not unique (equipment 1 and 3).

SELECT per_equipment.equipment_id, e.model_name, per_equipment.revenue
FROM (
    SELECT bl.equipment_id, SUM(bl.daily_price * DATEDIFF(b.end_date, b.start_date)) AS revenue
    FROM booking_lines AS bl
    JOIN bookings AS b ON b.booking_id = bl.booking_id
    WHERE b.status = 'returned'
    GROUP BY bl.equipment_id
) AS per_equipment
JOIN equipment AS e ON e.equipment_id = per_equipment.equipment_id
WHERE per_equipment.revenue > (
    SELECT AVG(revenue_totals.revenue)
    FROM (
        SELECT bl.equipment_id, SUM(bl.daily_price * DATEDIFF(b.end_date, b.start_date)) AS revenue
        FROM booking_lines AS bl
        JOIN bookings AS b ON b.booking_id = bl.booking_id
        WHERE b.status = 'returned'
        GROUP BY bl.equipment_id
    ) AS revenue_totals
)
ORDER BY per_equipment.revenue DESC, e.model_name;


-------------------------------------------------------------------------------------------

-- TRANSACTIONS
-- Run right after setup.sql + seed.sql, and A before B, so the numbers below match.
-- @booking_id saves the new booking's id. LAST_INSERT_ID() cannot be used for that after
-- the booking_lines INSERT, because it then returns the new booking_line_id instead.


-- A. ROLLBACK: a booking line that fails undoes the whole booking.
-- The booking is inserted, but the line points to equipment 99, which does not exist
-- → error 1452 (fk_booking_lines_equipment) → ROLLBACK.
-- Expected: 16 bookings / 22 lines before AND after. No half booking is left.

SELECT COUNT(*) FROM bookings;
SELECT COUNT(*) FROM booking_lines;

START TRANSACTION;

INSERT INTO bookings (customer_id, start_date, end_date)
VALUES (2, '2026-12-03', '2026-12-05');
SET @booking_id = LAST_INSERT_ID();
SELECT * FROM bookings WHERE booking_id = @booking_id;  -- visible inside the transaction

INSERT INTO booking_lines (booking_id, equipment_id, daily_price)
VALUES (@booking_id, 99, 350.00);  -- fails: error 1452

SHOW ERRORS;
ROLLBACK;

SELECT COUNT(*) FROM bookings;       -- 16
SELECT COUNT(*) FROM booking_lines;  -- 22


-------------------------------------------------------------------------------------------

-- B. COMMIT: booking + line for equipment 3 are saved together.
-- Expected: 16 / 22 before, 17 / 23 after.
-- The new booking gets id 18, not 17: AUTO_INCREMENT does not reuse the id from A's rollback.

SELECT COUNT(*) FROM bookings;
SELECT COUNT(*) FROM booking_lines;

START TRANSACTION;

INSERT INTO bookings (customer_id, start_date, end_date)
VALUES (2, '2026-12-03', '2026-12-05');
SET @booking_id = LAST_INSERT_ID();

INSERT INTO booking_lines (booking_id, equipment_id, daily_price)
VALUES (@booking_id, 3, 350.00);

COMMIT;

SELECT * FROM bookings WHERE booking_id = @booking_id;       -- booking 18
SELECT * FROM booking_lines WHERE booking_id = @booking_id;  -- one line, equipment 3
SELECT COUNT(*) FROM bookings;       -- 17
SELECT COUNT(*) FROM booking_lines;  -- 23
