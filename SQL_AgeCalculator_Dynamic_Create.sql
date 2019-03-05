
/***
	Topic: Create a age calculator SQL function
	Date created: 2019-03-02

	Parameters:
		@_Start_Date (date): Start date for processing. Can be singular value or table attribute.
			Default: 1983-01-01
		@_End_Date (date): End date for processing. Can be singular value or table attribute.
			Default: Current date
*/

USE SchoolAnalytics;
GO

/***
	Substitute @function_name value with desired name for function.
	Schema will be the current schema being used
*/
DECLARE @function_name NVARCHAR(255) = 'udf_CalculateAge'

DECLARE @_sql_str NVARCHAR(MAX)
SET @_sql_str =  'IF OBJECT_ID(N''' + QUOTENAME(SCHEMA_NAME()) + '.' + QUOTENAME(@function_name) + ''', N''FN'') IS NOT NULL'
SET @_sql_str += ' ' + 'DROP FUNCTION ' + QUOTENAME(SCHEMA_NAME()) + '.' + QUOTENAME(@function_name)
EXEC(@_sql_str);
GO

DECLARE @_function_str NVARCHAR(MAX)
SET @_function_str = N'CREATE FUNCTION ' + QUOTENAME(SCHEMA_NAME()) + '.' + QUOTENAME(@function_name) + ' (@_Start_Date DATE, @_End_Date DATE)
	RETURNS NVARCHAR(255)
	AS
	BEGIN
		DECLARE @_result NVARCHAR(255)

		IF @_Start_Date IS NULL
			SET @_Start_Date = ''1983-01-01''

		IF @_End_Date IS NULL
			SET @_End_Date = CONVERT(DATE, GETDATE())


		SET @_result = (
			SELECT DATEDIFF(YEAR, @_Start_Date, @_End_Date) -
				CASE
					WHEN (MONTH(@_Start_Date) > MONTH(@_End_Date)) OR (MONTH(@_Start_Date) = MONTH(@_End_Date) AND DAY(@_Start_Date) > DAY(@_End_Date)) THEN 1
					ELSE 0
				END)

		RETURN @_result
	END
'
EXEC(@_sql_str);
GO
