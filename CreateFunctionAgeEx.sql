USE [GeneralDataPRD]
GO
/****** Object:  UserDefinedFunction [dbo].[GetAge]    Script Date: 1/13/2018 7:29:21 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER FUNCTION [dbo].[GetAge](@BirthDate DATE, @EndDate DATE)
RETURNS INT
AS
BEGIN

--DECLARE @BirthDate DATE -- Now being set as a parameter
--DECLARE @EndDate DATE -- Now being set as a parameter
DECLARE @Age INT

-- SET @BirthDate = '01/01/1980' -- Now being set as a parameter
-- SET @EndDate = GETDATE() -- Now being set as a parameter


SET @Age = DATEDIFF(yy, @BirthDate, @EndDate) - 
		CASE
			WHEN (MONTH(@BirthDate) > MONTH(@EndDate)) 
				OR (MONTH(@Birthdate) = MONTH(@EndDate) AND DAY(@BirthDate) > DAY(@EndDate)) THEN 1
			ELSE 0
		END

RETURN @Age
END