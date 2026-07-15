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

The difference does not necessarily represent six rows unless the maximum exception count per row is also checked.

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

Examples:

```text
MATCHED + APPLICATION_ONLY + LOAN_ONLY
= total FULL OUTER JOIN rows
```

and:

```text
VALID_BOOKING
+ approved-booked exception statuses
= APPROVED_BOOKED rows
```

Control totals help detect missing classifications, accidental filters, and row multiplication errors.

---

## 15. Counting Exceptions by Adding Binary Flags

When each exception flag contains only `0` or `1`, the total number of exceptions on a row can be calculated by adding the flags.

```sql
COALESCE(customer_mismatch_flag, 0)
+ COALESCE(duplicate_booking_flag, 0)
+ COALESCE(amount_mismatch_flag, 0)
+ COALESCE(booked_before_decision_flag, 0)
    AS exception_count
```

Examples:

```text
0 + 0 + 0 + 0 = 0 exceptions
1 + 0 + 0 + 0 = 1 exception
1 + 1 + 0 + 0 = 2 exceptions
```

This is better than writing a long `CASE` statement for every possible flag combination.

With four binary flags, there can be:

```text
2⁴ = 16 possible combinations
```

Adding the flags handles all combinations automatically.

---

## 16. Why `COALESCE(flag, 0)` Is Used

Arithmetic with `NULL` returns `NULL`.

For example:

```text
1 + NULL + 0 + 0 = NULL
```

Using:

```sql
COALESCE(flag, 0)
```

converts any unexpected `NULL` flag to `0`, allowing the row-level exception count to remain numeric.

---

## 17. Exception-Count Distribution

The approved-booked population was summarized by `exception_count`.

| Exception count | Meaning |
|---:|---|
| 0 | No booking-detail defect |
| 1 | Exactly one defect |
| 2 | Two simultaneous defects |
| 3 | Three simultaneous defects |
| 4 | All four defects |

Two controls were used:

```text
Sum of row_count
= full APPROVED_BOOKED population
```

and:

```text
SUM(exception_count × row_count)
= total raw exception occurrences
```

This validates both the number of rows and the number of raised flags.

---

## 18. Dynamic Exception Labels with `CONCAT_WS`

A readable exception combination can be built dynamically using conditional labels and `CONCAT_WS`.

```sql
CONCAT_WS
(
    ' + ',

    CASE
        WHEN customer_mismatch_flag = 1
            THEN 'CUSTOMER_MISMATCH'
    END,

    CASE
        WHEN duplicate_booking_flag = 1
            THEN 'DUPLICATE_BOOKING'
    END,

    CASE
        WHEN amount_mismatch_flag = 1
            THEN 'AMOUNT_MISMATCH'
    END,

    CASE
        WHEN booked_before_decision_flag = 1
            THEN 'BOOKED_BEFORE_DECISION'
    END
) AS exception_combination
```

`CONCAT_WS`:

- uses the supplied separator
- ignores `NULL` values
- avoids unnecessary separators
- builds labels without defining every possible combination manually

Example:

```text
Flags: 1, 0, 1, 0

Result:
CUSTOMER_MISMATCH + AMOUNT_MISMATCH
```

A `CASE` expression without an `ELSE` returns `NULL` when its condition is false, which works well with `CONCAT_WS`.

---

## 19. Single-Defect vs Multi-Defect Rows

The exception-count analysis separates:

```text
Rows with no defect
Rows with exactly one defect
Rows with multiple simultaneous defects
```

This is useful because multi-defect rows may represent deeper process or integration failures than isolated exceptions.

In the current dataset:

- 761 approved-booked rows have exactly one booking-detail defect
- 6 approved-booked rows have exactly two defects
- no rows have three or four defects
