USE tempdb
IF EXISTS (SELECT * FROM SYS.OBJECTS WHERE OBJECT_ID = OBJECT_ID ('#BILLS') AND TYPE = 'U') DROP TABLE #BILLS
IF EXISTS (SELECT * FROM SYS.OBJECTS WHERE OBJECT_ID = OBJECT_ID ('#SALES') AND TYPE = 'U') DROP TABLE #SALES
USE MIS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @YEAR CHAR(4)
DECLARE @BUILD_PERIOD CHAR(2)
SET @YEAR = '2020'
SET @BUILD_PERIOD = '12'

--------------------------------------------------------------------------------------------------------------------------------------
-- RUN THIS FIRST SEGMENT TO BUILD THE DATA, THEN SKIP TO THE SECOND SECTION TO GENERATE RESULTS
--------------------------------------------------------------------------------------------------------------------------------------

CREATE TABLE #BILLS (
YR_NUM_ACPE_01												CHAR(4)
,PERD_NUM_ACPE_01											CHAR(2)
,EXTERNAL_SA_ID												INT
,FINANCIAL_ACTION_TYPE										VARCHAR(30)					
,FINANCIAL_ACTION_ITEM_TYPE									VARCHAR(30)	
,GL_CODE													VARCHAR(33)	
,SERVICE_PLAN												VARCHAR(50)			
,CRET_DT													DATE
,BILG_STRT_DT												DATE
,BILG_END_DT												DATE
,BILG_PERD													VARCHAR(30)													
,ID_BLFR													CHAR(2)
,AMT														DECIMAL(11,2)			
)

INSERT INTO #BILLS

SELECT
FT.YR_NUM_ACPE_01
,FT.PERD_NUM_ACPE_01
,SA.EXTERNAL_SA_ID
,FAT.DESCR													
,FAIT.DESCR													
,FC.GL_CODE
,SP.DESCR													
,SAST.CRET_DT
,SAST.BILG_STRT_DT
,SAST.BILG_END_DT
,BLPE.BILG_PERD
,SAST.ID_BLFR
,SUM(FT.AMT)												

FROM
VCRO_SA_STATEMENT											SAST
INNER JOIN
VCRO_FIN_ENTRY												FE
ON SAST.ID_SA = FE.ID_SA AND SAST.SEQ_NUM = FE.SEQ_NUM_SASM
INNER JOIN
VCRO_FIN_TRANS												FT
ON FE.ID_SA = FT.ID_SA_FE_01 AND FE.ID = FT.ID_FE_01 AND FE.CD_FAAT_01 = FT.CD_FAAT_01 AND SAST.ID_SA = FT.ID_SA_FE_01
INNER JOIN
VCRO_FIN_CODE												FC
ON FT.DBID_FC_01 = FC.DBID
INNER JOIN
VCRO_SERV_ACCT												SA
ON SAST.ID_SA = SA.ID
INNER JOIN
VCRO_FIN_ACT_TYP											FAT
ON FT.CD_FAAT_01 = FAT.CD
INNER JOIN
VCRO_FA_ITEM_TYPE											FAIT
ON FT.CD_FAIT = FAIT.CD
INNER JOIN
VCRO_BILLING_PERD											BLPE
ON SAST.DBID_BLPE = BLPE.DBID
INNER JOIN
VCRO_SERVICE_PLAN											SP
ON SA.ID_SP = SP.ID

WHERE
SAST.CD_BUSE = 'TSS'
AND FT.YR_NUM_ACPE_01 = @YEAR
AND FT.PERD_NUM_ACPE_01 <= @BUILD_PERIOD
AND FT.CD_FAAT_01 IN ('BLG','MCC')
AND FC.GL_CODE LIKE ('3%')
AND SAST.STAT_CD NOT IN ('C','V')
AND SAST.TYP_CD IN ('B','R') 

