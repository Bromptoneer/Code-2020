--*************************************************************************************************************************************************************************
-- RUN THIS QUERY ON WORKING DAY 2 FOR THE PERIOD BEING CLOSED
-- CS YEAR AND PERIOD ARE USED, EG. APRIL 2020 = YEAR 2021 AND PERIOD 1
-- MISUSERDATA TABLE CS_WORKDAY_GL_CONVERSION IS POPULATED FROM A SPREADSHEET AND MAY NEED TO BE UPDATED PERIODICALLY MAKING SURE TO MAINTAIN EXISTING TABLE STRUCTURE
--***************************************************************************************************************************************************************************

-- SET THE YEAR AND PERIOD BEING CLOSED BELOW

DECLARE @YEAR																										CHAR(4)
DECLARE @PERIOD																										CHAR(2)
SET @YEAR = '2021'
SET @PERIOD = '07'

-- DROP THE TEMP TABLE IF IT ALREADY EXISTS
USE tempdb
IF EXISTS (SELECT * FROM SYS.OBJECTS WHERE OBJECT_ID = OBJECT_ID ('#EXTRACT') AND TYPE = 'U') DROP TABLE #EXTRACT

USE MIS
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

CREATE TABLE #EXTRACT (
[HEADER KEY]																										INT
,[LINE KEY]																											INT
,[LINE ORDER]																										VARCHAR
,[LINE COMPANY]																										NVARCHAR(255)
,[LEDGER ACCOUNT]																									NVARCHAR(255)
,[ACCOUNT SET]																										CHAR(5)
,[ALTERNATE LEDGER ACCOUNT]																							NVARCHAR
,[ALT ACCOUNT SET]																									NVARCHAR
,[DEBIT AMOUNT]																										DECIMAL(12,2)
,[CREDIT AMOUNT]																									DECIMAL(12,2)
,[CURRENCY]																											CHAR(3)
,[CURRENCY RATE]																									NVARCHAR
,[LEDGER DEBIT AMOUNT]																								NVARCHAR
,[LEDGER CREDIT AMOUNT]																								NVARCHAR
,[QUANTITY]																											NVARCHAR
,[UNIT OF MEASURE]																									NVARCHAR
,[QUANTITY 2]																										NVARCHAR
,[UNIT OF MEASURE 2]																								NVARCHAR
,[MEMO]																												NVARCHAR(255)
,[EXTERNAL REFERENCE ID]																							VARCHAR(33)
,[BUDGET DATE]																										NVARCHAR
,[CHANNEL]																											NVARCHAR
,[COST CENTRE]																										NVARCHAR(255)
,[SUPPLIER]																											NVARCHAR
,[PRODUCT]																											NVARCHAR
,[SPEND CATEGORY]																									NVARCHAR(255)
,[CUSTOMER]																											NVARCHAR
,[REVENUE CATEGORY]																									NVARCHAR(255)
,[METER TYPE]																										NVARCHAR
,[UTILITY]																											NVARCHAR(255)
,[AFFILIATE]																										NVARCHAR
,[LOCATION]																											NVARCHAR
,[EXPENSE ITEM]																										NVARCHAR
,[BRAND]																											CHAR(4)
,[TEAM]																												NVARCHAR
,[PROJECT]																											NVARCHAR
,[TAX CODE]																											NVARCHAR
,[EMPLOYEE ID]																										NVARCHAR
,[BALANCING WORKTAG AFFILIATE]																						NVARCHAR
,[EXCLUDE FROM SPEND REPORT]																						NVARCHAR
,[TL TRANSACTION DATE]																								DATETIME
,[TL TAX TYPE]																										CHAR(13)
,[TL TAXABLE AMOUNT]																								DECIMAL(12,2)
,[TL TAX CODE]																										CHAR(6)
,[TL TAX RATE]																										CHAR(12)
,[TL TAX APPLICABILITY]																								CHAR(10)
,[TL TAX RECOVERABILITY]																							CHAR(17)
)

