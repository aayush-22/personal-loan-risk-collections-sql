# Case Study Findings

## Case Study

Application-to-Loan Booking Reconciliation

## Current Stage

Base reconciliation, source-presence classification, booking-rule classification, and booking-detail exception flags completed.

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

Application-only control:

```text
60,000 total applications
- 32,594 applications with at least one loan
= 27,406
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

Approved-application control:

```text
33,000 approved applications
- 492 approved applications without a loan
= 32,508 distinct approved applications with a loan
```

Approved-booked row control:

```text
32,508 distinct approved applications with a loan
+ 147 additional duplicate rows
= 32,655 approved-booked rows
```

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

Overlap difference:

```text
773 - 767 = 6 additional exception occurrences
```

Raw flags overlap, while final statuses are mutually exclusive.

Confirmed effects of priority:

- One duplicate-booking flag occurrence is classified under `CUSTOMER_MISMATCH`.
- Three amount-mismatch flag occurrences are classified under higher-priority statuses.
- Two booked-before-decision flag occurrences are classified under higher-priority statuses.

The exact combinations remain to be profiled.

---

## 10. Date Observation

```text
Earliest application date: 2024-01-01
Earliest booking date:     2023-12-31
```

The detailed rule identified 92 raw `booked_before_decision` occurrences. After higher-priority exceptions were applied, 90 rows remained in the final `BOOKED_BEFORE_DECISION` category.

---

## 11. Next Step

Calculate the number of exception flags per approved-booked row and summarize:

```text
0 exceptions
1 exception
2 exceptions
3 exceptions
4 exceptions
```

This will quantify single-defect and multi-defect records.
