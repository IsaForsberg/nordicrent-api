# NordicRent — Test Log

Results of the test cases in [`TESTPLAN.md`](TESTPLAN.md).

| Test ID | Date | Command / request | Expected result | Actual result | Pass/Fail |
|---|---|---|---|---|---|
| TC-ANON-01 | | `DELETE /api/customers/:id` (customer with only finished bookings) | `204`, personal data removed, `deleted_at` set, hidden from list, bookings kept | *not run yet* | |
| TC-ANON-02 | | `DELETE /api/customers/:id` (customer with an active booking) | `409`, customer row unchanged | *not run yet* | |