GROUP BY
FT.YR_NUM_ACPE_01
,FT.PERD_NUM_ACPE_01
,SA.EXTERNAL_SA_ID
,FAT.DESCR			
,FAIT.DESCR			
,FC.GL_CODE
,SP.DESCR			
,SAST.CRET_DT
,SAST.BILG_STRT_DT
,SAST.BILG_END_DT
,BLPE.BILG_PERD
,SAST.ID_BLFR

CREATE INDEX BILLS ON #BILLS (
YR_NUM_ACPE_01				
,PERD_NUM_ACPE_01			
,EXTERNAL_SA_ID				
,FINANCIAL_ACTION_TYPE		
,FINANCIAL_ACTION_ITEM_TYPE	
,SERVICE_PLAN
)


CREATE TABLE #SALES (
YR_NUM_ACPE_01												CHAR(4)
,PERD_NUM_ACPE_01											CHAR(2)
,EXTERNAL_SA_ID												INT
,BILG_PERD													VARCHAR(30)					
,FINANCIAL_ACTION_TYPE										VARCHAR(30)					
,FINANCIAL_ACTION_ITEM_TYPE									VARCHAR(30)					
,BUS_USE													CHAR(3)
,CD_ATRO													CHAR(4)
,SERVICE_PLAN												VARCHAR(50)
,COMPONENT_GROUP_DESCR										VARCHAR(30)	
,COMPONENT_TYPE_DESCR										VARCHAR(30)	
,COMPONENT_DESCR											VARCHAR(30)	
,ACCOUNT_CODE												CHAR(7)
,COST_CENTRE												CHAR(4)
,BSV														CHAR(4)
,AMT														DECIMAL(11,2)
)

INSERT INTO #SALES

SELECT
SALES.FIN_YEAR
,SALES.MONTH
,EXTERNAL_SA_ID
,BLPE.BILG_PERD
,FAT.DESCR									
,FAIT.DESCR									
,SALES.BUS_USE
,SALES.CD_ATRO
,SP.DESCR									
,COMGRP.DESCR								
,COMTYP.DESCR								
,SPCMP.DESCR								
,SALES.ACCOUNT_CODE
,SALES.COST_CENTRE
,SALES.JOB_NUMBER													
,SUM(SALES.REVENUE)

FROM
VMI_SALES_REPORT_DETAIL										SALES
INNER JOIN
VCRO_BILLING_PERD											BLPE
ON SALES.BILL_PERIOD_KEY = BLPE.DBID
INNER JOIN
VCRO_FIN_ACT_TYP											FAT
ON SALES.FAT = FAT.CD
INNER JOIN
VCRO_FA_ITEM_TYPE											FAIT
ON SALES.FAIT = FAIT.CD
INNER JOIN
VCRO_SERVICE_PLAN											SP
ON SALES.SERVICE_PLAN = SP.ID
INNER JOIN
VCRO_COMPONENT_GRP											COMGRP
ON SALES.COMPONENT_GROUP_ID = COMGRP.ID
INNER JOIN
VCRO_COMPONENT_TYP											COMTYP
ON SALES.COMPONENT_TYPE_ID = COMTYP.ID
INNER JOIN
VCRO_SERV_PLN_COMP											SPCMP
ON SALES.COMPONENT_ID = SPCMP.DBID

WHERE
SALES.FIN_YEAR = @YEAR
AND SALES.MONTH <= @BUILD_PERIOD
AND SALES.BUS_USE = 'TSS'

GROUP BY
SALES.FIN_YEAR
,SALES.MONTH
,EXTERNAL_SA_ID
,BLPE.BILG_PERD
,FAT.DESCR			
,FAIT.DESCR			
,SALES.BUS_USE
,SALES.CD_ATRO
,SP.DESCR			
,COMGRP.DESCR		
,COMTYP.DESCR		
,SPCMP.DESCR		
,SALES.ACCOUNT_CODE
,SALES.COST_CENTRE
,SALES.JOB_NUMBER

