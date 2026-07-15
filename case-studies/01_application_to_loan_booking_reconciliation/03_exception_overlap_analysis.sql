/*
    Case Study:
        Application-to-Loan Booking Reconciliation

    File:
        03_exception_overlap_analysis.sql

    Purpose:
        Analyze how many approved-and-booked rows have zero, one,
        or multiple simultaneous booking-detail exceptions.

    Prerequisite:
        Run 02_base_reconciliation.sql first in the same SSMS session.
        That script creates #Final_Reconciliation.

    Current Scope:
        - Calculate exception_count
        - Summarize rows by exception_count
        - Validate population and raw exception occurrences
        - Filter the six multi-defect rows
        - Build readable exception-combination labels

    Not Yet Included:
        Combination-level management aggregation is intentionally left
        for the next active-learning exercise.
*/

USE PersonalLoanRiskCollections;
GO

SET NOCOUNT ON;
GO


/*==============================================================
  0. PREREQUISITE CHECK
==============================================================*/

IF OBJECT_ID('tempdb..#Final_Reconciliation') IS NULL
BEGIN
    THROW 50001,
          'Run 02_base_reconciliation.sql first in the same SSMS session.',
          1;
END;
GO


/*==============================================================
  1. EXCEPTION-COUNT DISTRIBUTION
==============================================================*/

WITH Exception_Counts AS
(
    SELECT
        application_id,
        loan_id,
        customer_mismatch_flag,
        duplicate_booking_flag,
        amount_mismatch_flag,
        booked_before_decision_flag,

        COALESCE(customer_mismatch_flag, 0)
        + COALESCE(duplicate_booking_flag, 0)
        + COALESCE(amount_mismatch_flag, 0)
        + COALESCE(booked_before_decision_flag, 0)
            AS exception_count

    FROM #Final_Reconciliation
    WHERE booking_reconciliation_status = 'APPROVED_BOOKED'
)

SELECT
    exception_count,
    COUNT(*) AS row_count
FROM Exception_Counts
GROUP BY
    exception_count
ORDER BY
    exception_count;
GO


/*==============================================================
  2. CONTROL CHECKS
==============================================================*/

WITH Exception_Counts AS
(
    SELECT
        COALESCE(customer_mismatch_flag, 0)
        + COALESCE(duplicate_booking_flag, 0)
        + COALESCE(amount_mismatch_flag, 0)
        + COALESCE(booked_before_decision_flag, 0)
            AS exception_count

    FROM #Final_Reconciliation
    WHERE booking_reconciliation_status = 'APPROVED_BOOKED'
)

SELECT
    COUNT(*) AS approved_booked_rows,
    SUM(exception_count) AS total_exception_occurrences
FROM Exception_Counts;
GO


/*==============================================================
  3. FILTER MULTI-DEFECT ROWS
==============================================================*/

WITH Exception_Counts AS
(
    SELECT
        application_id,
        loan_id,
        customer_mismatch_flag,
        duplicate_booking_flag,
        amount_mismatch_flag,
        booked_before_decision_flag,

        COALESCE(customer_mismatch_flag, 0)
        + COALESCE(duplicate_booking_flag, 0)
        + COALESCE(amount_mismatch_flag, 0)
        + COALESCE(booked_before_decision_flag, 0)
            AS exception_count

    FROM #Final_Reconciliation
    WHERE booking_reconciliation_status = 'APPROVED_BOOKED'
)

SELECT
    application_id,
    loan_id,
    customer_mismatch_flag,
    duplicate_booking_flag,
    amount_mismatch_flag,
    booked_before_decision_flag,
    exception_count
FROM Exception_Counts
WHERE exception_count = 2
ORDER BY
    application_id,
    loan_id;
GO


/*==============================================================
  4. BUILD READABLE EXCEPTION-COMBINATION LABELS
==============================================================*/

WITH Exception_Counts AS
(
    SELECT
        application_id,
        loan_id,
        customer_mismatch_flag,
        duplicate_booking_flag,
        amount_mismatch_flag,
        booked_before_decision_flag,

        COALESCE(customer_mismatch_flag, 0)
        + COALESCE(duplicate_booking_flag, 0)
        + COALESCE(amount_mismatch_flag, 0)
        + COALESCE(booked_before_decision_flag, 0)
            AS exception_count

    FROM #Final_Reconciliation
    WHERE booking_reconciliation_status = 'APPROVED_BOOKED'
),

Multi_Defect_Rows AS
(
    SELECT
        *,

        CONCAT_WS
        (
            ' + ',

            CASE
                WHEN customer_mismatch_flag = 1
                    THEN 'CUSTOMER_MISMATCH'
            END,

            CASE
                WHEN duplicate_booking_flag = 1
                    THEN 'DUPLICATE_BOOKING'
            END,

            CASE
                WHEN amount_mismatch_flag = 1
                    THEN 'AMOUNT_MISMATCH'
            END,

            CASE
                WHEN booked_before_decision_flag = 1
                    THEN 'BOOKED_BEFORE_DECISION'
            END
        ) AS exception_combination

    FROM Exception_Counts
    WHERE exception_count = 2
)

SELECT
    application_id,
    loan_id,
    customer_mismatch_flag,
    duplicate_booking_flag,
    amount_mismatch_flag,
    booked_before_decision_flag,
    exception_count,
    exception_combination
FROM Multi_Defect_Rows
ORDER BY
    application_id,
    loan_id;
GO
