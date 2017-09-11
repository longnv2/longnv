--USE PVCOM
--GO
--DECLARE @DATE DATE
--SET @DATE = '20170601'
--EXEC PCD_FACTDEPOSIT @DATE
--EXEC PCD_FACTDEPOSITSUMMARY @DATE
--EXEC PCD_FACTLOAN @DATE
--EXEC PCD_FACTLOANSUMMARY @DATE


USE PVCOM
GO
DECLARE @START INT
DECLARE @END INT
DECLARE @START_DATE DATE

IF OBJECT_ID('tempdb..#TEMP_DATE') IS NOT NULL
	DROP TABLE #TEMP_DATE

CREATE TABLE #TEMP_DATE(
	  ID int IDENTITY(1,1) PRIMARY KEY
	, FULL_DATE DATE
)

INSERT INTO #TEMP_DATE(FULL_DATE)
SELECT FULL_DATE 
FROM DimCalendar 
WHERE FULL_DATE between '20170401' and '20170430' and FLAG = 1



IF OBJECT_ID('tempdb..#TEMP_DATA') IS NOT NULL
	DROP TABLE #TEMP_DATA

CREATE TABLE #TEMP_DATA(
			  COB_DATE DATE
			, CONTRACT_NO VARCHAR(16)
			, BRANCH_CODE VARCHAR(10)
			, APP VARCHAR(3)
			, SUB_SEGMENT NVARCHAR(30)
			, CIF INT
			, VALUE_DATE DATE
			, MATURITY_DATE DATE
			, LCY_BAL FLOAT
			, RENEWAL_DATE DATE
)

IF OBJECT_ID('tempdb..#TEMP_DATA_2') IS NOT NULL
	DROP TABLE #TEMP_DATA_2

CREATE TABLE #TEMP_DATA_2(
			  COB_DATE DATE
			, CONTRACT_NO VARCHAR(16)
			, BRANCH_CODE VARCHAR(10)
			, APP VARCHAR(3)
			, SUB_SEGMENT NVARCHAR(30)
			, CIF INT
			, VALUE_DATE DATE
			, MATURITY_DATE DATE
			, LCY_BAL FLOAT
			, RENEWAL_DATE DATE
)


