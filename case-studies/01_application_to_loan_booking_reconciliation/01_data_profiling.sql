/*
    Case Study:
        Application-to-Loan Booking Reconciliation

    File:
        01_data_profiling.sql

    Purpose:
        Understand table grain, key uniqueness, row distribution,
        and source-system relationships before reconciliation.
*/

Select * from pl.Customer;

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT customer_id) AS distinct_customer_count
FROM pl.Customer;

Select * from pl.Loan_Application;

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT application_id) AS distinct_application_count
FROM pl.Loan_Application;

SELECT * FROM pl.Loan;

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT loan_id) AS distinct_loan_count,
    COUNT(DISTINCT application_id) AS distinct_application_count
FROM pl.Loan;

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

