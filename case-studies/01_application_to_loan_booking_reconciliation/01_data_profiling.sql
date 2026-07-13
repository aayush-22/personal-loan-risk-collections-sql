/*
    Case Study:
        Application-to-Loan Booking Reconciliation

    File:
        01_data_profiling.sql

    Purpose:
        Validate source-table grain, key uniqueness, row counts,
        and application-to-loan multiplicity before building the
        reconciliation logic.

    Important:
        This file contains profiling queries only.
        It does not contain the final reconciliation solution.
*/

USE PersonalLoanRiskCollections;
GO

SET NOCOUNT ON;
GO


/*==============================================================
  1. DATASET ROW COUNTS
==============================================================*/

SELECT
    'pl.Customer' AS table_name,
    COUNT_BIG(*) AS row_count
FROM pl.Customer

UNION ALL

SELECT
    'pl.Loan_Application',
    COUNT_BIG(*)
FROM pl.Loan_Application

UNION ALL

SELECT
    'pl.Loan',
    COUNT_BIG(*)
FROM pl.Loan;
GO


/*==============================================================
  2. CUSTOMER TABLE GRAIN VALIDATION

  Expected grain:
      One row per customer
==============================================================*/

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT customer_id) AS distinct_customer_count
FROM pl.Customer;
GO


/*==============================================================
  3. LOAN APPLICATION TABLE GRAIN VALIDATION

  Expected grain:
      One row per loan application
==============================================================*/

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT application_id) AS distinct_application_count
FROM pl.Loan_Application;
GO


/*==============================================================
  4. LOAN TABLE GRAIN VALIDATION

  Expected grain:
      One row per booked loan account

  Important:
      loan_id should be unique.
      application_id may not be unique.
==============================================================*/

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT loan_id) AS distinct_loan_count,
    COUNT(DISTINCT application_id) AS distinct_application_count
FROM pl.Loan;
GO


/*==============================================================
  5. APPLICATION IDs CONNECTED TO MULTIPLE LOANS

  Business question:
      Which application references appear more than once
      in the booking table?
==============================================================*/

SELECT
    application_id,
    COUNT(*) AS loan_count
FROM pl.Loan
GROUP BY
    application_id
HAVING
    COUNT(*) > 1
ORDER BY
    loan_count DESC,
    application_id;
GO


/*==============================================================
  6. MULTIPLE-LOAN SUMMARY

  Measures:
      - affected applications
      - excess loan records
      - maximum loans linked to one application
==============================================================*/

WITH Loan_Count AS
(
    SELECT
        application_id,
        COUNT(*) AS loan_count
    FROM pl.Loan
    GROUP BY
        application_id
)
SELECT
    COUNT(*) AS applications_with_multiple_loans,
    SUM(loan_count - 1) AS excess_loan_records,
    MAX(loan_count) AS maximum_loans_for_one_application
FROM Loan_Count
WHERE loan_count > 1;
GO


/*==============================================================
  7. APPLICATION-TO-LOAN MULTIPLICITY DISTRIBUTION

  Purpose:
      Show how many application references have exactly
      1 loan, 2 loans, 3 loans, and so on.
==============================================================*/

WITH Loan_Count AS
(
    SELECT
        application_id,
        COUNT(*) AS loan_count
    FROM pl.Loan
    GROUP BY
        application_id
)
SELECT
    loan_count,
    COUNT(*) AS application_count
FROM Loan_Count
GROUP BY
    loan_count
ORDER BY
    loan_count;
GO


/*==============================================================
  8. SOURCE DATE-RANGE PROFILE

  Purpose:
      Establish the available application and booking periods
      and identify suspicious date boundaries for later review.
==============================================================*/

SELECT
    MIN(application_date) AS earliest_application_date,
    MAX(application_date) AS latest_application_date
FROM pl.Loan_Application;
GO

SELECT
    MIN(booking_date) AS earliest_booking_date,
    MAX(booking_date) AS latest_booking_date
FROM pl.Loan;
GO


/*==============================================================
  9. APPLICATION STATUS DISTRIBUTION

  Purpose:
      Understand the decision population before reconciliation.
==============================================================*/

SELECT
    application_status,
    COUNT(*) AS application_count,
    CAST(SUM(requested_amount) AS DECIMAL(18,2)) AS requested_amount,
    CAST(SUM(COALESCE(approved_amount, 0)) AS DECIMAL(18,2))
        AS approved_amount
FROM pl.Loan_Application
GROUP BY
    application_status
ORDER BY
    application_status;
GO


/*==============================================================
  10. APPLICATION CHANNEL DISTRIBUTION

  Purpose:
      Understand portfolio sourcing mix for later segmentation.
==============================================================*/

SELECT
    application_channel,
    COUNT(*) AS application_count
FROM pl.Loan_Application
GROUP BY
    application_channel
ORDER BY
    application_count DESC;
GO
