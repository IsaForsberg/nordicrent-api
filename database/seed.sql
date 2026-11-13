-- NordicRent seed data
-- Run as root (or another admin), AFTER a fresh run of setup.sql.
-- setup.sql drops and recreates the database, so: setup.sql -> seed.sql resets everything.
-- The seed data was generated with AI help and reviewed (see README).
--
-- IDs are written out explicitly so the FK references below are easy to follow.
-- "Today" in this data is 2026-11-13: bookings before that are returned/cancelled,
-- bookings that cover that date are active, later bookings are confirmed.

USE nordicrent_api;

-- ---------------------------------------------------------------------------
-- Depots (3)
-- ---------------------------------------------------------------------------
INSERT INTO depots (depot_id, name, city, address) VALUES
    (1, 'NordicRent Centrum', 'Umeå', 'Storgatan 12'),
    (2, 'NordicRent Fjäll', 'Östersund', 'Prästgatan 41'),
    (3, 'NordicRent Hamnen', 'Göteborg', 'Packhusplatsen 6');

-- ---------------------------------------------------------------------------
-- Categories (4)
-- ---------------------------------------------------------------------------
INSERT INTO categories (category_id, name, description) VALUES
    (1, 'Kayak', 'Single and double sea kayaks, delivered with paddles and spray skirts'),
    (2, 'Electric bike', 'Electric bikes for city and gravel, delivered with helmet and charger'),
    (3, 'Tent', 'Two person tents for hiking and camping'),
    (4, 'Cross-country skis', 'Classic cross-country skis, delivered with poles');

-- ---------------------------------------------------------------------------
-- Customers (8): 7 active, 1 anonymized
-- ---------------------------------------------------------------------------
INSERT INTO customers (customer_id, first_name, last_name, email, phone, deleted_at) VALUES
    (1, 'Anna', 'Andersson', 'anna.andersson@example.com', '070-123 45 67', NULL),
    (2, 'Erik', 'Lindqvist', 'erik.lindqvist@example.com', '073-234 56 78', NULL),
    (3, 'Sara', 'Nilsson', 'sara.nilsson@example.com', '076-345 67 89', NULL),
    (4, 'Johan', 'Berg', 'johan.berg@example.com', '070-456 78 90', NULL),
    (5, 'Maria', 'Holm', 'maria.holm@example.com', '072-567 89 01', NULL),
    (6, 'Ali', 'Hassan', 'ali.hassan@example.com', '073-678 90 12', NULL),
    (7, 'Linnea', 'Ek', 'linnea.ek@example.com', '076-789 01 23', NULL),
    -- Anonymized customer: personal data removed, booking history (booking 5) kept
    (8, NULL, NULL, NULL, NULL, '2026-09-30 10:15:00');

-- ---------------------------------------------------------------------------
-- Equipment (12)
-- Status: 4, 10, 11 are rented (on the active bookings 12 and 13),
-- 8 is in maintenance, 12 is retired (still referenced by an old booking).
-- ---------------------------------------------------------------------------
INSERT INTO equipment (equipment_id, category_id, depot_id, model_name, daily_price, purchase_date, status) VALUES
    (1,  1, 1, 'Prijon Kodiak',            350.00, '2024-04-10', 'available'),
    (2,  1, 1, 'Point 65 Mercury',         400.00, '2024-05-02', 'available'),
    (3,  1, 3, 'Prijon Kodiak',            350.00, '2025-03-20', 'available'),
    (4,  2, 1, 'Crescent Elora',           450.00, '2025-02-14', 'rented'),
    (5,  2, 2, 'Monark Delta',             425.00, '2024-06-01', 'available'),
    (6,  2, 3, 'Crescent Elora',           450.00, '2025-04-03', 'available'),
    (7,  3, 2, 'Hilleberg Nallo 2',        200.00, '2023-05-15', 'available'),
    (8,  3, 2, 'Fjällräven Abisko Dome 2', 180.00, '2024-03-11', 'maintenance'),
    (9,  3, 3, 'Hilleberg Nallo 2',        200.00, '2025-05-09', 'available'),
    (10, 4, 2, 'Fischer Twin Skin Pro',    150.00, '2024-11-01', 'rented'),
    (11, 4, 1, 'Madshus Redline',          175.00, '2025-10-20', 'rented'),
    (12, 1, 1, 'Tahe Marine Greenland',    380.00, '2021-06-01', 'retired');

