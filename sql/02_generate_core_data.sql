/*
    File: 02_generate_core_data.sql
    Purpose:
      1. Generate a deterministic synthetic portfolio.
      2. Populate realistic customer, application, and booking records.
      3. Embed controlled data-quality and reconciliation defects.

    Approximate scale:
      - 40,000 customers
      - 60,000 applications
      - 33,000+ loan records
*/

USE PersonalLoanRiskCollections;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

BEGIN TRY
    BEGIN TRANSACTION;

    DELETE FROM pl.Loan;
    DELETE FROM pl.Loan_Application;
    DELETE FROM pl.Customer;

    /* ---------------------------------------------------------
       1. CUSTOMER MASTER
       --------------------------------------------------------- */

    ;WITH NumberSeries AS
    (
        SELECT TOP (40000)
            ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
        FROM sys.all_objects AS a
        CROSS JOIN sys.all_objects AS b
    )
    INSERT INTO pl.Customer
    (
        customer_id,
        date_of_birth,
        gender,
        state_code,
        city_tier,
        employment_type,
        annual_income,
        bureau_score,
        existing_monthly_emi,
        customer_created_at,
        record_source
    )
    SELECT
        1000000 + n AS customer_id,

        DATEADD
        (
            DAY,
            -1 * (7670 + ((n * 97) % 15330)),
            CAST('2026-06-30' AS DATE)
        ) AS date_of_birth,

        CASE n % 20
            WHEN 0 THEN 'OTHER'
            WHEN 1 THEN 'FEMALE'
            WHEN 2 THEN 'FEMALE'
            WHEN 3 THEN 'FEMALE'
            WHEN 4 THEN 'FEMALE'
            WHEN 5 THEN 'FEMALE'
            WHEN 6 THEN 'FEMALE'
            WHEN 7 THEN 'FEMALE'
            WHEN 8 THEN 'FEMALE'
            WHEN 9 THEN 'FEMALE'
            ELSE 'MALE'
        END AS gender,

        CASE n % 15
            WHEN 0  THEN 'KA'
            WHEN 1  THEN 'MH'
            WHEN 2  THEN 'DL'
            WHEN 3  THEN 'TN'
            WHEN 4  THEN 'TG'
            WHEN 5  THEN 'UP'
            WHEN 6  THEN 'BR'
            WHEN 7  THEN 'WB'
            WHEN 8  THEN 'GJ'
            WHEN 9  THEN 'RJ'
            WHEN 10 THEN 'MP'
            WHEN 11 THEN 'KL'
            WHEN 12 THEN 'HR'
            WHEN 13 THEN 'PB'
            ELSE 'OR'
        END AS state_code,

        CASE
            WHEN n % 100 < 38 THEN 'TIER_1'
            WHEN n % 100 < 73 THEN 'TIER_2'
            ELSE 'TIER_3'
        END AS city_tier,

        CASE
            WHEN n % 100 < 68 THEN 'SALARIED'
            WHEN n % 100 < 92 THEN 'SELF_EMPLOYED'
            ELSE 'PROFESSIONAL'
        END AS employment_type,

        CAST
        (
            300000 + ((n * 7919) % 2700001)
            AS DECIMAL(14,2)
        ) AS annual_income,

        CAST
        (
            550 + ((n * 37) % 301)
            AS SMALLINT
        ) AS bureau_score,

        CAST
        (
            ((n * 3571) % 65001)
            AS DECIMAL(12,2)
        ) AS existing_monthly_emi,

        DATEADD
        (
            SECOND,
            n % 86400,
            DATEADD
            (
                DAY,
                (n * 13) % 730,
                CAST('2022-01-01' AS DATETIME2(0))
            )
        ) AS customer_created_at,

        'CUSTOMER_MASTER' AS record_source
    FROM NumberSeries;

    /* ---------------------------------------------------------
       2. LOAN APPLICATIONS
       --------------------------------------------------------- */

    ;WITH NumberSeries AS
    (
        SELECT TOP (60000)
            ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
        FROM sys.all_objects AS a
        CROSS JOIN sys.all_objects AS b
    ),
    ApplicationBase AS
    (
        SELECT
            n,
            2000000 + n AS application_id,
            1000000 + (((n * 17) - 1) % 40000) + 1 AS customer_id,
            DATEADD
            (
                DAY,
                (n * 29) % 912,
                CAST('2024-01-01' AS DATE)
            ) AS application_date,
            CAST
            (
                50000 + (((n * 7919) % 291) * 5000)
                AS DECIMAL(14,2)
            ) AS requested_amount,
            CASE n % 6
                WHEN 0 THEN 12
                WHEN 1 THEN 18
                WHEN 2 THEN 24
                WHEN 3 THEN 36
                WHEN 4 THEN 48
                ELSE 60
            END AS tenure_months,
            CAST
            (
                10.50 + ((n * 31) % 281) / 20.0
                AS DECIMAL(5,2)
            ) AS proposed_interest_rate,
            CASE
                WHEN n % 100 < 55 THEN 'APPROVED'
                WHEN n % 100 < 80 THEN 'REJECTED'
                WHEN n % 100 < 90 THEN 'CANCELLED'
                ELSE 'PENDING'
            END AS application_status
        FROM NumberSeries
    )
    INSERT INTO pl.Loan_Application
    (
        application_id,
        customer_id,
        application_date,
        requested_amount,
        approved_amount,
        tenure_months,
        proposed_interest_rate,
        application_status,
        decision_date,
        rejection_reason,
        application_channel,
        branch_code,
        product_code,
        source_system,
        created_at
    )
    SELECT
        application_id,
        customer_id,
        application_date,
        requested_amount,

        CASE
            WHEN application_status = 'APPROVED'
            THEN
                CASE
                    WHEN requested_amount - ((n % 6) * 5000) < 50000
                    THEN CAST(50000 AS DECIMAL(14,2))
                    ELSE requested_amount - ((n % 6) * 5000)
                END
            ELSE NULL
        END AS approved_amount,

        tenure_months,
        proposed_interest_rate,
        application_status,

        CASE
            WHEN application_status = 'PENDING'
            THEN NULL
            ELSE DATEADD(DAY, n % 8, application_date)
        END AS decision_date,

        CASE
            WHEN application_status <> 'REJECTED'
            THEN NULL
            WHEN n % 5 = 0 THEN 'LOW_BUREAU_SCORE'
            WHEN n % 5 = 1 THEN 'HIGH_FOIR'
            WHEN n % 5 = 2 THEN 'INCOME_NOT_VERIFIED'
            WHEN n % 5 = 3 THEN 'POLICY_RULE_FAILURE'
            ELSE 'ADVERSE_CREDIT_HISTORY'
        END AS rejection_reason,

        CASE
            WHEN n % 100 < 32 THEN 'MOBILE_APP'
            WHEN n % 100 < 57 THEN 'WEB'
            WHEN n % 100 < 75 THEN 'BRANCH'
            WHEN n % 100 < 91 THEN 'PARTNER'
            ELSE 'CALL_CENTRE'
        END AS application_channel,

        CONCAT
        (
            'B',
            RIGHT('000' + CAST(((n - 1) % 120) + 1 AS VARCHAR(3)), 3)
        ) AS branch_code,

        CASE
            WHEN n % 10 < 7 THEN 'PL_STANDARD'
            WHEN n % 10 < 9 THEN 'PL_PREAPPROVED'
            ELSE 'PL_SALARIED_PLUS'
        END AS product_code,

        'LOAN_ORIGINATION_SYSTEM' AS source_system,

        DATEADD
        (
            SECOND,
            (n * 19) % 72000,
            CAST(application_date AS DATETIME2(0))
        ) AS created_at
    FROM ApplicationBase;

    /* ---------------------------------------------------------
       3. NORMAL APPROVED-APPLICATION BOOKINGS
       A small subset is intentionally left without a booking.
       --------------------------------------------------------- */

    ;WITH ApprovedApplications AS
    (
        SELECT
            a.*,
            ROW_NUMBER() OVER (ORDER BY a.application_id) AS rn
        FROM pl.Loan_Application AS a
        WHERE a.application_status = 'APPROVED'
          AND a.application_id % 67 <> 0
    )
    INSERT INTO pl.Loan
    (
        loan_id,
        application_id,
        customer_id,
        booking_date,
        principal_amount,
        interest_rate,
        tenure_months,
        first_emi_date,
        loan_status,
        disbursement_account_type,
        source_system,
        created_at
    )
    SELECT
        3000000 + rn AS loan_id,
        application_id,

        CASE
            WHEN application_id % 251 = 0
            THEN
                1000000
                + ((customer_id - 1000000) % 40000)
                + 1
            ELSE customer_id
        END AS customer_id,

        CASE
            WHEN application_id % 401 = 0
            THEN DATEADD(DAY, -1, decision_date)
            ELSE DATEADD(DAY, 1 + (application_id % 5), decision_date)
        END AS booking_date,

        CASE
            WHEN application_id % 127 = 0
            THEN approved_amount + 5000
            ELSE approved_amount
        END AS principal_amount,

        proposed_interest_rate,
        tenure_months,

        DATEADD
        (
            MONTH,
            1,
            CASE
                WHEN application_id % 401 = 0
                THEN DATEADD(DAY, -1, decision_date)
                ELSE DATEADD(DAY, 1 + (application_id % 5), decision_date)
            END
        ) AS first_emi_date,

        CASE
            WHEN application_id % 37 = 0 THEN 'CHARGED_OFF'
            WHEN application_id % 20 = 0 THEN 'CLOSED'
            ELSE 'ACTIVE'
        END AS loan_status,

        CASE
            WHEN application_id % 4 = 0 THEN 'CURRENT'
            ELSE 'SAVINGS'
        END AS disbursement_account_type,

        'LOAN_BOOKING_SYSTEM' AS source_system,

        DATEADD
        (
            HOUR,
            2,
            CAST
            (
                CASE
                    WHEN application_id % 401 = 0
                    THEN DATEADD(DAY, -1, decision_date)
                    ELSE DATEADD(DAY, 1 + (application_id % 5), decision_date)
                END
                AS DATETIME2(0)
            )
        ) AS created_at
    FROM ApprovedApplications;

    /* ---------------------------------------------------------
       4. DUPLICATE BOOKINGS FOR A SUBSET OF APPROVED APPLICATIONS
       --------------------------------------------------------- */

    DECLARE @CurrentMaxLoanId BIGINT;

    SELECT @CurrentMaxLoanId = MAX(loan_id)
    FROM pl.Loan;

    ;WITH DuplicateCandidates AS
    (
        SELECT
            a.*,
            ROW_NUMBER() OVER (ORDER BY a.application_id) AS rn
        FROM pl.Loan_Application AS a
        WHERE a.application_status = 'APPROVED'
          AND a.application_id % 67 <> 0
          AND a.application_id % 223 = 0
    )
    INSERT INTO pl.Loan
    (
        loan_id,
        application_id,
        customer_id,
        booking_date,
        principal_amount,
        interest_rate,
        tenure_months,
        first_emi_date,
        loan_status,
        disbursement_account_type,
        source_system,
        created_at
    )
    SELECT
        @CurrentMaxLoanId + rn AS loan_id,
        application_id,
        customer_id,
        DATEADD(DAY, 2 + (application_id % 4), decision_date),
        approved_amount,
        proposed_interest_rate,
        tenure_months,
        DATEADD(MONTH, 1, DATEADD(DAY, 2 + (application_id % 4), decision_date)),
        'ACTIVE',
        CASE
            WHEN application_id % 4 = 0 THEN 'CURRENT'
            ELSE 'SAVINGS'
        END,
        'BOOKING_RETRY_PROCESS',
        DATEADD
        (
            HOUR,
            4,
            CAST
            (
                DATEADD(DAY, 2 + (application_id % 4), decision_date)
                AS DATETIME2(0)
            )
        )
    FROM DuplicateCandidates;

    /* ---------------------------------------------------------
       5. INVALID BOOKINGS FOR NON-APPROVED APPLICATIONS
       --------------------------------------------------------- */

    SELECT @CurrentMaxLoanId = MAX(loan_id)
    FROM pl.Loan;

    ;WITH InvalidBookingCandidates AS
    (
        SELECT
            a.*,
            ROW_NUMBER() OVER (ORDER BY a.application_id) AS rn
        FROM pl.Loan_Application AS a
        WHERE a.application_status <> 'APPROVED'
          AND a.application_id % 307 = 0
    )
    INSERT INTO pl.Loan
    (
        loan_id,
        application_id,
        customer_id,
        booking_date,
        principal_amount,
        interest_rate,
        tenure_months,
        first_emi_date,
        loan_status,
        disbursement_account_type,
        source_system,
        created_at
    )
    SELECT
        @CurrentMaxLoanId + rn,
        application_id,
        customer_id,
        DATEADD(DAY, 3, application_date),
        requested_amount,
        proposed_interest_rate,
        tenure_months,
        DATEADD(MONTH, 1, DATEADD(DAY, 3, application_date)),
        'ACTIVE',
        'SAVINGS',
        'BOOKING_EXCEPTION_PROCESS',
        DATEADD
        (
            HOUR,
            3,
            CAST(DATEADD(DAY, 3, application_date) AS DATETIME2(0))
        )
    FROM InvalidBookingCandidates;

    /* ---------------------------------------------------------
       6. ORPHAN LOANS WITH NO MATCHING APPLICATION
       --------------------------------------------------------- */

    SELECT @CurrentMaxLoanId = MAX(loan_id)
    FROM pl.Loan;

    ;WITH NumberSeries AS
    (
        SELECT TOP (100)
            ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
        FROM sys.all_objects
    )
    INSERT INTO pl.Loan
    (
        loan_id,
        application_id,
        customer_id,
        booking_date,
        principal_amount,
        interest_rate,
        tenure_months,
        first_emi_date,
        loan_status,
        disbursement_account_type,
        source_system,
        created_at
    )
    SELECT
        @CurrentMaxLoanId + n,
        9000000 + n,
        1000000 + (((n * 389) - 1) % 40000) + 1,
        DATEADD(DAY, n % 180, CAST('2026-01-01' AS DATE)),
        CAST(100000 + ((n % 80) * 10000) AS DECIMAL(14,2)),
        CAST(12.50 + ((n % 20) * 0.25) AS DECIMAL(5,2)),
        CASE n % 6
            WHEN 0 THEN 12
            WHEN 1 THEN 18
            WHEN 2 THEN 24
            WHEN 3 THEN 36
            WHEN 4 THEN 48
            ELSE 60
        END,
        DATEADD
        (
            MONTH,
            1,
            DATEADD(DAY, n % 180, CAST('2026-01-01' AS DATE))
        ),
        'ACTIVE',
        'SAVINGS',
        'LEGACY_BOOKING_MIGRATION',
        DATEADD
        (
            HOUR,
            5,
            CAST
            (
                DATEADD(DAY, n % 180, CAST('2026-01-01' AS DATE))
                AS DATETIME2(0)
            )
        )
    FROM NumberSeries;

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    THROW;
END CATCH;
GO
