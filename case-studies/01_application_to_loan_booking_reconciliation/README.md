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
9. Analyze exception overlaps
10. Produce management and financial-exposure summaries

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

Next:

- Exception-overlap analysis
- Distinct affected-application counts
- Financial exposure
- Monthly, channel, branch, and product summaries
