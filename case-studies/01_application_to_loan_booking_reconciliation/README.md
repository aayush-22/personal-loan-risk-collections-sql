# Case Study 01: Application-to-Loan Booking Reconciliation

## Business Context

The loan-origination system stores applications and credit decisions. Approved applications are sent to a downstream booking system where a live loan account should be created.

Operations requires a repeatable reconciliation control to identify missing, invalid, duplicated, orphaned, and inconsistent bookings.

## Questions Covered

- Approved applications without a loan
- Loans booked against rejected, cancelled, or pending applications
- Multiple loans created for one application
- Loans referencing applications that do not exist
- Customer mismatches
- Approved-amount versus booked-principal mismatches
- Bookings created before the application decision
- Overlapping exception conditions
- Joined-row counts versus distinct affected applications

## Development Method

1. Validate table grain and key uniqueness
2. Profile application-to-loan multiplicity
3. Build an application-centric population
4. Build a complete cross-system population
5. Classify source-system presence
6. Apply booking business rules
7. Create independent exception flags
8. Assign a priority-based final status
9. Analyze exception counts and overlaps
10. Produce application-level, financial, and management summaries

## Current Progress

Completed:

- Source-table profiling
- Application-side `LEFT JOIN`
- Complete `FULL OUTER JOIN`
- Source-presence classification
- Booking-rule classification
- Customer-mismatch flag
- Duplicate-booking flag
- Amount-mismatch flag
- Booking-before-decision flag
- Priority-based final status
- Raw flag versus final-status validation
- Exception-count calculation
- Exception-count distribution
- Population and weighted-flag control checks
- Identification of six multi-defect rows
- Dynamic exception-combination labels with `CONCAT_WS`

Current exception-count result:

| Exception count | Rows |
|---:|---:|
| 0 | 31,888 |
| 1 | 761 |
| 2 | 6 |
| 3 | 0 |
| 4 | 0 |

Current multi-defect findings:

- 6 rows have two simultaneous defects
- 5 distinct two-defect combinations exist
- `CUSTOMER_MISMATCH + AMOUNT_MISMATCH` occurs twice
- the remaining four combinations occur once each

Next:

- Complete combination-level aggregation
- Calculate distinct affected applications
- Measure financial exposure
- Analyze trends and source segments
- Build management summaries
- Create reusable SQL objects
- Build the Power BI dashboard

## Project Files

```text
01_data_profiling.sql
02_base_reconciliation.sql
03_exception_overlap_analysis.sql
findings.md
README.md
```

## Current Control Totals

```text
FULL OUTER JOIN population       = 60,247
APPROVED_BOOKED rows             = 32,655
Valid booking-detail rows        = 31,888
Rows with at least one defect    = 767
Raw exception occurrences        = 773
Multi-defect rows                = 6
```
