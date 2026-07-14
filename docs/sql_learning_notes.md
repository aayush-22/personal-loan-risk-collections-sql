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

`WHERE` filters source rows before aggregation. `HAVING` filters grouped results after aggregation.

---

## 4. Affected Groups vs Excess Records

These are different measurements.

- **Affected applications:** number of application IDs with more than one loan
- **Excess records:** number of loan rows beyond the expected one loan per application

```sql
SUM(loan_count - 1)
```

---

## 5. CTE for Multi-Level Aggregation

A CTE can first calculate one row per application and then support an outer summary.

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

---

## 6. Choosing a Join from the Business Requirement

### Application-side `LEFT JOIN`

Use an application-side `LEFT JOIN` when every application must remain visible, including applications with no loan.

```text
All applications
+ matching loans where available
```

### `FULL OUTER JOIN`

Use a `FULL OUTER JOIN` when reconciliation must retain unmatched records from both systems.

```text
Applications without loans
+ matched records
+ loans without applications
```

A join should be chosen based on the population the business wants to preserve.

---

## 7. Join Row Multiplication

A join can return more rows than the driving table when one source row matches multiple target rows.

In this dataset:

```text
60,000 application rows
+ 147 additional rows from second loan matches
= 60,147 LEFT JOIN rows
```

This reflects the source-data relationship and is not automatically a SQL error.

---

## 8. Source Presence vs Business Validity

These are separate classification layers.

### Source-system presence

```text
MATCHED
APPLICATION_ONLY
LOAN_ONLY
```

This answers:

> In which source systems does the record exist?

### Booking business rule

```text
APPROVED_BOOKED
APPROVED_NOT_BOOKED
INVALID_BOOKING
NO_BOOKING_EXPECTED
ORPHAN_LOAN
```

This answers:

> Does the existence or absence of the booking agree with the application decision?

A rejected application with a loan is technically `MATCHED` but is a business-level `INVALID_BOOKING`.

---

## 9. Select the Shared Business Key from Both Systems

In reconciliation queries, select both versions of a common key.

```sql
LA.application_id,
L.application_id AS loan_application_id
```

For an orphan loan:

- application-side `application_id` is `NULL`
- loan-side `loan_application_id` is populated

This makes the invalid source reference visible.

---

## 10. CASE Expression Priority

A searched `CASE` returns the result from the **first true condition**.

Therefore, overlapping exceptions need an agreed business priority.

Current priority:

```text
1. CUSTOMER_MISMATCH
2. DUPLICATE_BOOKING
3. AMOUNT_MISMATCH
4. BOOKED_BEFORE_DECISION
5. VALID_BOOKING
```

Structural conditions such as orphan loans and missing bookings are evaluated before booking-detail exceptions.

---

## 11. Independent Flags vs Final Status

### Independent exception flags

```text
customer_mismatch_flag
duplicate_booking_flag
amount_mismatch_flag
booked_before_decision_flag
```

One row may have several flags equal to `1`.

### Priority-based final status

```text
final_reconciliation_status
```

Each row receives exactly one final category.

This design preserves all defects while producing a mutually exclusive management summary.

---

## 12. Raw Flag Counts vs Final-Status Counts

Raw flag totals may overlap.

Example:

| Customer mismatch | Duplicate booking | Final status |
|---:|---:|---|
| 1 | 1 | `CUSTOMER_MISMATCH` |

The row contributes once to each raw flag total but only once to the final status.

Current result:

```text
Raw flag occurrences = 773
Priority-based booking-detail exception rows = 767
Difference = 6 overlapping occurrences
```

The difference does not necessarily represent six rows. One row with three flags creates two additional occurrences.

---

## 13. Joined-Row Count vs Distinct Application Count

The reconciliation result remains at application-loan joined-row grain.

Therefore:

```text
DUPLICATE_BOOKING rows
≠
distinct applications with duplicate bookings
```

Business reporting may require all three:

- affected joined rows
- distinct affected applications
- excess loan records

---

## 14. Control Totals

A professional reconciliation should verify that related summaries tie back to one another.

Examples from this project:

```text
MATCHED + APPLICATION_ONLY + LOAN_ONLY
= total FULL OUTER JOIN rows
```

and:

```text
VALID_BOOKING
+ all approved-booked exception statuses
= APPROVED_BOOKED rows
```

Control totals help detect missing classifications, accidental filters, and row multiplication errors.
