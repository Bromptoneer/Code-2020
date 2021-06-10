------------------------------------------------------------------------------------------------------------------------------------------------------------
-- SET UP THE QUERY
------------------------------------------------------------------------------------------------------------------------------------------------------------
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

USE tempdb
IF EXISTS (SELECT * FROM SYS.OBJECTS WHERE OBJECT_ID = OBJECT_ID ('#ACCTS') AND TYPE = 'U') DROP TABLE #ACCTS
IF EXISTS (SELECT * FROM SYS.OBJECTS WHERE OBJECT_ID = OBJECT_ID ('#RECEIVABLES') AND TYPE = 'U') DROP TABLE #RECEIVABLES
IF EXISTS (SELECT * FROM SYS.OBJECTS WHERE OBJECT_ID = OBJECT_ID ('#LAST_PAYMENT') AND TYPE = 'U') DROP TABLE #LAST_PAYMENT
USE MIS

CREATE TABLE #ACCTS			(
ID_SA						BIGINT
,ID_CRAC					INT
,EXTERNAL_SA_ID				INT
,CD_BUSE					CHAR(3)
,CD_ATRO					CHAR(4)
,BRAND_DESCR				VARCHAR(60)
,FIN_LIVE_IND				CHAR(8)
,ACTV_DT_SA					DATETIME
,FINALLED_DT				DATETIME
,AGEING_DT					DATETIME
,PREPAYMENT_SITE			CHAR(1)
,TRUE_BAL_AMT				DECIMAL(11,2)
)

CREATE INDEX ACCTS ON #ACCTS (ID_SA, ID_CRAC, PREPAYMENT_SITE)

CREATE TABLE #RECEIVABLES	(
ID_RECV						BIGINT	
,ID_SA						BIGINT
,ID_PPLA					BIGINT
,AGE_QT						CHAR(16)
,AGED_ACTIVE_QT				CHAR(6)
,AGE_MO						CHAR(17)
,AGED_ACTIVE_MO				CHAR(6)
,CUR_BAL_AMT				DECIMAL(11,2)
,RUN_YEAR					CHAR(4)
,RUN_PERIOD					SMALLINT
							)

CREATE INDEX RECV ON #RECEIVABLES (ID_RECV, ID_SA, ID_PPLA)

CREATE TABLE #LAST_PAYMENT	(
ID_SA						BIGINT
,LAST_PAYMENT_DATE			DATETIME
							)

CREATE INDEX PAY ON #LAST_PAYMENT (ID_SA)
------------------------------------------------------------------------------------------------------------------------------------------------------------
-- SELECT RETAIL ACCOUNTS TO USE AS A DRIVER 
------------------------------------------------------------------------------------------------------------------------------------------------------------
INSERT INTO #ACCTS (
ID_SA			
,ID_CRAC		
,EXTERNAL_SA_ID	
,CD_BUSE		
,CD_ATRO		
,BRAND_DESCR
,ACTV_DT_SA	
,PREPAYMENT_SITE	
,TRUE_BAL_AMT
)

SELECT
SA.ID			
,CA.ID		
,SA.EXTERNAL_SA_ID	
,SA.CD_BUSE		
,BRD.CD_ATRO		
,BRDE.DESCR
,SA.DISP_EFTV_DT
,CASE 
	WHEN SP.ID_SPTY IN ('EDK','GSP') THEN 'Y'
	ELSE 'N'
	END
,SA.TRUE_BAL_AMT

FROM
VCRO_SERV_ACCT																																SA
INNER JOIN
VCRO_CA_SERV_ACCT																															CASA
ON SA.ID = CASA.ID_SA
INNER JOIN
VCRO_CUST_ACCOUNT																															CA
ON CASA.ID_CRAC = CA.ID
INNER JOIN
VCRO_BRAND																																	BRD
ON CA.CD_BRND = BRD.CD
INNER JOIN
VCRO_BRAND_DESCR	BRDE
ON BRD.CD_BRDE = BRDE.CD
INNER JOIN
VCRO_SERVICE_PLAN																															SP
ON SA.ID_SP = SP.ID