INSERT INTO #EXTRACT (
[HEADER KEY]					
,[LINE KEY]						
,[LINE COMPANY]					
,[LEDGER ACCOUNT]				
,[ACCOUNT SET]					
,[DEBIT AMOUNT]					
,[CREDIT AMOUNT]				
,[CURRENCY]						
,[MEMO]							
,[EXTERNAL REFERENCE ID]		
,[COST CENTRE]					
,[SPEND CATEGORY]				
,[REVENUE CATEGORY]				
,[UTILITY]						
,[BRAND]
,[TL TRANSACTION DATE]
,[TL TAX TYPE]
,[TL TAX CODE]
,[TL TAX RATE]
,[TL TAX APPLICABILITY]
,[TL TAX RECOVERABILITY]
)

SELECT
RIGHT(GLC.[Workday legal Entity],2)
,ROW_NUMBER() OVER (ORDER BY (SELECT GLC.CS_ACCOUNT_CODE))															
,GLC.[Workday legal Entity]																							
,GLC.[Workday Nominal Code]																							
,'CHILD'																											
,CASE
	WHEN SUM(COALESCE(FCPT.DEBIT_TOT_AMT,'0'))-SUM(COALESCE(FCPT.CREDIT_TOT_AMT,'0')) > '0' 
	THEN ABS(SUM(COALESCE(FCPT.DEBIT_TOT_AMT,'0'))-SUM(COALESCE(FCPT.CREDIT_TOT_AMT,'0')))
	ELSE '0' END																									
,CASE
	WHEN SUM(COALESCE(FCPT.DEBIT_TOT_AMT,'0'))-SUM(COALESCE(FCPT.CREDIT_TOT_AMT,'0')) < '0' 
	THEN ABS(SUM(COALESCE(FCPT.DEBIT_TOT_AMT,'0'))-SUM(COALESCE(FCPT.CREDIT_TOT_AMT,'0')))
	ELSE '0' END																									
,'GBP'																												
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
	)																												
,FC.GL_CODE																											
,GLC.[Workday Cost Centre]																							
,GLC.[Workday Spend Category]																						
,GLC.[Workday Revenue Category]																						
,GLC.Utility																										
,'BR41'																												
,CASE
	WHEN FC.VAT_CODE_IND = 'Y' AND FC.GL_CODE LIKE '1571%' THEN (
																SELECT MAX(END_DT)
																FROM
																VCRO_ACCT_PERIOD
																WHERE
																YR_NUM = @YEAR
																AND PERD_NUM = @PERIOD
																)
	ELSE NULL END																										
,CASE
	WHEN FC.VAT_CODE_IND = 'Y' AND FC.GL_CODE LIKE '1571%' THEN 'TAX_COLLECTED'
	ELSE ''	END																																																						
,CASE
	WHEN FC.VAT_CODE_IND = 'Y' AND FC.GL_CODE LIKE '1571%' THEN 'GBR_5%'
	ELSE ''	END																										
,CASE
	WHEN FC.VAT_CODE_IND = 'Y' AND FC.GL_CODE LIKE '1571%' THEN 'TAX_RATE-6-3'
	ELSE ''	END																										
,CASE
	WHEN FC.VAT_CODE_IND = 'Y' AND FC.GL_CODE LIKE '1571%' THEN 'OUTPUT_VAT'
	ELSE ''	END																										
,CASE
	WHEN FC.VAT_CODE_IND = 'Y' AND FC.GL_CODE LIKE '1571%' THEN 'FULLY RECOVERABLE'
	ELSE ''	END																										

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
,FC.VAT_CODE_IND

UPDATE #EXTRACT
SET #EXTRACT.[TL TAXABLE AMOUNT] = TEMP.AMT
FROM (
SELECT
[EXTERNAL REFERENCE ID]
,([DEBIT AMOUNT] - [CREDIT AMOUNT])*-20	AMT
FROM
#EXTRACT
WHERE
[TL TRANSACTION DATE] IS NOT NULL
) TEMP
WHERE
#EXTRACT.[EXTERNAL REFERENCE ID] = TEMP.[EXTERNAL REFERENCE ID]


