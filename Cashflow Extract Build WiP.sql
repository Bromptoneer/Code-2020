SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- CREATE A TABLE TO HOLD THE BULK OF THE REQUIRED DATA
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE TABLE MISUSERDATA.[UK\PB32946].CASHFLOW_POSITION_DATA_1 (
CORE_MPAN_MPNT														BIGINT
,ID_SA																BIGINT
,EXTERNAL_SA_ID														VARCHAR(15)
,ID_CRAC															INT
,SUPPLIER_TYPE														VARCHAR(6)
,SUPPLIER_EFTV_DT													DATETIME
,SUPPLIER_END_DT													DATETIME
,DAYS_SUP_EFTV														INT
,REG_STAT															VARCHAR(4)
,SERVICE_PLAN														VARCHAR(60)
,BLFR																VARCHAR(2)
,SMART																VARCHAR(1)
,DUAL_FUEL															VARCHAR(1)
,NUMBER_RATES														INT
,DAY_UNIT_RATE														DECIMAL(14,6)
,NIGHT_UNIT_RATE													DECIMAL(14,6)
,DAILY_STANDING_CHARGE												DECIMAL(14,6)
,LAST_BILL_TO_DT													DATETIME
,NEXT_BILL_DT														DATETIME
,NEXT_SCHEDULED_R_E													VARCHAR(1)
,PREPAYMENT_SITE													VARCHAR(1)
,PAYMENT_PLAN														VARCHAR(60)
,PAYMENT_INTERVAL													VARCHAR(60)
,LAST_PAYMENT_DT													DATETIME
,LAST_PAYMENT_AMOUNT												DECIMAL(11,2)
,NEXT_PAYMENT_DATE													DATETIME
,NEXT_PAYMENT_AMT													DECIMAL(11,2)
,TRUE_BAL_AMT														DECIMAL(11,2)
,[EAC/AQ]															DECIMAL(15,2)
)
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- PUT THE PORTFOLIO DATA INTO THE TABLE
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
INSERT INTO MISUSERDATA.[UK\PB32946].CASHFLOW_POSITION_DATA_1 (
CORE_MPAN_MPNT		
,ID_SA				
,EXTERNAL_SA_ID		
,ID_CRAC			
,SUPPLIER_TYPE		
,SUPPLIER_EFTV_DT	
,SUPPLIER_END_DT	
,DAYS_SUP_EFTV		
,REG_STAT			
,SERVICE_PLAN		
,BLFR				
,SMART				
,DUAL_FUEL			
,NUMBER_RATES			
,NEXT_BILL_DT		
,NEXT_SCHEDULED_R_E	
,PREPAYMENT_SITE	
,PAYMENT_PLAN		
,PAYMENT_INTERVAL	
,NEXT_PAYMENT_DATE	
,NEXT_PAYMENT_AMT		
,[EAC/AQ]				
)

SELECT
PORT.CORE_MPAN_MPNT
,PORT.ID_SA
,PORT.EXTERNAL_SA_ID
,PORT.ID_CRAC
,PORT.SUPPLIER_TYPE
,PORT.SUPPLIER_EFTV_DT
,PORT.SUPPLIER_END_DT
,PORT.DAYS_SUP_EFTV
,PORT.REG_STAT
,PORT.SERVICE_PLAN
,PORT.BLFR
,PORT.SMART
,PORT.DUAL_FUEL
,PORT.NUMBER_RATES
,PORT.NEXT_BILL_DT
,PORT.NEXT_SCHEDULED_R_E
,PORT.PREPAYMENT_SITE
,PORT.PAYMENT_PLAN
,PORT.PAYMENT_INTERVAL
,PORT.NEXT_PAYMENT_DATE
,PORT.NEXT_PAYMENT_AMT
,PORT.[EAC/AQ]

FROM
MISUSERDATA.[UK\DC43967].PORTFOLIO_FOR_SMART_WASHES					PORT

WHERE
PORT.NON_DOM = 'N'
AND PORT.CHP = 'N'
AND PORT.ERRONEOUS_TRANSFER = 'N'
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ADD THE SA TRUE BALANCE AMOUNT
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
UPDATE MISUSERDATA.[UK\PB32946].CASHFLOW_POSITION_DATA_1
SET MISUSERDATA.[UK\PB32946].CASHFLOW_POSITION_DATA_1.TRUE_BAL_AMT = SA.TRUE_BAL_AMT
FROM (
	SELECT
	SA.ID
	,SA.TRUE_BAL_AMT 
	FROM 
	VCRO_SERV_ACCT	SA
	INNER JOIN
	MISUSERDATA.[UK\PB32946].CASHFLOW_POSITION_DATA_1	PORT
	ON SA.ID = PORT.ID_SA
	)	SA
WHERE
MISUSERDATA.[UK\PB32946].CASHFLOW_POSITION_DATA_1.ID_SA = SA.ID
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ADD THE DATE OF THE READING FROM THE LAST INVOICE
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
UPDATE MISUSERDATA.[UK\PB32946].CASHFLOW_POSITION_DATA_1
SET MISUSERDATA.[UK\PB32946].CASHFLOW_POSITION_DATA_1.LAST_BILL_TO_DT = SAST.MAX_BILL_DT
FROM (
	SELECT
	SAST.ID_SA
	,MAX(SAST.BILG_END_DT)	MAX_BILL_DT
	FROM
	VCRO_SA_STATEMENT	SAST
	INNER JOIN
	MISUSERDATA.[UK\PB32946].CASHFLOW_POSITION_DATA_1 PORT
	ON SAST.ID_SA = PORT.ID_SA
	GROUP BY
	SAST.ID_SA
	) SAST
WHERE MISUSERDATA.[UK\PB32946].CASHFLOW_POSITION_DATA_1.ID_SA = SAST.ID_SA
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- NEED TO GET SOME PRICE DATA
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- SAMPLE
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT
TOP 1000 *
FROM
MISUSERDATA.[UK\PB32946].CASHFLOW_POSITION_DATA_1