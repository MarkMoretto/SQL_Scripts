-- SQL confusion matrix sampler

-- Date: 2019-02-26
-- Contributor: Mark Moretto


SET NOCOUNT ON

---------------------------------------------------------------------------
-- Create a temp table with actual and predicated attributes
IF OBJECT_ID('tempdb.dbo.#_data') IS NOT NULL DROP TABLE #_data
CREATE TABLE #_data (
	[INDEX] INT IDENTITY(1,1) NOT NULL PRIMARY KEY
	,	[ACTUAL] FLOAT
	,	[PREDICTED] FLOAT
)


/**************************************************************************
Generate random numbers with a Laplace distribution

Basic formula
	X = a - b * sgn(urn) * ln(1 - (2 * urn))

where:
	urn = uniform random number
	a = alpha value
	b = beta value
	sgn = sign function (in SQL pseudocode):
		case
			when x > 0 then 1
			when x < 0 then -1
			else 0
		end

Ref: https://en.wikipedia.org/wiki/Laplace_distribution
*********************************************************************************/


DECLARE @_number_of_records INT = 1000 -- Number of sample records to generate
DECLARE @_count INT = 1 -- Initialize counter variable.
DECLARE @_urn_act FLOAT --Uniform random number variable (actual)
DECLARE @_urn_pred FLOAT --Uniform random number variable (predicted)
DECLARE @_alpha FLOAT = 0.6 -- Alpha value. (Usually works best 0 < a < 1)
DECLARE @_beta FLOAT = 1.0 -- Distribution width.

WHILE @_count <= @_number_of_records
BEGIN
	-- Keeping a single urn to work from might be better
	SET @_urn_act = ROUND(RAND(CHECKSUM(NEWID())) * (1), 4)
	SET @_urn_pred = ROUND(RAND(CHECKSUM(NEWID())) * (1), 4)
	INSERT INTO #_data
	SELECT CASE WHEN X.V_ACT > 0 THEN 1 ELSE 0 END AS [ACTUAL]
	,	CASE WHEN X.V_PRED > 0 THEN 1 ELSE 0 END AS [PREDICTED]
	FROM (
		SELECT (@_alpha - @_beta * LOG(1 - 2 * ABS(@_urn_act - 0.5)) * CASE WHEN 0 < @_urn_act - 0.5 THEN 1 WHEN 0 > @_urn_act - 0.5 THEN -1 ELSE 0 END) AS [V_ACT]
		, (@_alpha - @_beta * LOG(1 - 2 * ABS(@_urn_pred - 0.5)) * CASE WHEN 0 < @_urn_pred - 0.5 THEN 1 WHEN 0 > @_urn_pred - 0.5 THEN -1 ELSE 0 END) AS [V_PRED]
	) AS X
	SET @_count += 1 -- Add 1 to our counter.
END


/**********************************************************
Confusion matrix formulae:

			Predicted
		  Pos.	  Neg.
Actual	----------------
Pos.	|  TP	|  FN	|
		----------------
Neg.	|  FP	|  TN	|
		----------------

Accuracy -> Unbiased average of model results
		(TP + TN)
	------------------
	(TP + TN + FP + FN)


Recall -> How many positive examples were correctly recognized?
			TP
		---------	
		(TP + FN)


Precision -> How many positives are actually positive?
			TP
		----------	
		(TP + FP)


F-Measure -> Calculates harmonic mean
	  (2 * Recall * Precision)
	 -------------------------
		(Recall + Precision)

************************************************************/



-- #######################
-- ### Output method 1 ###
-- #######################
---------------------------------------------------------------------------
-- Tip 1: Subquery until desired results achieved!
-- Tip 2: Don't follow tip 1. We really only need 1 subquery here.  This is setup for illustrative purposes.

SELECT ROUND(Y.[ACC], 4) AS [Accuracy]
,	ROUND(Y.[RCLL], 4) AS [Recall]
,	ROUND(Y.[PRCSN], 4) AS [Precision]
,	ROUND(Y.F_MEAS, 4) AS [F_Measure]
FROM (
	SELECT [ACC] = (X.TP + X.TN) / (X.TP + X.TN + X.FP + X.FN)
	,	[RCLL] = (X.TP / (X.TP + X.FN))
	,	[PRCSN] = (X.TP / (X.TP + X.FP))
	,	[F_MEAS] = (2 * (X.TP / (X.TP + X.FN)) * (X.TP / (X.TP + X.FP))) / (X.TP / (X.TP + X.FN)) + (X.TP / (X.TP + X.FP))
	FROM (
		SELECT [TP] = CONVERT(FLOAT, SUM(CASE WHEN ACTUAL = '1' AND PREDICTED = '1' THEN 1 ELSE 0 END)) --True Positive (TP): Actual is 1, predicted is 1
		,	[TN] = CONVERT(FLOAT, SUM(CASE WHEN ACTUAL = '0' AND PREDICTED = '0' THEN 1 ELSE 0 END)) --True Negative (TN): Actual is 0, predicted is 0
		,	[FP] = CONVERT(FLOAT, SUM(CASE WHEN ACTUAL = '0' AND PREDICTED = '1' THEN 1 ELSE 0 END)) --False Positive (FP): Actual is 0, predicted is 1
		,	[FN] = CONVERT(FLOAT, SUM(CASE WHEN ACTUAL = '1' AND PREDICTED = '0' THEN 1 ELSE 0 END)) --False Negative (FN): Actual is 1, predicted is 0
		FROM #_data AS D
	) AS X
) AS Y



