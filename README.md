# NordicRent API

Backend for NordicRent, a Scandinavian startup that rents out outdoor equipment (tents, kayaks, e-bikes, ski equipment) from depots in several cities. Customers book equipment for a date range, pick it up at a depot and return it. Staff register returns and write a condition report for each item.

The backend consists of:
- a normalized **MySQL** database (customers, depots, categories, equipment, bookings, booking items)
- a **REST API** in Node.js/Express on top of it
- a **MongoDB** collection for condition reports

> Final project in the course *Databashantering MySQL*, Backend Web Developer (YH).

---

## Tech stack

TODO

## Installation

TODO

## Environment variables

TODO (see `.env.example`)

## Seeding the database

TODO

The sample data in `database/seed.sql` was generated with the help of an AI tool. I have reviewed it and can explain it.

---

## API endpoints

All endpoints exchange JSON.

### Customers (`/api/customers`)

| Method | Endpoint | Description |
|---|---|---|
| GET | `/api/customers` | List customers (paginated, anonymized customers hidden) |
| GET | `/api/customers/:id` | Get one customer |
| POST | `/api/customers` | Create a customer |
| PUT | `/api/customers/:id` | Update a customer |
| DELETE | `/api/customers/:id` | Anonymize a customer (only without active bookings), see [Customer deletion](#customer-deletion-anonymization) |
| GET | `/api/customers/:id/bookings` | The customer's booking history |

### Equipment (`/api/equipment`)

| Method | Endpoint | Description |
|---|---|---|
| GET | `/api/equipment` | List equipment, filter by category, city and status |
| GET | `/api/equipment/:id` | Get one item |
| POST | `/api/equipment` | Add an item |
| PUT | `/api/equipment/:id` | Update an item |
| DELETE | `/api/equipment/:id` | Retire an item (sets status `retired`, the row is kept) |
| GET | `/api/equipment/top-earners` | Items with rental revenue above the average per item |

### Bookings (`/api/bookings`)

| Method | Endpoint | Description |
|---|---|---|
| POST | `/api/bookings` | Create a booking with items (transaction, `409` on overlap) |
| GET | `/api/bookings/:id` | A booking with its items and equipment details |
| PATCH | `/api/bookings/:id/return` | Register a return: update status and write condition report(s) to MongoDB |
| PATCH | `/api/bookings/:id/cancel` | Cancel a confirmed booking |

### Condition reports (`/api/reports`, MongoDB)

| Method | Endpoint | Description |
|---|---|---|
| POST | `/api/reports` | Create a condition report |
| GET | `/api/reports/equipment/:equipmentId` | All reports for an item, newest first |
| GET | `/api/reports/damaged` | All reports with the damage flag set |

### Other

| Method | Endpoint | Description |
|---|---|---|
| GET | `/api/health` | Returns `{ "status": "ok" }` |

### Example requests (curl)

TODO

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
| `booking_items` | Connects bookings and equipment (N:M). Without it, a booking would have to contain its items, or an item its bookings. Now `equipment` is only about equipment and `bookings` only about the booking. |

TODO: describe which dependencies were eliminated (e.g. depot city stored in `depots`, not on every item).

### Price stored on booking items

`booking_items` stores the daily price that applied **when the booking was made**. `equipment` stores the **current** price. These are two different facts, not a copy of the same one, even if they have the same value at the moment of booking. This means old bookings do not change when prices change, and it does not break 3NF.

### Total price is calculated, not stored

`bookings` has no total price column. The total is calculated when it is read: the sum of the daily prices in `booking_items` × the number of days. A stored total would be derived from other columns and could get out of sync with the rows (for example if single items could be cancelled in the future). Without a total column it can never be wrong, and the schema stays in 3NF. The same calculation (price × days) is also used for `top-earners`.

### Foreign keys and ON DELETE

| Foreign key | References | ON DELETE | Reason |
|---|---|---|---|
| `equipment.depot_id` | `depots` | RESTRICT | A depot with equipment cannot be deleted. If a depot closes, its equipment is moved first. |
| `equipment.category_id` | `categories` | RESTRICT | A category cannot be deleted while items use it. |
| `bookings.customer_id` | `customers` | RESTRICT | A booking cannot exist without a customer, and the booking history must be protected. Customers are anonymized instead of deleted. |
| `booking_items.booking_id` | `bookings` | CASCADE | A booking item means nothing without its booking. |
| `booking_items.equipment_id` | `equipment` | RESTRICT | Protects the booking history (totals are calculated from the rows). Items are retired instead of deleted. |

### Customer deletion (anonymization)

`DELETE /api/customers/:id` does not remove the customer row.

1. If the customer has active bookings (`confirmed` or `active`), the request is rejected with `409 Conflict`.
2. Otherwise the customer's personal data (name, email, phone) is removed and `deleted_at` is set. The row and the booking history are kept.

Reason: deleting the row with `ON DELETE CASCADE` would also delete old bookings and change revenue statistics (e.g. top earners), and in a real company bookkeeping rules require financial records to be kept for several years. Anonymization removes the personal data (GDPR) but keeps the history correct. `bookings.customer_id` uses `ON DELETE RESTRICT` so the database itself protects the history. Anonymized customers are hidden from `GET /api/customers` (`WHERE deleted_at IS NULL`).

This solution was approved by the course teacher.

---

## MySQL vs MongoDB

TODO

## Transaction design

TODO

## Security

TODO

## Testing

See [`TESTPLAN.md`](TESTPLAN.md) and [`TESTLOG.md`](TESTLOG.md).