CREATE INDEX SALES ON #SALES (
YR_NUM_ACPE_01				
,PERD_NUM_ACPE_01			
,EXTERNAL_SA_ID				
,FINANCIAL_ACTION_TYPE		
,FINANCIAL_ACTION_ITEM_TYPE	
,SERVICE_PLAN
)
--------------------------------------------------------------------------------------------------------------------------------------
-- THE SEGMENT BELOW PRODUCES RESULTS, DO FOR ONE PERIOD AT A TIME BY CHANGING THE VARIABLE
--------------------------------------------------------------------------------------------------------------------------------------
USE MIS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @RESULT_PERIOD CHAR(2)
SET @RESULT_PERIOD = '12'


SELECT
SALES.YR_NUM_ACPE_01
,SALES.PERD_NUM_ACPE_01
,SALES.EXTERNAL_SA_ID
,SALES.FINANCIAL_ACTION_TYPE
,SALES.FINANCIAL_ACTION_ITEM_TYPE
,SALES.SERVICE_PLAN
,SALES.COMPONENT_TYPE_DESCR
,SALES.COMPONENT_GROUP_DESCR
,SALES.COMPONENT_DESCR
,BILLS.GL_CODE
,BILLS.BILG_PERD
,BILLS.CRET_DT
,BILLS.BILG_STRT_DT
,BILLS.BILG_END_DT
,BILLS.ID_BLFR
,BILLS.AMT													BILL_AMOUNT
,SALES.AMT													SALES_AMOUNT

FROM
#BILLS														BILLS
INNER JOIN
#SALES														SALES
ON BILLS.EXTERNAL_SA_ID = SALES.EXTERNAL_SA_ID AND BILLS.FINANCIAL_ACTION_TYPE = SALES.FINANCIAL_ACTION_TYPE AND BILLS.FINANCIAL_ACTION_ITEM_TYPE = SALES.FINANCIAL_ACTION_ITEM_TYPE
	AND BILLS.YR_NUM_ACPE_01 = SALES.YR_NUM_ACPE_01 AND BILLS.PERD_NUM_ACPE_01 = SALES.PERD_NUM_ACPE_01

WHERE
SALES.COMPONENT_TYPE_DESCR = 'TELCO CALLS'
AND SALES.PERD_NUM_ACPE_01 = @RESULT_PERIOD

ORDER BY
SALES.EXTERNAL_SA_ID

SELECT
SALES.YR_NUM_ACPE_01
,SALES.PERD_NUM_ACPE_01
,SALES.EXTERNAL_SA_ID
,SALES.FINANCIAL_ACTION_TYPE
,SALES.FINANCIAL_ACTION_ITEM_TYPE
,SALES.SERVICE_PLAN
,SALES.COMPONENT_TYPE_DESCR
,SALES.COMPONENT_GROUP_DESCR
,SALES.COMPONENT_DESCR
,BILLS.GL_CODE
,BILLS.BILG_PERD
,BILLS.CRET_DT
,BILLS.BILG_STRT_DT
,BILLS.BILG_END_DT
,BILLS.ID_BLFR
,BILLS.AMT													BILL_AMOUNT
,SALES.AMT													SALES_AMOUNT

FROM
#BILLS														BILLS
INNER JOIN
#SALES														SALES
ON BILLS.EXTERNAL_SA_ID = SALES.EXTERNAL_SA_ID AND BILLS.FINANCIAL_ACTION_TYPE = SALES.FINANCIAL_ACTION_TYPE AND BILLS.FINANCIAL_ACTION_ITEM_TYPE = SALES.FINANCIAL_ACTION_ITEM_TYPE
	AND BILLS.YR_NUM_ACPE_01 = SALES.YR_NUM_ACPE_01 AND BILLS.PERD_NUM_ACPE_01 = SALES.PERD_NUM_ACPE_01

