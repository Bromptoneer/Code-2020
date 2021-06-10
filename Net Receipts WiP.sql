--------------------------------------------------------------------------------------------------------
-- NET RECEIPTS BALANCES BY BUSINESS	
--------------------------------------------------------------------------------------------------------
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
USE MIS
--------------------------------------------------------------------------------------------------------
-- SET THE YEAR AND THE PERIOD
--------------------------------------------------------------------------------------------------------
DECLARE @YEAR CHAR(4)
DECLARE @PERIOD SMALLINT

SET @YEAR = '2020'
SET @PERIOD = '12'
--------------------------------------------------------------------------------------------------------
-- COLLECT ALL FCPT BALANCES ON NET RECEIPTS CODES
--------------------------------------------------------------------------------------------------------
SELECT						
FCPT.YR_NUM_ACPE_01						
,FCPT.PERD_NUM_ACPE_01						
,FCPT.SEQ_NUM_01							
,RIGHT(LTRIM(RTRIM(FC.GL_CODE)),4)									BSV
,LTRIM(RTRIM(FC.GL_CODE))											GL_CODE
,COALESCE(SUM(DEBIT_TOT_AMT),0)										SUM_OF_DEBIT_BALANCES
,COALESCE(SUM(CREDIT_TOT_AMT),0)									SUM_OF_CREDIT_BALANCES
,COALESCE(SUM(DEBIT_TOT_AMT),0)-COALESCE(SUM(CREDIT_TOT_AMT),0)		NET_BALANCE
						
FROM						
VCRO_FC_PERIOD_TOT													FCPT
INNER JOIN						
VCRO_FIN_CODE														FC
ON FCPT.DBID_FC_01 = FC.DBID						
						
WHERE						
FC.GL_CD_CATGRY = 'NRA'						
AND FCPT.YR_NUM_ACPE_01 = @YEAR
AND FCPT.PERD_NUM_ACPE_01 = @PERIOD		
						
GROUP BY						
FCPT.YR_NUM_ACPE_01						
,FCPT.PERD_NUM_ACPE_01						
,FCPT.SEQ_NUM_01						
,LTRIM(RTRIM(FC.GL_CODE))						
						
ORDER BY						
FCPT.YR_NUM_ACPE_01						
,FCPT.PERD_NUM_ACPE_01						
,FCPT.SEQ_NUM_01						

RAISERROR('COMPLETED FCPT',0,1) WITH NOWAIT
--------------------------------------------------------------------------------------------------------
-- GET ALL FINANCIAL TRANSACTIONS WITH A NET RECEIPTS ENTRY
--------------------------------------------------------------------------------------------------------
SELECT
FT.YR_NUM_ACPE_01
,FT.PERD_NUM_ACPE_01
,FT.SEQ_NUM_FCPT_01
,FAT.DESCR															FAT
,COALESCE(FAIT.DESCR,'')											FAIT
,RIGHT(LTRIM(RTRIM(FC.GL_CODE)),4)									BSV
,FC.GL_CODE
,FT.ID_SA_FE_01														ID_SA
,FT.ID_FE_01														ID_FE
,SUM(FT.AMT)

FROM
VCRO_FIN_TRANS														FT
INNER JOIN
VCRO_FIN_CODE														FC
ON (FT.DBID_FC_01 = FC.DBID OR FT.DBID_FC_02 = FC.DBID)
INNER JOIN
VCRO_FIN_ACT_TYP													FAT
ON FT.CD_FAAT_01 = FAT.CD
LEFT OUTER JOIN
VCRO_FA_ITEM_TYPE													FAIT
ON FT.CD_FAIT = FAIT.CD

WHERE
FT.YR_NUM_ACPE_01 = @YEAR
AND FT.PERD_NUM_ACPE_01 = @PERIOD
AND FC.GL_CD_CATGRY = 'NRA'

GROUP BY
FT.YR_NUM_ACPE_01
,FT.PERD_NUM_ACPE_01
,FT.SEQ_NUM_FCPT_01
,FAT.DESCR								
,COALESCE(FAIT.DESCR,'')				
,RIGHT(LTRIM(RTRIM(FC.GL_CODE)),4)		
,FC.GL_CODE
,FT.ID_SA_FE_01	
,FT.ID_FE_01			

RAISERROR('COMPLETED DETAIL',0,1) WITH NOWAIT
--------------------------------------------------------------------------------------------------------
-- WHAT COMES NEXT?
--------------------------------------------------------------------------------------------------------