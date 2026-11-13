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


-- 3. Nested SELECT (subqueries)
-- Question: Which customers are our top customers, meaning customers who have made
-- more bookings than the average customer?
-- The query first calculates the average number of bookings per customer, and then
-- selects the customers who are above that average.
-- Cancelled bookings are not counted (in either place, so the comparison stays fair).
-- The anonymized customer's booking is counted, because it really took place.
-- The inner query per_customer counts the bookings for each customer, the subquery
-- after > calculates the average, and the JOIN with customers adds the name.
SELECT  CONCAT(c.first_name, ' ', c.last_name) AS name, per_customer.booking_count
FROM (
    SELECT b.customer_id, COUNT(*) AS booking_count
    FROM bookings AS b 
    WHERE b.status <> 'cancelled'
    GROUP BY b.customer_id
) AS per_customer
JOIN customers AS c ON c.customer_id = per_customer.customer_id
WHERE per_customer.booking_count > (
    SELECT AVG(booking_totals.booking_count)
    FROM(
        SELECT COUNT(*) AS booking_count
        FROM bookings
        WHERE status <> 'cancelled'
        GROUP BY customer_id
    ) AS booking_totals
)
ORDER BY per_customer.booking_count DESC, name;



