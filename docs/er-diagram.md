# NordicRent — ER Diagram

The MySQL tables match `database/setup.sql`. The MongoDB document `condition_reports` matches what `POST /api/reports` saves.

```mermaid
erDiagram
    customers ||--o{ bookings : "makes"
    bookings ||--|{ booking_lines : "contains"
    equipment ||--o{ booking_lines : "is included in"
    depots ||--o{ equipment : "holds"
    categories ||--o{ equipment : "groups"
    equipment ||--o{ condition_reports : "MongoDB, application reference (no FK)"

    customers {
        INT customer_id PK "AUTO_INCREMENT"
        VARCHAR first_name "VARCHAR(50), NULL only if anonymized (CHECK)"
        VARCHAR last_name "VARCHAR(50), NULL only if anonymized (CHECK)"
        VARCHAR email UK "VARCHAR(80), NULL only if anonymized (CHECK)"
        VARCHAR phone "VARCHAR(20), NULL only if anonymized (CHECK)"
        DATETIME deleted_at "NULL = active customer, a date = anonymized"
    }

    depots {
        INT depot_id PK "AUTO_INCREMENT"
        VARCHAR name "VARCHAR(70), NOT NULL, UNIQUE together with city"
        VARCHAR city "VARCHAR(50), NOT NULL, UNIQUE together with name"
        VARCHAR address "VARCHAR(150), NOT NULL"
    }

    categories {
        INT category_id PK "AUTO_INCREMENT"
        VARCHAR name UK "VARCHAR(40), NOT NULL"
        TEXT description "NOT NULL"
    }

    equipment {
        INT equipment_id PK "AUTO_INCREMENT"
        INT category_id FK "NOT NULL, ON DELETE RESTRICT"
        INT depot_id FK "NOT NULL, ON DELETE RESTRICT"
        VARCHAR model_name "VARCHAR(80), NOT NULL"
        DECIMAL daily_price "DECIMAL(7,2), NOT NULL, CHECK >= 0"
        DATE purchase_date "NOT NULL"
        ENUM status "available/rented/maintenance/retired, NOT NULL, DEFAULT available"
    }

    bookings {
        INT booking_id PK "AUTO_INCREMENT"
        INT customer_id FK "NOT NULL, ON DELETE RESTRICT"
        DATE start_date "NOT NULL"
        DATE end_date "NOT NULL, CHECK end_date > start_date"
        ENUM status "confirmed/active/returned/cancelled, NOT NULL, DEFAULT confirmed"
        DATETIME created_at "NOT NULL, DEFAULT CURRENT_TIMESTAMP"
    }

    booking_lines {
        INT booking_line_id PK "AUTO_INCREMENT"
        INT booking_id FK "NOT NULL, ON DELETE CASCADE, UNIQUE together with equipment_id"
        INT equipment_id FK "NOT NULL, ON DELETE RESTRICT, UNIQUE together with booking_id"
        DECIMAL daily_price "DECIMAL(7,2), NOT NULL, CHECK >= 0, price at the time of booking"
    }

    condition_reports {
        ObjectId _id PK "created automatically by MongoDB"
        Number equipmentId "points to equipment, not a real FK (checked against MySQL)"
        String notes "free text, 1-1000 characters"
        Object checklist "true/false per item, differs per category"
        Boolean damageFlag "true = the item is damaged"
        Date createdAt "set by the backend, newest first in GET"
    }
```

The total price is not stored as a column. It is calculated from `booking_lines.daily_price` × number of days (`end_date` − `start_date`).

## Named constraints

| Table | Constraint | Rule |
|---|---|---|
| `depots` | `uq_depot_location` | the same name cannot appear twice in the same city |
| `customers` | `chk_customer_personal_data` | an active customer (`deleted_at` is `NULL`) must have all four personal fields |
| `equipment` | `fk_equipment_category`, `fk_equipment_depot` | must point to an existing category and depot (RESTRICT) |
| `equipment` | `chk_equipment_daily_price` | `daily_price >= 0` |
| `bookings` | `fk_booking_customer` | must point to an existing customer (RESTRICT) |
| `bookings` | `chk_booking_duration` | `end_date > start_date`, so the shortest booking is one day |
| `booking_lines` | `fk_booking_lines_booking` | lines are deleted together with their booking (CASCADE) |
| `booking_lines` | `fk_booking_lines_equipment` | equipment used in a booking cannot be deleted (RESTRICT) |
| `booking_lines` | `uq_booking_equipment` | the same equipment cannot appear twice in one booking |
| `booking_lines` | `chk_booking_lines_daily_price` | `daily_price >= 0` |

## Connection between backend and frontend

The database stores relationships as IDs. A row in `equipment` only has `category_id` and `depot_id`, which are numbers, for example `category_id = 1` and `depot_id = 1`. A frontend that lists equipment wants to show the user "Kayak" and "Umeå", not 1 and 1.

The backend bridges the gap. In `GET /api/equipment` it joins `equipment` with `categories` and `depots`, so that the category name and the depot's city come from their own tables, and sends the result back as JSON that a frontend can show directly. One item from the response:

```json
{
  "equipment_id": 1,
  "model_name": "Prijon Kodiak",
  "city": "Umeå",
  "status": "available",
  "current_daily_price": "350.00",
  "category_name": "Kayak"
}
```

This is also why the normalized design works in practice: the category name and the depot's city are stored only once, in their own tables, and the JOIN puts them together when they are needed. If a category is renamed, only one row changes, and every response from the API shows the new name.

The short text about 3NF, relationships, the MongoDB choice and the transaction is in the [README](../README.md#database-design).

The diagram exported as an image: [`er-diagram-nordicrent.png`](er-diagram-nordicrent.png).
