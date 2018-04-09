/*** Rough query that uses cursor function to transform all text into proper case ***/

SET NOCOUNT ON;

IF OBJECT_ID('tempdb..#tempName') IS NOT NULL
DROP TABLE #tempName;

IF OBJECT_ID('tempdb..#tempNameMain') IS NOT NULL
DROP TABLE #tempNameMain;

DECLARE @nameFull1 NVARCHAR(250); -- Variable for testing string
DECLARE @nameFull2 NVARCHAR(250); -- Variable for testing string
DECLARE @nameFull3 NVARCHAR(250); -- Variable for testing string
DECLARE @nameFull4 NVARCHAR(250); -- Variable for testing string
DECLARE @stuffToSkip NVARCHAR(50) = '%[^A-Z]%'; -- Omits anything besides alphabetic characters
DECLARE @nameSEP NVARCHAR(5) = '%[,]%'; -- Separator for splitting first and last names

/*** Strings (names) for testing ***/
/*** Change/Modify as needed ***/
SET @nameFull1 = 'PACHECO, ROSA DAVILA VON'; -- Prefix may or may not be in wrong location here
SET @nameFull2 = 'SMITH, TOM A'; -- Function handles single-letter middle initials
SET @nameFull3 = 'JOHNSON, STEVE ALLEN '; -- Function will trim down excess spacing from end of name
SET @nameFull4 = ' PENNYPINCHER,THADDEUS WINTHROP '; -- No additional space around comma; Extra space at beginning of last name, end of first name

/*** Create tester table ***/
CREATE TABLE #tempName(
	CUST_ID NVARCHAR(13) NOT NULL PRIMARY KEY,
	CUST_NAME NVARCHAR(250) NOT NULL,
);

/*** Insert data into tester table ***/
INSERT INTO #tempName (CUST_ID, CUST_NAME)
VALUES	(123456789, @nameFull1),
		(123456790, @nameFull2),
		(123456791, @nameFull3),
		(123456792, @nameFull4);

SELECT *
FROM #tempName
/*** Split and trim first and last names ***/
SELECT
TN.CUST_ID AS [MRN]
,	SUBSTRING(LTRIM(RTRIM(TN.CUST_NAME)), 1, PATINDEX(@nameSEP, LTRIM(RTRIM(TN.CUST_NAME))) - 1) AS [CUST_LAST_NAME] -- 
,	LTRIM(RIGHT(RTRIM(TN.CUST_NAME), LEN(RTRIM(TN.CUST_NAME)) - NULLIF(LTRIM(PATINDEX(@nameSEP, RTRIM(TN.CUST_NAME))), 1))) AS [CUST_FIRST_NAME]
INTO #tempNameMain
FROM #tempName AS TN


/*** Select all of tempNameMain into tempNameOut ***/
IF OBJECT_ID('tempdb..#tempNameOut') IS NOT NULL
DROP TABLE #tempNameOut;

CREATE TABLE #tempNameOut(
	HF_MRN NVARCHAR(13) NOT NULL PRIMARY KEY,
	LAST_NAME NVARCHAR(60) NOT NULL,
	FIRST_NAME NVARCHAR(50) NOT NULL
);


/*** Cursoring through rows and converting text to proper case ***/
DECLARE @specialChar NVARCHAR(10) -- whitespace
DECLARE @firstNameIdx INT -- Index of first name
DECLARE @lastNameIdx INT -- Index of first name
DECLARE @currCharFirst NCHAR(1) -- Current character first name
DECLARE @currCharLast NCHAR(1) -- Current character last name
DECLARE @firstFirstYN INT -- Flag for first letter of new name (binary)
DECLARE @firstLastYN INT -- Flag for first letter of new name (binary)
DECLARE @firstNameIn NVARCHAR(255) -- Input of first name from selected table
DECLARE @firstNameOut NVARCHAR(255) -- Output of first name from selected table
DECLARE @lastNameIn NVARCHAR(255); -- Input of last name from selected table
DECLARE @lastNameOut NVARCHAR(255);  -- Output of last name from selected table
DECLARE @outID NVARCHAR(13);
DECLARE @inID NVARCHAR(13);
DECLARE @outerLoop INT;
DECLARE @innerLoop INT;

