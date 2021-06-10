--*************************************************************************************************************************************************************************
-- RUN THIS QUERY ON WORKING DAY 2 FOR THE PERIOD BEING CLOSED
-- CS YEAR AND PERIOD ARE USED, EG. APRIL 2020 = YEAR 2021 AND PERIOD 1
-- MISUSERDATA TABLE CS_WORKDAY_GL_CONVERSION IS POPULATED FROM A SPREADSHEET AND MAY NEED TO BE UPDATED PERIODICALLY MAKING SURE TO MAINTAIN EXISTING TABLE STRUCTURE
--***************************************************************************************************************************************************************************

-- SET THE YEAR AND PERIOD BEING CLOSED BELOW

DECLARE @YEAR																										CHAR(4)
DECLARE @PERIOD																										CHAR(2)
SET @YEAR = '2021'
SET @PERIOD = '06'

USE MIS
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT
RIGHT(GLC.[Workday legal Entity],2)																					[HEADER KEY]
,ROW_NUMBER() OVER (ORDER BY (SELECT GLC.CS_ACCOUNT_CODE))															[LINE KEY]
,''																													[LINE ORDER]
,GLC.[Workday legal Entity]																							[LINE COMPANY]
,GLC.[Workday Nominal Code]																							[LEDGER ACCOUNT]
,'CHILD'																											[ACCOUNT SET]
,''																													[ALTERNATE LEDGER ACCOUNT]
,''																													[ACCOUNT SET]
,CASE
	WHEN SUM(COALESCE(FCPT.DEBIT_TOT_AMT,'0'))-SUM(COALESCE(FCPT.CREDIT_TOT_AMT,'0')) > '0' 
	THEN CAST(ABS(SUM(COALESCE(FCPT.DEBIT_TOT_AMT,'0'))-SUM(COALESCE(FCPT.CREDIT_TOT_AMT,'0'))) AS VARCHAR)
	ELSE '' END																										[DEBIT AMOUNT]
,CASE
	WHEN SUM(COALESCE(FCPT.DEBIT_TOT_AMT,'0'))-SUM(COALESCE(FCPT.CREDIT_TOT_AMT,'0')) < '0' 
	THEN CAST(ABS(SUM(COALESCE(FCPT.DEBIT_TOT_AMT,'0'))-SUM(COALESCE(FCPT.CREDIT_TOT_AMT,'0'))) AS VARCHAR)
	ELSE '' END																										[CREDIT AMOUNT]
,'GBP'																												[CURRENCY]
,''																													[CURRENCY RATE]
,''																													[LEDGER DEBIT AMOUNT]
,''																													[LEDGER CREDIT AMOUNT]
,''																													[QUANTITY]
,''																													[UNIT OF MEASURE]
,''																													[QUANTITY 2]
,''																													[UNIT OF MEASURE 2]
,CONCAT(
	(SELECT
	CONVERT(CHAR(4),MAX(END_DT),100) + CONVERT(CHAR(4),MAX(END_DT),120)
	FROM
	VCRO_ACCT_PERIOD
	WHERE
	YR_NUM = @YEAR
	AND PERD_NUM = @PERIOD)
	,' '
	,FC.DESCR
	)																												[MEMO]
,FC.GL_CODE																											[EXTERNAL REFERENCE ID]
,''																													[BUDGET DATE]
,''																													[CHANNEL]
,GLC.[Workday Cost Centre]																							[COST CENTRE]
,''																													[SUPPLIER]
,''																													[PRODUCT]
,GLC.[Workday Spend Category]																						[SPEND CATEGORY]
,''																													[CUSTOMER]
,GLC.[Workday Revenue Category]																						[REVENUE CATEGORY]
,''																													[METER TYPE]
,GLC.Utility																										[UTILITY]
,''																													[AFFILIATE]
,''																													[LOCATION]
,''																													[EXPENSE ITEM]
,'BR41'																												[BRAND]
,''																													[TEAM]
,''																													[PROJECT]
,''																													[TAX CODE]
,''																													[EMPLOYEE ID]
,''																													[BALANCING WORKTAG AFFILIATE]
,''																													[EXCLUDE FROM SPEND REPORT]
,''																													[TRANSACTION DATE]
,''																													[TAX TYPE]
,''																													[TAXABLE AMOUNT]
,''																													[TAX CODE]
,''																													[TAX RATE]
,''																													[TAX APPLICABILITY]
,''																													[TAX RECOVERABILITY]

FROM
VCRO_FC_PERIOD_TOT																									FCPT
LEFT OUTER JOIN
MISUserData.[UK\PB32946].CS_WORKDAY_GL_CONVERSION																	GLC
ON FCPT.DBID_FC_01 = GLC.CS_DBID_FC
INNER JOIN
VCRO_FIN_CODE																										FC
ON FCPT.DBID_FC_01 = FC.DBID

WHERE
FCPT.YR_NUM_ACPE_01 = @YEAR
AND FCPT.PERD_NUM_ACPE_01 = @PERIOD
AND FC.GL_CODE LIKE '% 90%1'

GROUP BY
GLC.[Workday legal Entity]
,GLC.[Workday Nominal Code]		
,FC.DESCR						
,FC.GL_CODE	
,GLC.[Workday Cost Centre]					
,GLC.[Workday Spend Category]	
,GLC.[Workday Revenue Category]	
,GLC.Utility					
,GLC.CS_ACCOUNT_CODE