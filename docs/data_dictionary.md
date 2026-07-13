# Core Data Dictionary

## `pl.Customer`

Synthetic customer-level master data.

| Column | Description |
|---|---|
| `customer_id` | Unique synthetic customer identifier |
| `date_of_birth` | Synthetic date of birth |
| `gender` | Synthetic gender category |
| `state_code` | Indian state/UT code used for portfolio segmentation |
| `city_tier` | Tier 1, Tier 2, or Tier 3 location category |
| `employment_type` | Salaried, self-employed, or professional |
| `annual_income` | Synthetic annual income |
| `bureau_score` | Synthetic bureau score between 550 and 850 |
| `existing_monthly_emi` | Existing monthly obligations at customer level |
| `customer_created_at` | Customer-master creation timestamp |
| `record_source` | Source system for the customer record |

## `pl.Loan_Application`

Application-level records from the loan-origination layer.

| Column | Description |
|---|---|
| `application_id` | Unique application identifier |
| `customer_id` | Customer who submitted the application |
| `application_date` | Date the application was submitted |
| `requested_amount` | Amount requested by the customer |
| `approved_amount` | Final approved amount; null for non-approved applications |
| `tenure_months` | Requested or approved tenure |
| `proposed_interest_rate` | Proposed annual interest rate |
| `application_status` | Approved, rejected, cancelled, or pending |
| `decision_date` | Date of final decision; null for pending applications |
| `rejection_reason` | Reason for rejection where applicable |
| `application_channel` | Branch, web, mobile app, partner, or call centre |
| `branch_code` | Synthetic sourcing branch |
| `product_code` | Personal-loan product code |
| `source_system` | Originating source system |
| `created_at` | Record-creation timestamp |

## `pl.Loan`

Loan-booking records from the downstream booking system.

| Column | Description |
|---|---|
| `loan_id` | Unique booked-loan identifier |
| `application_id` | Application reference supplied to booking |
| `customer_id` | Customer identifier supplied to booking |
| `booking_date` | Date the loan was booked |
| `principal_amount` | Principal amount booked |
| `interest_rate` | Annual interest rate booked |
| `tenure_months` | Loan tenure booked |
| `first_emi_date` | Expected first EMI date |
| `loan_status` | Active, closed, or charged off |
| `disbursement_account_type` | Savings or current account |
| `source_system` | Booking-system source |
| `created_at` | Record-creation timestamp |
