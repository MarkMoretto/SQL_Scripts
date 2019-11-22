
USE CLARITY

-- Main unsolved table
DROP TABLE IF EXISTS #_sudoku_grid
CREATE TABLE #_sudoku_grid (
	[idx] SMALLINT IDENTITY(1,1) NOT NULL PRIMARY KEY
	,	[1] SMALLINT, [2] SMALLINT, [3] SMALLINT
	,	[4] SMALLINT, [5]SMALLINT, [6] SMALLINT
	,	[7] SMALLINT, [8]SMALLINT, [9] SMALLINT
)
-- Populate rest of grid
INSERT INTO #_sudoku_grid
VALUES
(2,9,5,7,0,0,8,6,0),
(0,3,1,8,6,5,0,2,0),
(8,0,6,0,0,0,0,0,0),
(0,0,7,0,5,0,0,0,6),
(0,0,0,3,8,7,0,0,0),
(5,0,0,0,1,6,7,0,0),
(0,0,0,5,0,0,1,0,9),
(0,2,0,6,0,0,3,5,0),
(0,5,4,0,0,8,6,7,2)
--SELECT * FROM #_sudoku_grid


-- Tuple of numbers 1 - 9
DROP TABLE IF EXISTS #_number_tuple
CREATE TABLE #_number_tuple (
	[idx] SMALLINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
	[IS_EMPTY] BIT
)
INSERT INTO #_number_tuple
SELECT 1 AS [IS_EMPTY]
FROM #_sudoku_grid
WHERE idx > 0
--SELECT * FROM #_number_tuple
--SELECT SUM(idx) FROM #_number_tuple

-- Create temp table to hold pivoted row, column, and cell data
DROP TABLE IF EXISTS #_pivot_grid_base
CREATE TABLE #_pivot_grid_base ([r] SMALLINT, [c] SMALLINT, [cell] SMALLINT)


DECLARE @_r SMALLINT = 1 -- Row (outer)
,	@_ri SMALLINT = 1 -- Row (inner)
,	@_c SMALLINT = 1 -- Col (outer)
,	@_ci SMALLINT = 1 -- Col (inner)
,	@_lg_grid_max SMALLINT = 9 -- Max rows/columns of main grid
,	@_sm_grid_max SMALLINT = 3 -- Max rows/columns of 3x3 grid
DECLARE @_sql VARCHAR(2000)
WHILE (@_r <= @_lg_grid_max)
	BEGIN
		SET @_c = 1 -- `Reset` @_c to 1 for each row in the grid
		WHILE (@_c <= @_lg_grid_max)
			BEGIN
				SET @_sql = 'SELECT ' + CAST(@_r AS NCHAR(1)) + ' AS [r],'	-- Current row
				SET @_sql += CHAR(32) + CAST(@_c AS NCHAR(1)) + ' AS [c],'	-- Current column
				SET @_sql += CHAR(32) + 'X.[' + CAST(@_c AS NCHAR(1)) + ']' -- Current cell value
				SET @_sql += CHAR(32) + 'FROM #_sudoku_grid AS X'			-- Main table
				SET @_sql += CHAR(32) + 'WHERE X.[idx] = ' + CAST(@_r AS NCHAR(1)) -- WHERE constraint for each row
				INSERT INTO #_pivot_grid_base
				EXEC(@_sql)
				SET @_c += 1
			END
		SET @_r += 1
	END

--SELECT * FROM #_pivot_grid_base
--SELECT * FROM #_sudoku_grid
--SELECT [r], SUM([c]) AS [tot_col], SUM([cell]) AS [tot_cell] FROM #_pivot_grid_base GROUP BY [r]


/***************************************************************************
	Create temp table with both 3x3 subgrids and the complete grid marked off
	for each row-column combination
***************************************************************************/
DROP TABLE IF EXISTS #_pivot_grid_full
SELECT Y.[r], Y.[c]
,	[r_3] = Y.rn_r_mod_3
,	[c_3] = ROW_NUMBER() OVER(PARTITION BY Y.[rn_r_mod_3] ORDER BY Y.[r], Y.[c])
,	[cell] = Y.cell
INTO #_pivot_grid_full
FROM (
	SELECT X.*
	,	ROW_NUMBER() OVER(PARTITION BY X.[r_mod_3], X.[c_mod_3] ORDER BY X.[r], X.[c]) AS [rn_r_mod_3]
	FROM (
		SELECT Q.* 
		,	Q.[r] % 3 AS [r_mod_3]
		,	Q.[c] % 3 AS [c_mod_3]
		FROM #_pivot_grid_base AS Q
	) AS X
) AS Y
--SELECT * FROM #_pivot_grid_full ORDER BY r, c

SELECT r,  SUM(cell) FROM #_pivot_grid_full GROUP BY r ORDER BY r
SELECT c,  SUM(cell) FROM #_pivot_grid_full GROUP BY c ORDER BY c
SELECT r_3, SUM(cell) FROM #_pivot_grid_full GROUP BY r_3 ORDER BY r_3


-- Set IS_EMPTY to zero if cell is not empty
UPDATE QQ
SET QQ.[IS_EMPTY] = 0
FROM (
	SELECT P.[c], P.[cell], NT.[IS_EMPTY]
	FROM #_pivot_grid_lg AS P
	INNER JOIN #_number_tuple AS NT ON NT.idx = P.c
	WHERE P.r = 1
	AND P.cell > 0
) AS QQ

--SELECT * FROM #_number_tuple -- Check output of update
--SELECT P.[c], P.[cell], NT.[IS_EMPTY] FROM #_pivoted AS P INNER JOIN #_number_tuple AS NT ON NT.idx = P.c WHERE P.r = 1 -- Affirm update
DROP TABLE IF EXISTS #_available
SELECT [idx] INTO #_available FROM #_number_tuple WHERE IS_EMPTY = 1
--SELECT * FROM #_available -- Check available values



/*
WHILE (@_r <= @_lg_grid_max)
	BEGIN
		--SET @_cell = (SELECT * FROM #_sudoku_grid AS X WHERE X.[idx] = r)
		SET @_col_vals = (
				SELECT STUFF((
					SELECT ',' + T1.[EXCEPT_SRCE]
					FROM #_sudoku_grid AS S
					WHERE S.[idx] = @_r
					FOR XML PATH (''), TYPE).value('.', 'NVARCHAR(MAX)')
					, 1, 1, '')
				)
	END
*/












/*
SELECT pvt.[Doctor], pvt.[Professor], pvt.[Singer], pvt.[Actor]
FROM (
	SELECT SG.[1],SG.[2],SG.[3],SG.[4],SG.[5],SG.[6],SG.[7],SG.[8],SG.[9]
	FROM #_sudoku_grid AS SG
) AS p
PIVOT (
	MAX([Name]) FOR [Occupation] IN ([Doctor], [Professor], [Singer], [Actor])
) as pvt
GROUP BY pvt.person_id, [Doctor], [Professor], [Singer], [Actor]
*/