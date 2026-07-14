/*
    Case Study:
        Application-to-Loan Booking Reconciliation

    File:
        02_base_reconciliation.sql

    Purpose:
        Build the full reconciliation population, classify source presence,
        apply booking rules, create independent exception flags, and assign
        one priority-based final reconciliation status.
*/

USE PersonalLoanRiskCollections;
GO

SET NOCOUNT ON;
GO

DROP TABLE IF EXISTS #Loan_Count;
DROP TABLE IF EXISTS #Base_Reconciliation;
DROP TABLE IF EXISTS #Exception_Flags;
DROP TABLE IF EXISTS #Final_Reconciliation;


/* 1. Count loans linked to each application reference */

SELECT
    application_id,
    COUNT(*) AS loan_count_per_application
INTO #Loan_Count
FROM pl.Loan
GROUP BY
    application_id;


/* 2. Build the complete application-to-loan population */

SELECT
    LA.application_id,
    LA.customer_id AS application_customer_id,
    LA.application_date,
    LA.application_status,
    LA.decision_date,
    LA.approved_amount,

    L.application_id AS loan_application_id,
    L.loan_id,
    L.customer_id AS loan_customer_id,
    L.booking_date,
    L.principal_amount,
    L.loan_status,

    LC.loan_count_per_application,

    CASE
        WHEN LA.application_id IS NULL
            THEN 'LOAN_ONLY'
        WHEN L.loan_id IS NULL
            THEN 'APPLICATION_ONLY'
        ELSE 'MATCHED'
    END AS match_flag,

    CASE
        WHEN LA.application_id IS NULL
             AND L.loan_id IS NOT NULL
            THEN 'ORPHAN_LOAN'

        WHEN LA.application_status = 'APPROVED'
             AND L.loan_id IS NULL
            THEN 'APPROVED_NOT_BOOKED'

        WHEN LA.application_status IN ('REJECTED', 'CANCELLED', 'PENDING')
             AND L.loan_id IS NOT NULL
            THEN 'INVALID_BOOKING'

        WHEN LA.application_status IN ('REJECTED', 'CANCELLED', 'PENDING')
             AND L.loan_id IS NULL
            THEN 'NO_BOOKING_EXPECTED'

        WHEN LA.application_status = 'APPROVED'
             AND L.loan_id IS NOT NULL
            THEN 'APPROVED_BOOKED'

        ELSE 'UNCLASSIFIED'
    END AS booking_reconciliation_status

INTO #Base_Reconciliation
FROM pl.Loan_Application AS LA
FULL OUTER JOIN pl.Loan AS L
    ON LA.application_id = L.application_id
LEFT JOIN #Loan_Count AS LC
    ON L.application_id = LC.application_id;


/* 3. Create independent booking-detail exception flags */

SELECT
    *,

    CASE
        WHEN booking_reconciliation_status = 'APPROVED_BOOKED'
             AND application_customer_id <> loan_customer_id
            THEN 1
        ELSE 0
    END AS customer_mismatch_flag,

    CASE
        WHEN booking_reconciliation_status = 'APPROVED_BOOKED'
             AND loan_count_per_application > 1
            THEN 1
        ELSE 0
    END AS duplicate_booking_flag,

    CASE
        WHEN booking_reconciliation_status = 'APPROVED_BOOKED'
             AND approved_amount <> principal_amount
            THEN 1
        ELSE 0
    END AS amount_mismatch_flag,

    CASE
        WHEN booking_reconciliation_status = 'APPROVED_BOOKED'
             AND booking_date < decision_date
            THEN 1
        ELSE 0
    END AS booked_before_decision_flag

INTO #Exception_Flags
FROM #Base_Reconciliation;


/* 4. Assign one final status according to business priority */

SELECT
    *,

    CASE
        WHEN booking_reconciliation_status = 'ORPHAN_LOAN'
            THEN 'ORPHAN_LOAN'

        WHEN booking_reconciliation_status = 'APPROVED_NOT_BOOKED'
            THEN 'APPROVED_NOT_BOOKED'

        WHEN booking_reconciliation_status = 'INVALID_BOOKING'
            THEN 'INVALID_BOOKING'

        WHEN booking_reconciliation_status = 'NO_BOOKING_EXPECTED'
            THEN 'NO_BOOKING_EXPECTED'

        WHEN customer_mismatch_flag = 1
            THEN 'CUSTOMER_MISMATCH'

        WHEN duplicate_booking_flag = 1
            THEN 'DUPLICATE_BOOKING'

        WHEN amount_mismatch_flag = 1
            THEN 'AMOUNT_MISMATCH'

        WHEN booked_before_decision_flag = 1
            THEN 'BOOKED_BEFORE_DECISION'

        WHEN booking_reconciliation_status = 'APPROVED_BOOKED'
            THEN 'VALID_BOOKING'

        ELSE 'UNCLASSIFIED'
    END AS final_reconciliation_status

INTO #Final_Reconciliation
FROM #Exception_Flags;


/* 5. Source-presence summary */

SELECT
    match_flag,
    COUNT(*) AS row_count
FROM #Final_Reconciliation
GROUP BY
    match_flag
ORDER BY
    row_count DESC;


/* 6. Booking-rule summary */

SELECT
    booking_reconciliation_status,
    COUNT(*) AS row_count
FROM #Final_Reconciliation
GROUP BY
    booking_reconciliation_status
ORDER BY
    row_count DESC;


/* 7. Final priority-based summary */

SELECT
    final_reconciliation_status,
    COUNT(*) AS row_count
FROM #Final_Reconciliation
GROUP BY
    final_reconciliation_status
ORDER BY
    row_count DESC;


/* 8. Raw exception-flag totals */

SELECT
    SUM(customer_mismatch_flag) AS total_customer_mismatch,
    SUM(duplicate_booking_flag) AS total_duplicate_booking,
    SUM(amount_mismatch_flag) AS total_amount_mismatch,
    SUM(booked_before_decision_flag) AS total_booked_before_decision
FROM #Final_Reconciliation;


/* 9. Detailed records for investigation */

SELECT
    *
FROM #Final_Reconciliation
ORDER BY
    COALESCE(application_id, loan_application_id),
    loan_id;