WHERE
SA.CD_BUSE IN ('ESU','GSS','TSS')
AND BRD.CD_ATRO NOT IN ('BE','BEG')
AND SP.ID_SPTY IN ('EDK','ESD','GSD','GSP','TDB')
AND SA.TRUE_BAL_AMT > '0'

UPDATE #ACCTS

SET #ACCTS.FIN_LIVE_IND = FL.STATUS
FROM	(
		SELECT
		CA.ID 
		,CASE WHEN MAX(SA.DISP_END_DT) > GETDATE() THEN 'LIVE' ELSE 'FINALLED' END STATUS
		FROM
		VCRO_SERV_ACCT																														SA
		INNER JOIN
		VCRO_CA_SERV_ACCT																													CASA
		ON SA.ID = CASA.ID_SA
		INNER JOIN
		VCRO_CUST_ACCOUNT																													CA
		ON CASA.ID_CRAC = CA.ID
		GROUP BY
		CA.ID
		) FL
WHERE #ACCTS.ID_CRAC = FL.ID

UPDATE #ACCTS

SET #ACCTS.FINALLED_DT = FL.FINAL_DT
FROM	(
		SELECT
		CA.ID
		,CASE WHEN MAX(SA.DISP_END_DT) > GETDATE() THEN '9999-12-31' ELSE MAX(SA.DISP_END_DT) END FINAL_DT
		FROM
		VCRO_SERV_ACCT																														SA
		INNER JOIN
		VCRO_CA_SERV_ACCT																													CASA
		ON SA.ID = CASA.ID_SA
		INNER JOIN
		VCRO_CUST_ACCOUNT																													CA
		ON CASA.ID_CRAC = CA.ID
		GROUP BY
		CA.ID
		) FL
WHERE #ACCTS.ID_CRAC = FL.ID

UPDATE #ACCTS
SET #ACCTS.PREPAYMENT_SITE = 'N' 
WHERE #ACCTS.PREPAYMENT_SITE = 'Y' AND #ACCTS.FIN_LIVE_IND = 'FINALLED'
------------------------------------------------------------------------------------------------------------------------------------------------------------
-- SELECT RECEIVEABLES FOR PREPAYMENT SITES SO THAT AN OPEN ITEM DEBTORS POSITION CAN BE ESTABLISHED
------------------------------------------------------------------------------------------------------------------------------------------------------------
INSERT INTO #RECEIVABLES

SELECT
RECV.ID
,RECV.ID_SA			
,RECV.ID_PPLA		
,CASE
	WHEN DATEDIFF(DAY,RECV.DISP_CRET_DT,GETDATE()) BETWEEN '0' AND '91' THEN 'A__0 TO 3 MTHS'
	WHEN DATEDIFF(DAY,RECV.DISP_CRET_DT,GETDATE()) BETWEEN '92' AND '182' THEN 'B__4 TO 6 MTHS'					
	WHEN DATEDIFF(DAY,RECV.DISP_CRET_DT,GETDATE()) BETWEEN '183' AND '274' THEN 'C__7 TO 9 MTHS'					
	WHEN DATEDIFF(DAY,RECV.DISP_CRET_DT,GETDATE()) BETWEEN '274' AND '365' THEN 'D__10 TO 12 MTHS'						
	ELSE 'E__OVER 12 MTHS' END					
,CASE			
	WHEN DATEDIFF(M,RECV.DISP_CRET_DT,GETDATE()) BETWEEN '0' AND '6' THEN 'ACTIVE'
	ELSE 'AGED' END	
,CASE
	WHEN DATEDIFF(D,RECV.DISP_CRET_DT,GETDATE()) BETWEEN '0' AND '30' THEN 'A: 0 TO 30 DAYS'	
	WHEN DATEDIFF(D,RECV.DISP_CRET_DT,GETDATE()) BETWEEN '31' AND '60' THEN 'B; 31 TO 60 DAYS'				
	WHEN DATEDIFF(D,RECV.DISP_CRET_DT,GETDATE()) BETWEEN '61' AND '90' THEN 'C: 61 TO 90 DAYS'				
	WHEN DATEDIFF(D,RECV.DISP_CRET_DT,GETDATE()) BETWEEN '91' AND '120' THEN 'D: 91 TO 120 DAYS'					
	ELSE 'E: OVER 121 DAYS' END					
