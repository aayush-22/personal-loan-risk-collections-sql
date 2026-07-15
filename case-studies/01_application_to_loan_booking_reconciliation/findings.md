# Case Study Findings

## Case Study

Application-to-Loan Booking Reconciliation

## Current Stage

Base reconciliation, business-rule classification, detailed exception flags, and exception-overlap analysis completed.

---

## 1. Dataset Size

| Table | Row count |
|---|---:|
| `pl.Customer` | 40,000 |
| `pl.Loan_Application` | 60,000 |
| `pl.Loan` | 32,841 |

---

## 2. Confirmed Table Grain

| Table | Grain |
|---|---|
| `pl.Customer` | One row per customer |
| `pl.Loan_Application` | One row per application |
| `pl.Loan` | One row per booked loan account |

---

## 3. Key Uniqueness and Multiplicity

```text
Total loan rows:                  32,841
Distinct loan IDs:               32,841
Distinct application references: 32,694
```

`loan_id` is unique, but `application_id` is not unique in `pl.Loan`.

| Metric | Result |
|---|---:|
| Applications with multiple loans | 147 |
| Excess loan records | 147 |
| Maximum loans for one application | 2 |

Multiplicity distribution:

| Loans per application reference | Application references |
|---:|---:|
| 1 | 32,547 |
| 2 | 147 |

Control:

```text
32,547 × 1 + 147 × 2 = 32,841 loan rows
```

---

## 4. Base Join Results

### Application-centric `LEFT JOIN`

```text
Total rows = 60,147
```

```text
60,000 applications
+ 147 additional second-loan matches
= 60,147
```

### Complete `FULL OUTER JOIN`

```text
Total rows = 60,247
```

```text
60,147 application-side joined rows
+ 100 orphan loans
= 60,247
```

---

## 5. Source-System Presence

| Presence status | Rows |
|---|---:|
| `MATCHED` | 32,741 |
| `APPLICATION_ONLY` | 27,406 |
| `LOAN_ONLY` | 100 |
| **Total** | **60,247** |

Distinct matched applications:

```text
32,741 matched rows
- 147 additional duplicate-booking rows
= 32,594 distinct matched applications
```

---

## 6. Booking Business-Rule Classification

| Booking status | Rows |
|---|---:|
| `APPROVED_BOOKED` | 32,655 |
| `APPROVED_NOT_BOOKED` | 492 |
| `INVALID_BOOKING` | 86 |
| `NO_BOOKING_EXPECTED` | 26,914 |
| `ORPHAN_LOAN` | 100 |
| **Total** | **60,247** |

Interpretation:

- `APPROVED_NOT_BOOKED`: approval exists but no booking was found
- `INVALID_BOOKING`: rejected, cancelled, or pending application has a loan
- `NO_BOOKING_EXPECTED`: non-approved application correctly has no loan
- `ORPHAN_LOAN`: booking references an application absent from origination

---

## 7. Booking-Detail Exception Rules

The following independent flags were created for `APPROVED_BOOKED` rows:

| Flag | Rule |
|---|---|
| Customer mismatch | Application and loan customer IDs differ |
| Duplicate booking | More than one loan exists for the application |
| Amount mismatch | Approved amount differs from booked principal |
| Booked before decision | Booking date is earlier than decision date |

Final-status priority:

```text
1. CUSTOMER_MISMATCH
2. DUPLICATE_BOOKING
3. AMOUNT_MISMATCH
4. BOOKED_BEFORE_DECISION
5. VALID_BOOKING
```

---

## 8. Final Priority-Based Status

| Final status | Rows |
|---|---:|
| `VALID_BOOKING` | 31,888 |
| `NO_BOOKING_EXPECTED` | 26,914 |
| `APPROVED_NOT_BOOKED` | 492 |
| `DUPLICATE_BOOKING` | 293 |
| `AMOUNT_MISMATCH` | 254 |
| `CUSTOMER_MISMATCH` | 130 |
| `ORPHAN_LOAN` | 100 |
| `BOOKED_BEFORE_DECISION` | 90 |
| `INVALID_BOOKING` | 86 |
| **Total** | **60,247** |

Approved-booked reconciliation:

