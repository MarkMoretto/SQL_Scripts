/******************************************************************************************************
Purpose: Convert decimal to hexidecimal
Date created: 2020-04-13
Contributor: Mark Moretto

Description:
	This is a scalar function for converting decimal numbers into hexidecimal values.
	For example, 4253 in hexidecimal should be 109D.

Variables:
	@_n (INT/BIGINT) - The decimal value to convert.  This function does not handle floating-point
					values at this time.
	@_verbose (NVARCHAR) - Option to output more information about the process and a 'fancier' pintout
					to the messages section.
******************************************************************************************************/


/******************************************************************************************************
Example 1:
	SELECT EDWUsersDB.MMorett1.DecToHex(4253) --> 109D

Example 2:
	USE tempdb;
	GO

	DROP TABLE IF EXISTS #_tmp
	CREATE TABLE #_tmp ([n] INT IDENTITY(149,1), [values] varchar(10));
	GO 

	INSERT #_tmp([values]) 
	SELECT TOP 20 NULL AS [values]
	FROM master..sysobjects a CROSS JOIN master..sysobjects b

	SELECT EDWUsersDB.MMorett1.DecToHex(T.n)
	FROM #_tmp AS T
******************************************************************************************************/


USE master;
GO


DROP FUNCTION IF EXISTS dbo.DecToHex;
GO

CREATE FUNCTION dbo.DecToHex (@_decimal_number INT)
RETURNS VARCHAR(255)
AS
BEGIN

	-- Declare temp table to hold interim hex results
	DECLARE @_hex_out TABLE (
		[idx] SMALLINT IDENTITY(1,1) NOT NULL PRIMARY KEY
		,	[hex_char] VARCHAR(5)
		)

	DECLARE	@_remainder INT
	,	@_base INT = 16
	,	@_quotient DECIMAL(18, 10)
	,	@_numer DECIMAL(18, 10)
	,	@_mantissa DECIMAL(18, 10)
	,	@_dividend INT = @_decimal_number
	,	@_running BIT = 1

	WHILE (@_running > 0)
		BEGIN
			WHILE (@_dividend >= @_base)
				BEGIN
					SET @_quotient = CONVERT(INT, CAST(@_dividend AS DECIMAL(18,10)) / @_base)
					SET @_remainder = CONVERT(INT, @_dividend - (@_quotient * @_base))

					INSERT @_hex_out ([hex_char])
					SELECT
						CASE
							WHEN @_remainder < 10 THEN CONVERT(VARCHAR(5), @_remainder)
							WHEN @_remainder = '10' THEN 'A'
							WHEN @_remainder = '11' THEN 'B'
							WHEN @_remainder = '12' THEN 'C'
							WHEN @_remainder = '13' THEN 'D'
							WHEN @_remainder = '14' THEN 'E'
							--WHEN @_remainder = '15' THEN 'F'
							ELSE 'F'
						END

					SET @_dividend = @_quotient
				END

			--INSERT @_hex_out SELECT CONVERT(VARCHAR(5), @_dividend)
			INSERT @_hex_out ([hex_char])
			SELECT
				CASE
					WHEN @_dividend < 10 THEN CONVERT(VARCHAR(5), @_dividend)
					WHEN @_dividend = '10' THEN 'A'
					WHEN @_dividend = '11' THEN 'B'
					WHEN @_dividend = '12' THEN 'C'
					WHEN @_dividend = '13' THEN 'D'
					WHEN @_dividend = '14' THEN 'E'
					--WHEN @_remainder = '15' THEN 'F'
					ELSE 'F'
				END

			SET @_running -= 1
		END


	DECLARE @_hexadecimal NVARCHAR(255)
	SET @_hexadecimal = (
			SELECT STUFF((
				SELECT '' + X.hex_char
				FROM @_hex_out AS X
				ORDER BY X.idx DESC
				FOR XML PATH (''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 0, '')
			)

	RETURN @_hexadecimal
END;
GO
