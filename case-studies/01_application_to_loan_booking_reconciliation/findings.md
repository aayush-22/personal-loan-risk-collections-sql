# Application-to-Loan Booking Reconciliation: Findings

## Current Stage

Source-table profiling and grain validation.

---

## Dataset Size

| Table | Row count |
|---|---:|
| `pl.Customer` | 40,000 |
| `pl.Loan_Application` | 60,000 |
| `pl.Loan` | 32,841 |

---

## Confirmed Table Grain

| Table | Grain |
|---|---|
| `pl.Customer` | One row per customer |
| `pl.Loan_Application` | One row per loan application |
| `pl.Loan` | One row per booked loan account |

---

## Key-Uniqueness Findings

### `pl.Customer`

- Total rows: 40,000
- Distinct customer IDs: 40,000
- Conclusion: `customer_id` is unique.

### `pl.Loan_Application`

- Total rows: 60,000
- Distinct application IDs: 60,000
- Conclusion: `application_id` is unique.

### `pl.Loan`

- Total loan rows: 32,841
- Distinct loan IDs: 32,841
- Distinct application IDs: 32,694
- Conclusion: `loan_id` is unique, but `application_id` is not unique.

---

## Multiple-Loan Finding

| Metric | Result |
|---|---:|
| Applications with multiple loans | 147 |
| Excess loan records | 147 |
| Maximum loans for one application | 2 |

There are 147 application IDs with two loan rows each. Since the maximum is two, every affected application has exactly one excess loan record.

```text
147 affected applications
× 1 excess loan record
= 147 excess loan records
```

---

## Reconciliation Implication

The observed relationship is:

```text
Loan_Application 1 ──────── 0, 1, or many Loan
```

The expected business rule to test later is:

```text
One approved application should produce exactly one booked loan.
```

A direct join may increase the row count because an application with two loans will appear twice. This multiplication reflects the source-data relationship and is not automatically a SQL error.

---

## Preliminary Date Observation

- Earliest application date: 2024-01-01
- Earliest booking date: 2023-12-31

A booking date earlier than the earliest application date is suspicious and requires application-level investigation before being classified.
