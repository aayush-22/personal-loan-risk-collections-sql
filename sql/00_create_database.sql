/*
    File: 00_create_database.sql
    Purpose: Create the portfolio database.
*/

USE master;
GO

IF DB_ID('PersonalLoanRiskCollections') IS NULL
BEGIN
    EXEC ('CREATE DATABASE PersonalLoanRiskCollections');
END;
GO

ALTER DATABASE PersonalLoanRiskCollections SET RECOVERY SIMPLE;
GO

USE PersonalLoanRiskCollections;
GO
