USE [GeneralDataPRD]
GO


DECLARE @DOB DATE
DECLARE @EndDate DATE

SET @DOB = '02/09/1983'
SET @EndDate = GETDATE()

SELECT [dbo].[GetAge] (@DOB, @EndDate) AS [USER_AGE]
GO


