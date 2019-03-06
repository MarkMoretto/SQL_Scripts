
USE AdventureWorks2016;
GO


IF OBJECT_ID('tempdb.dbo.#_emp_data') IS NOT NULL DROP TABLE #_emp_data
DECLARE @_end_dt AS DATE = CONVERT(DATE, DATEADD(MONTH, DATEDIFF(MONTH, -1, GETDATE()) -1, -1)) -- End of last month
SELECT VE.[BusinessEntityID]
,	VE.[FirstName]
,	VE.[LastName]
,	EMP.BirthDate
,	EMP.[Gender]
,	EMP.[MaritalStatus]
,	VE.[PhoneNumber]
,	VE.[PhoneNumberType]
,	VE.[AddressLine1] AS [Address]
,	VE.[City]
,	VE.[StateProvinceName] AS [State_Province]
,	VE.[PostalCode] AS [Zip]
,	VE.[CountryRegionName] AS [Country_Region]
,	EMP.[HireDate]
,	FORMAT(CONVERT(FLOAT, DATEDIFF(DAY, EMP.[HireDate], @_end_dt)) / 365.25, '#.00') AS [YRS_WITH_CO]
,	EMP.[JobTitle]
,	EMP.[OrganizationLevel]
,	EMP.[SalariedFlag]
,	EMP.[VacationHours]
,	EMP.[SickLeaveHours]
,	EMP.[CurrentFlag]
INTO #_emp_data
FROM HumanResources.vEmployee AS VE
INNER JOIN HumanResources.Employee AS EMP ON EMP.BusinessEntityID = VE.BusinessEntityID;
GO

--SELECT * FROM #_emp_data


/***
	Drop function if it exists
*/
IF (SELECT COUNT(*) FROM sys.all_objects WHERE type IN ('TF', 'FN') AND name LIKE 'udf_GetColumnValues') > '0' DROP FUNCTION dbo.udf_GetColumnValues;
GO


CREATE FUNCTION dbo.udf_GetColumnValues	(
	@table_name NVARCHAR(255)
)
RETURNS @_output_table TABLE (
	[OBJECT_ID] INT NOT NULL
	,	[COL_NAME] NVARCHAR(255)
	,	[DATA_TYPE] NVARCHAR(128)
	,	[MAX_LEN] SMALLINT
)
AS
BEGIN
	DECLARE @_schema_name NVARCHAR(255)
	DECLARE @_object_name NVARCHAR(255)

	IF CHARINDEX('.', @table_name) > '0'
		BEGIN
			SET @_schema_name = (SELECT CASE WHEN CHARINDEX('.', @table_name) > '0' THEN SUBSTRING(@table_name, 0, CHARINDEX('.', @table_name)) END)
			SET @_object_name = (SELECT CASE WHEN CHARINDEX('.', @table_name) > '0' THEN REVERSE(SUBSTRING(REVERSE(@table_name), 0, CHARINDEX('.', REVERSE(@table_name)))) END)
		END;
	ELSE
		BEGIN
			SET @_object_name = @table_name
		END;

	IF LEFT(@_object_name, 1) = '#'
		BEGIN
			WITH table_info AS (
				SELECT AC.object_id AS [OBJECT_ID]
				,	AC.name AS [COL_NAME]
				,	UPPER(T.name) AS [DATA_TYPE]
				,	T.max_length AS [MAX_LEN]
				FROM tempdb.sys.tables AS TBL
				INNER JOIN tempdb.sys.all_columns AS AC ON AC.object_id =TBL.object_id
				INNER JOIN tempdb.sys.types AS T ON T.system_type_id = AC.system_type_id
				WHERE LEFT(TBL.name, LEN(@_object_name)) = @_object_name
			)
			INSERT INTO @_output_table ([OBJECT_ID],[COL_NAME],[DATA_TYPE],[MAX_LEN])
			SELECT TI.[OBJECT_ID]
			,	TI.[COL_NAME]
			,	TI.[DATA_TYPE]
			,	TI.[MAX_LEN]
			FROM table_info AS TI
		END;

	IF (LEFT(@_object_name, 1) = 'v' OR LEFT(@_object_name, 2) = 'vw')
		BEGIN
			WITH table_info AS (
				SELECT AC.[object_id] AS [OBJECT_ID]
				,	AC.[name] AS [COL_NAME]
				,	UPPER(T.[name]) AS [DATA_TYPE]
				,	T.[max_length] AS [MAX_LEN]
				FROM sys.views AS VW
				INNER JOIN tempdb.sys.all_columns AS AC ON AC.object_id = VW.object_id
				INNER JOIN tempdb.sys.types AS T ON T.system_type_id = AC.system_type_id
				WHERE VW.[name] = @_object_name
			)
			INSERT INTO @_output_table ([OBJECT_ID],[COL_NAME],[DATA_TYPE],[MAX_LEN])
			SELECT TI.[OBJECT_ID]
			,	TI.[COL_NAME]
			,	TI.[DATA_TYPE]
			,	TI.[MAX_LEN]
			FROM table_info AS TI
		END;

	RETURN;

END;
GO


SELECT * FROM master.dbo.udf_ColumnCount('HumanResources.vEmployee');

IF OBJECT_ID ('tempdb.dbo.##_column_output') IS NOT NULL DROP TABLE ##_column_output
DECLARE @_table_name NVARCHAR(255) = '#_emp_data'
--SELECT * FROM master.dbo.udf_ColumnCount(@_table_name)
DECLARE @_sql NVARCHAR(MAX)
--PRINT 'SELECT * FROM dbo.udf_ColumnCount(''' + @_table_name + ''')'
SET @_sql = 'SELECT * INTO ##_column_output FROM master.dbo.udf_ColumnCount(''' + @_table_name + ''')'
EXEC(@_sql)

--SELECT * FROM ##_column_output





SELECT TOP 1000 *
FROM sys.views AS TBL


--SELECT AC.object_id, AC.name AS [COL_NAME], AC.column_id, UPPER(T.name) AS [TYPE_NAME], T.max_length AS [MAX_LEN]
SELECT AC.*
FROM sys.views AS TBL
INNER JOIN sys.all_columns AS AC ON AC.object_id =TBL.object_id
INNER JOIN sys.types AS T ON T.system_type_id = AC.system_type_id
WHERE TBL.name = 'vEmployee'


/***
Good for temp tables.

	SELECT AC.object_id, AC.name AS [COL_NAME], AC.column_id, UPPER(T.name) AS [TYPE_NAME], T.max_length AS [MAX_LEN]
	FROM tempdb.sys.tables AS TBL
	INNER JOIN tempdb.sys.all_columns AS AC ON AC.object_id =TBL.object_id
	INNER JOIN tempdb.sys.types AS T ON T.system_type_id = AC.system_type_id
	WHERE LEFT(TBL.name, LEN('#_emp_data')) = '#_emp_data'
*/