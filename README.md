# Personal Loan Risk & Collections SQL Portfolio

A recruiter-visible SQL portfolio based on realistic personal-loan origination, booking, risk, servicing, and collections use cases.

## Technology

- Microsoft SQL Server / SSMS
- T-SQL
- Git and GitHub

## Current Dataset: Core Origination and Booking Layer

The initial dataset contains:

- 40,000 synthetic customers
- 60,000 synthetic loan applications
- Approximately 33,000 loan-booking records
- Multiple application statuses, channels, branches, amounts, tenures, and customer risk profiles
- Intentionally embedded reconciliation defects for analysis

The records are synthetic and contain no real customer information.

## Repository Structure

```text
personal-loan-risk-collections-sql/
├── README.md
├── docs/
│   └── data_dictionary.md
├── sql/
│   ├── 00_create_database.sql
│   ├── 01_create_core_tables.sql
│   ├── 02_generate_core_data.sql
│   └── 03_seed_validation.sql
└── case-studies/
    └── 01_application_to_loan_booking_reconciliation/
        └── README.md
```

## Execution Order

Run the scripts in SSMS in this order:

1. `sql/00_create_database.sql`
2. `sql/01_create_core_tables.sql`
3. `sql/02_generate_core_data.sql`
4. `sql/03_seed_validation.sql`

The data-generation script is deterministic. Re-running the table-creation and generation scripts produces the same dataset.

## Why the Loan Table Has No Application Foreign Key

The `pl.Loan` table intentionally does not have a foreign key from `application_id` to `pl.Loan_Application`.

This allows the dataset to contain orphan loan records, which are necessary for reconciliation and data-quality case studies. The relationship is logically expected but deliberately not physically enforced.

## Current Case Study

### Application-to-Loan Booking Reconciliation

The first case study will identify and summarize exceptions between the loan-origination application layer and the loan-booking layer.

The solution will be developed using active learning. The final SQL solution will not be committed until the business rules, base dataset, exception logic, and management summary have been developed step by step.
