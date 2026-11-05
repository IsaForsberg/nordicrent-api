# NordicRent — ER Diagram

`TODO` = data type not decided yet (to be handled in step 2).

```mermaid
erDiagram
    customers ||--o{ bookings : "makes"
    bookings ||--|{ booking_items : "contains"
    equipment ||--o{ booking_items : "is included in"
    depots ||--o{ equipment : "holds"
    categories ||--o{ equipment : "groups"
    booking_items ||--o{ condition_reports : "MongoDB, linked by id (no FK)"

    customers {
        INT customer_id PK
        VARCHAR first_name "NOT NULL"
        VARCHAR last_name "NOT NULL"
        VARCHAR email UK "NULL only if anonymized (CHECK)"
        VARCHAR phone "NULL only if anonymized?"
        TODO deleted_at "NULL = active customer"
    }

    depots {
        INT depot_id PK
        VARCHAR name "NOT NULL"
        VARCHAR city "NOT NULL"
        VARCHAR address "NOT NULL"
    }

    categories {
        INT category_id PK
        VARCHAR name UK "NOT NULL"
        VARCHAR description
    }

    equipment {
        INT equipment_id PK
        INT category_id FK "ON DELETE RESTRICT"
        INT depot_id FK "ON DELETE RESTRICT"
        VARCHAR model_name "NOT NULL"
        DECIMAL daily_price "size not decided, CHECK price >= 0?"
        DATE purchase_date "NOT NULL"
        ENUM status "available/rented/maintenance/retired, DEFAULT available"
    }

    bookings {
        INT booking_id PK
        INT customer_id FK "ON DELETE RESTRICT"
        DATE start_date "NOT NULL"
        DATE end_date "NOT NULL, CHECK after start_date?"
        ENUM status "confirmed/active/returned/cancelled, DEFAULT confirmed"
        TODO created_at "when the booking was made, DATE or with time?"
    }

    booking_items {
        INT booking_item_id PK
        INT booking_id FK "ON DELETE CASCADE, UNIQUE together with equipment_id"
        INT equipment_id FK "ON DELETE RESTRICT, UNIQUE together with booking_id"
        DECIMAL daily_price "price at the time of booking"
    }

    condition_reports {
        TODO _id PK "created automatically by MongoDB"
        INT booking_item_id "points to booking_items, not a real FK"
        TODO notes "free text"
        TODO checklist "nested object, differs per category"
        TODO photo_urls "list of URLs"
        TODO damaged "damage flag"
    }
```

The total price is not stored as a column. It is calculated from `booking_items.daily_price` × number of days (`end_date` − `start_date`).

For the submission, the diagram must be exported as an image or PDF.
