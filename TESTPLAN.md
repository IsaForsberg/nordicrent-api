# NordicRent — Test Plan

Each test case has an ID, what is tested, how it is run and the expected result. The actual results are recorded in [`TESTLOG.md`](TESTLOG.md).

TODO: at least 10 cases in total, covering successful CRUD flows, 404, validation errors (400), a double booking attempt (409), a simulated SQL injection attempt, a forced transaction rollback, and at least one read/write case against MongoDB.

---

## Customer anonymization

These tests show that `DELETE /api/customers/:id` works as described in the README (approved by the course teacher): the customer can no longer be identified, but the booking history is kept.

### TC-ANON-01: Anonymize a customer with only finished bookings

**Setup:** a customer who only has bookings with status `returned` and/or `cancelled`.

**Steps:**
1. `DELETE /api/customers/:id`
2. Check the customer row in MySQL.
3. `GET /api/customers`
4. Check the customer's old bookings in MySQL.

**Expected result:**
- Status `204 No Content`.
- Name, email and phone no longer contain the customer's personal data. Nothing left in the row can identify the customer.
- `deleted_at` is set.
- The customer does not appear in `GET /api/customers`.
- The old bookings and their booking items still exist, and revenue statistics (e.g. top earners) are unchanged.

### TC-ANON-02: Reject anonymization when the customer has active bookings

**Setup:** a customer who has at least one booking with status `confirmed` or `active`.

**Steps:**
1. `DELETE /api/customers/:id`
2. Check the customer row in MySQL.

**Expected result:**
- Status `409 Conflict` with a clear error message.
- The customer row is unchanged (personal data kept, `deleted_at` still `NULL`).