```text
31,888 valid
+ 130 customer mismatch
+ 293 duplicate booking
+ 254 amount mismatch
+ 90 booked before decision
= 32,655 approved-booked rows
```

---

## 9. Raw Exception Flags

| Raw flag | Count |
|---|---:|
| Customer mismatch | 130 |
| Duplicate booking | 294 |
| Amount mismatch | 257 |
| Booked before decision | 92 |

```text
Raw flag occurrences = 130 + 294 + 257 + 92 = 773
```

Priority-based booking-detail exception rows:

```text
130 + 293 + 254 + 90 = 767
```

Difference:

```text
773 - 767 = 6 additional exception occurrences
```

---

## 10. Exception-Count Distribution

The four binary exception flags were added for each `APPROVED_BOOKED` row.

| Exception count | Row count | Interpretation |
|---:|---:|---|
| 0 | 31,888 | No booking-detail defect |
| 1 | 761 | Exactly one defect |
| 2 | 6 | Two simultaneous defects |
| 3 | 0 | No rows |
| 4 | 0 | No rows |
| **Total** | **32,655** | Full approved-booked population |

Population control:

```text
31,888 + 761 + 6 = 32,655
```

Weighted flag control:

```text
0 × 31,888
+ 1 × 761
+ 2 × 6
= 773 raw exception occurrences
```

The controls match the earlier approved-booked population and raw flag totals.

---

## 11. Booking-Detail Quality Rates

### Valid booking-detail rate

```text
31,888 ÷ 32,655 × 100
≈ 97.65%
```

### Booking-detail exception rate

Rows with at least one defect:

```text
761 + 6 = 767
```

```text
767 ÷ 32,655 × 100
≈ 2.35%
```

These rates apply only to the `APPROVED_BOOKED` population and do not include approved-not-booked, invalid bookings, or orphan loans.

---

## 12. Multi-Defect Rows

Exactly six approved-booked rows have two simultaneous defects.

| Application ID | Loan ID | Exception combination |
|---:|---:|---|
| 2008251 | 3004494 | `CUSTOMER_MISMATCH + AMOUNT_MISMATCH` |
| 2013020 | 3007063 | `CUSTOMER_MISMATCH + BOOKED_BEFORE_DECISION` |
| 2015028 | 3008155 | `CUSTOMER_MISMATCH + DUPLICATE_BOOKING` |
| 2039112 | 3021198 | `DUPLICATE_BOOKING + AMOUNT_MISMATCH` |
| 2040128 | 3021754 | `CUSTOMER_MISMATCH + AMOUNT_MISMATCH` |
| 2056729 | 3030754 | `DUPLICATE_BOOKING + BOOKED_BEFORE_DECISION` |

No row has three or four simultaneous booking-detail defects.

---

## 13. Multi-Defect Combination Findings

Five distinct two-defect combinations were identified:

| Exception combination | Rows |
|---|---:|
| `CUSTOMER_MISMATCH + AMOUNT_MISMATCH` | 2 |
| `CUSTOMER_MISMATCH + BOOKED_BEFORE_DECISION` | 1 |
| `CUSTOMER_MISMATCH + DUPLICATE_BOOKING` | 1 |
| `DUPLICATE_BOOKING + AMOUNT_MISMATCH` | 1 |
| `DUPLICATE_BOOKING + BOOKED_BEFORE_DECISION` | 1 |
| **Total** | **6** |

The final combination-level aggregation query has not yet been completed in the active-learning exercise, but the detailed rows already establish these counts.

---

## 14. Why the Earlier Overlap Difference Equals Six

Earlier:

```text
Raw exception occurrences = 773
Unique defective rows      = 767
Difference                 = 6
```

The exception-count analysis proved that:

- exactly six rows have two flags
- no row has more than two flags

Each two-defect row contributes one additional raw occurrence beyond its one unique-row count.

```text
6 rows × 1 additional occurrence = 6
```

---

## 15. Next Step

Complete the combination-level management summary using:

```text
exception_combination
row_count
```

After that, continue with:

- distinct affected-application counts
- exception-level financial exposure
- monthly, channel, branch, and product segmentation
- management summary
- reusable reconciliation object
- Power BI dashboard