,CASE			
	WHEN DATEDIFF(D,RECV.DISP_CRET_DT,GETDATE()) BETWEEN '0' AND '60' THEN 'ACTIVE'			
	ELSE 'AGED' END	
,RECV.CUR_BAL_AMT	
,(SELECT YR_NUM FROM VCRO_ACCT_PERIOD WHERE TYP = 'GL' AND GETDATE() BETWEEN STRT_DT AND END_DT)
,(SELECT PERD_NUM FROM VCRO_ACCT_PERIOD WHERE TYP = 'GL' AND GETDATE() BETWEEN STRT_DT AND END_DT)

FROM
VCRO_RECEIVABLE																																RECV
INNER JOIN
#ACCTS																																		ACCTS
ON RECV.ID_SA = ACCTS.ID_SA

WHERE
RECV.CUR_BAL_AMT > '0'
AND RECV.ID_SA IN (SELECT ID_SA FROM #ACCTS WHERE PREPAYMENT_SITE = 'Y')
------------------------------------------------------------------------------------------------------------------------------------------------------------
-- SELECT THE LAST PAYMENT RECEIVED FOR NON-PREPAYMENT SITES SO THAT ANY SA BALANCE CAN BE AGED ON A BALANCE FORWARD BASIS
------------------------------------------------------------------------------------------------------------------------------------------------------------
INSERT INTO #LAST_PAYMENT

SELECT
ACCTS.ID_SA
,MAX(PAY.DISP_RCVD_TMSTMP)

FROM
VCRO_PAYMENT																																PAY
INNER JOIN
#ACCTS																																		ACCTS
ON PAY.ID_CRAC = ACCTS.ID_CRAC

WHERE
ACCTS.PREPAYMENT_SITE = 'N'

GROUP BY
ACCTS.ID_SA
------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ADD AN AGEING DATE TO THE ACCOUNTS TABLE:
-- WHERE THE ACCOUNT IS PREPAYMENT THIS WILL BE A HIGH DATE (9999-12-31) AS PREPAYMENT WILL BE AGED BASED ON RECEIVABLES
-- WHERE THE ACCOUNT IS FINALLED THIS WILL BE THE FINALLED DATE
-- WHERE THE ACCOUNT IS LIVE AND PAYING THIS WILL BE THE DATE OF THE LAST PAYMENT
-- WHERE THE ACCOUNT IS LIVE BUT NOT PAYING THIS WILL BE THE SA START DATE
------------------------------------------------------------------------------------------------------------------------------------------------------------
UPDATE #ACCTS
SET #ACCTS.AGEING_DT = '9999-12-31'
WHERE #ACCTS.PREPAYMENT_SITE = 'Y'

UPDATE #ACCTS
SET #ACCTS.AGEING_DT = #ACCTS.FINALLED_DT
WHERE 
#ACCTS.FIN_LIVE_IND = 'FINALLED' 
AND #ACCTS.FINALLED_DT <= GETDATE()
AND #ACCTS.PREPAYMENT_SITE = 'N'

UPDATE #ACCTS
SET #ACCTS.AGEING_DT = AD.DT 
FROM(
SELECT
ID_SA
,LAST_PAYMENT_DATE DT
FROM
#LAST_PAYMENT
) AD
WHERE
#ACCTS.ID_SA = AD.ID_SA 
AND #ACCTS.FIN_LIVE_IND = 'LIVE' 
AND #ACCTS.PREPAYMENT_SITE = 'N'

UPDATE #ACCTS
SET #ACCTS.AGEING_DT = #ACCTS.ACTV_DT_SA
WHERE 
#ACCTS.ID_SA NOT IN (SELECT ID_SA FROM #LAST_PAYMENT)
AND #ACCTS.FIN_LIVE_IND = 'LIVE' 
AND #ACCTS.PREPAYMENT_SITE = 'N'
------------------------------------------------------------------------------------------------------------------------------------------------------------
-- EXTRACT THE DEBTORS POSITION FOR DD & OD ALIGNED TO THE NEW METHODOLOGY
------------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT
ACCTS.CD_BUSE
,RTRIM(ACCTS.FIN_LIVE_IND)																													FIN_LIVE_IND
,CASE
	WHEN PSPM.CD_PMET IN ('DDB','DCA','CCA') THEN 'DD'
	ELSE 'MCC'
	END																																		PAYMENT_METHOD
,CASE
	WHEN ACCTS.FIN_LIVE_IND = 'LIVE' AND DATEDIFF(DAY,ACCTS.AGEING_DT,GETDATE()) <= '34' THEN '1. Live 0-34 DAYS'
	WHEN ACCTS.FIN_LIVE_IND = 'LIVE' AND DATEDIFF(DAY,ACCTS.AGEING_DT,GETDATE()) BETWEEN '35' AND '60' THEN '2. Live 35-60 DAYS'
	WHEN ACCTS.FIN_LIVE_IND = 'LIVE' AND DATEDIFF(DAY,ACCTS.AGEING_DT,GETDATE()) BETWEEN '61' AND '90' THEN '3. Live 61-90 DAYS'
	WHEN ACCTS.FIN_LIVE_IND = 'LIVE' AND DATEDIFF(DAY,ACCTS.AGEING_DT,GETDATE()) BETWEEN '91' AND '360' THEN '4. Live 91-360 DAYS'
	WHEN ACCTS.FIN_LIVE_IND = 'LIVE' AND DATEDIFF(DAY,ACCTS.AGEING_DT,GETDATE()) BETWEEN '361' AND '720' THEN '5. Live 361-720 DAYS'
	WHEN ACCTS.FIN_LIVE_IND = 'LIVE' AND DATEDIFF(DAY,ACCTS.AGEING_DT,GETDATE()) > '720' THEN '6. Live > 720 DAYS'
	WHEN ACCTS.FIN_LIVE_IND = 'FINALLED' AND DATEDIFF(MONTH,ACCTS.AGEING_DT,GETDATE()) < '3' THEN '7. Lost 1-2 Months'
	WHEN ACCTS.FIN_LIVE_IND = 'FINALLED' AND DATEDIFF(MONTH,ACCTS.AGEING_DT,GETDATE()) BETWEEN '3' AND '6' THEN '8. Lost 3-6 Months'
	WHEN ACCTS.FIN_LIVE_IND = 'FINALLED' AND DATEDIFF(MONTH,ACCTS.AGEING_DT,GETDATE()) BETWEEN '7' AND '12' THEN '9. Lost 7-12 Months'
	WHEN ACCTS.FIN_LIVE_IND = 'FINALLED' AND DATEDIFF(MONTH,ACCTS.AGEING_DT,GETDATE()) > '12' THEN '10. Lost 12 Months+'
	END																																		AGE_CATEGORY
,SUM(ACCTS.TRUE_BAL_AMT)																													DEBT

FROM
#ACCTS																																		ACCTS
LEFT OUTER JOIN
VCRO_PAYMENT_PLAN																															PP
ON ACCTS.ID_CRAC = PP.ID_CRAC AND PP.CLOSE_DT >GETDATE()
LEFT OUTER JOIN (
SELECT DISTINCT ID_PPLA, MAX(NUM_PSCH) NUM_PSCH FROM VCRO_PAYMENT_SCHED GROUP BY ID_PPLA
)																																			PS
ON PP.ID = PS.ID_PPLA
LEFT OUTER JOIN (
SELECT DISTINCT ID_PPLA, CD_PMET, MAX(NUM_PSCH) NUM_PSCH FROM VCRO_PS_PYMT_MTHD GROUP BY ID_PPLA, CD_PMET
)																																			PSPM
ON PS.ID_PPLA = PSPM.ID_PPLA AND PS.NUM_PSCH = PSPM.NUM_PSCH

WHERE
ACCTS.PREPAYMENT_SITE = 'N'

GROUP BY
ACCTS.CD_BUSE
,RTRIM(ACCTS.FIN_LIVE_IND)	
,CASE
	WHEN PSPM.CD_PMET IN ('DDB','DCA','CCA') THEN 'DD'
	ELSE 'MCC'
	END																							
,CASE
	WHEN ACCTS.FIN_LIVE_IND = 'LIVE' AND DATEDIFF(DAY,ACCTS.AGEING_DT,GETDATE()) <= '34' THEN '1. Live 0-34 DAYS'
	WHEN ACCTS.FIN_LIVE_IND = 'LIVE' AND DATEDIFF(DAY,ACCTS.AGEING_DT,GETDATE()) BETWEEN '35' AND '60' THEN '2. Live 35-60 DAYS'
	WHEN ACCTS.FIN_LIVE_IND = 'LIVE' AND DATEDIFF(DAY,ACCTS.AGEING_DT,GETDATE()) BETWEEN '61' AND '90' THEN '3. Live 61-90 DAYS'
	WHEN ACCTS.FIN_LIVE_IND = 'LIVE' AND DATEDIFF(DAY,ACCTS.AGEING_DT,GETDATE()) BETWEEN '91' AND '360' THEN '4. Live 91-360 DAYS'
	WHEN ACCTS.FIN_LIVE_IND = 'LIVE' AND DATEDIFF(DAY,ACCTS.AGEING_DT,GETDATE()) BETWEEN '361' AND '720' THEN '5. Live 361-720 DAYS'
	WHEN ACCTS.FIN_LIVE_IND = 'LIVE' AND DATEDIFF(DAY,ACCTS.AGEING_DT,GETDATE()) > '720' THEN '6. Live > 720 DAYS'
	WHEN ACCTS.FIN_LIVE_IND = 'FINALLED' AND DATEDIFF(MONTH,ACCTS.AGEING_DT,GETDATE()) < '3' THEN '7. Lost 1-2 Months'
	WHEN ACCTS.FIN_LIVE_IND = 'FINALLED' AND DATEDIFF(MONTH,ACCTS.AGEING_DT,GETDATE()) BETWEEN '3' AND '6' THEN '8. Lost 3-6 Months'
	WHEN ACCTS.FIN_LIVE_IND = 'FINALLED' AND DATEDIFF(MONTH,ACCTS.AGEING_DT,GETDATE()) BETWEEN '7' AND '12' THEN '9. Lost 7-12 Months'
	WHEN ACCTS.FIN_LIVE_IND = 'FINALLED' AND DATEDIFF(MONTH,ACCTS.AGEING_DT,GETDATE()) > '12' THEN '10. Lost 12 Months+'
	END																		
------------------------------------------------------------------------------------------------------------------------------------------------------------
-- EXTRACT THE DEBTORS POSITION FOR PREPAYMENT WITH OPEN ITEM AGEING
------------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT
ACCTS.CD_BUSE
,RTRIM(ACCTS.FIN_LIVE_IND)	FIN_LIVE_IND
,'PREPAYMENT'																																PAYMENT_METHOD
,RTRIM(RECV.AGE_QT)																															AGE_CATEGORY
,SUM(RECV.CUR_BAL_AMT)																														DEBT

FROM
#ACCTS																																		ACCTS
INNER JOIN
#RECEIVABLES																																RECV
ON ACCTS.ID_SA = RECV.ID_SA

WHERE
ACCTS.PREPAYMENT_SITE = 'Y'

GROUP BY
ACCTS.CD_BUSE
,ACCTS.FIN_LIVE_IND
,RECV.AGE_QT
------------------------------------------------------------------------------------------------------------------------------------------------------------
-- END
------------------------------------------------------------------------------------------------------------------------------------------------------------