-- ---------------------------------------------------------------------------
-- Bookings (16)
-- Bookings per customer: Anna 4, Erik 3, Sara 2, Johan 2, Maria 2,
-- Ali 1, Linnea 1, anonymized customer 1. Average = 16 / 8 = 2.
-- ---------------------------------------------------------------------------
INSERT INTO bookings (booking_id, customer_id, start_date, end_date, status, created_at) VALUES
    (1,  1, '2025-06-14', '2025-06-17', 'returned',  '2025-05-20 09:12:00'),
    (2,  7, '2025-06-20', '2025-06-22', 'returned',  '2025-06-01 18:45:00'),
    (3,  1, '2025-07-05', '2025-07-12', 'returned',  '2025-06-10 20:03:00'),
    (4,  4, '2025-07-15', '2025-07-18', 'cancelled', '2025-06-28 11:30:00'),
    (5,  8, '2025-07-20', '2025-07-25', 'returned',  '2025-07-01 14:22:00'),
    (6,  3, '2025-08-01', '2025-08-04', 'returned',  '2025-07-15 08:50:00'),
    (7,  2, '2025-08-09', '2025-08-11', 'returned',  '2025-07-30 16:10:00'),
    (8,  5, '2025-08-15', '2025-08-18', 'returned',  '2025-08-02 12:05:00'),
    (9,  4, '2025-09-05', '2025-09-07', 'returned',  '2025-08-25 19:40:00'),
    (10, 1, '2026-02-14', '2026-02-21', 'returned',  '2026-01-20 10:00:00'),
    (11, 2, '2026-03-01', '2026-03-05', 'returned',  '2026-02-10 13:15:00'),
    (12, 2, '2026-11-10', '2026-11-16', 'active',    '2026-10-28 17:30:00'),
    (13, 5, '2026-11-12', '2026-11-15', 'active',    '2026-11-01 09:45:00'),
    (14, 1, '2026-12-27', '2027-01-03', 'confirmed', '2026-11-05 21:00:00'),
    (15, 3, '2027-06-12', '2027-06-15', 'confirmed', '2026-11-08 15:20:00'),
    (16, 6, '2026-12-05', '2026-12-07', 'confirmed', '2026-11-11 11:11:00');

-- ---------------------------------------------------------------------------
-- Booking lines (22)
-- daily_price is the price when the booking was made (snapshot).
-- Normally the same as equipment.daily_price, EXCEPT booking 7:
-- equipment 4 cost 400.00 in 2025 and costs 450.00 today.
-- No equipment is booked on overlapping dates.
-- ---------------------------------------------------------------------------
INSERT INTO booking_lines (booking_line_id, booking_id, equipment_id, daily_price) VALUES
    (1,  1,  1,  350.00),
    (2,  1,  2,  400.00),
    (3,  2,  12, 380.00),
    (4,  3,  7,  200.00),
    (5,  3,  1,  350.00),
    (6,  4,  5,  425.00),
    (7,  5,  8,  180.00),
    (8,  5,  5,  425.00),
    (9,  6,  3,  350.00),
    (10, 7,  4,  400.00),
    (11, 8,  9,  200.00),
    (12, 8,  3,  350.00),
    (13, 9,  6,  450.00),
    (14, 10, 10, 150.00),
    (15, 11, 10, 150.00),
    (16, 12, 10, 150.00),
    (17, 13, 11, 175.00),
    (18, 13, 4,  450.00),
    (19, 14, 11, 175.00),
    (20, 15, 1,  350.00),
    (21, 15, 2,  400.00),
    (22, 16, 5,  425.00);
