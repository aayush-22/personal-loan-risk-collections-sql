# Case Study 01: Application-to-Loan Booking Reconciliation

## Business Context

The loan-origination system stores customer applications and final credit decisions. Approved applications are sent to a downstream booking system, where a live loan account should be created.

Operations has identified potential inconsistencies between these systems and requires a repeatable reconciliation control.

## Business Questions

The project will investigate:

- Approved applications without a corresponding loan
- Loans booked against non-approved applications
- Multiple loans created for one application
- Loans referencing applications that do not exist
- Customer mismatch between application and booking
- Approved-amount versus booked-principal mismatch
- Booking-date anomalies
- Exception counts and financial exposure
- Reconciliation trends by month, channel, branch, and product

## Development Method

The solution will be built through active learning:

1. Understand the grain of each table
2. Define expected business rules
3. Build the base reconciliation population
4. Derive exception flags
5. Resolve one-to-many complications
6. Create exception severity
7. Produce management summaries
8. Validate results
9. Refactor into a reusable production-style script

## Status

Dataset setup in progress. The final reconciliation SQL has not yet been added.