SET @specialChar = '[' + CHAR(9) + CHAR(10) + CHAR(13) + CHAR(32) + CHAR(45) + CHAR(160) + ' ' + '-' + ']' -- List to check for hyphenation/whitespace

/*** Set cursor to  ***/
DECLARE outNameCUR CURSOR FOR 
SELECT CUST_ID FROM #tempName
OPEN outNameCUR
FETCH NEXT FROM outNameCUR
INTO @outID
SET @outerLoop = @@FETCH_STATUS

WHILE @outerLoop = 0
BEGIN
	SET @firstNameIdx = 1
	SET @lastNameIdx = 1
	SET @firstFirstYN = 1
	SET @firstLastYN = 1
	SET @firstNameOut = ''
	SET @lastNameOut = ''

	DECLARE inNameCUR CURSOR FOR 
	SELECT TN.MRN, TN.CUST_LAST_NAME, TN.CUST_FIRST_NAME FROM #tempNameMain AS TN 
	WHERE TN.MRN = @outID
	OPEN inNameCUR
	FETCH NEXT FROM inNameCUR
	INTO @inID, @lastNameIn, @firstNameIn
	SET @innerLoop = @@FETCH_STATUS

	WHILE @innerLoop = 0
	BEGIN
		WHILE @firstNameIdx <= LEN(@firstNameIn)
		BEGIN
			/*** Selects first character of first name; Ensures that it is uppercase ***/
			SET @currCharFirst = SUBSTRING(UPPER(@firstNameIn), @firstNameIdx, 1)

			/*** Check if on first character; If so, append that to empty first name string and set flag to zero ***/
			IF @firstFirstYN = 1
			BEGIN
				SET @firstNameOut = @firstNameOut + @currCharFirst -- Append first character to 
				SET @firstFirstYN = 0 -- Set flag to 0; No longer on first character
			END

			/*** Otherwise, join the rest of the characters in lowercase format ***/
			ELSE
			BEGIN
				SET @firstNameOut = @firstNameOut + LOWER(@currCharFirst)
			END

			/*** If the character is a white space, set first chracter flag to 1 ***/
			IF @currCharFirst LIKE @specialChar SET @firstFirstYN = 1

			/*** Iterate index by one ***/
			SET @firstNameIdx = @firstNameIdx + 1
		END

		/*** Using the same process on the last name ***/
		WHILE @lastNameIdx <= LEN(@lastNameIn)
		BEGIN
			SET @currCharLast = SUBSTRING(UPPER(@lastNameIn), @lastNameIdx, 1);
			IF @firstLastYN = 1
			BEGIN
				SET @lastNameOut = @lastNameOut + @currCharLast
				SET @firstLastYN = 0
			END;
			ELSE
			BEGIN
				SET @lastNameOut = @lastNameOut + LOWER(@currCharLast)
			END;
			IF @currCharLast LIKE @specialChar SET @firstLastYN = 1;
			SET @lastNameIdx = @lastNameIdx + 1;

		END

	FETCH NEXT FROM inNameCUR
	INTO @outID, @lastNameIn, @firstNameIn
	SET @innerLoop = @@FETCH_STATUS

	INSERT INTO #tempNameOut
	SELECT @inID
	,	@lastNameOut
	,	@firstNameOut
	END

	CLOSE inNameCUR
	DEALLOCATE inNameCUR

	FETCH NEXT FROM outNameCUR
	INTO @outID
	SET @outerLoop = @@FETCH_STATUS

END
/*** Close and clean up cursor ***/
CLOSE outNameCUR
DEALLOCATE outNameCUR


/*** Check results of function ***/
SELECT *
FROM #tempNameOut;