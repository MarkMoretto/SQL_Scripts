/* Calculate age of person */
/* This is a scalar function as it returns a single value */
/* Listed under Database -> Programmability -> Functions -> Scalar-valued Functions */

USE GeneralDataPRD;
GO

CREATE FUNCTION GetAge(@BirthDate DATE, @EndDate DATE)
RETURNS INT
AS
BEGIN

DECLARE @Age INT
--DECLARE @BirthDate DATE -- Now being set as a parameter
--DECLARE @EndDate DATE -- Now being set as a parameter

--SET @BirthDate = '01/01/1980' -- Now being set as a parameter
--SET @EndDate = GETDATE() -- Now being set as a parameter


SET @Age = DATEDIFF(yy, @BirthDate, @EndDate) - 
		CASE
			WHEN (MONTH(@BirthDate) > MONTH(@EndDate)) 
				OR (MONTH(@Birthdate) = MONTH(@EndDate) AND DAY(@BirthDate) > DAY(@EndDate)) THEN 1
			ELSE 0
		END

RETURN @Age
END