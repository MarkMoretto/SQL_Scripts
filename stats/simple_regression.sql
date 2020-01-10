-- Transact-SQL Linear Regression
-- X and y are a random set of normally-distributed numbers.  X -> {1, 10}, y -> {1, 50}

SET NOCOUNT ON

DROP TABLE IF EXISTS #_data
DROP TABLE IF EXISTS #_tmp
DROP TABLE IF EXISTS #_fin

-- Create and populate our data table
CREATE TABLE #_data (
	[index] INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
	[X] FLOAT,
	[y] FLOAT
)

DECLARE @_number_of_rows SMALLINT = 1000
,	@_index INT = 1
WHILE (@_index <= @_number_of_rows)
	BEGIN
		INSERT INTO #_data ([X], [y])
		SELECT CONVERT(FLOAT, (ABS(CHECKSUM(NEWID())) % 10) + 1) AS [X]
		, CONVERT(FLOAT, (ABS(CHECKSUM(NEWID())) % 50) + 1) AS [y]
		SET @_index += 1
	END
--SELECT * FROM #_data



CREATE TABLE #_fin (
	[X_mean] FLOAT,
	[y_mean] FLOAT,
	[X_sd] FLOAT,
	[y_sd] FLOAT,
	[corr] FLOAT,
	[N] INT
)


-- Calculate mean, standard deviation, correlation, etc.

;WITH counts AS (
	SELECT COUNT(*) AS [N] FROM #_data
)
, base_calcs AS (
	SELECT Y.*
	,	Y.[sum_X] / C.N AS [X_avg]
	,	Y.[sum_y] / C.N AS [y_avg]
	FROM (
		SELECT SUM(X.[X]) AS [sum_X]
		,	SUM(X.[y]) AS [sum_y]
		,	POWER(SUM(X.[X]), 2) AS [sum_X2]
		,	POWER(SUM(X.[y]), 2) AS [sum_y2]
		,	SUM(X.[X_y]) AS [sum_Xy]
		,	SUM(X.[X_X]) AS [sum_XX]
		,	SUM(X.[y_y]) AS [sum_yy]
		FROM (
			SELECT D.X, D.y
			, (D.X * D.y) AS [X_y]
			, (D.X * D.X) AS [X_X]
			, (D.y * D.y) AS [y_y]
			FROM #_data AS D
		) AS X
	) AS Y, counts AS C
)
, raw_data AS (
	SELECT DD.X, DD.y
	FROM #_data AS DD
)
, res AS (
	SELECT MA.X_avg AS [X_mean]
	,	MA.y_avg AS [y_mean]
	,	C.N
	,	ROUND((RD.X - MA.X_avg), 6) AS [X_dev]
	,	ROUND(POWER((RD.X - MA.X_avg), 2), 6) AS [X_sq_dev]
	,	ROUND((RD.y - MA.y_avg), 6) AS [y_dev]
	,	ROUND(POWER((RD.y - MA.y_avg), 2), 6) AS [y_sq_dev]
	,	POWER((X.ssx / C.N), 0.5) AS [X_sd_p]
	,	POWER((X.ssx / (C.N - 1)), 0.5) AS [X_sd_s]
	,	POWER((X.ssy / C.N), 0.5) AS [y_sd_p]
	,	POWER((X.ssy / (C.N - 1)), 0.5) AS [y_sd_s]
	,	(C.N * MA.sum_Xy) - (MA.sum_X * MA.sum_y) AS [corr_num]
	,	(SQRT(C.N * MA.sum_XX - MA.sum_X2) * SQRT(C.N * MA.sum_yy - MA.sum_y2)) AS [corr_denom]
	FROM (
		SELECT SUM(POWER((ABC.X - XYZ.X_avg), 2)) AS [ssx]
		,	SUM(POWER((ABC.y - XYZ.y_avg), 2)) AS [ssy]
		FROM raw_data AS ABC, base_calcs AS XYZ, counts AS C
	) AS X
	, raw_data AS RD, base_calcs AS MA, counts AS C
)
INSERT INTO #_fin ([X_mean], [y_mean], [X_sd], [y_sd], [corr], [N])
SELECT TOP 1 res.X_mean, res.y_mean, ROUND(res.X_sd_s, 4) AS [X_sd], ROUND(res.y_sd_s, 4) AS [y_sd], ROUND(res.[corr_num] / res.[corr_denom], 6) AS [corr], res.N
FROM res
--SELECT * FROM #_fin


-- Leverage: http://onlinestatbook.com/2/regression/influential.html
;WITH vars AS (
	SELECT X.b
	,	X.[y_mean] - (X.b * X.[X_mean]) AS [y_int]
	FROM (
		SELECT f.*
		,	f.[corr] * (f.[y_sd] / f.[x_sd]) AS [b]
		FROM #_fin AS f
	)AS X
)
, lev AS (
	SELECT X.X, (POWER(X.inner_h, 2) + 1) / X.N AS [h]
	FROM (
		SELECT D.X, F.N, (D.X - F.X_mean) / F.X_sd AS [inner_h]
		FROM #_fin AS F, #_data AS D
	) AS X

)
, res AS (
	SELECT D.X
	,	D.y
	,  (V.b * D.X) + V.y_int AS [pred_y]
	,	L.h
	FROM #_data AS D, vars AS V, lev AS L
	WHERE L.X = D.X
)
SELECT DISTINCT R.*
,	(R.y - R.pred_y) AS [y_residuals]
FROM res AS R
