# NordicRent API

Backend for NordicRent, a Scandinavian startup that rents out outdoor equipment (tents, kayaks, e-bikes, ski equipment) from depots in several cities. Customers book equipment for a date range, pick it up at a depot and return it. Staff write condition reports for the equipment.

The backend consists of:
- a normalized **MySQL** database (customers, depots, categories, equipment, bookings, booking lines)
- a small **Node.js/Express** API that shows the database being used by an application
- a **MongoDB** collection for condition reports

> Final project in the course *Databashantering MySQL*, Backend Web Developer (YH). The project will be developed further into NordicRent API v2 in the next course.

---

## Tech stack

| Part | Used for |
|---|---|
| **Node.js** + **Express 4** | the REST API |
| **MySQL** (developed on 9.7) + **mysql2** | the relational data: customers, depots, categories, equipment, bookings, booking lines |
| **MongoDB Community Server** (developed on 9.0) + **mongodb** driver | condition reports (`nordicrent_docs.condition_reports`) |
| **dotenv** | reads the database settings from `.env` |

## Installation

Requires Node.js, a running MySQL server (port 3306) and a running MongoDB server (port 27017).

1. Clone the repository and install the packages:
   ```bash
   git clone https://github.com/IsaForsberg/nordicrent-api.git
   cd nordicrent-api
   npm install
   ```
2. Create `.env` from the example file:
   ```bash
   cp .env.example .env
   ```
