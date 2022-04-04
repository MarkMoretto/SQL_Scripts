/****** 
Expand old region table into region-state dimension table.
******/

USE Raytheon

SET NOCOUNT ON

/*** Drop temp table(s). ***/
DROP TABLE IF EXISTS #_tmp

DROP TABLE IF EXISTS #_region_state

/*** Split state abbreviations from region and insert into new temp. table. ***/
SELECT
	ROW_NUMBER() OVER(ORDER BY [idx]) - 1 AS [id]
,	RTRIM(SUBSTRING([label], 0, CHARINDEX('(', [label]))) AS [label]
,	RTRIM(
		SUBSTRING([label], CHARINDEX('(', [label]) + 1, LEN([label]) - CHARINDEX('(', [label]) - 1)
	) + ',' AS [states]
INTO #_tmp
FROM [CollegeApp].[region]
WHERE [idx] > 0


/*** Tokenize and load state abbreviations into temp table. ***/
DECLARE @_current_row NVARCHAR(MAX)
,	@_state_abbr NVARCHAR(MAX) = ''
,	@_max_len INT = 0
,	@_char_index INT = 1
,	@_token NCHAR(1)
,	@_row_number INT = 0
,	@_max_rows INT = (SELECT MAX([id]) FROM #_tmp)
,	@_region_label NVARCHAR(100) = ''

-- Declare table variable.
DECLARE @_tokens TABLE (
	[idx] INT IDENTITY(1,1) NOT NULL PRIMARY KEY CLUSTERED
	,	[region] NVARCHAR(100) NOT NULL
	,	[state_abbr] NCHAR(2)
)

WHILE (@_row_number <= @_max_rows)
	BEGIN
		-- Set region and current row variables.  Region will remain consistent for each 
		-- state abbreviation that is found.
		SET @_region_label = (SELECT [label] FROM #_tmp WHERE [id] = @_row_number)
		SET @_current_row =  (SELECT [states] FROM #_tmp WHERE [id] = @_row_number)
		SET @_max_len = (SELECT LEN(@_current_row))
		WHILE (@_char_index <= @_max_len)
			BEGIN
				-- Set a token value that is one character long.
				SET @_token = (SELECT SUBSTRING(@_current_row, @_char_index, 1))
				IF (PATINDEX('%[A-Z]%', @_token) = 1)
					BEGIN
						SET @_state_abbr += @_token
					END
				ELSE
					BEGIN
						IF ((@_token NOT LIKE '%[A-Z]%') AND (LEN(@_state_abbr) > '0'))
						INSERT INTO @_tokens
						SELECT
							CAST(@_region_label AS NVARCHAR(100)) AS [region]
						,	CAST(@_state_abbr AS NCHAR(2)) AS [state_abbr]
						SET @_state_abbr = ''
					END

				-- Advance character index by 1.
				SET @_char_index += 1
			END

			-- Advance row by 1 and reset char_index to 0.
			SET @_row_number += 1
			SET @_char_index = 0
	END

/*** Insert data from temp table into main table. ***/
SELECT 
	T.[idx]
,	T.[region]
,	T.[state_abbr]
INTO #_region_state
FROM @_tokens AS T
--WHERE LEN(T.[state_abbr]) > 0

/*** Add region_id field. ***/


/*** Create table and insert data into table. ***/
DROP TABLE IF EXISTS [CollegeApp].[region_state_dim]

CREATE TABLE [CollegeApp].[region_state_dim] (
	[ID] INT IDENTITY(1,1) NOT NULL PRIMARY KEY CLUSTERED
	,	[region_id] INT NOT NULL
	,	[region] NVARCHAR(100) NOT NULL
	,	[state_abbr] NCHAR(2) NOT NULL
)

INSERT [CollegeApp].[region_state_dim] ([region_id], [region], [state_abbr])
SELECT
	Q.region_id
,	RS.[region]
,	RS.[state_abbr] 
FROM #_region_state AS RS
INNER JOIN (
	/*** Calculate region_id field. ***/
	SELECT RS.[region]
	,	ROW_NUMBER() OVER(ORDER BY COUNT(1) DESC) AS [region_id]
	FROM CollegeApp.institution AS I
	INNER JOIN #_region_state AS RS ON RS.state_abbr = I.STABBR
	GROUP BY RS.[region]
) AS Q ON Q.region = RS.region

SET NOCOUNT OFF
