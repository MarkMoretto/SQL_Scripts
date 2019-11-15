-- Print Prime Numbers up to 1000
-- Query is for MS SQL/Transact-SQL

SET NOCOUNT ON

DROP TABLE IF EXISTS #_primes
CREATE TABLE #_primes (
	[idx] INT IDENTITY(1,1) NOT NULL PRIMARY KEY
	,	[X] INT NOT NULL
	,	[prime_yn] BIT
)

-- Populate our table with an index and default values
DECLARE @_max_count INT = 1000 -- Max value to evaluate
,	@_N INT = 2 -- Start at two since we don't want to include 0 or 1
WHILE (@_N <= @_max_count)
	BEGIN
		INSERT INTO #_primes ([X], [prime_yn])
		SELECT @_N, 1 -- Default value is 1 for prime_yn; This will change as we evaluate each number
		SET @_N += 1 -- Increment our pacekeeper by 1
	END



DECLARE @_current INT = 2 -- Seed current value with 2 to start
,	@_prior INT = 0 -- 'Placeholder' to help increment the count
WHILE (@_current <= @_max_count)
	BEGIN
		-- Set prior variable to current variable
		SET @_prior = @_current

		-- Update prime_ym to zero if number does not pass test
		UPDATE QQ
		SET QQ.prime_yn = 0
		FROM (
			SELECT P.X
			,	P.prime_yn
			FROM #_primes AS P
			WHERE P.X % @_current = 0 -- If X % current == 0, then it does not pass test
			AND P.X > @_current -- X must be larger than current number given our iterative process
			AND P.prime_yn = 1 -- Only include X values that have not passed the test yet.
		) AS QQ
		BREAK

		SET @_current += 1 -- Update current number 

	END

----Uncomment to print results as a single string to the message area in SSMS
--DECLARE @_output NVARCHAR(MAX)
--SET @_output = (
--		SELECT STUFF(
--		(SELECT '&' + CAST(P.X AS VARCHAR(5))
--		FROM #_primes AS P
--		WHERE P.prime_yn = 1
--		FOR XML PATH (''), TYPE).value('.', 'varchar(max)')
--		, 1, 1, '')
--	)
--PRINT @_output


--Select results
SELECT X FROM #_primes WHERE prime_yn = 1
/*
Output: 
X
2
3
5
7
11
13
17
19
23
29
...
991
997
*/