3. Create the database, the application user and the sample data, see [Setting up and resetting the database](#setting-up-and-resetting-the-database).

## Database settings

- **Database:** `nordicrent_api` (MySQL, created by `database/setup.sql`).
- **Application user:** the API never connects as root. `setup.sql` creates `nordicrent_app_user` with only the privileges the 7 routes need:

  | Table | Privileges |
  |---|---|
  | `equipment` | `SELECT`, `INSERT`, `UPDATE` (delete = status `retired`, so no `DELETE`) |
  | `bookings`, `booking_lines` | `SELECT`, `INSERT` |
  | `categories`, `depots` | `SELECT` |
  | `customers` | none (the foreign key from `bookings` is checked by MySQL itself) |

- **Password:** `12345` is a local development password, written in both `setup.sql` and `.env.example`. Change it in both places before any real installation.
- **Host `'%'` instead of `'127.0.0.1'`:** the user is created as `'nordicrent_app_user'@'%'`. During development MySQL runs in a Podman container, and inside the container the API's connection does not come from `127.0.0.1` but from the host machine's network address. With `'127.0.0.1'` the login failed (`Access denied for user 'nordicrent_app_user'@'<the host machine's network address>'`). `'%'` means *from any host*, not *anyone*: the password is still required and the privileges above still apply. It works both with a container and with MySQL installed directly. In a real installation the MySQL port should only be exposed locally (`podman run -p 127.0.0.1:3306:3306 ...`) and the password should be strong.
- **`DB_HOST=127.0.0.1`** in `.env` is the address the API connects *to* (MySQL on the same machine). It is not the same thing as the host part of the user.

## Environment variables

Copy `.env.example` to `.env`. `.env` is in `.gitignore` and is never committed.

| Variable | Example | Meaning |
|---|---|---|
| `DB_HOST` | `127.0.0.1` | MySQL server |
| `DB_PORT` | `3306` | MySQL port |
| `DB_NAME` | `nordicrent_api` | database created by `setup.sql` |
| `DB_USER` | `nordicrent_app_user` | the application user (not root) |
| `DB_PASSWORD` | `12345` | local development password, see [Database settings](#database-settings) |
| `MONGO_URI` | `mongodb://127.0.0.1:27017` | MongoDB server |
| `MONGO_DB` | `nordicrent_docs` | MongoDB database for condition reports |
| `PORT` | `3007` | port the API listens on |

## Starting and stopping

MySQL and MongoDB must be running before the API starts.

```bash
node src/server.js
```

On start the API first checks both databases (`SELECT 1` against MySQL, then connects to MongoDB). If one of them is not reachable, the API does not start and shows the error in the terminal, instead of running with only one database. When it is running it prints:

```
NordicRent API is running at http://localhost:3007/api/health
```

Stop the API with **Ctrl+C** in the terminal.

## Setting up and resetting the database

Run both files **as root** (or another admin user), in this order:

1. `database/setup.sql`: drops and recreates the database `nordicrent_api`, creates all tables and constraints, and creates the application user with its privileges.
2. `database/seed.sql`: inserts the sample data (3 depots, 4 categories, 8 customers, 12 equipment items, 16 bookings, 22 booking lines).

For example from the terminal:

```bash
mysql -u root -p < database/setup.sql
mysql -u root -p < database/seed.sql
```

(or open the files in a database client and run them there).

**Resetting:** run the same two files again. `setup.sql` starts with `DROP DATABASE IF EXISTS`, so `setup.sql` → `seed.sql` always gives the same starting point, with the same IDs. Run this before testing, since the tests in `DATABASE_TESTS.md` and the transactions in `queries.sql` add rows. The MongoDB collection is not reset by these files.

The sample data in `database/seed.sql` was generated with the help of an AI tool. I designed the structure of the data myself and gave clear instructions about what it should contain: how many depots, categories, equipment items and customers, how the bookings should be spread across the customers (one customer with four bookings, one with three, several with two, some with one) and which bookings should be finished, ongoing or planned. I then went through the data, ran it against the database and verified that it matches what I asked for.

---

## API endpoints

All endpoints exchange JSON.

| Method | Endpoint | Database feature shown |
|---|---|---|
| GET | `/api/equipment` | SELECT + JOIN (equipment, category, depot) |
| POST | `/api/equipment` | Parameterized INSERT |
| PUT | `/api/equipment/:id` | Parameterized UPDATE |
| DELETE | `/api/equipment/:id` | Retires the item (sets status `retired`, the row is kept), see [Foreign keys](#foreign-keys-and-on-delete) |
| POST | `/api/bookings` | MySQL transaction: booking + booking lines |
| POST | `/api/reports` | Saves a condition report in MongoDB |
| GET | `/api/reports/equipment/:id` | Gets the condition reports for an item from MongoDB |
| GET | `/api/health` | Optional. Returns `{ "status": "ok" }` |

### Example requests (curl)

The examples assume the sample data from `database/seed.sql`. Add `-i` to see the status code.

```bash
BASE=http://localhost:3007

# Health check
curl $BASE/api/health

# List all equipment (with category name and city)
curl $BASE/api/equipment

# Add equipment → 201 + equipment_id
curl -X POST $BASE/api/equipment \
  -H "Content-Type: application/json" \
  -d '{"category_id": 1, "depot_id": 1, "model_name": "Prijon Yukon", "daily_price": 300, "purchase_date": "2026-05-01"}'

# Update equipment 2 (all five fields are required) → 200
curl -X PUT $BASE/api/equipment/2 \
  -H "Content-Type: application/json" \
  -d '{"category_id": 1, "depot_id": 1, "model_name": "Point 65 Mercury", "daily_price": 425, "purchase_date": "2024-05-02"}'

# Retire equipment 9 (status becomes "retired", the row is kept) → 200
curl -X DELETE $BASE/api/equipment/9

# Book equipment 1 and 2 → 201 + booking_id (409 if a date is taken or an item cannot be booked)
curl -X POST $BASE/api/bookings \
  -H "Content-Type: application/json" \
  -d '{"customer_id": 1, "equipment_ids": [1, 2], "start_date": "2027-03-01", "end_date": "2027-03-04"}'

# Save a condition report for equipment 1 → 201 + report_id
curl -X POST $BASE/api/reports \
  -H "Content-Type: application/json" \
  -d '{"equipmentId": 1, "notes": "Small scratch on the hull", "checklist": {"hull": true, "paddle": true, "skirt": false}, "damageFlag": false}'

# Get all condition reports for equipment 1, newest first → 200 (an empty list if there are none)
curl $BASE/api/reports/equipment/1
```

| Status | When |
|---|---|
| `400` | missing or invalid fields, an invalid id in the URL, or data MySQL rejects (e.g. a category that does not exist) |
| `404` | the equipment does not exist or is retired (and for `DELETE`, also when it is rented) |
| `409` | a booking where a date is taken or an item cannot be booked, or a duplicate value |
| `500` | an unexpected database error (the details are only logged in the terminal) |

---

## Database design

The ER diagram is in [`docs/er-diagram.md`](docs/er-diagram.md).

### Normalization (3NF)

The data is split so that each table describes one thing and each piece of information is stored in one place only. Tables are connected with foreign keys.

| Table | Why it exists |
|---|---|
| `customers` | All information about a customer in one place. |
| `depots` | The locations where NordicRent operates. Only information about the depots. |
| `categories` | A separate entity with name and description. Many items belong to the same category, so the description is stored once instead of on every item. |
| `equipment` | The physical items and their status. Linked to one depot (each depot has its own equipment) and one category (many items can share a category). |
| `bookings` | What applies to the whole booking: customer, date range, status and when the booking was made. A customer can have many bookings, a booking has exactly one customer. |
| `booking_lines` | Connects bookings and equipment (N:M). Without it, a booking would have to contain its items, or an item its bookings. Now `equipment` is only about equipment and `bookings` only about the booking. |

Dependencies that were removed by splitting the tables:

- **Depot city and address** depend on the depot, not on the item. If they were stored on every item in `equipment`, a moved depot would have to be updated on many rows (a transitive dependency: `equipment_id → depot_id → city`). Now they are stored once, in `depots`.
- **Category description** is stored once in `categories`, not repeated on every item.
- **Customer name, email and phone** are stored once in `customers`, not on every booking.
- **Dates and customer** belong to the whole booking, so they are stored in `bookings`, not repeated on every booking line.

The price on `booking_lines` is not a repeated copy, see below.

### Price stored on booking lines

`booking_lines` stores the daily price that applied **when the booking was made**. `equipment` stores the **current** price. These are two different facts, not a copy of the same one, even if they have the same value at the moment of booking. This means old bookings do not change when prices change, and it does not break 3NF.

### Total price is calculated, not stored

`bookings` has no total price column. The total is calculated when it is read: the sum of the daily prices in `booking_lines` × the number of days. A stored total would be derived from other columns and could get out of sync with the rows (for example if single items could be cancelled in the future). Without a total column it can never be wrong, and the schema stays in 3NF. The same calculation (price × days) is also used in the top earners query in `database/queries.sql`.

### Foreign keys and ON DELETE

| Foreign key | References | ON DELETE | Reason |
|---|---|---|---|
| `equipment.depot_id` | `depots` | RESTRICT | A depot with equipment cannot be deleted. If a depot closes, its equipment is moved first. |
| `equipment.category_id` | `categories` | RESTRICT | A category cannot be deleted while items use it. |
| `bookings.customer_id` | `customers` | RESTRICT | A booking cannot exist without a customer, and the booking history must be protected. Customers are anonymized instead of deleted. |
| `booking_lines.booking_id` | `bookings` | CASCADE | A booking line means nothing without its booking. |
| `booking_lines.equipment_id` | `equipment` | RESTRICT | Protects the booking history (totals are calculated from the rows). Items are retired instead of deleted, so `DELETE /api/equipment/:id` sets status `retired`. |

### Customer deletion policy

Customers are never deleted from the database, they are anonymized. This is why `bookings.customer_id` uses `ON DELETE RESTRICT`: the database itself protects the booking history.

1. A customer with active bookings (`confirmed` or `active`) cannot be removed.
2. Otherwise the customer's personal data (name, email, phone) is removed and `deleted_at` is set. The row and the booking history are kept.

Reason: deleting the row with `ON DELETE CASCADE` would also delete old bookings and change revenue statistics (e.g. top earners), and in a real company bookkeeping rules require financial records to be kept for several years. Anonymization removes the personal data (GDPR) but keeps the history correct.

This policy was approved by the course teacher. The customer API routes are not part of this course and are planned for API v2.

### Backend and frontend

See [Connection between backend and frontend](docs/er-diagram.md#connection-between-backend-and-frontend) in the ER diagram document (`GET /api/equipment` joins the IDs into names that a frontend can show).

---

## SQL queries

`database/queries.sql` contains the queries that show the SQL part of the project. They are run directly in MySQL and do not have their own API routes.

| # | Shows | Question it answers |
|---|---|---|
| 1 | JOIN with three tables | What equipment do we have, in which city and category, with status and current price? (the basis for `GET /api/equipment`) |
| 2 | GROUP BY + COUNT | How many items still in use (not retired) does each depot have? |
| 3 | Nested SELECT | Which customers have made more bookings than the average customer? |
| 4 | Nested SELECT | Which items have earned more than the average item? (price on the booking line × number of days, only returned bookings) |

At the end of the file there are two transactions that show **ROLLBACK** (a booking line that fails undoes the whole booking) and **COMMIT**, with the expected row counts as comments. Run them right after `setup.sql` + `seed.sql`.

## MySQL vs MongoDB

**What a condition report is.** A condition report is filled in after the customer has returned the items from a booking. The report contains the item's id (`equipmentId`), notes about any damage or other deviation (`notes`), a checklist to go through (`checklist`) and `damageFlag` to mark whether the item is damaged.

**Why documents.** The reports look different depending on the item's category. For example, a tent has a checklist with canvas and tent pegs, and an e-bike has frame, tyres and battery health. We store the reports in MongoDB so that information that is not needed in a certain report can be left out. The report does not show `null`; information that should not be there is left out completely. If we add a new category, for example stand-up paddle boards (SUP), storing its checklist in MySQL would need a new table or new columns. In MongoDB we only create a new "template" and update the validation, and when the POST request is made, the report is created in MongoDB.

**Why bookings stay in MySQL.** Bookings stay in MySQL because we need the booking dates, so the database knows what is rented out and when. A booking is also connected to `booking_lines` with foreign keys, which MongoDB cannot do towards MySQL. The booking and its lines are saved in a transaction: if anything fails, nothing is saved, all or nothing.

**The trade-off.** MongoDB does not check by itself that the data matches what it should be, so we add validation in Express on the POST request. Without checks in the backend, any data could be sent to MongoDB, and a report with completely wrong information could be created. In MySQL the database is responsible for the structure, in MongoDB the backend is. Since `equipmentId` is not a foreign key, the backend first asks MySQL whether the item exists. If it does not, the backend responds with an error and nothing is saved in MongoDB.

## Transaction design

`POST /api/bookings` saves a booking and all its lines as **one transaction: all or nothing**.

1. The body is validated (customer, 1–10 items without duplicates, valid dates, `end_date > start_date`).
2. One connection is taken from the pool (`pool.getConnection()`). A transaction only exists on the connection that started it, so every query uses that connection, not `pool.execute()`.
3. `beginTransaction()` → `INSERT` into `bookings`.
4. For each item:
   - **Overlap check:** is the item already on a `confirmed` or `active` booking whose dates overlap? (`start_date <= new end AND end_date >= new start`). `<=`/`>=` also block the day the item is returned, which gives staff a **buffer day** to check it. The check runs before the line is inserted, otherwise it would find the booking's own line.
   - **Insert the line** with `INSERT … SELECT`: the daily price is copied from `equipment` (the client can never set the price), and only if the item is not `retired` or in `maintenance`.
5. If a date is taken, or an item cannot be booked → `rollback()` and `409`. Nothing is saved, not even the lines for the items that were fine.
6. Otherwise `commit()` and `201` with the `booking_id`. On any other error → `rollback()`. In `finally` the connection is always given back to the pool with `release()`.

**Known limitation:** two requests for the same item at exactly the same moment could both pass the overlap check, because neither can see the other's uncommitted rows. This would be solved by locking the item's row first (`SELECT … FOR UPDATE`).

The tests are in `DATABASE_TESTS.md` (DB-03 and DB-07).

## Error handling

Errors are handled in two layers:

1. **Validation in JavaScript** (`src/validation.js`) before the database is used → `400` with a message that says which fields are required.
2. **MySQL constraints** as the second line of defence. The function `dbFailure` in `src/server.js` translates MySQL errors that got past the validation:

| MySQL error | Example | Status |
|---|---|---|
| 1062 duplicate entry, 1451 row is referenced | duplicate value in a `UNIQUE` column, deleting a row that `RESTRICT` protects | `409` |
| 1452 no referenced row, 3819 check constraint | `category_id` that does not exist, negative price | `400` |
| anything else | lost connection, SQL error | `500` |

On `500` the client only gets a generic message (`Database operation failed`). Table names and error codes are only logged in the terminal, so the client cannot see how the database is built. `0` affected rows on `PUT`/`DELETE` gives `404`.

## Object-oriented design

All SQL for equipment is in the class `EquipmentRepository` (`src/repositories/equipmentRepository.js`):

```js
class EquipmentRepository {
  constructor(pool) {
    this.pool = pool;
  }

  async retire(id) {
    const [result] = await this.pool.execute(
      `UPDATE equipment SET status='retired'
       WHERE equipment_id=? AND status<>'retired' AND status<>'rented'`,
      [Number(id)]
    );
    return result.affectedRows;
  }
}
```

```js
// server.js
const equipmentRepository = new EquipmentRepository(pool);
const affectedRows = await equipmentRepository.retire(req.params.id);
if (affectedRows === 0) return res.status(404).json({ ... });
```

**Why:** the class only talks to the database (SQL, parameters, return values). The route only handles HTTP (validation, status codes, JSON). The routes stay short, the SQL is in one place, and the pool is passed in through the constructor so the whole app shares one pool.

## Security

- **Application user instead of root:** the API connects as `nordicrent_app_user`, which only has the privileges the routes need (see [Database settings](#database-settings)). It has no `DELETE`, `DROP` or `GRANT`, so even a bug in the code cannot delete data or change the schema.
- **Parameterized queries:** every query uses `?` placeholders. The values are sent separately from the SQL, so user input is always treated as data and never as SQL code. This protects against SQL injection.
- **`.env`:** the database password and settings are read from `.env`, which is not committed. `.env.example` only has the local development values.
- **Generic error messages:** the client never sees MySQL error details (see [Error handling](#error-handling)).
- **Validation** of all input before it reaches MySQL or MongoDB. For MongoDB, which has no schema, the validation and the equipment check in MySQL are the only protection.

## Database tests

See [`DATABASE_TESTS.md`](DATABASE_TESTS.md).
