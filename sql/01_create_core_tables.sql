/*
    File: 01_create_core_tables.sql
    Purpose: Create the core customer, application, and loan-booking tables.
*/

USE PersonalLoanRiskCollections;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.schemas
    WHERE name = 'pl'
)
BEGIN
    EXEC ('CREATE SCHEMA pl');
END;
GO

DROP TABLE IF EXISTS pl.Loan;
DROP TABLE IF EXISTS pl.Loan_Application;
DROP TABLE IF EXISTS pl.Customer;
GO

CREATE TABLE pl.Customer
(
    customer_id            BIGINT          NOT NULL,
    date_of_birth          DATE            NOT NULL,
    gender                 VARCHAR(12)     NOT NULL,
    state_code             CHAR(2)         NOT NULL,
    city_tier              VARCHAR(10)     NOT NULL,
    employment_type        VARCHAR(25)     NOT NULL,
    annual_income          DECIMAL(14,2)   NOT NULL,
    bureau_score           SMALLINT        NOT NULL,
    existing_monthly_emi   DECIMAL(12,2)   NOT NULL,
    customer_created_at    DATETIME2(0)    NOT NULL,
    record_source          VARCHAR(30)     NOT NULL,

    CONSTRAINT PK_Customer
        PRIMARY KEY CLUSTERED (customer_id),

    CONSTRAINT CK_Customer_Gender
        CHECK (gender IN ('MALE', 'FEMALE', 'OTHER')),

    CONSTRAINT CK_Customer_CityTier
        CHECK (city_tier IN ('TIER_1', 'TIER_2', 'TIER_3')),

    CONSTRAINT CK_Customer_Employment
        CHECK (employment_type IN
        (
            'SALARIED',
            'SELF_EMPLOYED',
            'PROFESSIONAL'
        )),

    CONSTRAINT CK_Customer_BureauScore
        CHECK (bureau_score BETWEEN 300 AND 900),

    CONSTRAINT CK_Customer_Income
        CHECK (annual_income > 0),

    CONSTRAINT CK_Customer_ExistingEMI
        CHECK (existing_monthly_emi >= 0)
);
GO

CREATE TABLE pl.Loan_Application
(
    application_id          BIGINT          NOT NULL,
    customer_id             BIGINT          NOT NULL,
    application_date        DATE            NOT NULL,
    requested_amount        DECIMAL(14,2)   NOT NULL,
    approved_amount         DECIMAL(14,2)   NULL,
    tenure_months           SMALLINT        NOT NULL,
    proposed_interest_rate  DECIMAL(5,2)    NOT NULL,
    application_status      VARCHAR(20)     NOT NULL,
    decision_date           DATE            NULL,
    rejection_reason        VARCHAR(100)    NULL,
    application_channel     VARCHAR(20)     NOT NULL,
    branch_code             VARCHAR(10)     NOT NULL,
    product_code            VARCHAR(20)     NOT NULL,
    source_system           VARCHAR(30)     NOT NULL,
    created_at              DATETIME2(0)    NOT NULL,

    CONSTRAINT PK_LoanApplication
        PRIMARY KEY CLUSTERED (application_id),

    CONSTRAINT FK_LoanApplication_Customer
        FOREIGN KEY (customer_id)
        REFERENCES pl.Customer(customer_id),

    CONSTRAINT CK_LoanApplication_Status
        CHECK (application_status IN
        (
            'APPROVED',
            'REJECTED',
            'CANCELLED',
            'PENDING'
        )),

    CONSTRAINT CK_LoanApplication_RequestedAmount
        CHECK (requested_amount BETWEEN 50000 AND 1500000),

    CONSTRAINT CK_LoanApplication_ApprovedAmount
        CHECK
        (
            approved_amount IS NULL
            OR approved_amount BETWEEN 50000 AND 1500000
        ),

    CONSTRAINT CK_LoanApplication_Tenure
        CHECK (tenure_months IN (12, 18, 24, 36, 48, 60)),

    CONSTRAINT CK_LoanApplication_Rate
        CHECK (proposed_interest_rate BETWEEN 8.00 AND 30.00)
);
GO

CREATE TABLE pl.Loan
(
    loan_id                     BIGINT          NOT NULL,
    application_id              BIGINT          NOT NULL,
    customer_id                 BIGINT          NOT NULL,
    booking_date                DATE            NOT NULL,
    principal_amount            DECIMAL(14,2)   NOT NULL,
    interest_rate               DECIMAL(5,2)    NOT NULL,
    tenure_months               SMALLINT        NOT NULL,
    first_emi_date              DATE            NOT NULL,
    loan_status                 VARCHAR(20)     NOT NULL,
    disbursement_account_type   VARCHAR(20)     NOT NULL,
    source_system               VARCHAR(30)     NOT NULL,
    created_at                  DATETIME2(0)     NOT NULL,

    CONSTRAINT PK_Loan
        PRIMARY KEY CLUSTERED (loan_id),

    CONSTRAINT FK_Loan_Customer
        FOREIGN KEY (customer_id)
        REFERENCES pl.Customer(customer_id),

    CONSTRAINT CK_Loan_Principal
        CHECK (principal_amount BETWEEN 50000 AND 1600000),

    CONSTRAINT CK_Loan_Tenure
        CHECK (tenure_months IN (12, 18, 24, 36, 48, 60)),

    CONSTRAINT CK_Loan_Rate
        CHECK (interest_rate BETWEEN 8.00 AND 30.00),

    CONSTRAINT CK_Loan_Status
        CHECK (loan_status IN ('ACTIVE', 'CLOSED', 'CHARGED_OFF')),

    CONSTRAINT CK_Loan_AccountType
        CHECK (disbursement_account_type IN ('SAVINGS', 'CURRENT'))
);
GO

CREATE INDEX IX_LoanApplication_Customer
    ON pl.Loan_Application(customer_id);

CREATE INDEX IX_LoanApplication_StatusDate
    ON pl.Loan_Application(application_status, application_date)
    INCLUDE (approved_amount, decision_date);

CREATE INDEX IX_Loan_Application
    ON pl.Loan(application_id)
    INCLUDE (loan_id, customer_id, booking_date, principal_amount);

CREATE INDEX IX_Loan_Customer
    ON pl.Loan(customer_id);

CREATE INDEX IX_Loan_BookingDate
    ON pl.Loan(booking_date);
GO