-- #######################
-- ### Output method 2 ###
-- #######################
---------------------------------------------------------------------------
-- Reformat data to an actual matrix and output calculated measures below that.

;WITH data_tbl AS (
	SELECT [TP] = CONVERT(FLOAT, SUM(CASE WHEN ACTUAL = '1' AND PREDICTED = '1' THEN 1 ELSE 0 END)) --True Positive (TP): Actual is 1, predicted is 1
	,	[TN] = CONVERT(FLOAT, SUM(CASE WHEN ACTUAL = '0' AND PREDICTED = '0' THEN 1 ELSE 0 END)) --True Negative (TN): Actual is 0, predicted is 0
	,	[FP] = CONVERT(FLOAT, SUM(CASE WHEN ACTUAL = '0' AND PREDICTED = '1' THEN 1 ELSE 0 END)) --False Positive (FP): Actual is 0, predicted is 1
	,	[FN] = CONVERT(FLOAT, SUM(CASE WHEN ACTUAL = '1' AND PREDICTED = '0' THEN 1 ELSE 0 END)) --False Negative (FN): Actual is 1, predicted is 0
	FROM #_data AS D
)
SELECT [''] = 'PREDICTED_P'
,	[ACTUAL_P] = X.TP
,	[ACTUAL_N] = X.FP
FROM data_tbl AS X
UNION ALL
SELECT [''] = 'PREDICATED_N'
,	[ACTUAL_P] = X.FN
,	[ACTUAL_N] = X.TN
FROM data_tbl AS X
UNION ALL
SELECT [''] = 'Accuracy'
,	[ACTUAL_P] = ROUND((X.TP + X.TN) / (X.TP + X.TN + X.FP + X.FN), 4)
,	[ACTUAL_N] = NULL
FROM data_tbl AS X
UNION ALL
SELECT [''] = 'Recall'
,	[ACTUAL_P] = ROUND(X.TP / (X.TP + X.FN), 4)
,	[ACTUAL_N] = NULL
FROM data_tbl AS X
UNION ALL
SELECT [''] = 'Precision'
,	[ACTUAL_P] = ROUND(X.TP / (X.TP + X.FP), 4)
,	[ACTUAL_N] = NULL
FROM data_tbl AS X
UNION ALL
SELECT [''] = 'F Measure'
,	[ACTUAL_P] = ROUND((2 * (X.TP / (X.TP + X.FN)) * (X.TP / (X.TP + X.FP))) / (X.TP / (X.TP + X.FN)) + (X.TP / (X.TP + X.FP)), 4)
,	[ACTUAL_N] = NULL
FROM data_tbl AS X



-- #######################
-- ### Output method 3 ###
-- #######################
------------------------------------------------------------------------------
-- We can also put each calculation to a variable result for further processing.

--True Positive (TP): Actual is 1, predicted is 1
DECLARE @_TP FLOAT = (
				SELECT SUM(X.VAL)
				FROM (
					SELECT
						CASE	
							WHEN ACTUAL = '1' AND PREDICTED = '1' THEN 1
							ELSE 0
						END AS [VAL]
					FROM #_data) AS X
					)

--True Negative (TN): Actual is 0, predicted is 0
DECLARE @_TN FLOAT = (
				SELECT SUM(X.VAL)
				FROM (
					SELECT
						CASE
							WHEN ACTUAL = '0' AND PREDICTED = '0' THEN 1
							ELSE 0
							END AS [VAL] 
						FROM #_data) AS X
					)

--False Positive (FP): Actual is 0, predicted is 1
DECLARE @_FP FLOAT = (
				SELECT SUM(X.VAL)
				FROM (
					SELECT
						CASE
							WHEN ACTUAL = '0' AND PREDICTED = '1' THEN 1
							ELSE 0
						END AS [VAL]
					FROM #_data) AS X
					)

--False Negative (FN): Actual is 1, predicted is 0
DECLARE @_FN FLOAT = (
				SELECT SUM(X.VAL)
				FROM (
					SELECT
						CASE
							WHEN ACTUAL = '1' AND PREDICTED = '0' THEN 1
							ELSE 0
						END AS [VAL]
					FROM #_data) AS X
					)

DECLARE @_accuracy FLOAT = (@_TP + @_TN) / (@_TP + @_TN + @_FP + @_FN)
DECLARE @_recall FLOAT = @_TP / (@_TP + @_FN)
DECLARE @_precision FLOAT = @_TP / (@_TP + @_FP)
DECLARE @_f_measure FLOAT = (2 * @_recall * @_precision) / (@_recall + @_precision)

SELECT @_TP, @_TN, @_FP, @_FN
, @_accuracy AS [ACCURACY]
, ROUND(@_recall, 4) AS [RECALL]
, ROUND(@_precision, 4) AS [PRECISION]
, ROUND(@_f_measure, 4) AS [F_MEAS]
