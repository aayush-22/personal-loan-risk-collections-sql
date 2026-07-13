/*
    File: 03_seed_validation.sql
    Purpose: Confirm that the synthetic dataset loaded successfully.

    These are loading checks only. They are not the reconciliation solution.
*/

USE PersonalLoanRiskCollections;
GO

SET NOCOUNT ON;
GO

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

SELECT
    application_status,
    COUNT_BIG(*) AS application_count,
    CAST(SUM(requested_amount) AS DECIMAL(18,2)) AS requested_amount
FROM pl.Loan_Application
GROUP BY application_status
ORDER BY application_status;
GO

SELECT
    application_channel,
    COUNT_BIG(*) AS application_count
FROM pl.Loan_Application
GROUP BY application_channel
ORDER BY application_count DESC;
GO

SELECT
    (SELECT MIN(application_date) FROM pl.Loan_Application)
        AS earliest_application_date,
    (SELECT MAX(application_date) FROM pl.Loan_Application)
        AS latest_application_date,
    (SELECT MIN(booking_date) FROM pl.Loan)
        AS earliest_booking_date,
    (SELECT MAX(booking_date) FROM pl.Loan)
        AS latest_booking_date;
GO

SELECT TOP (10)
    *
FROM pl.Customer
ORDER BY customer_id;
GO

SELECT TOP (10)
    *
FROM pl.Loan_Application
ORDER BY application_id;
GO

SELECT TOP (10)
    *
FROM pl.Loan
ORDER BY loan_id;
GO