WHERE
SALES.COMPONENT_TYPE_DESCR = 'TELCO PACKAGE'
AND SALES.PERD_NUM_ACPE_01 = @RESULT_PERIOD

ORDER BY
SALES.EXTERNAL_SA_ID

SELECT
SALES.YR_NUM_ACPE_01
,SALES.PERD_NUM_ACPE_01
,SALES.EXTERNAL_SA_ID
,SALES.FINANCIAL_ACTION_TYPE
,SALES.FINANCIAL_ACTION_ITEM_TYPE
,SALES.SERVICE_PLAN
,SALES.COMPONENT_TYPE_DESCR
,SALES.COMPONENT_GROUP_DESCR
,SALES.COMPONENT_DESCR
,BILLS.GL_CODE
,BILLS.BILG_PERD
,BILLS.CRET_DT
,BILLS.BILG_STRT_DT
,BILLS.BILG_END_DT
,BILLS.ID_BLFR
,BILLS.AMT													BILL_AMOUNT
,SALES.AMT													SALES_AMOUNT

FROM
#BILLS														BILLS
INNER JOIN
#SALES														SALES
ON BILLS.EXTERNAL_SA_ID = SALES.EXTERNAL_SA_ID AND BILLS.FINANCIAL_ACTION_TYPE = SALES.FINANCIAL_ACTION_TYPE AND BILLS.FINANCIAL_ACTION_ITEM_TYPE = SALES.FINANCIAL_ACTION_ITEM_TYPE
	AND BILLS.YR_NUM_ACPE_01 = SALES.YR_NUM_ACPE_01 AND BILLS.PERD_NUM_ACPE_01 = SALES.PERD_NUM_ACPE_01

WHERE
SALES.COMPONENT_TYPE_DESCR = 'TELCO FEATURE'
AND SALES.PERD_NUM_ACPE_01 = @RESULT_PERIOD

ORDER BY
SALES.EXTERNAL_SA_ID

SELECT
SALES.YR_NUM_ACPE_01
,SALES.PERD_NUM_ACPE_01
,SALES.FINANCIAL_ACTION_TYPE
,SALES.FINANCIAL_ACTION_ITEM_TYPE
,SALES.SERVICE_PLAN
,SALES.COMPONENT_TYPE_DESCR
,SALES.COMPONENT_GROUP_DESCR
,SALES.COMPONENT_DESCR
,BILLS.GL_CODE
,BILLS.BILG_PERD
,BILLS.ID_BLFR
,SUM(BILLS.AMT)												BILL_AMOUNT
,SUM(SALES.AMT)												SALES_AMOUNT

FROM
#BILLS														BILLS
INNER JOIN
#SALES														SALES
ON BILLS.EXTERNAL_SA_ID = SALES.EXTERNAL_SA_ID AND BILLS.FINANCIAL_ACTION_TYPE = SALES.FINANCIAL_ACTION_TYPE AND BILLS.FINANCIAL_ACTION_ITEM_TYPE = SALES.FINANCIAL_ACTION_ITEM_TYPE
	AND BILLS.YR_NUM_ACPE_01 = SALES.YR_NUM_ACPE_01 AND BILLS.PERD_NUM_ACPE_01 = SALES.PERD_NUM_ACPE_01

WHERE
SALES.PERD_NUM_ACPE_01 <= @RESULT_PERIOD

GROUP BY
SALES.YR_NUM_ACPE_01
,SALES.PERD_NUM_ACPE_01
,SALES.FINANCIAL_ACTION_TYPE
,SALES.FINANCIAL_ACTION_ITEM_TYPE
,SALES.SERVICE_PLAN
,SALES.COMPONENT_TYPE_DESCR
,SALES.COMPONENT_GROUP_DESCR
,SALES.COMPONENT_DESCR
,BILLS.GL_CODE
,BILLS.BILG_PERD
,BILLS.ID_BLFR