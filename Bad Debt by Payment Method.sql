SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

USE tempdb
IF EXISTS (SELECT * FROM SYS.OBJECTS WHERE OBJECT_ID = OBJECT_ID ('#ACCTS') AND TYPE = 'U') DROP TABLE #ACCTS
IF EXISTS (SELECT * FROM SYS.OBJECTS WHERE OBJECT_ID = OBJECT_ID ('#RECEIVABLES') AND TYPE = 'U') DROP TABLE #RECEIVABLES
USE MIS

CREATE TABLE #ACCTS			(
ID_SA						BIGINT
,ID_CRAC					INT
,EXTERNAL_SA_ID				INT
,CD_BUSE					CHAR(3)
,CD_ATRO					CHAR(4)
,BRAND_DESCR				VARCHAR(60)
,FIN_LIVE_IND				CHAR(8)
,TYP						CHAR(4)
,SECTOR						CHAR(4)
)

INSERT INTO #ACCTS (
ID_SA			
,ID_CRAC		
,EXTERNAL_SA_ID	
,CD_BUSE		
,CD_ATRO		
,BRAND_DESCR	
,TYP			
,SECTOR			
)

SELECT
SA.ID			
,CA.ID		
,SA.EXTERNAL_SA_ID	
,SA.CD_BUSE		
,BRD.CD_ATRO		
,BRDE.DESCR
,'DOMM'
,'MASS'

FROM
VCRO_SERV_ACCT				SA
INNER JOIN
VCRO_CA_SERV_ACCT			CASA
ON SA.ID = CASA.ID_SA
INNER JOIN
VCRO_CUST_ACCOUNT			CA
ON CASA.ID_CRAC = CA.ID
INNER JOIN
VCRO_BRAND					BRD
ON CA.CD_BRND = BRD.CD
INNER JOIN
VCRO_BRAND_DESCR	BRDE
ON BRD.CD_BRDE = BRDE.CD
INNER JOIN
VCRO_SERVICE_PLAN			SP
ON SA.ID_SP = SP.ID

WHERE
SA.CD_BUSE IN ('ESU','GSS','TSS')
AND BRD.CD_ATRO NOT IN ('BE','BEG')
AND SP.ID_SPTY IN ('EDK','ESD','GSD','GSP','TDB')
--AND SA.TRUE_BAL_AMT > '0'

CREATE INDEX ACCTS ON #ACCTS (ID_SA)

UPDATE #ACCTS

SET #ACCTS.FIN_LIVE_IND = FL.STATUS
FROM (
SELECT CA.ID, CASE WHEN MAX(SA.DISP_END_DT) > GETDATE() THEN 'LIVE' ELSE 'FINALLED' END STATUS
FROM
VCRO_SERV_ACCT				SA
INNER JOIN
VCRO_CA_SERV_ACCT			CASA
ON SA.ID = CASA.ID_SA
INNER JOIN
VCRO_CUST_ACCOUNT			CA
ON CASA.ID_CRAC = CA.ID
GROUP BY
CA.ID
) FL
WHERE #ACCTS.ID_CRAC = FL.ID


SELECT
DWO.YEAR
,DWO.PERIOD
,ACCTS.CD_BUSE
,CASE
	WHEN PSPM.CD_PMET = 'DDB' THEN 'MTHLY DD/SO'					
	WHEN PSPM.CD_PMET = 'DCA' THEN 'MTHLY DD/SO'					
	WHEN PSPM.CD_PMET = 'DDV' THEN 'QTLY DD'					
	WHEN PSPM.CD_PMET = 'DDA' THEN 'MTHLY DD/SO'					
	WHEN PSPM.CD_PMET = 'CCA' THEN 'MTHLY DD/SO'					
	WHEN PSPM.CD_PMET = 'DCV' THEN 'QTLY DD'					
	WHEN PSPM.CD_PMET = 'SOR' THEN 'MTHLY DD/SO'		
	WHEN PSPM.CD_PMET IN ('UNS','') OR PSPM.CD_PMET IS NULL THEN ''					
	ELSE PSPM.CD_PMET END																								PAYMENT_METHOD
,CASE					
	WHEN PP.CODE_PPTY IN ('KBM','TKM','SPG') THEN 'PREPAYMENT'					
	ELSE ''	END																											PAY_TYPE
,COUNT(DISTINCT ACCTS.ID_SA)																							COUNT_ACCOUNTS																						
,SUM(DWO.AMT)

FROM
VMI_DEBT_WRITE_OFF2020																									DWO
INNER JOIN
#ACCTS																													ACCTS
ON DWO.ID_SA = ACCTS.ID_SA
LEFT OUTER JOIN
VCRO_PAYMENT_PLAN																										PP
ON DWO.ID_PPLA = PP.ID
LEFT OUTER JOIN (
SELECT DISTINCT ID_PPLA, MAX(NUM_PSCH) NUM_PSCH FROM VCRO_PAYMENT_SCHED GROUP BY ID_PPLA
) AS																													PS
ON PP.ID = PS.ID_PPLA
LEFT OUTER JOIN (
SELECT DISTINCT ID_PPLA, CD_PMET, MAX(NUM_PSCH) NUM_PSCH FROM VCRO_PS_PYMT_MTHD GROUP BY ID_PPLA, CD_PMET
) AS																													PSPM
ON PS.ID_PPLA = PSPM.ID_PPLA AND PS.NUM_PSCH = PSPM.NUM_PSCH
LEFT OUTER JOIN (
SELECT DISTINCT ID_PPLA, CODE_PMED, MAX(NUM_PSCH) NUM_PSCH FROM VCRO_PAY_MED_ISSUE GROUP BY ID_PPLA, CODE_PMED
) AS																													PMI
ON PS.ID_PPLA = PMI.ID_PPLA AND PS.NUM_PSCH = PMI.NUM_PSCH
LEFT OUTER JOIN (
SELECT DISTINCT ID_CRAC, MAX(CLO_DT) CLO_DT FROM VCRO_COLL_CASE GROUP BY ID_CRAC
) AS																													CC
ON ACCTS.ID_CRAC = CC.ID_CRAC

WHERE
DWO.YEAR = '2020'
AND DWO.PERIOD < '11'
AND DWO.CD_FAIT IN ('DWO','BDR')

GROUP BY
DWO.YEAR
,DWO.PERIOD
,ACCTS.CD_BUSE
,CASE
	WHEN PSPM.CD_PMET = 'DDB' THEN 'MTHLY DD/SO'					
	WHEN PSPM.CD_PMET = 'DCA' THEN 'MTHLY DD/SO'					
	WHEN PSPM.CD_PMET = 'DDV' THEN 'QTLY DD'					
	WHEN PSPM.CD_PMET = 'DDA' THEN 'MTHLY DD/SO'					
	WHEN PSPM.CD_PMET = 'CCA' THEN 'MTHLY DD/SO'					
	WHEN PSPM.CD_PMET = 'DCV' THEN 'QTLY DD'					
	WHEN PSPM.CD_PMET = 'SOR' THEN 'MTHLY DD/SO'		
	WHEN PSPM.CD_PMET IN ('UNS','') OR PSPM.CD_PMET IS NULL THEN ''	
	ELSE PSPM.CD_PMET END											
,CASE					
	WHEN PP.CODE_PPTY IN ('KBM','TKM','SPG') THEN 'PREPAYMENT'		
	ELSE ''	END														