SELECT
[HEADER KEY]																										[HEADER KEY]					
,[LINE KEY]																											[LINE KEY]											
,ISNULL([LINE ORDER],'')																							[LINE ORDER]										
,[LINE COMPANY]																										[LINE COMPANY]					
,[LEDGER ACCOUNT]																									[LEDGER ACCOUNT]				
,[ACCOUNT SET]																										[ACCOUNT SET]					
,ISNULL([ALTERNATE LEDGER ACCOUNT],'')																				[ALTERNATE LEDGER ACCOUNT]		
,ISNULL([ALT ACCOUNT SET],'')																						[ALT ACCOUNT SET]				
,CASE
		WHEN [DEBIT AMOUNT] <> '0' THEN CAST([DEBIT AMOUNT] AS VARCHAR)
		ELSE '' END																									[DEBIT AMOUNT]					
,CASE
		WHEN [CREDIT AMOUNT] <> '0' THEN CAST([CREDIT AMOUNT] AS VARCHAR)
		ELSE '' END																									[CREDIT AMOUNT]				
,[CURRENCY]																											[CURRENCY]						
,ISNULL([CURRENCY RATE],'')																							[CURRENCY RATE]				
,ISNULL([LEDGER DEBIT AMOUNT],'')																					[LEDGER DEBIT AMOUNT]			
,ISNULL([LEDGER CREDIT AMOUNT],'')																					[LEDGER CREDIT AMOUNT]			
,ISNULL([QUANTITY],'')																								[QUANTITY]						
,ISNULL([UNIT OF MEASURE],'')																						[UNIT OF MEASURE]				
,ISNULL([QUANTITY 2],'')																							[QUANTITY 2]					
,ISNULL([UNIT OF MEASURE 2]	,'')																					[UNIT OF MEASURE 2]			
,[MEMO]																												[MEMO]							
,[EXTERNAL REFERENCE ID]																							[EXTERNAL REFERENCE ID]		
,ISNULL([BUDGET DATE],'')																							[BUDGET DATE]					
,ISNULL([CHANNEL],'')																								[CHANNEL]						
,[COST CENTRE]																										[COST CENTRE]					
,ISNULL([SUPPLIER],'')																								[SUPPLIER]						
,ISNULL([PRODUCT],'')																								[PRODUCT]						
,[SPEND CATEGORY]																									[SPEND CATEGORY]				
,ISNULL([CUSTOMER],'')																								[CUSTOMER]						
,[REVENUE CATEGORY]																									[REVENUE CATEGORY]				
,ISNULL([METER TYPE],'')																							[METER TYPE]					
,[UTILITY]																											[UTILITY]						
,ISNULL([AFFILIATE],'')																								[AFFILIATE]					
,ISNULL([LOCATION],'')																								[LOCATION]						
,ISNULL([EXPENSE ITEM],'')																							[EXPENSE ITEM]					
,[BRAND]																											[BRAND]						
,ISNULL([TEAM],'')																									[TEAM]							
,ISNULL([PROJECT],'')																								[PROJECT]						
,ISNULL([TAX CODE],'')																								[TAX CODE]						
,ISNULL([EMPLOYEE ID],'')																							[EMPLOYEE ID]					
,ISNULL([BALANCING WORKTAG AFFILIATE],'')																			[BALANCING WORKTAG AFFILIATE]	
,ISNULL([EXCLUDE FROM SPEND REPORT],'')																				[EXCLUDE FROM SPEND REPORT]	
,CASE 
	WHEN [TL TRANSACTION DATE] > '1900-01-01' THEN CONVERT(VARCHAR(10),[TL TRANSACTION DATE],120)
	ELSE '' END																										[TL TRANSACTION DATE]			
,ISNULL([TL TAX TYPE],'')																							[TL TAX TYPE]					
,CASE 
	WHEN [TL TAXABLE AMOUNT] <> '0' THEN CAST([TL TAXABLE AMOUNT] AS VARCHAR)
	ELSE '' END																										[TL TAXABLE AMOUNT]			
,ISNULL([TL TAX CODE],'')																							[TL TAX CODE]					
,ISNULL([TL TAX RATE],'')																							[TL TAX RATE]					
,ISNULL([TL TAX APPLICABILITY],'')																					[TL TAX APPLICABILITY]			
,ISNULL([TL TAX RECOVERABILITY],'')																					[TL TAX RECOVERABILITY]		

FROM
#EXTRACT

WHERE
[DEBIT AMOUNT] <> '0'
OR [CREDIT AMOUNT] <> '0'