SET @START = 1
SET @END = (SELECT MAX(ID) FROM #TEMP_DATE)

while (@START <= @END)
BEGIN
	SET @START_DATE = (SELECT FULL_DATE FROM #TEMP_DATE WHERE ID = @START)

		INSERT INTO #TEMP_DATA (
			 COB_DATE
			, CONTRACT_NO
			, BRANCH_CODE
			, APP
			, SUB_SEGMENT
			, CIF
			, VALUE_DATE
			, MATURITY_DATE
			, LCY_BAL
			, RENEWAL_DATE
		)
		SELECT COB_DATE
			, CONTRACT_NO
			, BRANCH_CODE
			, APP
			, SUB_SEGMENT
			, CIF
			, VALUE_DATE
			, MATURITY_DATE
			, LCY_BAL
			, RENEWAL_DATE
		FROM (
			SELECT FD.COB_DATE
				, FD.CONTRACT_NO
				, FD.BRANCH_CODE
				, FD.APP
				, FD.CIF
				, FD.SUB_SEGMENT
				, FD.VALUE_DATE
				, FD.MATURITY_DATE
				, FD.LCY_BAL
				, D.RENEWAL_DATE
				, ROW_NUMBER() OVER(PARTITION BY FD.CONTRACT_NO ORDER BY D.RENEWAL_DATE DESC) AS RN
			FROM FACTDEPOSIT AS FD
			LEFT JOIN 
				(
					SELECT ARRANGEMENT_ID
						, RENEWAL_DATE
						, VALUE_DATE
						, EFFECTIVE_FROM_DATETIME
						, EFFECTIVE_TO_DATETIME
					FROM STG_T24..F_AA_ACCOUNT_DETAILS
					WHERE EFFECTIVE_FROM_DATETIME <= @START_DATE AND ISNULL(EFFECTIVE_TO_DATETIME, '29990101') > @START_DATE
						--AND CURR = 'Y'
				) AS D
			ON FD.CONTRACT_NO = D.ARRANGEMENT_ID
			WHERE FD.COB_DATE = @START_DATE --AND '20170605'
				AND APP = 'CKH'
				--AND FD.VALUE_DATE = FD.COB_DATE
				AND REGION = 'HCM'
				AND SEGMENT = 'KHDN'
				AND FLAG IS NULL
				AND LCY_BAL <> 0
				--AND D.VALUE_DATE = FD.MATURITY_DATE
				--AND CONTRACT_NO = 'AA17048FJ2R1'
			) X
		WHERE RN = 1
		PRINT(@START_DATE)
	SET @START = @START + 1
	IF (@START > @END)
		BREAK
END



while (@START <= @END)
BEGIN
	SET @START_DATE = (SELECT FULL_DATE FROM #TEMP_DATE WHERE ID = @START)
	INSERT INTO #TEMP_DATA_2(
		COB_DATE
		, CONTRACT_NO
		, BRANCH_CODE
		, APP
		, CIF
		, VALUE_DATE
		, MATURITY_DATE
		, LCY_BAL
		, RENEWAL_DATE
	)

		SELECT T.COB_DATE
				, T.CONTRACT_NO
				, T.APP
				, T.BRANCH_CODE
				, T.CIF
				, T.VALUE_DATE
				, T.MATURITY_DATE
				, (T.LCY_BAL - X.LCY_BAL) AS LCY_BAL
				, T.RENEWAL_DATE
		FROM #TEMP_DATA T
		JOIN (
				SELECT *
				FROM #TEMP_DATA
				WHERE COB_DATE = DATEADD(DAY, -1, @START_DATE)
				AND RENEWAL_DATE = @START_DATE
			) AS X
		ON T.CONTRACT_NO = X.CONTRACT_NO
		WHERE T.COB_DATE = @START_DATE AND (T.LCY_BAL - X.LCY_BAL) <> 0

		PRINT(@START_DATE)
	SET @START = @START + 1
	IF (@START > @END)
		BREAK
END


SELECT * 
FROM #TEMP_DATA 
WHERE COB_DATE = VALUE_DATE AND SUB_SEGMENT NOT LIKE '%UPPER%' AND CIF = '10301107'

select * from STG_T24..F_AA_INTEREST_ACCRUALS where PROPERTY_NAME like 'AA171025VB2N%' order by DATA_DATETIME

SELECT * FROM STG_T24..F_AA_ACCOUNT_DETAILS WHERE ARRANGEMENT_ID = 'AA171025VB2N'

SELECT * FROM FactDeposit WHERE CONTRACT_NO = 'AA171025VB2N' ORDER BY COB_DATE


SELECT  * FROM STG_T24..F_ WHERE ARRANGEMENT_KEY LIKE 'AA171025VB2N%' ORDER BY DATA_DATETIME





SELECT * FROM #TEMP_DATA WHERE CONVERT(VARCHAR(6), RENEWAL_DATE, 112) LIKE '201706%'
ORDER BY CONTRACT_NO, COB_DATE

SELECT TOP 10 * FROM FactDeposit WHERE CONTRACT_NO = 'AA17114X3360'










SELECT * FROM #TEMP_DATA 
WHERE CONTRACT_NO = 'AA17114X3360'
ORDER BY COB_DATE


select * from #TEMP_DATA where CONTRACT_NO = 'AA171534SY1S' order by COB_DATE



SELECT * 
FROM FactDeposit WHERE CONTRACT_NO = 'AA17114X3360' 
	AND FLAG IS NULL
ORDER BY COB_DATE



SELECT * FROM STG_T24..F_AA_ARRANGEMENT WHERE ARRANGEMENT_ID = 'AA171534SY1S' ORDER BY DATA_DATETIME

select * from STG_T24..F_AA_ACCOUNT_DETAILS where ARRANGEMENT_ID = 'AA170481DNWK' ORDER BY RENEWAL_DATE

select * from FactDeposit where cob_date = '20170424' and CIF = '10301107' and APP = 'CKH' ORDER BY VALUE_DATE