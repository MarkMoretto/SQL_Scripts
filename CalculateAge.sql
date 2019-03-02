DECLARE @BirthDate DATE
DECLARE @EndDate DATE
DECLARE @Age INT

SET @BirthDate = '01/01/1980'
SET @EndDate = GETDATE()


SET @Age = DATEDIFF(yy, @BirthDate, @EndDate) - 
		CASE
			WHEN (MONTH(@BirthDate) > MONTH(@EndDate)) 
				OR (MONTH(@Birthdate) = MONTH(@EndDate) AND DAY(@BirthDate) > DAY(@EndDate)) THEN 1
			ELSE 0
		END

SELECT @Age