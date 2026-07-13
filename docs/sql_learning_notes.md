# SQL Learning Notes

This file records reusable SQL concepts learned while building the Personal Loan Risk & Collections SQL portfolio.

---

## 1. Table Grain

The **grain of a table** describes what one row represents.

- `pl.Customer`: one row per customer
- `pl.Loan_Application`: one row per loan application
- `pl.Loan`: one row per booked loan account

Understanding grain is necessary before joining tables because it determines whether keys are unique, whether a join can multiply rows, and whether aggregation is required.

### Grain validation pattern

```sql
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT primary_key_column) AS distinct_key_count
FROM table_name;
```

When `total_rows = distinct_key_count`, the tested key uniquely identifies every row.

---

## 2. Primary Key vs Business Key

A table can have a unique primary key while another business identifier is not unique.

In `pl.Loan`:

- `loan_id` is unique
- `application_id` is not unique

Therefore, one application may be connected to multiple loan records.

```sql
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT loan_id) AS distinct_loan_count,
    COUNT(DISTINCT application_id) AS distinct_application_count
FROM pl.Loan;
```

---

## 3. Detecting One-to-Many Relationships

```sql
SELECT
    application_id,
    COUNT(*) AS loan_count
FROM pl.Loan
GROUP BY application_id
HAVING COUNT(*) > 1;
```

`WHERE` filters rows before aggregation. `HAVING` filters groups after aggregation.

---

## 4. Affected Groups vs Excess Records

These are separate measurements.

- `COUNT(*)` after filtering `loan_count > 1` gives the number of affected applications.
- `SUM(loan_count - 1)` gives the number of loan rows beyond the expected one loan per application.

Example:

| Application | Loan count | Excess records |
|---|---:|---:|
| A101 | 2 | 1 |
| A102 | 4 | 3 |

Affected applications = 2, but excess records = 4.

---

## 5. CTE for Multi-Level Aggregation

```sql
WITH Loan_Count AS
(
    SELECT
        application_id,
        COUNT(*) AS loan_count
    FROM pl.Loan
    GROUP BY application_id
)
SELECT
    COUNT(*) AS applications_with_multiple_loans,
    SUM(loan_count - 1) AS excess_loan_records,
    MAX(loan_count) AS maximum_loans_for_one_application
FROM Loan_Count
WHERE loan_count > 1;
```

The CTE first creates one row per application. The outer query then summarizes those application-level results.
